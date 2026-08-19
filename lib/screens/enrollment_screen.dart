import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/candidate.dart';
import 'package:get/get.dart';
import '../controller/device_info_controller.dart';
import '../controller/dashboard_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class BiometricEnrollmentScreen extends StatefulWidget {
  final Candidate candidate;
  const BiometricEnrollmentScreen({super.key, required this.candidate});
  @override
  State<BiometricEnrollmentScreen> createState() =>
      _BiometricEnrollmentScreenState();
}
class _BiometricEnrollmentScreenState extends State<BiometricEnrollmentScreen> {
  final DeviceInfoController _deviceInfoController =
      Get.put(DeviceInfoController());
  bool _livePhotoCaptured = false;
  bool _leftThumbScanned = false;
  bool _rightThumbScanned = false;
  Uint8List? _livePhotoImage;
  Uint8List? _leftThumbImage;
  Uint8List? _rightThumbImage;

  String? _activeScan;

  @override
  void initState() {
    super.initState();
    _deviceInfoController.clearBiometricData();
    _loadExistingData();
  }

  void _loadExistingData() {
    try {
      final box = Hive.box('candidates_box');
      for (var i = 0; i < box.length; i++) {
        var item = Map<String, dynamic>.from(box.getAt(i) as Map);
        if ((item['id'] ?? item['_id']).toString() == widget.candidate.id) {
          if (item['biometricData'] != null && item['biometricData'] is Map) {
            Map<String, dynamic> bData = Map<String, dynamic>.from(item['biometricData']);
            _deviceInfoController.leftBiometricData.addAll(bData);
            _deviceInfoController.rightBiometricData.addAll(bData);
          }
          setState(() {
            if (item['livePhotoBase64'] != null) {
              String base64 = item['livePhotoBase64'].toString().split(',').last;
              _livePhotoImage = base64Decode(base64);
              _livePhotoCaptured = true;
            } else if (item['localLivePhotoPath'] != null && File(item['localLivePhotoPath']).existsSync()) {
              _livePhotoImage = File(item['localLivePhotoPath']).readAsBytesSync();
              _livePhotoCaptured = true;
            } else if (item['livePhoto'] != null && item['livePhoto'].toString().startsWith('http')) {
              _fetchAndSetBytes(item['livePhoto'].toString(), 'live');
            }

            if (item['leftThumbBase64'] != null) {
              String base64 = item['leftThumbBase64'].toString().split(',').last;
              _leftThumbImage = base64Decode(base64);
              _leftThumbScanned = true;
            } else if (item['localLeftThumbPath'] != null && File(item['localLeftThumbPath']).existsSync()) {
              _leftThumbImage = File(item['localLeftThumbPath']).readAsBytesSync();
              _leftThumbScanned = true;
            } else if (item['leftThumb'] != null && item['leftThumb'].toString().startsWith('http')) {
              _fetchAndSetBytes(item['leftThumb'].toString(), 'left');
            }

            if (item['rightThumbBase64'] != null) {
              String base64 = item['rightThumbBase64'].toString().split(',').last;
              _rightThumbImage = base64Decode(base64);
              _rightThumbScanned = true;
            } else if (item['localRightThumbPath'] != null && File(item['localRightThumbPath']).existsSync()) {
              _rightThumbImage = File(item['localRightThumbPath']).readAsBytesSync();
              _rightThumbScanned = true;
            } else if (item['rightThumb'] != null && item['rightThumb'].toString().startsWith('http')) {
              _fetchAndSetBytes(item['rightThumb'].toString(), 'right');
            }
          });
          break;
        }
      }
    } catch (e) {
      debugPrint("Error loading existing data: $e");
    }
  }

