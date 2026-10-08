import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';
import '../controller/login_controller.dart';
import '../controller/session_controller.dart';
import '../services/sync_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text.dart';
import 'candidates_screen.dart';
import 'pending_sync_screen.dart';

class VerifierDashboardScreen extends StatefulWidget {
  const VerifierDashboardScreen({super.key});

  @override
  State<VerifierDashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<VerifierDashboardScreen> {
  VerifierDashboardController get _c => Get.find<VerifierDashboardController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryNeon,
          onRefresh: _c.refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 18),
                Obx(() {
                  final s = VerifierSessionController.to.session;
                  return _heroCard(s?.profile.name ?? '',
                      s?.verifierId ?? '', s?.centerName ?? '',
                      s?.centerCode ?? '', s?.examName ?? '',
                      s?.profile.photo ?? '');
                }),
                const SizedBox(height: 16),
                Obx(() {
                  final s = _c.summary.value;
                  return _progressCard(s.total, s.verified);
                }),
                const SizedBox(height: 12),
                Obx(() {
                  final s = _c.summary.value;
                  return Row(
                    children: [
                      Expanded(
                          child: _miniStat('PENDING', s.pending, Colors.amber)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _miniStat('VERIFIED', s.verified,
                              AppTheme.successGreen)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _miniStat(
                              'REJECTED', s.rejected, AppTheme.errorRed)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _miniStat(
                              'RECHECK', s.recheck, Colors.orange)),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                CustomText.heading('QUICK ACTIONS',
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.5),
                const SizedBox(height: 12),
                Obx(() {
                  final s = _c.summary.value;
                  return _primaryAction(
                    title: 'Candidate Queue',
                    subtitle: 'Verify candidates at this center',
                    badge: '${s.pending} pending',
                    onTap: () => Get.to(() => const VerifierCandidatesScreen()),
                  );
                }),
                const SizedBox(height: 12),
                Obx(() {
                  final n = VerifierSyncService.to.pending.length;
                  return _secondaryAction(
                    title: 'Offline Sync Queue',
                    subtitle: n > 0
                        ? '$n verification(s) waiting to sync'
                        : 'All records synced',
                    badgeText: n > 0 ? '$n' : null,
                    color: n > 0 ? Colors.amber : AppTheme.successGreen,
                    onTap: () => Get.to(() => const PendingSyncScreen()),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/images/logo_mark.png',
              width: 38, height: 38, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.heading('SECURE EXAM',
                  fontSize: 16, letterSpacing: 1.5, color: AppTheme.textLight),
              CustomText.regular('VERIFIER CONSOLE',
                  fontSize: 10,
                  color: AppTheme.primaryNeon,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.primaryNeon),
          onPressed: () => _c.refreshAll(),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppTheme.errorRed),
          onPressed: () => Get.defaultDialog(
            title: "Logout?",
            middleText: "End this verifier session?",
            textConfirm: "Logout",
            confirmTextColor: Colors.white,
            buttonColor: AppTheme.errorRed,
            onConfirm: () {
              Get.back();
              Get.find<VerifierLoginController>().logout();
            },
          ),
        ),
      ],
    );
  }

  Widget _heroCard(String name, String verifierId, String center,
      String centerCode, String exam, String photoUrl) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16213B), Color(0xFF123047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryNeon.withOpacity(0.6),
                      width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl.isNotEmpty
                    ? Image.network(photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback())
                    : _avatarFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.heading(
                        name.isEmpty ? 'Verifier' : name.toUpperCase(),
                        fontSize: 18, color: AppTheme.textLight),
                    const SizedBox(height: 2),
                    CustomText.regular(center.isEmpty ? '—' : center,
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _idBadge(verifierId),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _chip(Icons.pin_rounded, 'CENTER', centerCode)),
              Expanded(child: _chip(Icons.event_note, 'EXAM', exam)),
              Expanded(child: _chip(Icons.badge, 'VERIFIER', verifierId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return const ColoredBox(
      color: AppTheme.surfaceDark,
      child: Icon(Icons.person, color: AppTheme.primaryNeon, size: 30),
    );
  }

  Widget _idBadge(String verifierId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primaryNeon.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
      ),
      child: CustomText.mono(verifierId.isEmpty ? '—' : verifierId,
          fontSize: 13, color: AppTheme.primaryNeon),
    );
  }

  Widget _chip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            CustomText.regular(label,
                fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1),
          ],
        ),
        const SizedBox(height: 3),
        CustomText.mono(value.isEmpty ? '—' : value,
            fontSize: 13, color: AppTheme.textLight),
      ],
    );
  }

  Widget _progressCard(int total, int verified) {
    final pct = total == 0 ? 0.0 : (verified / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(
                      AppTheme.successGreen),
                ),
                CustomText.mono('${(pct * 100).round()}%',
                    fontSize: 16, color: AppTheme.textLight),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.regular('VERIFICATION PROGRESS',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CustomText.mono('$verified',
                        fontSize: 26, color: AppTheme.successGreen),
                    CustomText.regular(' / $total verified',
                        fontSize: 13, color: AppTheme.textMuted),
                  ],
                ),
                CustomText.regular(
                    pct >= 1.0
                        ? 'All assigned candidates processed'
                        : '${total - verified} left to verify',
                    fontSize: 11,
                    color: AppTheme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          CustomText.mono('$value', fontSize: 19, color: color),
          const SizedBox(height: 2),
          CustomText.regular(label,
              fontSize: 9,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _primaryAction({
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNeon.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.fingerprint_rounded,
                  size: 38, color: AppTheme.backgroundDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.heading(title,
                        fontSize: 17, color: AppTheme.backgroundDark),
                    CustomText.regular(subtitle,
                        fontSize: 12,
                        color: AppTheme.backgroundDark.withOpacity(0.75)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText.regular(badge,
                    fontSize: 11,
                    color: Colors.amber,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.backgroundDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryAction({
    required String title,
    required String subtitle,
    required String? badgeText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sync_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.regular(title,
                        fontSize: 15,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600),
                    CustomText.regular(subtitle,
                        fontSize: 12, color: AppTheme.textMuted),
                  ],
                ),
              ),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText.regular(badgeText,
                      fontSize: 11,
                      color: AppTheme.backgroundDark,
                      fontWeight: FontWeight.bold),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
