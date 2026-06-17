import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import 'package:get/get.dart';
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
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
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Obx(() => Text(
                          _dashboardController.centerCode.value.isNotEmpty ? _dashboardController.centerCode.value : 'CNTR-104',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        )),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
                Obx(() => Text(
                  _dashboardController.centerName.value.isNotEmpty ? _dashboardController.centerName.value : 'Govt. Polytechnic College, Zone 4',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: 8),
                const Text(
                  'Management Dashboard & Sync Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Live Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.cloud_queue, color: AppTheme.primaryBlue, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Live Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Synced: 25/05/2026, 19:58:55',
                                style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Scheduled',
                                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Obx(() => Text(
                                    '${_downloadController.totalStudents.value}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  )),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'On Device',
                                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Obx(() => Text(
                                    '${_downloadController.totalStudents.value}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successGreen,
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text(
                                  _dashboardController.centerName.value.isNotEmpty ? _dashboardController.centerName.value : 'Govt. Polytechnic College, Zone 4',
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: AppTheme.primaryBlue),
                                    SizedBox(width: 4),
                                    Obx(() => Text(
                                      _downloadController.shift.value.isNotEmpty ? '${_downloadController.shift.value} (${_downloadController.timing.value})' : 'Morning (Shift 1) (09:00 AM - 12:00 PM)',
                                      style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 10,
                                      ),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(() => CustomButton(
                            text: _dashboardController.isLoading.value ? 'Uploading...' : 'Sync and Upload',
                            icon: Icon(
                              _dashboardController.isLoading.value ? Icons.refresh : Icons.cloud_upload_outlined,
                              size: 18,
                            ),
                            backgroundColor: _dashboardController.isLoading.value ? Colors.grey.shade400 : const Color(0xFF1E293B),
                            onPressed: _dashboardController.isLoading.value ? null : _startSync,
                          )),
                          Obx(() => _dashboardController.isLoading.value ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                backgroundColor: Colors.grey.shade200,
                                color: AppTheme.successGreen,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Uploading in progress...',
                                    style: TextStyle(fontSize: 10, color: AppTheme.textDark, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ) : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Attendance Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Attendance Overview',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Scheduled', style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
                                      SizedBox(height: 4),
                                      Obx(() => Text('${_downloadController.totalStudents.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.successGreen.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Present ↗', style: TextStyle(fontSize: 10, color: AppTheme.successGreen)),
                                      SizedBox(height: 4),
                                      Text('2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Absent ↘', style: TextStyle(fontSize: 10, color: AppTheme.errorRed)),
                                      SizedBox(height: 4),
                                      Text('148', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