  Future<void> _fetchAndSetBytes(String url, String type) async {
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        final uint8list = Uint8List.fromList(bytes);
        if (mounted) {
          setState(() {
            if (type == 'live') {
              _livePhotoImage = uint8list;
              _livePhotoCaptured = true;
            } else if (type == 'left') {
              _leftThumbImage = uint8list;
              _leftThumbScanned = true;
            } else if (type == 'right') {
              _rightThumbImage = uint8list;
              _rightThumbScanned = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching network image: $e");
    }
  }

  Future<Uint8List?> _compressBytes(Uint8List bytes) async {
    try {
      var result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 480,
        minWidth: 640,
        quality: 60,
      );
      return result;
    } catch (e) {
      return bytes;
    }
  }

  Future<void> _captureLivePhoto() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        Get.snackbar("Permission Denied", "Camera permission required.");
        return;
      }
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );
      if (photo != null) {
        final Uint8List bytes = await photo.readAsBytes();
        final Uint8List? compressed = await _compressBytes(bytes);
        setState(() {
          _livePhotoImage = compressed;
          _livePhotoCaptured = true;
        });
      }
    } catch (e) {
      debugPrint("Error picking photo: $e");
    }
  }

  bool get _isAllComplete =>
      _livePhotoCaptured && _leftThumbScanned && _rightThumbScanned;

  @override
  void dispose() {
    if (_activeScan != null) _deviceInfoController.cancelScan();
    super.dispose();
  }

  void _handleSave() async {
    try {
      final box = Hive.box('candidates_box');
      int index = -1;
      Map<String, dynamic>? studentData;
      
      for (int i = 0; i < box.length; i++) {
        var item = Map<String, dynamic>.from(box.getAt(i) as Map);
        if ((item['id'] ?? item['_id']).toString() == widget.candidate.id) {
          index = i;
          studentData = item;
          break;
        }
      }

      if (index != -1 && studentData != null) {
        studentData['attendanceStatus'] = true;
        studentData['attendanceTime'] = DateTime.now().toIso8601String();
        studentData['biometricStatus'] = true;
        studentData['biometricTime'] = DateTime.now().toIso8601String();
        studentData['syncStatus'] = false;
        studentData['syncFailed'] = false;

        if (_livePhotoImage != null) {
          studentData['livePhotoBase64'] = "data:image/jpeg;base64,${base64Encode(_livePhotoImage!)}";
        }
        if (_leftThumbImage != null) {
          studentData['leftThumbBase64'] = "data:image/png;base64,${base64Encode(_leftThumbImage!)}";
        }
        if (_rightThumbImage != null) {
          studentData['rightThumbBase64'] = "data:image/png;base64,${base64Encode(_rightThumbImage!)}";
        }
        if (_deviceInfoController.fingerprintTemplate != null) {
          studentData['biometricTemplate'] = base64Encode(_deviceInfoController.fingerprintTemplate!);
        }

        Map<String, dynamic> fullBiometricData = {};
        if (studentData['biometricData'] != null && studentData['biometricData'] is Map) {
          fullBiometricData.addAll(Map<String, dynamic>.from(studentData['biometricData'] as Map));
        }
        if (_deviceInfoController.leftBiometricData.isNotEmpty) {
          fullBiometricData.addAll(_deviceInfoController.leftBiometricData);
        }
        if (_deviceInfoController.rightBiometricData.isNotEmpty) {
          fullBiometricData.addAll(_deviceInfoController.rightBiometricData);
        }
        if (fullBiometricData.isNotEmpty) {
          studentData['biometricData'] = fullBiometricData;
        }

        await box.putAt(index, studentData);
        Navigator.pop(context);
        Get.snackbar('Success', 'Attendance recorded locally. Syncing in background.', backgroundColor: Colors.green);
        
        // Trigger background sync
        try {
          final DashboardController dashboardController = Get.isRegistered<DashboardController>() 
              ? Get.find<DashboardController>() 
              : Get.put(DashboardController());
          dashboardController.backgroundSync();
        } catch (e) {
          print("Error triggering background sync: $e");
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    final Color textMuted = Theme.of(context).brightness == Brightness.light ? const Color(0xFF64748B) : Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIOMETRIC ENROLLMENT', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${widget.candidate.name} (${widget.candidate.rollNo})', style: GoogleFonts.outfit(fontSize: 11, color: textMuted)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHudCard(
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildReferencePhoto()),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(widget.candidate.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Roll No: ${widget.candidate.rollNo} • Reference Photo', style: GoogleFonts.outfit(fontSize: 11, color: textMuted)),
                            ])),
                            IconButton(onPressed: _showFullPhoto, icon: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCaptureCard(
                        title: 'Live Photo',
                        subtitle: _livePhotoCaptured ? 'Captured' : 'Required',
                        icon: Icons.camera_alt,
                        isCompleted: _livePhotoCaptured,
                        buttonText: 'Capture',
                        imageBytes: _livePhotoImage,
                        onPressed: _captureLivePhoto,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGridCaptureCard(
                            title: 'Left Thumb',
                            subtitle: _activeScan == 'left' ? 'Scanning...' : (_leftThumbScanned ? 'Done' : 'Required'),
                            icon: Icons.fingerprint,
                            isCompleted: _leftThumbScanned,
                            isScanning: _activeScan == 'left',
                            buttonText: 'Scan',
                            imageBytes: _leftThumbImage,
                            onCancel: _deviceInfoController.cancelScan,
                            onPressed: _activeScan != null ? null : () async {
                              setState(() => _activeScan = 'left');
                              bool success = await _deviceInfoController.scanFingerPrint(scanType: 'left');
                              setState(() {
                                _activeScan = null;
                                if (success) {
                                  _leftThumbScanned = true;
                                  _leftThumbImage = _deviceInfoController.leftFingerprintImage ?? _deviceInfoController.fingerprintImage;
                                }
                              });
                            },
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridCaptureCard(
                            title: 'Right Thumb',
                            subtitle: _activeScan == 'right' ? 'Scanning...' : (_rightThumbScanned ? 'Done' : 'Required'),
                            icon: Icons.fingerprint,
                            isCompleted: _rightThumbScanned,
                            isScanning: _activeScan == 'right',
                            buttonText: 'Scan',
                            imageBytes: _rightThumbImage,
                            onCancel: _deviceInfoController.cancelScan,
                            onPressed: _activeScan != null ? null : () async {
                              setState(() => _activeScan = 'right');
                              bool success = await _deviceInfoController.scanFingerPrint(scanType: 'right');
                              setState(() {
                                _activeScan = null;
                                if (success) {
                                  _rightThumbScanned = true;
                                  _rightThumbImage = _deviceInfoController.rightFingerprintImage ?? _deviceInfoController.fingerprintImage;
                                }
                              });
                            },
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _isAllComplete ? const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)]) : null,
                  color: _isAllComplete ? null : Colors.grey.withOpacity(0.2),
                ),
                child: ElevatedButton(
                  onPressed: _isAllComplete ? _handleSave : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: Text('SAVE & MARK REGISTERED', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: _isAllComplete ? Colors.white : Colors.white24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildReferencePhoto() {
    if (widget.candidate.localPhotoPath != null && File(widget.candidate.localPhotoPath!).existsSync()) {
      return Image.file(File(widget.candidate.localPhotoPath!), fit: BoxFit.cover);
    } else if (widget.candidate.photo != null && widget.candidate.photo!.startsWith('http')) {
      return Image.network(widget.candidate.photo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitials());
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Center(child: Text(widget.candidate.name.substring(0, 2).toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF1976D2), fontWeight: FontWeight.bold)));
  }

  void _showFullPhoto() {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 400), child: _buildReferencePhoto()))),
      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context))
    ])));
  }

  Widget _buildCaptureCard({required String title, required String subtitle, required IconData icon, required bool isCompleted, required String buttonText, required VoidCallback? onPressed, bool isScanning = false, VoidCallback? onCancel, Uint8List? imageBytes}) {
    final Color accent = isCompleted ? Colors.green : Colors.red;
    return _buildHudCard(child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle, image: imageBytes != null ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover) : null), child: imageBytes == null ? Icon(isCompleted ? Icons.check : icon, color: accent, size: 20) : null),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: isCompleted ? Colors.green : Theme.of(context).textTheme.bodySmall?.color)),
      ])),
      ElevatedButton(
        onPressed: isScanning ? onCancel : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.orange.withOpacity(0.1) : null,
          foregroundColor: isCompleted ? Colors.orange : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(60, 32),
        ),
        child: isScanning 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) 
          : Text(isCompleted ? 'RE-CAPTURE' : buttonText, style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold))
      ),
    ]));
  }

  Widget _buildGridCaptureCard({required String title, required String subtitle, required IconData icon, required bool isCompleted, required String buttonText, required VoidCallback? onPressed, bool isScanning = false, VoidCallback? onCancel, Uint8List? imageBytes}) {
    final Color accent = isCompleted ? Colors.green : Colors.red;
    return _buildHudCard(child: Column(children: [
      Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 12),
      Container(
        width: 80, 
        height: 100, 
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(8), 
          image: imageBytes != null 
              ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.contain) 
              : null
        ), 
        child: imageBytes == null 
            ? Icon(isCompleted ? Icons.check : icon, color: accent, size: 32) 
            : null
      ),
      const SizedBox(height: 12),
      Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: isCompleted ? Colors.green : Theme.of(context).textTheme.bodySmall?.color)),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: isScanning ? onCancel : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.orange.withOpacity(0.1) : null,
          foregroundColor: isCompleted ? Colors.orange : null,
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        child: isScanning 
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) 
          : Text(isCompleted ? 'RE-CAPTURE' : buttonText, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold))
      )),
    ]));
  }
}
