import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controller/dashboard_controller.dart';
import '../controller/download_controller.dart';
import '../controller/login_controller.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _dashboardController =
      Get.put(DashboardController());
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
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold),
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
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Get.back();
                        _loginController.logout();
                      },
                      child: const Text("LOGOUT",
                          style: TextStyle(color: Colors.white)),
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

  Widget _buildHudCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color neonGreen = Color(0xFF10B981);
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
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
                            const Icon(Icons.location_on,
                                color: Color(0xFF1976D2), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Obx(() => Text(
                                    _dashboardController.centerCode.value,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1976D2),
                                      fontSize: 13,
                                      letterSpacing: 1.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                                Get.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Theme.of(context).primaryColor),
                            onPressed: () => Get.changeTheme(Get.isDarkMode
                                ? AppTheme.lightTheme
                                : AppTheme.darkTheme),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.redAccent),
                            onPressed: () => _showLogoutDialog(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        _dashboardController.centerName.value,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'MANAGEMENT DASHBOARD & SYNC STATUS',
                    style: GoogleFonts.outfit(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ValueListenableBuilder(
                  valueListenable: Hive.box('candidates_box').listenable(),
                  builder: (context, Box box, _) {
                    int total = box.length;
                    int present = box.values
                        .where((s) => (s as Map)['attendanceStatus'] == true)
                        .length;
                    int synced = box.values
                        .where((s) => (s as Map)['syncStatus'] == true)
                        .length;
                    int failed = box.values
                        .where((s) =>
                            (s as Map)['syncFailed'] == true &&
                            (s)['syncStatus'] != true)
                        .length;
                    int pending = present - synced - failed;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          // Live Status Card
                          _buildHudCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cloud_sync,
                                            color: Color(0xFF1976D2), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'SYNC STATUS',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.color,
                                            letterSpacing: 1.2,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (failed > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Text(
                                              '$failed Failed',
                                              style: GoogleFonts.outfit(
                                                color: Colors.red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          pending > 0 || failed > 0
                                              ? '$pending Pending'
                                              : 'All Synced',
                                          style: GoogleFonts.outfit(
                                            color: pending > 0
                                                ? Colors.orange
                                                : neonGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(
                                        'SCHEDULED',
                                        total.toString(),
                                        Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color),
                                    Container(
                                        width: 1,
                                        height: 30,
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.1)),
                                    _buildStatColumn('PRESENT',
                                        present.toString(), neonGreen),
                                    Container(
                                        width: 1,
                                        height: 30,
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.1)),
                                    _buildStatColumn(
                                        'SYNCED', synced.toString(), cyberBlue),
                                    if (failed > 0) ...[
                                      Container(
                                          width: 1,
                                          height: 30,
                                          color: Theme.of(context)
                                              .dividerColor
                                              .withOpacity(0.1)),
                                      _buildStatColumn('FAILED',
                                          failed.toString(), Colors.red),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Obx(() => Container(
                                //   padding: const EdgeInsets.all(12),
                                //   decoration: BoxDecoration(
                                //     color: Colors.grey.withOpacity(0.05),
                                //     borderRadius: BorderRadius.circular(8),
                                //   ),
                                //   child: Row(
                                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //     children: [
                                //       Text("SERVER STATUS", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                //       Text(
                                //         "Total: ${_dashboardController.totalCandidates.value} | Present: ${_dashboardController.presentCandidates.value}",
                                //         style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: cyberBlue),
                                //       ),
                                //     ],
                                //   ),
                                // )),
                                const SizedBox(height: 24),
                                Obx(() {
                                  final bool loading =
                                      _dashboardController.isLoading.value;
                                  return Container(
                                    width: double.infinity,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: loading
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF1976D2),
                                                Color(0xFF2196F3)
                                              ],
                                            ),
                                      color: loading
                                          ? Colors.grey.withOpacity(0.2)
                                          : null,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: loading ? null : _startSync,
                                      icon: Icon(
                                        loading
                                            ? Icons.hourglass_empty
                                            : Icons.cloud_upload_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        loading
                                            ? 'UPLOADING...'
                                            : 'SYNC & UPLOAD DATA',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                      ),
                                    ),
                                  );
                                }),
                                Obx(() => _dashboardController.isLoading.value
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: LinearProgressIndicator(
                                          backgroundColor:
                                              Colors.grey.withOpacity(0.1),
                                          color: cyberBlue,
                                          minHeight: 4,
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Session Info Card
                          _buildHudCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.assignment_outlined,
                                        color: Color(0xFF1976D2), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SESSION INFORMATION',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.color,
                                        letterSpacing: 1.2,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Exam Name',
                                    _dashboardController.examName.value),
                                const SizedBox(height: 12),
                                _buildShiftInfoRow(
                                  'Shift',
                                  _downloadController.shiftStart.value,
                                  _downloadController.shiftEnd.value,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Operator Name',
                                    _dashboardController.operatorName.value),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color? color) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildShiftInfoRow(String label, String start, String end) {
    String formattedStart = _formatDateTime(start);
    String formattedEnd = _formatDateTime(end);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            '$formattedStart - $formattedEnd',
            textAlign: TextAlign.end,
            style:
                GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return dateTimeString;
    }
  }
}
