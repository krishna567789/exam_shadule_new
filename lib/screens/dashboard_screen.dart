import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controller/dashboard_controller.dart';
import '../controller/download_controller.dart';
import '../controller/login_controller.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'physical_attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _dashboardController = Get.put(DashboardController());
  final DownloadController _downloadController = Get.put(DownloadController());
  final LoginController _loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _dashboardController.getStoredData();
    _downloadController.countAllStudents();
  }

  void _startSync() {
    _dashboardController.syncAndUploadData();
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
                "Are you sure you want to log out? Local data will be cleared.",
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
    const Color primaryColor = Color(0xFF10B981); // Teal color from image
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.flag, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() => Text(
                _dashboardController.centerName.value,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              )),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => Get.changeTheme(isDark ? AppTheme.lightTheme : AppTheme.darkTheme),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Obx(() {
        _dashboardController.refreshLocalStats();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Application Details
              _buildSectionTitle("Application Details"),
              _buildHudCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppDetailRow("Exam Name:", _dashboardController.examName.value),
                    const SizedBox(height: 8),
                    _buildAppDetailRow("Centre Code:", _dashboardController.centerCode.value),
                    const SizedBox(height: 8),
                    _buildAppDetailRow("Shift:", StorageService.to.getString(StorageService.keyShift) ?? "1"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Candidate Summary
              _buildSectionTitle("Candidate Summary"),
              Row(
                children: [
                  _buildStatCard("Total", _dashboardController.globalTotal.value.toString(), const Color(0xFF4F46E5)),
                  _buildStatCard("Present", _dashboardController.globalPresent.value.toString(), const Color(0xFF10B981)),
                  _buildStatCard("Absent", _dashboardController.globalAbsent.value.toString(), const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 24),

              // 3. This Device Summary
              _buildSectionTitle("This Device Summary"),
              Row(
                children: [
                  _buildStatCard("Total", _dashboardController.localTotal.value.toString(), const Color(0xFF4F46E5)),
                  _buildStatCard(
                    "Present", 
                    _dashboardController.localPresent.value.toString(), 
                    const Color(0xFF10B981),
                    showArrow: true,
                  ),
                  _buildStatCard(
                    "Absent", 
                    _dashboardController.localAbsent.value.toString(), 
                    const Color(0xFFEF4444),
                    showArrow: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Sync Action
              Center(
                child: Column(
                  children: [
                    if (_dashboardController.isLoading.value)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CircularProgressIndicator(),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _dashboardController.isLoading.value ? null : _startSync,
                        icon: const Icon(Icons.sync, color: Colors.white),
                        label: Text(
                          _dashboardController.isLoading.value ? "UPLOADING..." : "SYNC PENDING DATA",
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Get.to(() => const PhysicalAttendanceScreen()),
                      icon: const Icon(Icons.upload_file),
                      label: const Text("PHYSICAL ATTENDANCE"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildAppDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor, {bool showArrow = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Full details",
                    style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey),
                  ),
                  const Icon(Icons.arrow_forward, size: 10, color: Colors.grey),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHudCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
