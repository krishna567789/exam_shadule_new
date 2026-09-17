import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../services/api_service.dart';
import 'base_controller.dart';

class SelectedFile {
  final File file;
  final String name;
  final int sizeInBytes;
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxBool isUploaded = false.obs;

  bool get isPdf => file.path.toLowerCase().endsWith('.pdf');

  SelectedFile({
    required this.file,
    required this.name,
    required this.sizeInBytes,
  });

  String get formattedSize {
    final mb = sizeInBytes / (1024 * 1024);
    if (mb < 0.01) {
      return "${(sizeInBytes / 1024).toStringAsFixed(1)} KB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }
}

class PhysicalAttendanceController extends BaseController {
  final selectedFiles = <SelectedFile>[].obs;
  final remarksController = TextEditingController();
  final isProcessing = false.obs;

  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory("${appDir.path}/attendance_pdfs");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  void removePdf(int index) {
    if (index >= 0 &&
        index < selectedFiles.length &&
        !selectedFiles[index].isUploading.value) {
      try {
        final f = selectedFiles[index].file;
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
      selectedFiles.removeAt(index);
    }
  }

  Future<void> pickFilesAndCreatePdf() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isNotEmpty) {
        bool hasPdfInSelection =
            result.any((f) => f.name.toLowerCase().endsWith('.pdf'));
        bool hasImageInSelection = result.any((f) => ['jpg', 'jpeg', 'png']
            .contains(f.name.split('.').last.toLowerCase()));

        bool hasPdfInList = selectedFiles.any((f) => f.isPdf);
        bool hasImageInList = selectedFiles.any((f) => !f.isPdf);

        if ((hasPdfInSelection && hasImageInList) ||
            (hasImageInSelection && hasPdfInList) ||
            (hasPdfInSelection && hasImageInSelection)) {
          showError(
              'You cannot mix PDFs and Images. Please select only one type, or clear existing files first.');
          return;
        }

        if (hasPdfInSelection &&
            (hasPdfInList ||
                result
                        .where((f) => f.name.toLowerCase().endsWith('.pdf'))
                        .length >
                    1)) {
          showError('You can only select a single PDF document.');
          return;
        }

        isProcessing.value = true;
        showLoading();

        final output = await _getStorageDirectory();

        for (var file in result) {
          if (file.path == null) continue;
          final sourceFile = File(file.path!);
          final originalName = file.name;
          final targetFile = File(
              "${output.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName");
          await sourceFile.copy(targetFile.path);
          final length = await targetFile.length();
          selectedFiles.add(SelectedFile(
            file: targetFile,
            name: originalName,
            sizeInBytes: length,
          ));
        }

        hideLoading();
        isProcessing.value = false;
      }
    } catch (e) {
      hideLoading();
      isProcessing.value = false;
      showError('Failed to pick files: $e');
    }
  }

