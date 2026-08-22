import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'base_controller.dart';

class PhysicalAttendanceController extends BaseController {
  final selectedFiles = <File>[].obs;
  final remarksController = TextEditingController();

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
      showError('Failed to pick files: $e');
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
      showError('Failed to scan document: $e');
    }
  }

  void removeFile(int index) => selectedFiles.removeAt(index);

  Future<void> submitAttendance() async {
    if (selectedFiles.isEmpty) {
      showError('Please select at least one file to upload.');
      return;
    }

    if (remarksController.text.trim().isEmpty) {
      showError('Please enter remarks.');
      return;
    }

    try {
      showLoading();

      String operatorId = StorageService.to.getLoginOperatorId() ?? "";

      var request = await ApiService.to
          .multipartRequest(ApiService.urlPhysicalAttendance);
      // request.fields['operatorId'] = operatorId;
      request.fields['remarks'] = remarksController.text.trim();

      for (var file in selectedFiles) {
        String fileName = file.path.split('/').last;
        print('filename: ${fileName}');
        print('file.path: ${file.path}');
        request.files.add(await http.MultipartFile.fromPath('files', file.path,
            filename: fileName));
      }

      print("--- PHYSICAL ATTENDANCE REQUEST ---");
      print("URL: ${request.url}");
      print("Fields: ${request.fields}");
      print("Files: ${request.files.map((f) => f.filename).toList()}");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      hideLoading();
      print("--- PHYSICAL ATTENDANCE RESPONSE ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccess('Success', 'Physical attendance uploaded successfully.');
        selectedFiles.clear();
        remarksController.clear();
        Get.back();
      } else {
        var errorData = json.decode(response.body);
        showError(
            errorData['message'] ?? 'Upload failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      hideLoading();
      showError('An exception occurred: $e');
    }
  }
}
