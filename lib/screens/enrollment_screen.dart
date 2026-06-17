import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import '../models/candidate.dart';
import 'package:get/get.dart';
import '../controller/device_info_controller.dart';

class BiometricEnrollmentScreen extends StatefulWidget {
  final Candidate candidate;

  const BiometricEnrollmentScreen({super.key, required this.candidate});

  @override
  State<BiometricEnrollmentScreen> createState() => _BiometricEnrollmentScreenState();
}

class _BiometricEnrollmentScreenState extends State<BiometricEnrollmentScreen> {
  final DeviceInfoController _deviceInfoController = Get.put(DeviceInfoController());
  
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
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Widget _buildHudCard({
    required Widget child,
    bool showTopLeft = true,
    bool showTopRight = true,
    bool showBottomLeft = true,
    bool showBottomRight = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
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
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);
    const Color textMuted = Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cyberCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BIOMETRIC ENROLLMENT',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: cyberBlue.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Text(
              'Candidate: ${widget.candidate.name} (${widget.candidate.rollNo})',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cyberCyan,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reference Photo Card
                          _buildHudCard(
                            showTopLeft: true,
                            showBottomRight: true,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF112244),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: cyberBlue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.candidate.name.substring(0, min(widget.candidate.name.length, 2)).toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        color: cyberCyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reference Photo',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        'Pre-registered image',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: cyberCyan),
                                  label: Text(
                                    'View',
                                    style: GoogleFonts.outfit(
                                      color: cyberCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF112244),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'REQUIRED CAPTURES',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
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
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _isAllComplete
                          ? const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _isAllComplete ? null : Colors.grey.shade800,
                      boxShadow: _isAllComplete
                          ? [
                              BoxShadow(
                                color: cyberBlue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _isAllComplete ? _handleSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SAVE & MARK REGISTERED',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isAllComplete ? Colors.white : Colors.white24,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
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
    const Color cyberBlue = Color(0xFF2196F3);
    const Color textMuted = Color(0xFF90A4AE);
    const Color neonGreen = Color(0xFF10B981);
    const Color errorRed = Color(0xFFEF5350);

    return _buildHudCard(
      showTopLeft: !isCompleted,
      showBottomRight: !isCompleted,
      showTopRight: isCompleted,
      showBottomLeft: isCompleted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: imageBytes != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1329),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cyberBlue.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$title Fingerprint",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: cyberBlue.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    imageBytes,
                                    fit: BoxFit.contain,
                                    width: 260,
                                    height: 300,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'CLOSE',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF0A2E24) : const Color(0xFF331616),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? neonGreen.withOpacity(0.5) : errorRed.withOpacity(0.5),
                  width: 1.5,
                ),
                image: imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(imageBytes),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageBytes == null
                  ? Icon(
                      isCompleted ? Icons.check : icon,
                      color: isCompleted ? neonGreen : errorRed,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isCompleted ? neonGreen : textMuted,
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: errorRed),
                    ),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF331616),
                      foregroundColor: errorRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: errorRed, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(icon, size: 16, color: Colors.white),
                    label: Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onPressed == null ? Colors.grey.shade800 : const Color(0xFF1A3D75),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: onPressed == null ? Colors.transparent : cyberBlue.withOpacity(0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
          else
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check, size: 16, color: neonGreen),
              label: Text(
                'Done',
                style: GoogleFonts.outfit(
                  color: neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: neonGreen, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
}

