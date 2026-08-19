import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhysicalAttendanceController extends GetxController {
  var selectedFiles = <File>[].obs;
  var isLoading = false.obs;
  var remarksController = TextEditingController();

  void pickFiles() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isNotEmpty) {
        List<File> files = result.map((file) => File(file.path!)).toList();
        selectedFiles.addAll(files);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick files: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void scanDocument() async {
    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        List<File> files = pictures.map((path) => File(path)).toList();
        selectedFiles.addAll(files);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to scan document: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void removeFile(int index) {
    selectedFiles.removeAt(index);
  }

  Future<void> submitAttendance() async {
    if (selectedFiles.isEmpty) {
      Get.snackbar('Validation', 'Please select at least one file to upload.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (remarksController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please enter remarks.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? operatorId = prefs.getString('operator_email') ??
          prefs.getString('operator_id_db') ??
          '';

      var headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      var request = http.MultipartRequest(
          'POST', Uri.parse('https://bio.ubroapi.space/api/physical-attendance'));
      request.headers.addAll(headers);

      request.fields.addAll({
        'operatorId': operatorId,
        'remarks': remarksController.text.trim(),
      });

      // API snippet has 'file', but it might overwrite if multiple files are added with the same key.
      // Wait, http.MultipartRequest supports multiple files with the same key.
      for (var file in selectedFiles) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Physical attendance uploaded successfully.',
            backgroundColor: Colors.green, colorText: Colors.white);
        selectedFiles.clear();
        remarksController.clear();
      } else {
        Get.snackbar('Error', 'Upload failed: ${response.reasonPhrase}',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'An exception occurred: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
