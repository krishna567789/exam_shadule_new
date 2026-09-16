import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  void _showImagePreview(BuildContext context, String title, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF1976D2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image,
                                  color: Colors.white54, size: 40),
                              const SizedBox(height: 8),
                              Text("Failed to load image",
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberCyan = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _dashboardController.fetchOperatorProfile();
          },
          color: cyberCyan,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                              const Icon(Icons.badge_outlined,
                                  color: cyberCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "OPERATOR PROFILE",
                                style: GoogleFonts.outfit(
                                  color: cyberCyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Obx(() => _dashboardController
                                      .isProfileLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cyberCyan,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.refresh, size: 20),
                                      color: cyberCyan,
                                      tooltip: "Refresh Profile",
                                      onPressed: () => _dashboardController
                                          .fetchOperatorProfile(),
                                    )),
                              IconButton(
                                icon: Icon(
                                  Get.isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () => Get.changeTheme(Get.isDarkMode
                                    ? AppTheme.lightTheme
                                    : AppTheme.darkTheme),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Profile Avatar + Basic Info Card
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with glowing ring
                          Obx(() {
                            final photoUrl =
                                _dashboardController.operatorPhoto.value;
                            return Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: cyberCyan, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: cyberCyan.withOpacity(0.25),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: Colors.grey.withOpacity(0.1),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                          color: cyberCyan.withOpacity(0.1),
                                          child: const Icon(Icons.person,
                                              size: 40, color: cyberCyan),
                                        ),
                                      )
                                    : Container(
                                        color: cyberCyan.withOpacity(0.1),
                                        child: const Icon(Icons.person,
                                            size: 40, color: cyberCyan),
                                      ),
                              ),
                            );
                          }),
                          const SizedBox(width: 16),
                          // Name, ID and Role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text(
                                      _dashboardController
                                              .operatorName.value.isNotEmpty
                                          ? _dashboardController
                                              .operatorName.value
                                          : 'Operator',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.color,
                                      ),
                                    )),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    // Operator ID Chip
                                    Obx(() {
                                      final opId = _dashboardController
                                          .operatorId.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: cyberCyan.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color:
                                                  cyberCyan.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          "ID: ${opId.isNotEmpty ? opId : 'N/A'}",
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cyberCyan,
                                          ),
                                        ),
                                      );
                                    }),
                                    // Role Chip
                                    Obx(() {
                                      final role = _dashboardController
                                          .operatorRole.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.green
                                                  .withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Operator Details Card
                    _buildHudCard(
                      context: context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: cyberCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'PERSONAL INFORMATION',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.color,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Obx(() => _buildInfoRow(
                              'FULL NAME',
                              _dashboardController.operatorName.value,
                              Icons.person)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'FATHER NAME',
                              _dashboardController.fatherName.value,
                              Icons.family_restroom)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'MOBILE NUMBER',
                              _dashboardController.operatorPhone.value,
                              Icons.phone)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'EMAIL ADDRESS',
                              _dashboardController.operatorEmail.value,
                              Icons.email)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'LOCATION (CITY / STATE)',
                              _dashboardController.operatorCityState.value,
                              Icons.location_city)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'FULL ADDRESS',
                              _dashboardController.operatorAddress.value,
                              Icons.home)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Aadhaar Documents Card
                    _buildHudCard(
                      context: context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined,
                                  color: cyberCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'AADHAAR DOCUMENTS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.color,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => _buildDocumentPreview(
                                      context: context,
                                      title: 'Aadhaar Front',
                                      imageUrl: _dashboardController
                                          .operatorAadharFront.value,
                                    )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(() => _buildDocumentPreview(
                                      context: context,
                                      title: 'Aadhaar Back',
                                      imageUrl: _dashboardController
                                          .operatorAadharBack.value,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Center & Assignment Details Card
                    _buildHudCard(
                      context: context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: cyberCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'CENTER & SESSION DETAILS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.color,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Obx(() => _buildInfoRow(
                              'CENTER NAME',
                              _dashboardController.centerName.value.isNotEmpty
                                  ? _dashboardController.centerName.value
                                  : 'N/A',
                              Icons.business)),
                          const SizedBox(height: 14),
                          Obx(() => _buildInfoRow(
                              'CENTER CODE',
                              _dashboardController.centerCode.value.isNotEmpty
                                  ? _dashboardController.centerCode.value
                                  : 'N/A',
                              Icons.pin_drop)),
                          const SizedBox(height: 14),
                          _buildInfoRow(
                              'SESSION / SHIFT',
                              'Active Dynamic Session',
                              Icons.access_time_filled),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cyberCyan.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                left: BorderSide(
                                  color: cyberCyan,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'STATUS: ACTIVE OPERATOR',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: cyberCyan,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Authenticated and assigned for current examination session',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview({
    required BuildContext context,
    required String title,
    required String imageUrl,
  }) {
    final bool hasImage = imageUrl.isNotEmpty;
    const Color cyberCyan = Color(0xFF1976D2);

    return GestureDetector(
      onTap: hasImage
          ? () => _showImagePreview(context, title, imageUrl)
          : null,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasImage
                ? cyberCyan.withOpacity(0.4)
                : Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 28, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text("Failed to load",
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 28, color: Colors.grey.withOpacity(0.6)),
                    const SizedBox(height: 4),
                    Text("No Document",
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
              // Bottom overlay title
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasImage)
                        const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [IconData? icon]) {
    final String displayVal =
        (value.isNotEmpty && value != 'null') ? value : 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: const Color(0xFF1976D2)),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
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
              const SizedBox(height: 2),
              Text(
                displayVal,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
