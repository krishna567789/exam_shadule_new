import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../controller/physical_attendance_controller.dart';

class PhysicalAttendanceScreen extends StatefulWidget {
  const PhysicalAttendanceScreen({super.key});

  @override
  State<PhysicalAttendanceScreen> createState() => _PhysicalAttendanceScreenState();
}

class _PhysicalAttendanceScreenState extends State<PhysicalAttendanceScreen> {
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
              // Remarks Section
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
                        hintText: 'e.g., Morning shift attendance',
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

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.scanAndCreatePdf,
                      icon: const Icon(Icons.document_scanner, color: Colors.white, size: 18),
                      label: Text("SCAN & PDF", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
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
                      onPressed: controller.pickFilesAndCreatePdf,
                      icon: const Icon(Icons.file_upload, color: Colors.white, size: 18),
                      label: Text("PICK & PDF", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text("Generated PDFs", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
              const SizedBox(height: 8),

              // PDF List
              Expanded(
                child: Obx(() {
                  if (controller.selectedFiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text("No documents created yet.", style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.selectedFiles.length,
                    itemBuilder: (context, index) {
                      final pdfItem = controller.selectedFiles[index];
                      return _buildPdfListItem(pdfItem, index);
                    },
                  );
                }),
              ),

              const SizedBox(height: 16),
              
              // Upload Button
              Obx(() {
                final isAnyUploading = controller.selectedFiles.any((p) => p.isUploading.value);
                final allUploaded = controller.selectedFiles.isNotEmpty && controller.selectedFiles.every((p) => p.isUploaded.value);

                return Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isAnyUploading || allUploaded ? null : const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)]),
                    color: isAnyUploading || allUploaded ? Colors.grey : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isAnyUploading || allUploaded ? null : controller.uploadAllPdfs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      allUploaded ? "COMPLETED" : (isAnyUploading ? "UPLOADING..." : "UPLOAD FINAL PDFS"), 
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfListItem(SelectedFile pdfItem, int index) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _showPdfPreview(pdfItem),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  pdfItem.isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: pdfItem.isPdf ? Colors.redAccent : Colors.blueAccent,
                  size: 40,
                ),
                if (pdfItem.isUploaded.value)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ),
                  ),
              ],
            ),
            title: Text(
              pdfItem.name,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              pdfItem.formattedSize,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: pdfItem.isUploading.value 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : (pdfItem.isUploaded.value 
                  ? const Icon(Icons.cloud_done, color: Colors.green)
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => controller.removePdf(index),
                    )),
          ),
          if (pdfItem.isUploading.value)
            Obx(() => LinearProgressIndicator(
              value: pdfItem.uploadProgress.value,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 2,
            )),
        ],
      ),
    );
  }

  void _showPdfPreview(SelectedFile pdfItem) {
    if (!pdfItem.file.existsSync()) {
      Get.snackbar(
        'Error',
        'File no longer exists on device. Please remove and re-add it.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pdfItem.name, 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: pdfItem.isPdf
                  ? PDFView(
                      filePath: pdfItem.file.path,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: false,
                    )
                  : InteractiveViewer(
                      child: Image.file(pdfItem.file, fit: BoxFit.contain),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
