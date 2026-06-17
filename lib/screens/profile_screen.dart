import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final DashboardController _dashboardController = Get.put(DashboardController());

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
                        'OPERATOR AND CENTER INFORMATION',
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
                    child: _buildHudCard(
                      showTopLeft: true,
                      showBottomRight: true,
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
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Obx(() => _buildInfoRow(
                            'CENTER NAME',
                            _dashboardController.centerName.value.isNotEmpty
                                ? _dashboardController.centerName.value
                                : 'Govt. Polytechnic College, Zone 4',
                          )),
                          const SizedBox(height: 16),
                          Obx(() => _buildInfoRow(
                            'CENTER CODE',
                            _dashboardController.centerCode.value.isNotEmpty
                                ? _dashboardController.centerCode.value
                                : 'CNTR-104',
                          )),
                          const SizedBox(height: 16),
                          _buildInfoRow('SHIFT TIME', '09:00 AM - 12:00 PM'),
                          const SizedBox(height: 16),
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
                                Text(
                                  'ADDRESS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: cyberCyan,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sector 42, Knowledge Park, New Delhi',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
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
            fontSize: 11,
            color: const Color(0xFF90A4AE),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

