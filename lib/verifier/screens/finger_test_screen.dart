import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../../utils/app_theme.dart';
import '../../widgets/custom_text.dart';

/// SecuGen HU20 USB scanner diagnostic — capture a finger and inspect
/// quality, dimensions, template and device metadata.
class VerifierFingerTestScreen extends StatefulWidget {
  const VerifierFingerTestScreen({super.key});

  @override
  State<VerifierFingerTestScreen> createState() => _FingerTestScreenState();
}

class _FingerTestScreenState extends State<VerifierFingerTestScreen> {
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
  int? _rawImageLength;
  String? _serialNumber;
  int? _imageDPI;
  String? _fwVersion;
  int? _brightness;
  int? _contrast;
  int? _gain;

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
          _rawImageLength =
              result['image'] != null ? (result['image'] as List).length : null;
          _serialNumber = result['serialNumber']?.toString();
          _imageDPI = result['imageDPI'];
          _fwVersion = result['fwVersion']?.toString();
          _brightness = result['brightness'];
          _contrast = result['contrast'];
          _gain = result['gain'];
          if (result['deviceName'] != null) {
            _deviceName = result['deviceName']?.toString();
          }

          _statusMessage = _scanSuccess!
              ? "Biometric capture successful!"
              : "Capture failed.";
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryNeon),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText.heading('FINGERPRINT DEVICE TEST',
            fontSize: 17, letterSpacing: 1.2),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statusCard(),
              const SizedBox(height: 20),
              _deviceFeed(),
              const SizedBox(height: 20),
              _sectionLabel('DEVICE & METADATA'),
              const SizedBox(height: 8),
              _metaCard(),
              const SizedBox(height: 20),
              _sectionLabel('ENCRYPTED ISO TEMPLATE'),
              const SizedBox(height: 8),
              _templateBox(),
              const SizedBox(height: 26),
              _scanButton(),
              if (_errorCode != null) ...[
                const SizedBox(height: 16),
                Text(
                  "Error [$_errorCode]: $_errorMessage",
                  style: GoogleFonts.outfit(
                    color: AppTheme.errorRed,
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

  Widget _statusCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                  : (_scanSuccess == true
                      ? AppTheme.successGreen
                      : AppTheme.errorRed),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceFeed() {
    return Center(
      child: Column(
        children: [
          _sectionLabel('DEVICE FEED'),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF16213B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _fingerprintImage != null
                  ? Image.memory(_fingerprintImage!, fit: BoxFit.contain)
                  : Center(
                      child: Icon(
                        Icons.fingerprint,
                        size: 64,
                        color: AppTheme.primaryNeon.withOpacity(0.35),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _buildDetailRow("Device Name",
              _deviceName ?? "No SecuGen device detected"),
          _buildDetailRow("Serial Number (SN)", _serialNumber ?? "--"),
          _buildDetailRow(
              "Firmware & DPI",
              _fwVersion != null
                  ? "$_fwVersion (${_imageDPI ?? 500} DPI)"
                  : "--"),
          _buildDetailRow("Product ID (PID)", _pid ?? "--"),
          _buildDetailRow("Vendor ID (VID)", _vid ?? "--"),
          _buildDetailRow("Dimensions",
              _imageWidth != null ? "$_imageWidth × $_imageHeight px" : "--"),
          _buildDetailRow("Raw Sensor Buffer",
              _rawImageLength != null ? "$_rawImageLength bytes" : "--"),
          _buildDetailRow(
              "Quality Score",
              _qualityScore != null ? "$_qualityScore%" : "--",
              valueColor: _qualityScore != null && _qualityScore! >= 35
                  ? AppTheme.successGreen
                  : AppTheme.errorRed),
          _buildDetailRow("Template Size",
              _fingerprintTemplate != null
                  ? "${_fingerprintTemplate!.length} bytes"
                  : "--"),
          if (_brightness != null)
            _buildDetailRow(
                "Sensor Tuning", "B:${_brightness} C:${_contrast} G:${_gain}"),
        ],
      ),
    );
  }

  Widget _templateBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060B18),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.successGreen.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(12),
      height: 120,
      child: SingleChildScrollView(
        child: Text(
          _fingerprintTemplate != null
              ? base64Encode(_fingerprintTemplate!)
              : "No template generated. Capture a biometric fingerprint to generate the cryptosystem code.",
          style: GoogleFonts.shareTechMono(
            color: AppTheme.successGreen,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _scanButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), AppTheme.primaryNeon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 14,
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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.touch_app, color: AppTheme.backgroundDark),
        label: Text(
          _isScanning ? 'SCANNING SENSOR...' : 'START FINGERPRINT CAPTURE',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.backgroundDark,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: AppTheme.textMuted,
        letterSpacing: 1.4,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
              color: AppTheme.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.shareTechMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
