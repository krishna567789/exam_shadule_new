import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'package:get/get.dart';
import '../controller/download_controller.dart';
import '../controller/dashboard_controller.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final DownloadController _downloadController = Get.put(DownloadController());
  final DashboardController _dashboardController = Get.put(
    DashboardController(),
  );

  @override
  void initState() {
    super.initState();
    _dashboardController.getStoredData();
    _downloadController.selectedShift.value = '1'; // Default or from UI
  }

  void _handleDownload() async {
    await _downloadController.fetchAndStoreData();
    setState(() {}); // Update UI after download
  }

  void _handleContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Session Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Confirm center details and sync data before proceeding.',
              style: TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
            const SizedBox(height: 32),

            // Center Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CENTER CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textLight,
                              ),
                            ),
                            Obx(
                              () => Text(
                                _dashboardController.centerCode.value.isNotEmpty
                                    ? _dashboardController.centerCode.value
                                    : 'CNTR-104',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    const Text(
                      'Center Name',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        _dashboardController.centerName.value.isNotEmpty
                            ? _dashboardController.centerName.value
                            : 'Govt. Polytechnic College, Zone 4',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shift',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.wb_sunny_outlined,
                                  size: 16,
                                  color: AppTheme.textDark,
                                ),
                                const SizedBox(width: 4),
                                Obx(
                                  () => Text(
                                    _downloadController.shift.value.isNotEmpty
                                        ? '${_downloadController.shift.value} (${_downloadController.timing.value})'
                                        : 'Morning (Shift 1)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Scheduled',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                '${_downloadController.totalStudents.value}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Candidate Data Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Candidate Data Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Obx(
                          () => Icon(
                            _downloadController.totalStudents.value > 0
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: _downloadController.totalStudents.value > 0
                                ? AppTheme.successGreen
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Text(
                        _downloadController.totalStudents.value > 0
                            ? 'Candidate data downloaded successfully. You can now proceed.'
                            : 'Download required to proceed with attendance tracking.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => _downloadController.isDownloading.value
                          ? const Center(child: CircularProgressIndicator())
                          : _downloadController.totalStudents.value == 0
                          ? CustomButton(
                              text: 'Download Candidates Data',
                              icon: const Icon(
                                Icons.cloud_download_outlined,
                                size: 20,
                              ),
                              onPressed: _handleDownload,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: AppTheme.successGreen,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Data Downloaded',
                                    style: TextStyle(
                                      color: AppTheme.successGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Continue Button
            Obx(
              () => CustomButton(
                text: 'Continue to Attendance ->',
                backgroundColor: _downloadController.totalStudents.value > 0
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade300,
                textColor: _downloadController.totalStudents.value > 0
                    ? Colors.white
                    : Colors.grey.shade500,
                onPressed: _downloadController.totalStudents.value > 0
                    ? _handleContinue
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Cancel & Logout
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel & Logout',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
