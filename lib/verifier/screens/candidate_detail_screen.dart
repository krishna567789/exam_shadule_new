import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/candidate_detail_controller.dart';
import '../models/candidate.dart';
import '../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text.dart';

class VerifierCandidateDetailScreen extends StatefulWidget {
  final String candidateId;
  final Candidate? candidate;
  const VerifierCandidateDetailScreen({
    super.key,
    required this.candidateId,
    this.candidate,
  });

  @override
  State<VerifierCandidateDetailScreen> createState() =>
      _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<VerifierCandidateDetailScreen> {
  late final VerifierCandidateDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(VerifierCandidateDetailController());
    if (widget.candidate != null) {
      _c.setCandidate(widget.candidate!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.loadDetail(widget.candidateId);
    });
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
        foregroundColor: AppTheme.textLight,
        title: CustomText.heading('VERIFY CANDIDATE',
            fontSize: 16, letterSpacing: 1.5, color: AppTheme.textLight),
      ),
      body: Obx(() {
        if (_c.candidate.value == null) {
          if (_c.isDetailLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 54, color: AppTheme.errorRed),
                  const SizedBox(height: 16),
                  CustomText.heading('Failed to Load Candidate',
                      fontSize: 16, color: AppTheme.textLight),
                  const SizedBox(height: 8),
                  CustomText.regular(
                    _c.detailErrorMessage.value ??
                        'Candidate details not found',
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _c.loadDetail(widget.candidateId),
                    icon: const Icon(Icons.refresh,
                        color: AppTheme.backgroundDark),
                    label: const Text('RETRY',
                        style: TextStyle(
                            color: AppTheme.backgroundDark,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final c = _c.candidate.value!;
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
                  color: AppTheme.primaryNeon,
                  letterSpacing: 1.5),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _netThumb(
                      'LEFT',
                      c.biometric.leftThumb,
                      onTap: () => _showImagePreview(
                        title: 'Enrolled LEFT Thumb - ${c.name}',
                        rawData: c.biometric.leftThumb,
                        isLivePhoto: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _netThumb(
                      'RIGHT',
                      c.biometric.rightThumb,
                      onTap: () => _showImagePreview(
                        title: 'Enrolled RIGHT Thumb - ${c.name}',
                        rawData: c.biometric.rightThumb,
                        isLivePhoto: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _netThumb(
                      'LIVE',
                      c.biometric.livePhoto,
                      onTap: () => _showImagePreview(
                        title: 'Enrolled LIVE Photo - ${c.name}',
                        rawData: c.biometric.livePhoto,
                        isLivePhoto: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              CustomText.heading('CAPTURE ON DEVICE',
                  fontSize: 13,
                  color: AppTheme.primaryNeon,
                  letterSpacing: 1.5),
              const SizedBox(height: 10),
              Obx(() {
                final hasLeft = _c.enrolledLeftTemplate.value != null;
                final hasRight = _c.enrolledRightTemplate.value != null;
                final anyBusy = _c.anyScanInProgress;
                return Row(
                  children: [
                    Expanded(
                      child: _capturedFingerCard(
                        label: 'LEFT',
                        imageBytes: _c.capturedLeftImage.value,
                        imageUrl: _c.capturedLeftImageUrl.value,
                        quality: _c.capturedLeftQuality.value,
                        isScanning: _c.scanningSide.value == 'left',
                        isMatching: _c.matchingSide.value == 'left',
                        isBusy: anyBusy,
                        isEnrolled: hasLeft,
                        onScan: () => _c.scanFinger(side: 'left'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _capturedFingerCard(
                        label: 'RIGHT',
                        imageBytes: _c.capturedRightImage.value,
                        imageUrl: _c.capturedRightImageUrl.value,
                        quality: _c.capturedRightQuality.value,
                        isScanning: _c.scanningSide.value == 'right',
                        isMatching: _c.matchingSide.value == 'right',
                        isBusy: anyBusy,
                        isEnrolled: hasRight,
                        onScan: () => _c.scanFinger(side: 'right'),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              CustomText.heading('VERIFICATION RESULT',
                  fontSize: 13,
                  color: AppTheme.primaryNeon,
                  letterSpacing: 1.5),
              const SizedBox(height: 10),
              _biometricMatchBanner(_c),
              Obx(() => Row(
                    children: [
                      'pending',
                      'verified',
                      'rejected',
                      'recheck'
                    ].map((s) {
                      final sel = _c.verificationStatus.value == s;
                      final col = _statusColor(s);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _c.verificationStatus.value = s,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? col : AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? col
                                      : Colors.white.withValues(alpha: 0.15),
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  s.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                    color: sel
                                        ? AppTheme.backgroundDark
                                        : AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 14),
              Obx(() {
                final isManual = _c.isManualVerification.value;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isManual
                        ? Colors.orange.withOpacity(0.08)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isManual
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    title: Row(
                      children: [
                        Text(
                          'Manual Verification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isManual ? Colors.orange : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isManual
                                    ? Colors.orange
                                    : AppTheme.primaryNeon)
                                .withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isManual ? 'MANUAL' : 'BIOMETRIC',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isManual
                                  ? Colors.orange
                                  : AppTheme.primaryNeon,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        isManual
                            ? 'Manual Mode: Finger matching bypassed. Candidate can capture finger & submit.'
                            : 'Biometric Mode: Candidate fingerprint match is required to submit.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isManual
                              ? Colors.orange.shade200
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    value: isManual,
                    activeColor: Colors.orange,
                    onChanged: (v) => _c.toggleManualVerification(v),
                  ),
                );
              }),
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
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
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
                () => SafeArea(
                  child: CustomButton(
                    text: 'SUBMIT VERIFICATION',
                    isLoading: _c.isLoading,
                    backgroundColor: AppTheme.successGreen,
                    textColor: Colors.white,
                    onPressed: _c.submitVerification,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  void _showImagePreview({
    required String title,
    String? rawData,
    Uint8List? bytes,
    bool isLivePhoto = false,
  }) {
    final hasData = (rawData != null && rawData.trim().isNotEmpty) ||
        (bytes != null && bytes.isNotEmpty);
    if (!hasData) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            maxWidth: MediaQuery.of(ctx).size.width * 0.94,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryNeon.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 24,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLivePhoto ? Icons.person : Icons.fingerprint,
                      color: AppTheme.primaryNeon,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textLight, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Image Content with InteractiveViewer (pinch-to-zoom / pan)
              Flexible(
                child: Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Center(
                      child: bytes != null
                          ? Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 50,
                              ),
                            )
                          : _smartImage(
                              rawData!,
                              isLivePhoto: isLivePhoto,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ),

              // Footer with zoom tip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pinch, size: 14, color: AppTheme.primaryNeon),
                    SizedBox(width: 6),
                    Text(
                      'Pinch or drag to zoom and inspect details',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityCard(String name, String roll, String appId, String photo) {
    final hasPhoto = photo.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: hasPhoto
                ? () => _showImagePreview(
                      title: 'Candidate Photo - ${name.isEmpty ? roll : name}',
                      rawData: photo,
                      isLivePhoto: true,
                    )
                : null,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: hasPhoto
                        ? _smartImage(photo, isLivePhoto: true)
                        : _fallbackAvatar(),
                  ),
                ),
                if (hasPhoto)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 13,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
              ],
            ),
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
            child: CustomText.regular(value.isEmpty ? '—' : value,
                fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _netThumb(String label, String url, {VoidCallback? onTap}) {
    final hasImg = url.trim().isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: hasImg ? onTap : null,
      child: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasImg
                    ? AppTheme.primaryNeon.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _smartImage(url, isLivePhoto: label == 'LIVE'),
                ),
                if (hasImg)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 14,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          CustomText.mono(label, fontSize: 11, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _capturedFingerCard({
    required String label,
    required Uint8List? imageBytes,
    String? imageUrl,
    required int? quality,
    required bool isScanning,
    required bool isMatching,
    required bool isBusy,
    required VoidCallback onScan,
    bool isEnrolled = false,
  }) {
    final showSpinner = isScanning || isMatching;
    final hasImage = imageBytes != null ||
        (imageUrl != null && imageUrl.trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage
              ? AppTheme.primaryNeon
              : (isEnrolled
                  ? AppTheme.successGreen.withOpacity(0.4)
                  : Colors.white.withOpacity(0.12)),
          width: hasImage ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText.mono(label,
                      fontSize: 11, color: AppTheme.primaryNeon),
                  if (isEnrolled) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppTheme.successGreen, width: 0.8),
                      ),
                      child: const Text('ENROLLED',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen)),
                    ),
                  ],
                ],
              ),
              if (quality != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        (quality >= 60 ? AppTheme.successGreen : Colors.orange)
                            .withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$quality%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          quality >= 60 ? AppTheme.successGreen : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: hasImage
                ? () => _showImagePreview(
                      title:
                          'Captured ${label.isNotEmpty ? label : "Device"} Fingerprint${quality != null ? " ($quality%)" : ""}',
                      bytes: imageBytes,
                      rawData: imageBytes == null ? imageUrl : null,
                      isLivePhoto: false,
                    )
                : null,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasImage
                      ? AppTheme.primaryNeon.withOpacity(0.5)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) {
                                    if (imageUrl != null &&
                                        imageUrl.trim().isNotEmpty) {
                                      return _smartImage(imageUrl,
                                          fit: BoxFit.contain);
                                    }
                                    return _fallbackThumb(false);
                                  },
                                )
                              : _smartImage(imageUrl!, fit: BoxFit.contain),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 14,
                              color: AppTheme.primaryNeon,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 38,
                            color: AppTheme.textMuted.withOpacity(0.4),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No Scan Yet',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onScan,
              icon: showSpinner
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryNeon,
                      ),
                    )
                  : const Icon(Icons.fingerprint,
                      size: 16, color: AppTheme.primaryNeon),
              label: Text(
                isScanning
                    ? 'Scanning...'
                    : (isMatching
                        ? 'Matching...'
                        : (hasImage ? 'Rescan Finger' : 'Scan Finger')),
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppTheme.primaryNeon),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smartImage(String rawData,
      {bool isLivePhoto = false, BoxFit fit = BoxFit.cover}) {
    final trimmed = rawData.trim();
    if (trimmed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLivePhoto ? Icons.person_outline : Icons.fingerprint,
              size: 32,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            Text(
              isLivePhoto ? 'No Photo' : 'No Finger',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    // 1. Data URI (data:image/...;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str =
            commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackThumb(isLivePhoto),
        );
      } catch (_) {}
    }

    // 2. Raw Base64 string (PNG/JPEG/BMP/WSQ)
    if (!trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('/') &&
        trimmed.length > 50) {
      try {
        final bytes = base64Decode(trimmed);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackThumb(isLivePhoto),
        );
      } catch (_) {}
    }

    // 3. Network URL or relative path
    String fullUrl = trimmed;
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl =
          '${VerifierApiService.baseUrl}/${fullUrl.replaceFirst(RegExp(r'^/+'), '')}';
    }

    return Image.network(
      fullUrl,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryNeon,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _fallbackThumb(isLivePhoto),
    );
  }

  Widget _fallbackThumb(bool isLivePhoto) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLivePhoto ? Icons.broken_image : Icons.fingerprint,
            size: 32,
            color: Colors.amber.withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          const Text('Unavailable',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _biometricMatchBanner(VerifierCandidateDetailController c) {
    return Obx(() {
      final state = c.matchState.value;
      // Which side is currently busy — 'left' | 'right' | null
      final busySide = c.scanningSide.value ?? c.matchingSide.value;
      final isBusy = busySide != null;
      final isJsonLoaded = c.isBiometricJsonLoaded.value;
      final score = c.matchScore.value;
      final msg = c.matchMessage.value;

      Color borderColor;
      Color bgColor;
      IconData iconData;
      Color iconColor;
      String title;
      String desc;

      if (isBusy) {
        final sideLabel = busySide.toUpperCase();
        final isScanningStage = c.scanningSide.value != null;
        borderColor = AppTheme.primaryNeon;
        bgColor = AppTheme.primaryNeon.withOpacity(0.08);
        iconData = isScanningStage ? Icons.fingerprint : Icons.sync;
        iconColor = AppTheme.primaryNeon;
        title = isScanningStage
            ? 'Scanning $sideLabel Finger...'
            : 'Matching $sideLabel Finger...';
        desc = isScanningStage
            ? (msg.isNotEmpty
                ? msg
                : 'Please place your $busySide finger firmly on the sensor glass...')
            : 'Verifying captured $busySide thumb against enrolled $sideLabel template...';
      } else if (state == 'matched') {
        borderColor = AppTheme.successGreen;
        bgColor = AppTheme.successGreen.withOpacity(0.12);
        iconData = Icons.verified_user;
        iconColor = AppTheme.successGreen;
        title = score != null
            ? 'Biometric Verified (Score: $score%)'
            : 'Biometric Verified';
        desc = msg.isNotEmpty
            ? msg
            : 'Fingerprint matched enrolled biometric! Status set to VERIFIED.';
      } else if (c.isManualVerification.value) {
        borderColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.12);
        iconData =
            state == 'manual_captured' ? Icons.fingerprint : Icons.touch_app;
        iconColor = Colors.orange;
        title = state == 'manual_captured'
            ? 'Finger Captured (Manual Verification)'
            : 'Manual Verification Active';
        desc = msg.isNotEmpty
            ? msg
            : 'Biometric matching bypassed. Candidate can scan finger and submit verification manually.';
      } else if (state == 'mismatch') {
        borderColor = AppTheme.errorRed;
        bgColor = AppTheme.errorRed.withOpacity(0.12);
        iconData = Icons.gpp_bad;
        iconColor = AppTheme.errorRed;
        title = score != null
            ? 'Biometric Mismatch (Score: $score%)'
            : 'Biometric Mismatch';
        desc = msg.isNotEmpty
            ? msg
            : 'Fingerprint did not match enrolled template. Status set to REJECTED.';
      } else if (state == 'error') {
        borderColor = Colors.amber;
        bgColor = Colors.amber.withOpacity(0.12);
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.amber;
        title = 'Biometric Verification Alert';
        desc = msg.isNotEmpty ? msg : 'Unable to complete matching.';
      } else if (state == 'no_template') {
        borderColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.12);
        iconData = Icons.upload_file;
        iconColor = Colors.orange;
        title = 'Enrolled Template Missing';
        desc = msg.isNotEmpty
            ? msg
            : 'Enrolled template for this side is not available — please verify manually.';
      } else {
        final hasLeft = c.enrolledLeftTemplate.value != null;
        final hasRight = c.enrolledRightTemplate.value != null;
        String enrolledHandName = 'Finger';
        if (hasLeft && hasRight) {
          enrolledHandName = 'LEFT or RIGHT Thumb';
        } else if (hasLeft) {
          enrolledHandName = 'LEFT Thumb';
        } else if (hasRight) {
          enrolledHandName = 'RIGHT Thumb';
        }

        borderColor = isJsonLoaded
            ? AppTheme.primaryNeon.withOpacity(0.4)
            : AppTheme.surfaceDark;
        bgColor = AppTheme.surfaceDark.withOpacity(0.6);
        iconData = Icons.fingerprint;
        iconColor = isJsonLoaded ? AppTheme.primaryNeon : AppTheme.textMuted;
        title = isJsonLoaded
            ? 'Enrolled in Database: $enrolledHandName'
            : 'Loading Biometric Data...';
        desc = isJsonLoaded
            ? 'LEFT button matches only enrolled LEFT thumb, RIGHT button matches only enrolled RIGHT thumb (no cross-match).'
            : 'Downloading template from biometricJsonUrl...';

        // If stored templates for both hands are identical, enrolment data is faulty - alert before scan
        if (c.enrolledSidesIdentical.value) {
          borderColor = Colors.amber;
          bgColor = Colors.amber.withOpacity(0.12);
          iconData = Icons.warning_amber_rounded;
          iconColor = Colors.amber;
          title = 'Enrolment Data Faulty';
          desc =
              'Stored templates for both LEFT and RIGHT are identical on the server. '
              'Finger cannot be reliably verified — please re-enrol and sync candidate.';
        }
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isBusy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryNeon,
                ),
              )
            else
              Icon(iconData, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (state == 'matched')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('AUTO-VERIFIED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen)),
              )
            else if (c.isManualVerification.value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('MANUAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              )
            else if (state == 'mismatch')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('AUTO-REJECTED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorRed)),
              ),
          ],
        ),
      );
    });
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase().trim()) {
      case 'verified':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      case 'recheck':
        return Colors.amber;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
