import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/candidate_detail_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String candidateId;
  const CandidateDetailScreen({super.key, required this.candidateId});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  late final VerifierCandidateDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(VerifierCandidateDetailController());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _c.loadDetail(widget.candidateId));
  }

  @override
  void dispose() {
    Get.delete<VerifierCandidateDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: CustomText.heading('VERIFY CANDIDATE',
            fontSize: 16, letterSpacing: 1.5),
      ),
      body: Obx(() {
        final c = _c.candidate.value;
        if (c == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _identityCard(c.name, c.rollNo, c.applicationId, c.photo),
              const SizedBox(height: 14),
              _infoRow('Father', c.fatherName),
              _infoRow('Mother', c.motherName),
              _infoRow('Mobile', c.mobile),
              _infoRow('Email', c.email),
              _infoRow('Center', '${c.centerName} (${c.centerCode})'),
              _infoRow('Status', c.status.toUpperCase()),
              const SizedBox(height: 18),
              CustomText.heading('ENROLLED BIOMETRIC',
                  fontSize: 13,
                  color: AppTheme.primaryNeon, letterSpacing: 1.5),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _netThumb('LEFT', c.biometric.leftThumb)),
                  const SizedBox(width: 10),
                  Expanded(child: _netThumb('RIGHT', c.biometric.rightThumb)),
                  const SizedBox(width: 10),
                  Expanded(child: _netThumb('LIVE', c.biometric.livePhoto)),
                ],
              ),
              const SizedBox(height: 22),
              CustomText.heading('CAPTURE ON DEVICE',
                  fontSize: 13,
                  color: AppTheme.primaryNeon, letterSpacing: 1.5),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _c.scanFinger(side: 'left'),
                      icon: const Icon(Icons.fingerprint,
                          color: AppTheme.primaryNeon),
                      label: Obx(() => Text(
                          _c.capturedLeftQuality.value == null
                              ? 'Scan Left'
                              : 'Left ${_c.capturedLeftQuality.value}%',
                          style: const TextStyle(color: AppTheme.textLight))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryNeon),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _c.scanFinger(side: 'right'),
                      icon: const Icon(Icons.fingerprint,
                          color: AppTheme.primaryNeon),
                      label: Obx(() => Text(
                          _c.capturedRightQuality.value == null
                              ? 'Scan Right'
                              : 'Right ${_c.capturedRightQuality.value}%',
                          style: const TextStyle(color: AppTheme.textLight))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryNeon),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomText.heading('VERIFICATION RESULT',
                  fontSize: 13,
                  color: AppTheme.primaryNeon, letterSpacing: 1.5),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                    spacing: 8,
                    children: ['verified', 'rejected', 'recheck']
                        .map((s) {
                          final sel = _c.verificationStatus.value == s;
                          return ChoiceChip(
                            label: Text(s.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: sel
                                        ? AppTheme.backgroundDark
                                        : AppTheme.textLight)),
                            selected: sel,
                            selectedColor: _statusColor(s),
                            onSelected: (_) => _c.verificationStatus.value = s,
                          );
                        })
                        .toList(),
                  )),
              const SizedBox(height: 14),
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: CustomText.regular('Biometric Match',
                        fontSize: 14, color: AppTheme.textLight),
                    value: _c.biometricMatch.value,
                    activeColor: AppTheme.successGreen,
                    onChanged: (v) => _c.biometricMatch.value = v,
                  )),
              const SizedBox(height: 6),
              TextField(
                controller: _c.remarksCtl,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryNeon, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => CustomButton(
                  text: 'SUBMIT VERIFICATION',
                  isLoading: _c.isLoading,
                  backgroundColor: AppTheme.successGreen,
                  textColor: Colors.white,
                  onPressed: _c.submitVerification,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _identityCard(String name, String roll, String appId, String photo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photo.isNotEmpty
                ? Image.network(photo,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackAvatar())
                : _fallbackAvatar(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.heading(name.isEmpty ? '—' : name,
                    fontSize: 18, color: AppTheme.textLight),
                const SizedBox(height: 4),
                CustomText.mono('ROLL $roll',
                    fontSize: 14, color: AppTheme.primaryNeon),
                if (appId.isNotEmpty)
                  CustomText.regular('App $appId',
                      fontSize: 12, color: AppTheme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() => const SizedBox(
        width: 64,
        height: 64,
        child: Icon(Icons.person, size: 40, color: AppTheme.textMuted),
      );

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: CustomText.regular(label,
                fontSize: 13, color: AppTheme.textMuted),
          ),
          Expanded(
            child: CustomText.regular(
                value.isEmpty ? '—' : value,
                fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _netThumb(String label, String url) {
    return Column(
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: url.isEmpty
              ? const Icon(Icons.image_not_supported,
                  color: AppTheme.textMuted)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image, color: AppTheme.textMuted)),
                ),
        ),
        const SizedBox(height: 4),
        CustomText.regular(label, fontSize: 10, color: AppTheme.textMuted),
      ],
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'verified':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return Colors.orange;
    }
  }
}
