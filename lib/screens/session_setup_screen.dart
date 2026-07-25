import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'package:get/get.dart';
import '../controller/download_controller.dart';
import '../controller/dashboard_controller.dart';
import '../controller/login_controller.dart';
import 'package:intl/intl.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final DownloadController _downloadController = Get.put(DownloadController());
  final DashboardController _dashboardController =
      Get.put(DashboardController());
  final LoginController _loginController = Get.put(LoginController());

  @override
  void initState() {
    super.initState();
    _dashboardController.getStoredData();
    _downloadController.getStoredSessionData();
    _downloadController.selectedShift.value = '1';
    _downloadController.countAllStudents();
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return "--:--";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return "--:--";
    }
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
    final Color textMuted = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF64748B)
        : Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Session Setup',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        Get.changeTheme(
                          Get.isDarkMode
                              ? AppTheme.lightTheme
                              : AppTheme.darkTheme,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    _dashboardController.examName.value.isNotEmpty
                        ? 'Exam: ${_dashboardController.examName.value}'
                        : 'Confirm center details and sync data before proceeding.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _dashboardController.examName.value.isNotEmpty
                          ? Colors.blue.shade800
                          : textMuted,
                      fontWeight: _dashboardController.examName.value.isNotEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Center Details Card
                _buildHudCard(
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
                          Expanded(
                            child: Column(
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
                                    _dashboardController
                                            .centerCode.value.isNotEmpty
                                        ? _dashboardController.centerCode.value
                                        : 'N/A',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10),
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
                              : 'Loading...',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
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
                                      color: Color(0xFF1976D2),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Obx(
                                        () {
                                          if (_downloadController.shiftStart
                                                  .value.isNotEmpty &&
                                              _downloadController
                                                  .shiftEnd.value.isNotEmpty) {
                                            return Text(
                                              '${_formatTime(_downloadController.shiftStart.value)} - ${_formatTime(_downloadController.shiftEnd.value)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }
                                          return Text(
                                            _downloadController
                                                    .shift.value.isNotEmpty
                                                ? '${_downloadController.shift.value} (${_downloadController.timing.value})'
                                                : 'Current Session',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 12),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           'CAPACITY',
                      //           style: GoogleFonts.outfit(
                      //             fontSize: 10,
                      //             color: textMuted,
                      //             fontWeight: FontWeight.bold,
                      //           ),
                      //         ),
                      //         const SizedBox(height: 4),
                      //         Row(
                      //           children: [
                      //             const Icon(
                      //               Icons.people_alt_outlined,
                      //               size: 14,
                      //               color: Color(0xFF1976D2),
                      //             ),
                      //             const SizedBox(width: 6),
                      //             Obx(
                      //               () => Text(
                      //                 _dashboardController.centerCapacity.value,
                      //                 style: GoogleFonts.outfit(
                      //                   fontSize: 14,
                      //                   fontWeight: FontWeight.bold,
                      //                   color: Theme.of(context).textTheme.bodyMedium?.color,
                      //                 ),
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Candidate Data Status Card
                _buildHudCard(
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
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
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
                      const SizedBox(height: 10),
                      Obx(
                        () => _downloadController.isDownloading.value
                            ? Column(
                                children: [
                                  const LinearProgressIndicator(
                                    color: cyberBlue,
                                    backgroundColor: Color(0xFFE3F2FD),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Downloading data... ${(_downloadController.downloadProgress.value * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cyberBlue,
                                    ),
                                  ),
                                ],
                              )
                            : _downloadController.totalStudents.value == 0
                                ? Container(
                                    width: double.infinity,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0D47A1),
                                          Color(0xFF1E88E5)
                                        ],
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
                                          fontSize: 10,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'DATA DOWNLOADED',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2E7D32),
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

                const SizedBox(height: 32),

                // Continue Button
                Obx(
                  () => Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _downloadController.totalStudents.value > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF2196F3)])
                          : LinearGradient(colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500
                            ]),
                    ),
                    child: ElevatedButton(
                      onPressed: _downloadController.totalStudents.value > 0
                          ? _handleContinue
                          : null,
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel & Logout
                Center(
                  child: TextButton(
                    onPressed: () {
                      _loginController.logout();
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
      ),
    );
  }

  Widget _buildHudCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
