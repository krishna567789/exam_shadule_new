import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final DashboardController _dashboardController = Get.put(DashboardController());

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
                  'Operator and Center Information',
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
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Center Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Obx(() => _buildInfoRow('CENTER NAME', _dashboardController.centerName.value.isNotEmpty ? _dashboardController.centerName.value : 'Govt. Polytechnic College, Zone 4')),
                      const SizedBox(height: 16),
                      Obx(() => _buildInfoRow('CENTER CODE', _dashboardController.centerCode.value.isNotEmpty ? _dashboardController.centerCode.value : 'CNTR-104')),
                      const SizedBox(height: 16),
                      _buildInfoRow('SHIFT TIME', '09:00 AM - 12:00 PM'),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ADDRESS', style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Sector 42, Knowledge Park, New Delhi', style: TextStyle(fontSize: 12, color: AppTheme.textDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('RE-CAPTURE PIN', '1234'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
