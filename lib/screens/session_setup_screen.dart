import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final DashboardController _dashboardController = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
    _dashboardController.getStoredData();
    _downloadController.selectedShift.value = '1';
  }

  void _handleDownload() async {
    await _downloadController.fetchAndStoreData();
    setState(() {});
  }

  void _handleContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);
    const Color textMuted = Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Session Setup',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: cyberBlue.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confirm center details and sync data before proceeding.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Center Details Card
                  _buildHudCard(
                    showTopLeft: true,
                    showBottomRight: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF1976D2),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CENTER CODE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Obx(
                                  () => Text(
                                    _dashboardController.centerCode.value.isNotEmpty
                                        ? _dashboardController.centerCode.value
                                        : 'CNTR-104',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: const Color(0xFF154385).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CENTER NAME',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            _dashboardController.centerName.value.isNotEmpty
                                ? _dashboardController.centerName.value
                                : 'Govt. Polytechnic College, Zone 4',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                Text(
                                  'SHIFT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.wb_sunny_outlined,
                                      size: 14,
                                      color: cyberCyan,
                                    ),
                                    const SizedBox(width: 6),
                                    Obx(
                                      () => Text(
                                        _downloadController.shift.value.isNotEmpty
                                            ? '${_downloadController.shift.value} (${_downloadController.timing.value})'
                                            : 'Morning (Shift 1)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                                Text(
                                  'SCHEDULED',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(
                                  () => Text(
                                    '${_downloadController.totalStudents.value}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: cyberCyan,
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
                  const SizedBox(height: 20),

                  // Candidate Data Status Card
                  _buildHudCard(
                    showTopLeft: true,
                    showBottomRight: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CANDIDATE DATA STATUS',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Obx(
                              () => Icon(
                                _downloadController.totalStudents.value > 0
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: _downloadController.totalStudents.value > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.amber,
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
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => _downloadController.isDownloading.value
                              ? const Center(
                                  child: CircularProgressIndicator(color: cyberBlue))
                              : _downloadController.totalStudents.value == 0
                                  ? Container(
                                      width: double.infinity,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _handleDownload,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ),
                                        icon: const Icon(
                                          Icons.cloud_download_outlined,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'DOWNLOAD CANDIDATES DATA',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'DATA DOWNLOADED',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF10B981),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Continue Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CONTINUE TO ATTENDANCE',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel & Logout
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel & Logout',
                        style: GoogleFonts.outfit(
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHudCard({
    required Widget child,
    bool showTopLeft = true,
    bool showTopRight = true,
    bool showBottomLeft = true,
    bool showBottomRight = true,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A3D75).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

