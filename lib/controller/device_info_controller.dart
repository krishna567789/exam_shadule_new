import 'dart:convert';
import 'dart:typed_data';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:image/image.dart' as img;

class DeviceInfoController extends GetxController {
  var isRdServiceInstalled = false.obs;
  static const platform = MethodChannel('com.example.exam_shadule_new/rd_service');

  // Fingerprint data storage
  Uint8List? fingerprintImage;    // Raw image bytes
  Uint8List? fingerprintTemplate; // Template for matching
  var fingerprintImagePath = Rx<String?>(null);

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

  // ✅ SecuGen FDx SDK se fingerprint capture
  Future<bool> scanFingerPrint() async {
    if (isScanningFinger.value) return false;
    
    try {
      isScanningFinger.value = true;
      
      // USB devices pehle check karo
      final usbResult = await platform.invokeMethod('checkUsbDevices');
      print("USB Devices: $usbResult");

      // SDK se fingerprint capture karo
      final result = await platform.invokeMethod('captureFingerprint');

      if (result != null && result is Map) {
        bool success = result['success'] ?? false;
        if (success) {
          fingerprintImage    = result['image']    != null ? Uint8List.fromList(List<int>.from(result['image']))    : null;
          fingerprintTemplate = result['template'] != null ? Uint8List.fromList(List<int>.from(result['template'])) : null;

          if (fingerprintImage != null) {
            try {
              int width = result['width'] ?? 260;
              int height = result['height'] ?? 300;
              
              img.Image decodedImage = img.Image.fromBytes(
                width: width,
                height: height,
                bytes: fingerprintImage!.buffer,
                numChannels: 1,
              );
              
              fingerprintImage = Uint8List.fromList(img.encodePng(decodedImage));
            } catch (e) {
              print("Image encoding error: $e");
            }
          }

          Get.snackbar(
            "✅ Success",
            "Fingerprint scan successful!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
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
        'DEVICE_NOT_FOUND'  => 'SecuGen HU20 connected nahi hai. USB OTG se lagao.',
        'DEVICE_OPEN_FAILED'=> 'Device connection lost or scan cancelled.',
        'CAPTURE_FAILED'    => 'Fingerprint capture failed. Finger sensor pe rakhein.',
        'SDK_INIT_FAILED'   => 'SDK initialize nahi hua.',
        _                   => 'SecuGen Error (${e.code}): ${e.message}',
      };

      Get.snackbar(
        e.code == 'SDK_NOT_ADDED' ? "SDK Setup Required" : "Scanner Error",
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: e.code == 'SDK_NOT_ADDED' ? Colors.orange : Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      print("Fingerprint error: $e");
      if (isScanningFinger.value) {
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

  // Template comparison (SDK add hone ke baad use hoga)
  Future<bool> matchFingerprint(Uint8List template1, Uint8List template2) async {
    try {
      final result = await platform.invokeMethod('matchFingerprint', {
        'template1': template1,
        'template2': template2,
      });
      return result['matched'] ?? false;
    } catch (e) {
      print("Match error: $e");
      return false;
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
}
