import 'dart:io';
import 'package:exam_shadule_new/models/device_model/user_profile_model.dart';
import 'package:exam_shadule_new/screens/login_screen.dart';
import 'package:exam_shadule_new/screens/session_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as  http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_local_db/user_profile_helper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

extension StringAadharCheck on String {
  bool get isValidAadharNumber {
    // Match Aadhaar with or without space: "1234 5678 9012" or "123456789012"
    final spaced = RegExp(r'^[2-9]{1}[0-9]{3}\s[0-9]{4}\s[0-9]{4}$');
    final unspaced = RegExp(r'^[2-9]{1}[0-9]{11}$');

    return spaced.hasMatch(this.trim()) || unspaced.hasMatch(this.trim());
  }
}


class UserProfileController extends GetxController {
  var profileImage = Rxn<File>();
  var frontImage = Rxn<File>();
  var backImage = Rxn<File>();

  final nameController = TextEditingController();
  final fatherController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final centerNameController = TextEditingController();
  final centerCodeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> requestPermissions() async {
    PermissionStatus cameraPermission = await Permission.camera.request();
    PermissionStatus locationPermission = await Permission.location.request();

    if (!cameraPermission.isGranted || !locationPermission.isGranted) {
      Get.snackbar('Permission Denied', 'Please grant necessary permissions.');
      return;
    }
  }




  Future<void> pickImage(bool isProfileImage, {bool isFront = false}) async {
    await requestPermissions();
    XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      if (isProfileImage) {
        profileImage.value = file;
      } else {
        // Use Google ML Kit OCR
        final inputImage = InputImage.fromFile(file);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final extractedText = recognizedText.text;
        final lines = extractedText.split('\n');

        // ✅ Check for valid Aadhaar number format in any line
        final validAadharLines = lines.where((line) => line.trim().isValidAadharNumber).toList();

        // ✅ Look for Aadhaar-specific keywords
        final textLower = extractedText.toLowerCase();
        final hasGovtKeyword = textLower.contains('aadhaar') ||
            textLower.contains('uidai') ||
            textLower.contains('govt') ||
            textLower.contains('government of india');

        // Always accept the captured image to prevent blocking during user uploads
        if (isFront) {
          frontImage.value = file;
        } else {
          backImage.value = file;
        }
      }

      update();
    }
  }


  Future<XFile> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      imageFile.absolute.path.replaceAll(RegExp(r"\.jpg$"), "_compressed.jpg"),
      quality: 70,
    );

    return result!;
  }

  Future<void> submitForm() async {
    if (profileImage.value == null) {
      Get.snackbar('Error', 'Please upload a profile photo', backgroundColor: Colors.red);
      return;
    }
    if (frontImage.value == null) {
      Get.snackbar('Error', 'Please upload Aadhaar front photo', backgroundColor: Colors.red);
      return;
    }
    if (backImage.value == null) {
      Get.snackbar('Error', 'Please upload Aadhaar back photo', backgroundColor: Colors.red);
      return;
    }

    XFile compressedProfileImage = await compressImage(profileImage.value!);
    XFile compressedFrontImage = await compressImage(frontImage.value!);
    XFile compressedBackImage = await compressImage(backImage.value!);

    var request = http.MultipartRequest('POST', Uri.parse('https://bio.ubrosoft.com/api/users'));
    //Here is store data in local db
    UserProfileModel userProfile = UserProfileModel(
      name: nameController.text,
      fatherName: fatherController.text,
      mobileNumber: mobileController.text,
      email: emailController.text,
      address: addressController.text,
      centerName: centerNameController.text,
      centerCode: centerCodeController.text,
      aadharFront: frontImage.value?.path,
      aadharBack: backImage.value?.path,
      photo: profileImage.value?.path,
    );
    //Here is store data in local db
    request.fields.addAll({
      'name': nameController.text,
      'father_name': fatherController.text,
      'mobile_number': mobileController.text,
      'email': emailController.text,
      'address': addressController.text,
      'center_name': centerNameController.text,
      'center_code': centerCodeController.text,
    });
    request.files.add(await http.MultipartFile.fromPath('aadhar_front', compressedFrontImage.path));
    request.files.add(await http.MultipartFile.fromPath('aadhar_back', compressedBackImage.path));
    request.files.add(await http.MultipartFile.fromPath('photo', compressedProfileImage.path));

    try {
      Get.dialog(
        Center(
          child: CircularProgressIndicator(color: Color(0xff6388bd),),
        ),
        barrierDismissible: false, // Prevent closing dialog by tapping outside
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print("API URL: ${response.request?.url} | Response: ${response.body}");

      if (response.statusCode == 200) {
        Get.back();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('center_name', centerNameController.text);
        await prefs.setString('center_code', centerCodeController.text);
        print(prefs);
        await UserProfileHelper().storeUserProfile(userProfile);
        Get.snackbar('Success', 'Data submitted successfully!', backgroundColor: Colors.green);
        Get.offAll(()=> const SessionSetupScreen());
      } else {
        if(response.statusCode == 302){
          Get.back();

          Get.snackbar('Error', 'Email And Mobile number is already registered!', backgroundColor: Colors.red);
        }
        print(response.statusCode);
        print(response.request?.url.data);
      }
    } catch (e) {
      Get.back();

      print('Error: $e');
      Get.snackbar('Error', 'Something went wrong. Please try again later.', backgroundColor: Colors.red);
    }
  }
}
