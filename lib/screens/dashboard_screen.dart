import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';
import '../controller/download_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _dashboardController = Get.put(DashboardController());
  final DownloadController _downloadController = Get.put(DownloadController());
  
  @override
  void initState() {
    super.initState();
    _dashboardController.getStoredData();
    _downloadController.countAllStudents();
  }

  void _startSync() {
    _dashboardController.sendAttendanceData();
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
        color: const Color(0xFF0A1329).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A3D75).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);
    const Color textMuted = Color(0xFF90A4AE);
    const Color neonGreen = Color(0xFF10B981);
    const Color errorRed = Color(0xFFEF5350);

    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      body: SafeArea(
            child: Column(
              children: [
                // Header Section (Cyber Console Style)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1329).withOpacity(0.8),
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0xFF1A3D75),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: cyberCyan, size: 16),
                              const SizedBox(width: 8),
                              Obx(() => Text(
                                _dashboardController.centerCode.value.isNotEmpty
                                    ? _dashboardController.centerCode.value
                                    : 'CNTR-104',
                                style: GoogleFonts.outfit(
                                  color: cyberCyan,
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                ),
                              )),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: errorRed),
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        _dashboardController.centerName.value.isNotEmpty
                            ? _dashboardController.centerName.value
                            : 'Govt. Polytechnic College, Zone 4',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: cyberBlue.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      Text(
                        'MANAGEMENT DASHBOARD & SYNC STATUS',
                        style: GoogleFonts.outfit(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        // Live Status Card
                        _buildHudCard(
                          showTopLeft: true,
                          showBottomRight: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cloud_queue, color: cyberCyan, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LIVE STATUS',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Synced: 25/05/2026, 19:58:55',
                                    style: GoogleFonts.outfit(
                                      color: textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'SCHEDULED',
                                        style: GoogleFonts.outfit(
                                          color: textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Obx(() => Text(
                                        '${_downloadController.totalStudents.value}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )),
                                    ],
                                  ),
                                  Container(
                                    width: 1.5,
                                    height: 40,
                                    color: const Color(0xFF1A3D75).withOpacity(0.4),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'ON DEVICE',
                                        style: GoogleFonts.outfit(
                                          color: textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Obx(() => Text(
                                        '${_downloadController.totalStudents.value}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: neonGreen,
                                        ),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF112244).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: cyberBlue.withOpacity(0.8),
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(() => Text(
                                      _dashboardController.centerName.value.isNotEmpty
                                          ? _dashboardController.centerName.value
                                          : 'Govt. Polytechnic College, Zone 4',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    )),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 12, color: cyberCyan),
                                        const SizedBox(width: 6),
                                        Obx(() => Text(
                                          _downloadController.shift.value.isNotEmpty
                                              ? '${_downloadController.shift.value} (${_downloadController.timing.value})'
                                              : 'Morning (Shift 1) (09:00 AM - 12:00 PM)',
                                          style: GoogleFonts.outfit(
                                            color: textMuted,
                                            fontSize: 11,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Obx(() {
                                final bool loading = _dashboardController.isLoading.value;
                                return Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: loading
                                        ? null
                                        : const LinearGradient(
                                            colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: loading ? Colors.grey.shade800 : null,
                                    boxShadow: loading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: cyberBlue.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: loading ? null : _startSync,
                                    icon: Icon(
                                      loading ? Icons.sync : Icons.cloud_upload_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      loading ? 'SYNCING...' : 'SYNC & UPLOAD',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Obx(() => _dashboardController.isLoading.value
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            backgroundColor: const Color(0xFF0A1329),
                                            color: neonGreen,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Uploading in progress...',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: neonGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Attendance Overview Card
                        _buildHudCard(
                          showTopRight: true,
                          showBottomLeft: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.analytics_outlined, color: cyberCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ATTENDANCE OVERVIEW',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF112244).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF1A3D75).withOpacity(0.4),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SCHEDULED',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: textMuted,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Obx(() => Text(
                                            '${_downloadController.totalStudents.value}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A2E24).withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: neonGreen.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PRESENT ↗',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: neonGreen,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '2',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: neonGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF331616).withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: errorRed.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ABSENT ↘',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: errorRed,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '148',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: errorRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

