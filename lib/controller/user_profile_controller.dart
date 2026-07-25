import 'dart:convert';
import 'dart:io';
import 'package:exam_shadule_new/screens/session_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class UserProfileController extends GetxController {
  var profileImage = Rxn<File>();
  var frontImage = Rxn<File>();
  var backImage = Rxn<File>();

  final nameController = TextEditingController();
  final fatherController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final centerNameController = TextEditingController();
  final centerCodeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> fetchOperatorDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? operatorId = prefs.getString('operator_id_db');

      if (operatorId == null || operatorId.isEmpty) return;

      print("--- FETCHING OPERATOR DETAILS ---");
      final response = await http.get(
        Uri.parse('https://bio.ubroapi.space/api/operator-users/$operatorId/details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Details Response: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          var profile = responseData['data']['profile'];
          if (profile != null) {
            nameController.text = profile['name'] ?? "";
            fatherController.text = profile['fatherName'] ?? "";
            mobileController.text = profile['mobileNumber'] ?? "";
            emailController.text = profile['email'] ?? "";
            cityController.text = profile['city'] ?? "";
            stateController.text = profile['state'] ?? "";
            addressController.text = profile['address'] ?? "";
            
            // Save updated info to SharedPreferences
            await prefs.setString('operator_name', nameController.text);
            await prefs.setString('father_name', fatherController.text);
            await prefs.setString('operator_phone', mobileController.text);
            await prefs.setString('operator_city_state', "${cityController.text}, ${stateController.text}");
          }
        }
      }
    } catch (e) {
      print("Error fetching details: $e");
    }
  }

  Future<void> requestPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      await Permission.camera.request();
    } else {
      if (Platform.isAndroid) {
        await [Permission.photos, Permission.storage].request();
      }
    }
    await Permission.location.request();
  }

  Future<void> pickImage(bool isProfileImage, ImageSource source, {bool isFront = false}) async {
    await requestPermissions(source);
    XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (isProfileImage) {
        profileImage.value = file;
      } else {
        if (isFront) {
          frontImage.value = file;
        } else {
          backImage.value = file;
        }
      }
      update();
    }
  }

  Future<File?> compressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

      var result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path, 
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print("Compression Error: $e");
      return imageFile;
    }
  }

  Future<void> submitForm() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xff6388bd))),
        barrierDismissible: false,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('https://bio.ubroapi.space/api/operator-users'));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields.addAll({
        'name': nameController.text.trim(),
        'fatherName': fatherController.text.trim(),
        'mobileNumber': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'state': stateController.text.trim(),
        'city': cityController.text.trim(),
        'address': addressController.text.trim(),
      });

      // Helper to add files with explicit content type
      Future<void> addFileToRequest(String fieldName, File file) async {
        File? compressed = await compressImage(file);
        request.files.add(await http.MultipartFile.fromPath(
          fieldName,
          (compressed ?? file).path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      if (frontImage.value != null) {
        await addFileToRequest('aadharFront', frontImage.value!);
      }
      if (backImage.value != null) {
        await addFileToRequest('aadharBack', backImage.value!);
      }
      if (profileImage.value != null) {
        await addFileToRequest('photo', profileImage.value!);
      }

      print("--- SUBMIT PROFILE REQUEST ---");
      print("URL: ${request.url}");
      print("Fields: ${request.fields}");
      print("Files: ${request.files.map((f) => "${f.field}: ${f.filename} (${f.contentType})").toList()}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (Get.isDialogOpen ?? false) Get.back();

      print("--- SUBMIT PROFILE RESPONSE ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("-------------------------------");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('is_profile_completed', true);
        await prefs.setBool('is_logged_in', true); // SET LOGGED IN STATUS AFTER PROFILE CREATION
        await prefs.setString('operator_name', nameController.text.trim());
        await prefs.setString('father_name', fatherController.text.trim());
        await prefs.setString('operator_phone', mobileController.text.trim());
        await prefs.setString('operator_city_state', "${cityController.text.trim()}, ${stateController.text.trim()}");

        Get.snackbar('Success', 'Profile created successfully!', backgroundColor: Colors.greenAccent);
        Get.offAll(() => const SessionSetupScreen());
      } else {
        var errorData = json.decode(response.body);
        Get.snackbar('Error', errorData['message'] ?? 'Failed to create profile', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e, stackTrace) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('UserProfile Submit Error: $e');
      print('StackTrace: $stackTrace');
      Get.snackbar('Error', 'Something went wrong: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
