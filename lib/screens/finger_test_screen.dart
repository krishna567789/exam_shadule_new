import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class FingerTestScreen extends StatefulWidget {
  const FingerTestScreen({super.key});

  @override
  State<FingerTestScreen> createState() => _FingerTestScreenState();
}

class _FingerTestScreenState extends State<FingerTestScreen> {
  static const _platform =
      MethodChannel('com.example.exam_shadule_new/rd_service');

  bool _isScanning = false;
  String _statusMessage =
      "Ready to test scanner. Connect device and place finger.";

  // Scanned data variables
  bool? _scanSuccess;
  Uint8List? _fingerprintImage;
  Uint8List? _fingerprintTemplate;
  int? _imageWidth;
  int? _imageHeight;
  int? _qualityScore;
  String? _errorCode;
  String? _errorMessage;

  // Scanner metadata
  String? _deviceName;
  String? _pid;
  String? _vid;

  @override
  void initState() {
    super.initState();
    _checkDeviceOnLoad();
  }

  Future<void> _checkDeviceOnLoad() async {
    try {
      final usbCheck = await _platform.invokeMethod('checkUsbDevices');
      if (usbCheck != null && usbCheck is Map && usbCheck['devices'] != null) {
        final List devicesList = usbCheck['devices'];
        if (devicesList.isNotEmpty) {
          _parseUsbDeviceInfo(devicesList.first.toString());
        } else {
          setState(() {
            _deviceName = "No SecuGen device detected";
            _vid = null;
            _pid = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking USB devices: $e");
    }
  }

  void _parseUsbDeviceInfo(String deviceStr) {
    try {
      final regExp =
          RegExp(r'VID:([0-9A-F]+)\s+PID:([0-9A-F]+)\s*[-–—]\s*(.+)');
      final match = regExp.firstMatch(deviceStr);
      if (match != null) {
        setState(() {
          _vid = match.group(1);
          _pid = match.group(2);
          _deviceName = match.group(3);
        });
      } else {
        setState(() {
          _deviceName = deviceStr;
        });
      }
    } catch (e) {
      setState(() {
        _deviceName = deviceStr;
      });
    }
  }

  Future<void> _captureFingerprint() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage =
          "Initializing device & capturing... Place finger on scanner.";
      _scanSuccess = null;
      _fingerprintImage = null;
      _fingerprintTemplate = null;
      _imageWidth = null;
      _imageHeight = null;
      _qualityScore = null;
      _errorCode = null;
      _errorMessage = null;
    });

    try {
      // 1. Check USB connection first
      final usbCheck = await _platform.invokeMethod('checkUsbDevices');
      debugPrint("USB Check Result: $usbCheck");
      if (usbCheck != null && usbCheck is Map && usbCheck['devices'] != null) {
        final List devicesList = usbCheck['devices'];
        if (devicesList.isNotEmpty) {
          _parseUsbDeviceInfo(devicesList.first.toString());
        } else {
          setState(() {
            _deviceName = "No SecuGen device detected";
            _vid = null;
            _pid = null;
          });
        }
      }

      // 2. Call captureFingerprint
      final result = await _platform.invokeMethod('captureFingerprint');
      debugPrint("Raw capture result: $result");

      if (result != null && result is Map) {
        setState(() {
          _scanSuccess = result['success'] ?? false;

          if (result['image'] != null) {
            final rawImageBytes =
                Uint8List.fromList(List<int>.from(result['image']));
            try {
              int width = result['width'] ?? 260;
              int height = result['height'] ?? 300;
              img.Image decodedImage = img.Image.fromBytes(
                width: width,
                height: height,
                bytes: rawImageBytes.buffer,
                numChannels: 1,
              );
              _fingerprintImage =
                  Uint8List.fromList(img.encodePng(decodedImage));
            } catch (e) {
              debugPrint("Fingerprint image conversion failed: $e");
              _fingerprintImage = rawImageBytes;
            }
          }
          if (result['template'] != null) {
            _fingerprintTemplate =
                Uint8List.fromList(List<int>.from(result['template']));
          }

          _imageWidth = result['width'];
          _imageHeight = result['height'];
          _qualityScore = result['quality'];
          _statusMessage = _scanSuccess!
              ? "Biometric capture successful!"
              : "Capture failed.";
        });

        // Print biometric details to console
        _printBiometricDetails();
      } else {
        setState(() {
          _scanSuccess = false;
          _statusMessage = "Invalid result structure from device.";
        });
      }
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.code} - ${e.message}");
      setState(() {
        _scanSuccess = false;
        _errorCode = e.code;
        _errorMessage = e.message;
        _statusMessage = "Scanner error: ${e.message}";
      });
    } catch (e) {
      debugPrint("General capture error: $e");
      setState(() {
        _scanSuccess = false;
        _statusMessage = "Unexpected error: $e";
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _printBiometricDetails() {
    print("========== BIOMETRIC DEVICE TEST DETAILS ==========");
    print("Timestamp: ${DateTime.now().toIso8601String()}");
    print("Capture Status: ${_scanSuccess == true ? 'SUCCESS' : 'FAILED'}");
    if (_imageWidth != null) print("Image Width: $_imageWidth px");
    if (_imageHeight != null) print("Image Height: $_imageHeight px");
    if (_qualityScore != null) print("Image Quality Score: $_qualityScore%");
    if (_fingerprintImage != null) {
      print("Raw Image Byte Length: ${_fingerprintImage!.length} bytes");
    }
    if (_fingerprintTemplate != null) {
      print("Template Size: ${_fingerprintTemplate!.length} bytes");
      print("Template Base64: ${base64Encode(_fingerprintTemplate!)}");
    }
    if (_errorCode != null) print("Platform Error Code: $_errorCode");
    if (_errorMessage != null) print("Platform Error Message: $_errorMessage");
    print("===================================================");
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color textDark = Color(0xFF0F172A);
    const Color textMuted = Color(0xFF64748B);
    const Color neonGreen = Color(0xFF10B981);
    const Color errorRed = Color(0xFFEF5350);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FINGERPRINT DEVICE TEST',
          style: GoogleFonts.outfit(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner Status Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isScanning
                            ? Colors.orange
                            : (_scanSuccess == true ? neonGreen : errorRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Layout with Image display & Diagnostic report
              // Device Feed (Centered layout)
              Center(
                child: Column(
                  children: [
                    Text(
                      'DEVICE FEED',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _fingerprintImage != null
                            ? Image.memory(
                                _fingerprintImage!,
                                fit: BoxFit.contain,
                              )
                            : Center(
                                child: Icon(
                                  Icons.fingerprint,
                                  size: 64,
                                  color: textMuted.withOpacity(0.3),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Device & Metadata Card
              Text(
                'DEVICE & METADATA',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    _buildDetailRow("Device Name",
                        _deviceName ?? "No SecuGen device detected"),
                    _buildDetailRow("Product ID (PID)", _pid ?? "--"),
                    _buildDetailRow("Vendor ID (VID)", _vid ?? "--"),
                    _buildDetailRow("Quality Score",
                        _qualityScore != null ? "$_qualityScore%" : "--",
                        valueColor:
                            _qualityScore != null && _qualityScore! >= 40
                                ? neonGreen
                                : null),
                    _buildDetailRow(
                        "Template Size",
                        _fingerprintTemplate != null
                            ? "${_fingerprintTemplate!.length} bytes"
                            : "--"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Template Output Box
              Text(
                'ENCRYPTED ISO TEMPLATE',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                height: 120,
                child: SingleChildScrollView(
                  child: Text(
                    _fingerprintTemplate != null
                        ? base64Encode(_fingerprintTemplate!)
                        : "No template generated. Capture a biometric fingerprint to generate the cryptosystem code.",
                    style: GoogleFonts.shareTechMono(
                      color: neonGreen,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Scan Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _captureFingerprint,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.touch_app, color: Colors.white),
                  label: Text(
                    _isScanning
                        ? 'SCANNING SENSOR...'
                        : 'START FINGERPRINT CAPTURE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_errorCode != null) ...[
                const SizedBox(height: 16),
                Text(
                  "Error [$_errorCode]: $_errorMessage",
                  style: GoogleFonts.outfit(
                    color: errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    const Color textDark = Color(0xFF0F172A);
    const Color textMuted = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? textDark,
            ),
          ),
        ],
      ),
    );
  }
}
