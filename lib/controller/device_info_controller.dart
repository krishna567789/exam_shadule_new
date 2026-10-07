import 'dart:convert';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class DeviceInfoController extends GetxController {
  var isRdServiceInstalled = false.obs;
  static const platform = MethodChannel('com.example.exam_shadule_new/rd_service');

  // Fingerprint data storage
  Uint8List? fingerprintImage;    // Raw image bytes
  Uint8List? fingerprintTemplate; // SG400 template for matching
  Uint8List? fingerprintIsoTemplate; // ISO 19794-2 template of the last capture
  var fingerprintImagePath = Rx<String?>(null);

  // Extended Biometric & Hardware Metadata
  int? qualityScore;
  String? lastScanError; // banner ke liye, jab toast suppress ho
  int? imageWidth;
  int? imageHeight;
  int? rawImageSize;
  String? serialNumber;
  int? imageDPI;
  String? fwVersion;
  int? brightness;
  int? contrast;
  int? gain;
  String? deviceName;

  // Exact API structured biometric data maps for left and right scans
  Map<String, dynamic> leftBiometricData = {};
  Map<String, dynamic> rightBiometricData = {};
  Uint8List? leftFingerprintImage;
  Uint8List? rightFingerprintImage;

  @override
  void onInit() {
    super.onInit();
    checkRdServiceInstalled();
  }

  var isScanningFinger = false.obs;

  void checkRdServiceInstalled() async {
    bool isInstalled = await DeviceApps.isAppInstalled('com.secugen.rdservice');
    isRdServiceInstalled.value = isInstalled;
  }

  Future<void> cancelScan() async {
    if (isScanningFinger.value) {
      try {
        await platform.invokeMethod('cancelCapture');
      } catch (e) {
        print("Failed to cancel scan: $e");
      }
    }
  }

  // ✅ SecuGen FDx SDK se fingerprint capture with scanType ('left' or 'right')
  /// showToasts=false candidate verify screen bhejti hai (feedback banner me dikhta hai).
  Future<bool> scanFingerPrint({String scanType = 'left', bool showToasts = true}) async {
    if (isScanningFinger.value) return false;
    lastScanError = null;
    
    try {
      isScanningFinger.value = true;
      
      // USB devices pehle check karo
      final usbResult = await platform.invokeMethod('checkUsbDevices');
      print("USB Devices: $usbResult");

      // SDK se fingerprint capture karo (scanType native ko finger position batata hai)
      final result = await platform.invokeMethod('captureFingerprint', {
        'scanType': scanType,
      });

      if (result != null && result is Map) {
        bool success = result['success'] ?? false;
        if (success) {
          final rawImageBytes = result['image'] != null ? Uint8List.fromList(List<int>.from(result['image'])) : null;
          fingerprintTemplate = result['template'] != null ? Uint8List.fromList(List<int>.from(result['template'])) : null;
          // Live ISO template — fallback matching ke liye (primary SG400 hai)
          fingerprintIsoTemplate = result['isoTemplate'] != null ? Uint8List.fromList(List<int>.from(result['isoTemplate'])) : null;

          qualityScore = result['quality'];
          imageWidth = result['width'] ?? 300;
          imageHeight = result['height'] ?? 400;
          rawImageSize = rawImageBytes?.length;
          serialNumber = result['serialNumber']?.toString() ?? "H54170101182";
          imageDPI = result['imageDPI'] ?? 500;
          fwVersion = result['fwVersion']?.toString();
          brightness = result['brightness'];
          contrast = result['contrast'];
          gain = result['gain'];
          deviceName = result['deviceName']?.toString();

          int nfiq = result['nfiq'] ?? (qualityScore != null ? (qualityScore! >= 80 ? 1 : (qualityScore! >= 60 ? 2 : (qualityScore! >= 40 ? 3 : 4))) : 2);
          Uint8List? pngBytes;
          Uint8List? bmpBytes;

          if (rawImageBytes != null) {
            try {
              int width = imageWidth ?? 300;
              int height = imageHeight ?? 400;
              
              img.Image decodedImage = img.Image.fromBytes(
                width: width,
                height: height,
                bytes: rawImageBytes.buffer,
                numChannels: 1,
              );
              
              pngBytes = Uint8List.fromList(img.encodePng(decodedImage));
              bmpBytes = Uint8List.fromList(img.encodeBmp(decodedImage));
              fingerprintImage = pngBytes;
              printClearBiometricDetails(result, rawBytes: rawImageBytes, pngBytes: pngBytes);
            } catch (e) {
              print("Image encoding error: $e");
              pngBytes = rawImageBytes;
              bmpBytes = rawImageBytes;
              printClearBiometricDetails(result, rawBytes: rawImageBytes);
            }
          } else {
            printClearBiometricDetails(result);
          }

          String tmplBase64 = fingerprintTemplate != null ? base64Encode(fingerprintTemplate!) : "";
          String wsqBase64 = pngBytes != null ? base64Encode(pngBytes) : "";
          int wsqSize = pngBytes?.length ?? 0;
          String bmpBase64Str = bmpBytes != null ? base64Encode(bmpBytes) : wsqBase64;

          if (scanType == 'left') {
            leftFingerprintImage = pngBytes;
            leftBiometricData = {
              "SerialNumber": serialNumber ?? "H54170101182",
              "ImageHeight": imageHeight ?? 400,
              "ImageWidth": imageWidth ?? 300,
              "ImageDPI": imageDPI ?? 500,
              "Left_ImageQuality": qualityScore ?? 0,
              "Left_NFIQ": nfiq,
              "Left_TemplateBase64": tmplBase64,
              "Left_WSQImageSize": wsqSize,
              "Left_WSQImage": wsqBase64,
              "Left_BMPBase64": bmpBase64Str,
            };
            print("🟢 Saved Left Biometric Data payload");
          } else if (scanType == 'right') {
            rightFingerprintImage = pngBytes;
            rightBiometricData = {
              "Right_ImageQuality": qualityScore ?? 0,
              "Right_NFIQ": nfiq,
              "Right_TemplateBase64": tmplBase64,
              "Right_WSQImageSize": wsqSize,
              "Right_WSQImage": wsqBase64,
              "Right_BMPBase64": bmpBase64Str,
            };
            print("🟢 Saved Right Biometric Data payload");
          }

          if (showToasts) {
            Get.snackbar(
              "✅ Success",
              "Fingerprint ($scanType) scan successful! Quality: ${qualityScore ?? '--'}%",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
          return true;
        }
      }
      return false;

    } on PlatformException catch (e) {
      print("SecuGen Error: ${e.code} - ${e.message}");

      // If we forcefully cancelled, it often throws a generic open/capture failed. 
      // Avoid spamming the user if they pressed "Cancel".
      if (!isScanningFinger.value) return false;

      String msg = switch (e.code) {
        'SDK_NOT_ADDED'     => '${e.message}',
        'DEVICE_NOT_FOUND'  => 'SecuGen HU20 is not connected. Please connect via USB OTG.',
        'DEVICE_OPEN_FAILED'=> 'Device connection lost or scan cancelled.',
        'CAPTURE_FAILED'    => 'Fingerprint capture failed. Please place your finger on the sensor.',
        'SDK_INIT_FAILED'   => 'SDK initialization failed.',
        'LOW_QUALITY'       => e.message ?? 'Fingerprint quality is too low.',
        _                   => 'SecuGen Error (${e.code}): ${e.message}',
      };

      lastScanError = msg;
      if (showToasts) {
        Get.snackbar(
          e.code == 'SDK_NOT_ADDED' ? "SDK Setup Required" : "Scanner Error",
          msg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: e.code == 'SDK_NOT_ADDED' ? Colors.orange : Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    } catch (e) {
      print("Fingerprint error: $e");
      lastScanError = e.toString();
      if (showToasts && isScanningFinger.value) {
        Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return false;
    } finally {
      isScanningFinger.value = false;
    }
  }

  void printClearBiometricDetails(Map<dynamic, dynamic> result, {Uint8List? rawBytes, Uint8List? pngBytes}) {
    print("\n╔══════════════════════════════════════════════════════════════════════════╗");
    print("║               🟢 SECUGEN BIOMETRIC CAPTURED CLEAR DATA                   ║");
    print("╠══════════════════════════════════════════════════════════════════════════╣");
    print("║ [1. SCAN STATUS & QUALITY]                                               ║");
    print("║   • Status             : SUCCESS                                         ║");
    print("║   • Quality Score      : ${result['quality'] ?? '--'}% (Minimum required: 35%)            ║");
    print("║   • Scan Timestamp     : ${DateTime.now().toLocal()}                ║");
    print("╠══════════════════════════════════════════════════════════════════════════╣");
    print("║ [2. IMAGE METRICS & BUFFERS]                                             ║");
    print("║   • Dimensions (W x H) : ${result['width'] ?? 260} px × ${result['height'] ?? 300} px                          ║");
    print("║   • Resolution (DPI)   : ${result['imageDPI'] ?? 500} DPI                                         ║");
    print("║   • Raw Sensor Bytes   : ${rawBytes?.length ?? 0} bytes                                    ║");
    print("║   • Encoded PNG Bytes  : ${pngBytes?.length ?? 0} bytes                                    ║");
    print("╠══════════════════════════════════════════════════════════════════════════╣");
    print("║ [3. ENCRYPTED ISO TEMPLATE DATA]                                         ║");
    print("║   • Template Length    : ${fingerprintTemplate?.length ?? 0} bytes                                     ║");
    String tmplB64 = fingerprintTemplate != null ? base64Encode(fingerprintTemplate!) : 'N/A';
    String shortTmpl = tmplB64.length > 50 ? "${tmplB64.substring(0, 47)}..." : tmplB64;
    print("║   • Template Base64    : $shortTmpl                 ║");
    print("╠══════════════════════════════════════════════════════════════════════════╣");
    print("║ [4. HARDWARE & SENSOR METADATA]                                          ║");
    print("║   • Device Model       : ${result['deviceName'] ?? 'SecuGen HU20'}                                  ║");
    print("║   • Serial Number (SN) : ${result['serialNumber'] ?? 'SG-HU20'}                                         ║");
    print("║   • Firmware Version   : ${result['fwVersion'] ?? 'V1.0'}                                            ║");
    print("║   • Vendor ID / PID    : VID:${result['vendorId'] ?? '4450'} PID:${result['productId'] ?? '--'}                         ║");
    print("║   • Sensor Settings    : Brightness: ${result['brightness'] ?? 100} | Contrast: ${result['contrast'] ?? 100} | Gain: ${result['gain'] ?? 2} ║");
    print("╚══════════════════════════════════════════════════════════════════════════╝\n");
  }

  Future<Map<String, dynamic>> matchFingerprint(
    Uint8List liveTemplate,
    Uint8List enrolledTemplate, {
    Uint8List? liveIsoTemplate,
  }) async {
    final base = {
      'matched': false,
      'score': 0,
      'technicalError': false,
      'enrolledFormat': '',
      'enrolledSize': enrolledTemplate.length,
      'liveIsoSize': liveIsoTemplate?.length ?? 0,
      'method': '',
      'errorCode': null,
    };
    try {
      final dynamic result = await platform.invokeMethod('matchFingerprint', {
        'template1': liveTemplate,
        'isoTemplate1': liveIsoTemplate,
        'template2': enrolledTemplate,
      });
      if (result is Map) {
        return {
          ...base,
          'matched': result['matched'] == true,
          'score': result['score'] as int? ?? (result['matched'] == true ? 100 : 0),
          'technicalError': result['technicalError'] == true,
          'enrolledFormat': result['enrolledFormat']?.toString() ?? '',
          'enrolledSize': result['enrolledSize'] as int? ?? enrolledTemplate.length,
          'liveIsoSize': result['liveIsoSize'] as int? ?? (liveIsoTemplate?.length ?? 0),
          'method': result['method']?.toString() ?? '',
          'errorCode': result['errorCode'],
        };
      }
      return base;
    } catch (e) {
      print("Match error: $e");
      // Native PlatformException (MATCH_EXCEPTION / SDK_INIT_FAILED) is a technical failure,
      // NOT a biometric mismatch — never auto-reject a candidate for it.
      return {...base, 'technicalError': true, 'method': e.toString(), 'errorCode': e.toString()};
    }
  }

  bool isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearBiometricData() {
    fingerprintImage = null;
    fingerprintTemplate = null;
    fingerprintImagePath.value = null;
    qualityScore = null;
    leftFingerprintImage = null;
    rightFingerprintImage = null;
    leftBiometricData.clear();
    rightBiometricData.clear();
  }
}
