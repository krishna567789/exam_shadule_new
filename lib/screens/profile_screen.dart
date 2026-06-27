import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final DashboardController _dashboardController = Get.find<DashboardController>();

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
      padding: const EdgeInsets.all(20.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberCyan = Color(0xFF1976D2);
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
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: cyberCyan, size: 16),
                          const SizedBox(width: 8),
                          Obx(() => Text(
                            _dashboardController.centerCode.value.isNotEmpty
                                ? _dashboardController.centerCode.value
                                : 'N/A',
                            style: GoogleFonts.outfit(
                              color: cyberCyan,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          )),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Theme.of(context).primaryColor),
                        onPressed: () => Get.changeTheme(
                            Get.isDarkMode ? AppTheme.lightTheme : AppTheme.darkTheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    _dashboardController.centerName.value.isNotEmpty
                        ? _dashboardController.centerName.value
                        : 'No Center Assigned',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  )),
                  const SizedBox(height: 8),
                  Text(
                    'OPERATOR AND CENTER INFORMATION',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildHudCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: cyberCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'CENTER DETAILS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleSmall?.color,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Obx(() => _buildInfoRow(
                        'CENTER NAME',
                        _dashboardController.centerName.value.isNotEmpty
                            ? _dashboardController.centerName.value
                            : 'N/A',
                      )),
                      const SizedBox(height: 16),
                      Obx(() => _buildInfoRow(
                        'CENTER CODE',
                        _dashboardController.centerCode.value.isNotEmpty
                            ? _dashboardController.centerCode.value
                            : 'N/A',
                      )),
                      const SizedBox(height: 16),
                      _buildInfoRow('SHIFT TIME', 'Dynamic Session'),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cyberCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: cyberCyan,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASSIGNMENT STATUS',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cyberCyan,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Currently Active for Session',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
