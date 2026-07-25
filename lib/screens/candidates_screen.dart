import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/download_controller.dart';
import '../controller/login_controller.dart';
import '../models/candidate.dart';
import 'enrollment_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final DownloadController _downloadController = Get.find<DownloadController>();
  final LoginController _loginController = Get.find<LoginController>();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = "All"; // "All", "Present", "Absent"

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty || isoString == 'N/A') return "--:--";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  void _navigateToEnrollment(Map<String, dynamic> studentData) {
    if (studentData['attendanceStatus'] == true) {
      _showRegisteredDetails(studentData);
      return;
    }

    final candidate = Candidate(
      id: (studentData['id'] ?? studentData['_id'] ?? '').toString(),
      name: (studentData['name'] ?? 'N/A').toString(),
      rollNo: (studentData['rollNo'] ?? studentData['rollno'] ?? 'N/A').toString(),
      fatherName: studentData['fatherName']?.toString(),
      motherName: studentData['motherName']?.toString(),
      email: studentData['email']?.toString(),
      mobile: studentData['mobile']?.toString(),
      address: studentData['address']?.toString(),
      photo: studentData['photo']?.toString(),
      thumbnail: studentData['thumbnail']?.toString(),
      localPhotoPath: studentData['localPhotoPath']?.toString(),
      localThumbPath: studentData['localThumbPath']?.toString(),
      status: (studentData['attendanceStatus'] == true) 
          ? CandidateStatus.present 
          : CandidateStatus.absent,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiometricEnrollmentScreen(candidate: candidate),
      ),
    );
  }

  void _showRegisteredDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "REGISTERED DETAILS",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1976D2),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: ClipOval(
                  child: _buildPreviewImage(
                    base64Data: student['livePhotoBase64'],
                    urlData: student['livePhoto'],
                    localPath: student['localLivePhotoPath'],
                    fallbackIcon: Icons.person,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                student['name']?.toString() ?? "N/A",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              Text(
                "Roll No: ${student['rollNo'] ?? student['rollno'] ?? 'N/A'}",
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThumbPreview("Left Thumb", student['leftThumbBase64'], student['leftThumb'], student['localLeftThumbPath']),
                  _buildThumbPreview("Right Thumb", student['rightThumbBase64'], student['rightThumb'], student['localRightThumbPath']),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text("CLOSE", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Force navigate to re-capture
                        final candidate = Candidate(
                          id: (student['id'] ?? student['_id'] ?? '').toString(),
                          name: (student['name'] ?? 'N/A').toString(),
                          rollNo: (student['rollNo'] ?? student['rollno'] ?? 'N/A').toString(),
                          status: CandidateStatus.present,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BiometricEnrollmentScreen(candidate: candidate),
                          ),
                        );
                      },
                      child: Text("RE-CAPTURE", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbPreview(String label, dynamic base64Data, dynamic urlData, dynamic localPath) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildPreviewImage(
            base64Data: base64Data,
            urlData: urlData,
            localPath: localPath,
            fallbackIcon: Icons.fingerprint,
            isThumb: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage({
    required dynamic base64Data,
    required dynamic urlData,
    required dynamic localPath,
    required IconData fallbackIcon,
    bool isThumb = false,
  }) {
    if (base64Data != null && base64Data.toString().length > 10) {
      Widget img = Image.memory(
        base64Decode(base64Data.toString().split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: Colors.red, size: isThumb ? 24 : 50),
      );
      return isThumb ? ClipRRect(borderRadius: BorderRadius.circular(8), child: img) : img;
    }
    if (localPath != null && localPath.toString().isNotEmpty && File(localPath.toString()).existsSync()) {
      Widget img = Image.file(
        File(localPath.toString()),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: Colors.red, size: isThumb ? 24 : 50),
      );
      return isThumb ? ClipRRect(borderRadius: BorderRadius.circular(8), child: img) : img;
    }
    if (urlData != null && urlData.toString().startsWith('http')) {
      Widget img = Image.network(
        urlData.toString(),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Icon(fallbackIcon, color: Colors.grey, size: isThumb ? 24 : 50),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
      return isThumb ? ClipRRect(borderRadius: BorderRadius.circular(8), child: img) : img;
    }
    return Icon(fallbackIcon, color: Colors.grey, size: isThumb ? 24 : 50);
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                "Confirm Logout",
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to log out? Local unsynced data may be cleared.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text("CANCEL"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Get.back();
                        _loginController.logout();
                      },
                      child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    final Color textMuted = Theme.of(context).brightness == Brightness.light 
        ? const Color(0xFF64748B) 
        : Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF1976D2), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Obx(() => Text(
                                _downloadController.centerCode.value.isNotEmpty 
                                    ? _downloadController.centerCode.value 
                                    : 'N/A',
                                style: GoogleFonts.outfit(
                                  color: textMuted,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Color(0xFF1976D2), size: 20),
                        onPressed: () {
                          _showLogoutDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    _downloadController.centerName.value.isNotEmpty 
                        ? _downloadController.centerName.value 
                        : 'No Center Assigned',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: Hive.box('candidates_box').listenable(),
                    builder: (context, Box box, _) {
                      int total = box.length;
                      int present = box.values.where((s) => (s as Map)['attendanceStatus'] == true).length;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF1976D2), size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                     child: Obx(() {
                                       if (_downloadController.shiftStart.value.isNotEmpty && 
                                           _downloadController.shiftEnd.value.isNotEmpty && 
                                           _downloadController.shiftStart.value != 'N/A') {
                                         return Text(
                                           '${_formatTime(_downloadController.shiftStart.value)} - ${_formatTime(_downloadController.shiftEnd.value)}',
                                           style: GoogleFonts.outfit(
                                             color: Theme.of(context).textTheme.bodyMedium?.color,
                                             fontSize: 12,
                                           ),
                                           overflow: TextOverflow.ellipsis,
                                         );
                                       }
                                       return Text(
                                          _downloadController.shift.value.isNotEmpty && _downloadController.shift.value != 'N/A'
                                              ? _downloadController.shift.value
                                              : 'Current Session',
                                          style: GoogleFonts.outfit(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                       );
                                     }),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$present / $total Present',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1976D2),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF1976D2),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or roll no...',
                          hintStyle: TextStyle(
                            color: textMuted.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Candidates List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CANDIDATES',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleSmall?.color,
                      letterSpacing: 1.1,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                    icon: Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusFilter,
                          style: GoogleFonts.outfit(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "All", child: Text("All")),
                      const PopupMenuItem(value: "Present", child: Text("Present")),
                      const PopupMenuItem(value: "Absent", child: Text("Absent")),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Dynamic Candidates List from Hive
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('candidates_box').listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: textMuted.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "No candidates found",
                            style: GoogleFonts.outfit(color: textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  final List<Map<String, dynamic>> allStudents = box.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  final filteredStudents = allStudents.where((student) {
                    final name = (student['name'] ?? "").toString().toLowerCase();
                    final rollNo = (student['rollNo'] ?? student['rollno'] ?? "").toString().toLowerCase();
                    final matchesSearch = name.contains(_searchQuery) || rollNo.contains(_searchQuery);
                    
                    bool matchesStatus = true;
                    if (_statusFilter == "Present") {
                      matchesStatus = student['attendanceStatus'] == true;
                    } else if (_statusFilter == "Absent") {
                      matchesStatus = student['attendanceStatus'] != true;
                    }
                    
                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filteredStudents.isEmpty) {
                    return Center(
                      child: Text("No candidates match your filters",
                        style: GoogleFonts.outfit(color: textMuted)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final bool isPresent = student['attendanceStatus'] == true;
                      
                      Widget leadingWidget;
                      String? localPath = (student['localThumbPath'] ?? student['localPhotoPath'])?.toString();
                      String? networkUrl = (student['thumbnail'] ?? student['photo'])?.toString();
                      
                      if (localPath != null && File(localPath).existsSync()) {
                         leadingWidget = Image.file(File(localPath), fit: BoxFit.cover);
                      } else if (networkUrl != null && networkUrl.startsWith('http')) {
                         leadingWidget = Image.network(
                           networkUrl, 
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(student),
                           loadingBuilder: (context, child, loadingProgress) {
                             if (loadingProgress == null) return child;
                             return Center(child: CircularProgressIndicator(
                               strokeWidth: 2, 
                               value: loadingProgress.expectedTotalBytes != null 
                                 ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! 
                                 : null,
                             ));
                           },
                         );
                      } else {
                         leadingWidget = _buildInitialsWidget(student);
                      }

                      return GestureDetector(
                        onTap: () => _navigateToEnrollment(student),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: _buildHudCard(
                            context: context,
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cyberBlue.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      color: const Color(0xFFE3F2FD),
                                      child: leadingWidget,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['name']?.toString() ?? 'N/A',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Roll: ${student['rollNo'] ?? student['rollno'] ?? 'N/A'}",
                                        style: GoogleFonts.outfit(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !isPresent
                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                        : const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: !isPresent
                                          ? const Color(0xFFEF4444).withOpacity(0.4)
                                          : const Color(0xFF10B981).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isPresent && student['syncFailed'] == true)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 4.0),
                                          child: Icon(Icons.sync_problem, color: Colors.red, size: 14),
                                        ),
                                      Text(
                                        !isPresent ? 'ABSENT' : 'PRESENT',
                                        style: GoogleFonts.outfit(
                                          color: !isPresent
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsWidget(Map<String, dynamic> student) {
    String name = (student['name'] ?? "NA").toString();
    String initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          color: const Color(0xFF1976D2),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHudCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