  Future<void> scanAndCreatePdf() async {
    try {
      bool hasPdfInList = selectedFiles.any((f) => f.isPdf);
      if (hasPdfInList) {
        showError(
            'You cannot scan images while a PDF is already selected. Please clear the PDF first.');
        return;
      }

      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        isProcessing.value = true;
        showLoading();

        final output = await _getStorageDirectory();
        for (var path in pictures) {
          final sourceFile = File(path);
          final originalName = path.split('/').last;
          final targetFile = File(
              "${output.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName");
          await sourceFile.copy(targetFile.path);
          final length = await targetFile.length();
          selectedFiles.add(SelectedFile(
            file: targetFile,
            name: originalName,
            sizeInBytes: length,
          ));
        }

        hideLoading();
        isProcessing.value = false;
      }
    } catch (e) {
      hideLoading();
      isProcessing.value = false;
      showError('Failed to process document: $e');
    }
  }

  Future<File> _createFinalPdfFromImages(List<SelectedFile> images) async {
    final pdf = pw.Document();

    for (var imgItem in images) {
      File imageFile = imgItem.file;
      Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 60,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedBytes != null) {
        final image = pw.MemoryImage(compressedBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    final output = await _getStorageDirectory();
    final fileName = "attendance_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${output.path}/$fileName");
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  Future<void> uploadAllPdfs() async {
    if (selectedFiles.isEmpty) {
      showError('Please scan or pick at least one document.');
      return;
    }

    if (remarksController.text.trim().isEmpty) {
      showError('Please enter remarks.');
      return;
    }

    final pendingFiles =
        selectedFiles.where((p) => !p.isUploaded.value).toList();
    if (pendingFiles.isEmpty) {
      showSuccess('Info', 'All files are already uploaded.');
      return;
    }

    try {
      isProcessing.value = true;
      showLoading();

      SelectedFile finalFileToUpload;

      bool hasPdfInList = selectedFiles.any((f) => f.isPdf);

      if (hasPdfInList) {
        // Upload the single PDF
        finalFileToUpload = selectedFiles.firstWhere((f) => f.isPdf);
      } else {
        // Create a single PDF from all images
        File mergedFile =
            await _createFinalPdfFromImages(selectedFiles.toList());
        final length = await mergedFile.length();
        finalFileToUpload = SelectedFile(
          file: mergedFile,
          name: mergedFile.path.split('/').last,
          sizeInBytes: length,
        );
      }

      await _uploadSinglePdf(finalFileToUpload);

      if (finalFileToUpload.isUploaded.value) {
        for (var p in pendingFiles) {
          p.isUploaded.value = true;
        }
        showSuccess('Success', 'Final report uploaded successfully.');
      }

      hideLoading();
      isProcessing.value = false;
    } catch (e) {
      hideLoading();
      isProcessing.value = false;
      showError('Upload error: $e');
    }
  }

  Future<void> _uploadSinglePdf(SelectedFile scannedPdf) async {
    scannedPdf.isUploading.value = true;
    scannedPdf.uploadProgress.value = 0.0;
    try {
      if (!await scannedPdf.file.exists()) {
        throw 'File "${scannedPdf.name}" not found on device. Please remove and re-create it.';
      }

      var request = await ApiService.to
          .multipartRequest(ApiService.urlPhysicalAttendance);
      request.fields['remarks'] = remarksController.text.trim();

      final totalByteLength = await scannedPdf.file.length();
      final fileStream = scannedPdf.file.openRead();
      var byteCount = 0;
      final progressStream = fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            byteCount += data.length;
            if (totalByteLength > 0) {
              scannedPdf.uploadProgress.value =
                  (byteCount / totalByteLength).clamp(0.0, 1.0);
            }
            sink.add(data);
          },
        ),
      );

      final multipartFile = http.MultipartFile(
        'files',
        progressStream,
        totalByteLength,
        filename: scannedPdf.name,
        contentType: MediaType('application', 'pdf'),
      );

      request.files.add(multipartFile);

      print("--- PHYSICAL ATTENDANCE REQUEST ---");
      print("URL: ${request.url}");
      print("Headers: ${request.headers}");
      print("Fields: ${request.fields}");
      print(
          "Files: ${request.files.map((f) => "${f.field}: ${f.filename} (${f.length} bytes)").toList()}");
      print("-----------------------------------");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("--- PHYSICAL ATTENDANCE RESPONSE ---");
      Get.back();
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("------------------------------------");

      if (response.statusCode == 200 || response.statusCode == 201) {
        scannedPdf.isUploaded.value = true;
        scannedPdf.uploadProgress.value = 1.0;
      } else {
        var errorData = json.decode(response.body);
        throw errorData['message'] ?? 'Upload failed: ${response.reasonPhrase}';
      }
    } catch (e) {
      print("--- PHYSICAL ATTENDANCE ERROR ---");
      print("Error: $e");
      print("---------------------------------");
      scannedPdf.uploadProgress.value = 0.0;
      rethrow;
    } finally {
      scannedPdf.isUploading.value = false;
    }
  }
}
