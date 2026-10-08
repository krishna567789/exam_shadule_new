import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sync_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text.dart';

class PendingSyncScreen extends StatelessWidget {
  const PendingSyncScreen({super.key});

  VerifierSyncService get _s => Get.find<VerifierSyncService>();

  Future<void> _runSync() async {
    final result = await _s.syncAll();
    if (result.offline) {
      Get.snackbar("Offline", "No internet — will sync when connection returns",
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } else if (result.success > 0) {
      Get.snackbar("Synced", "${result.success} record(s) uploaded",
          backgroundColor: AppTheme.successGreen, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } else if (result.failed > 0) {
      Get.snackbar("Partial", "${result.failed} record(s) failed, will retry",
          backgroundColor: AppTheme.errorRed, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textLight,
        title: CustomText.heading('OFFLINE SYNC QUEUE',
            fontSize: 16, letterSpacing: 1.5, color: AppTheme.textLight),
      ),
      body: Obx(() {
        final items = _s.pending;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done, size: 60, color: AppTheme.successGreen),
                const SizedBox(height: 12),
                CustomText.regular('All records synced',
                    fontSize: 15, color: AppTheme.textLight),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: 'SYNC ${items.length} RECORD(S) NOW',
                isLoading: _s.isSyncing.value,
                backgroundColor: AppTheme.primaryNeon,
                textColor: AppTheme.backgroundDark,
                onPressed: _runSync,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = items[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_bottom, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText.regular(r.candidateName,
                                  fontSize: 15,
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.w600),
                              CustomText.mono('ROLL ${r.rollNo}',
                                  fontSize: 12, color: AppTheme.primaryNeon),
                              CustomText.regular(
                                  '${r.verificationStatus} · ${r.createdAt.substring(0, 19)}',
                                  fontSize: 11, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.errorRed),
                          onPressed: () => _s.remove(r.clientSyncId),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
