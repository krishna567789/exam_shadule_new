import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/physical_attendance_controller.dart';

class PhysicalAttendanceScreen extends StatelessWidget {
  PhysicalAttendanceScreen({super.key});

  final PhysicalAttendanceController controller = Get.put(PhysicalAttendanceController());

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Physical Attendance",
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Remarks", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.remarksController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., Morning shift physical attendance',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.scanDocument,
                      icon: const Icon(Icons.document_scanner, color: Colors.white, size: 18),
                      label: Text("SCAN DOC", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyberBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.pickFiles,
                      icon: const Icon(Icons.file_upload, color: Colors.white, size: 18),
                      label: Text("PICK FILES", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Selected Files", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  if (controller.selectedFiles.isEmpty) {
                    return Center(
                      child: Text("No files selected yet.", style: GoogleFonts.outfit(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.selectedFiles.length,
                    itemBuilder: (context, index) {
                      File file = controller.selectedFiles[index];
                      String ext = file.path.split('.').last.toLowerCase();
                      bool isImage = ['jpg', 'jpeg', 'png'].contains(ext);
                      return Card(
                        color: Theme.of(context).cardTheme.color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),

                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(file, width: 40, height: 40, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
                          title: Text(
                            file.path.split('/').last,
                            style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => controller.removeFile(index),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Obx(() => Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: controller.isLoading ? null : const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)]),
                  color: controller.isLoading ? Colors.grey : null,
                ),
                child: ElevatedButton(
                  onPressed: controller.isLoading ? null : controller.submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("UPLOAD ALL", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
