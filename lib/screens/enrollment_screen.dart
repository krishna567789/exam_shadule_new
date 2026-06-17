import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../models/candidate.dart';
import 'package:get/get.dart';
import '../controller/device_info_controller.dart';
import '../controller/biomatric_controller.dart';
class BiometricEnrollmentScreen extends StatefulWidget {
  final Candidate candidate;

  const BiometricEnrollmentScreen({super.key, required this.candidate});

  @override
  State<BiometricEnrollmentScreen> createState() => _BiometricEnrollmentScreenState();
}

class _BiometricEnrollmentScreenState extends State<BiometricEnrollmentScreen> {
  final DeviceInfoController _deviceInfoController = Get.put(DeviceInfoController());
  final BiometricController _biometricController = Get.put(BiometricController());

  bool _livePhotoCaptured = false;
  bool _leftThumbScanned = false;
  bool _rightThumbScanned = false;

  Uint8List? _leftThumbImage;
  Uint8List? _rightThumbImage;

  String? _activeScan; // 'left' or 'right'

  bool get _isAllComplete => _livePhotoCaptured && _leftThumbScanned && _rightThumbScanned;

  @override
  void dispose() {
    if (_activeScan != null) {
      _deviceInfoController.cancelScan();
    }
    super.dispose();
  }

  void _handleSave() {
    Navigator.pop(context); // Go back to candidate list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Candidate Registered Successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biometric Enrollment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Candidate: ${widget.candidate.name} (${widget.candidate.rollNo})',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reference Photo Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            widget.candidate.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference Photo',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            Text(
                              'Pre-registered image',
                              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.textLight),
                        label: const Text('View', style: TextStyle(color: AppTheme.textLight)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Required Captures',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              
              // Live Photo
              _buildCaptureCard(
                title: 'Live Photo',
                subtitle: _livePhotoCaptured ? 'Captured' : 'Pending Capture',
                icon: Icons.camera_alt_outlined,
                isCompleted: _livePhotoCaptured,
                buttonText: 'Capture Photo',
                onPressed: () {
                  setState(() => _livePhotoCaptured = true);
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildCaptureCard(
                title: 'Left Thumb',
                subtitle: _activeScan == 'left' ? 'Scanning...' : (_leftThumbScanned ? 'Scanned' : 'Pending Scan'),
                icon: Icons.fingerprint,
                isCompleted: _leftThumbScanned,
                isScanning: _activeScan == 'left',
                buttonText: 'Scan',
                imageBytes: _leftThumbImage,
                onCancel: () {
                  _deviceInfoController.cancelScan();
                },
                onPressed: _activeScan != null ? null : () async {
                  setState(() => _activeScan = 'left');
                  bool success = await _deviceInfoController.scanFingerPrint();
                  setState(() {
                    _activeScan = null;
                    if (success) {
                      _leftThumbScanned = true;
                      _leftThumbImage = _deviceInfoController.fingerprintImage;
                    }
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildCaptureCard(
                title: 'Right Thumb',
                subtitle: _activeScan == 'right' ? 'Scanning...' : (_rightThumbScanned ? 'Scanned' : 'Pending Scan'),
                icon: Icons.fingerprint,
                isCompleted: _rightThumbScanned,
                isScanning: _activeScan == 'right',
                buttonText: 'Scan',
                imageBytes: _rightThumbImage,
                onCancel: () {
                  _deviceInfoController.cancelScan();
                },
                onPressed: _activeScan != null ? null : () async {
                  setState(() => _activeScan = 'right');
                  bool success = await _deviceInfoController.scanFingerPrint();
                  setState(() {
                    _activeScan = null;
                    if (success) {
                      _rightThumbScanned = true;
                      _rightThumbImage = _deviceInfoController.fingerprintImage;
                    }
                  });
                },
              ),
              
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Save & Mark Registered',
                backgroundColor: _isAllComplete ? AppTheme.primaryBlue : Colors.grey.shade300,
                textColor: _isAllComplete ? Colors.white : Colors.grey.shade500,
                onPressed: _isAllComplete ? _handleSave : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required String buttonText,
    required VoidCallback? onPressed,
    bool isScanning = false,
    VoidCallback? onCancel,
    Uint8List? imageBytes,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: imageBytes != null ? () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$title Fingerprint", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.contain,
                              width: 260,
                              height: 300,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image: imageBytes != null ? DecorationImage(
                    image: MemoryImage(imageBytes),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: imageBytes == null ? Icon(
                  isCompleted ? Icons.check : icon,
                  color: isCompleted ? AppTheme.successGreen : Colors.red.shade300,
                  size: 20,
                ) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? AppTheme.successGreen : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              isScanning
                  ? ElevatedButton.icon(
                      onPressed: onCancel,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorRed),
                      ),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed.withOpacity(0.1),
                        foregroundColor: AppTheme.errorRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon, size: 16),
                      label: Text(buttonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: onPressed == null ? Colors.grey.shade400 : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    )
            else
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check, size: 16, color: AppTheme.successGreen),
                label: const Text('Done', style: TextStyle(color: AppTheme.successGreen)),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.successGreen.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
