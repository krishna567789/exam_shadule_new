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

class ScannedPdf {
  final File file;
  final String name;
  final int sizeInBytes;
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxBool isUploaded = false.obs;

  ScannedPdf({
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
  final scannedPdfs = <ScannedPdf>[].obs;
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
    if (index >= 0 && index < scannedPdfs.length && !scannedPdfs[index].isUploading.value) {
      try {
        final f = scannedPdfs[index].file;
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
      scannedPdfs.removeAt(index);
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
        isProcessing.value = true;
        showLoading();

        List<String> imagePaths = [];
        List<File> existingPdfs = [];

        for (var file in result) {
          if (file.path == null) continue;
          String fileName = file.name;
          String ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
          
          if (['jpg', 'jpeg', 'png'].contains(ext)) {
            imagePaths.add(file.path!);
          } else if (ext == 'pdf') {
            existingPdfs.add(File(file.path!));
          }
        }

        // Handle Images -> Convert to PDF
        if (imagePaths.isNotEmpty) {
          await _createPdfFromImages(imagePaths);
        }

        // Handle Existing PDFs -> Copy to persistent storage
        if (existingPdfs.isNotEmpty) {
          final output = await _getStorageDirectory();
          for (var pdfFile in existingPdfs) {
            if (await pdfFile.exists()) {
              final originalName = pdfFile.path.split('/').last;
              final targetFile = File("${output.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName");
              await pdfFile.copy(targetFile.path);
              final length = await targetFile.length();
              scannedPdfs.add(ScannedPdf(
                file: targetFile,
                name: originalName,
                sizeInBytes: length,
              ));
            }
          }
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
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        isProcessing.value = true;
        showLoading();
        await _createPdfFromImages(pictures);
        hideLoading();
        isProcessing.value = false;
        showSuccess('Success', 'PDF created with ${pictures.length} pages.');
      }
    } catch (e) {
      hideLoading();
      isProcessing.value = false;
      showError('Failed to process document: $e');
    }
  }

  Future<void> _createPdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (var path in imagePaths) {
      File imageFile = File(path);
      // Compress/Resize Image
      Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 60, // Lower quality for smaller PDF size
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
    scannedPdfs.add(ScannedPdf(
      file: file,
      name: fileName,
      sizeInBytes: pdfBytes.length,
    ));
  }

  Future<void> uploadAllPdfs() async {
    if (scannedPdfs.isEmpty) {
      showError('Please scan or pick at least one PDF.');
      return;
    }

    if (remarksController.text.trim().isEmpty) {
      showError('Please enter remarks.');
      return;
    }

    final pendingPdfs = scannedPdfs.where((p) => !p.isUploaded.value).toList();
    if (pendingPdfs.isEmpty) {
      showSuccess('Info', 'All files are already uploaded.');
      return;
    }

    try {
      // Sequential upload as requested
      for (var scannedPdf in pendingPdfs) {
        await _uploadSinglePdf(scannedPdf);
      }
      
      if (scannedPdfs.every((p) => p.isUploaded.value)) {
        showSuccess('Success', 'All reports uploaded successfully.');
      }
    } catch (e) {
      showError('Upload error: $e');
    }
  }

  Future<void> _uploadSinglePdf(ScannedPdf scannedPdf) async {
    scannedPdf.isUploading.value = true;
    scannedPdf.uploadProgress.value = 0.0;
    try {
      if (!await scannedPdf.file.exists()) {
        throw 'File "${scannedPdf.name}" not found on device. Please remove and re-create it.';
      }

      var request = await ApiService.to.multipartRequest(ApiService.urlPhysicalAttendance);
      request.fields['remarks'] = remarksController.text.trim();
      
      final totalByteLength = await scannedPdf.file.length();
      final fileStream = scannedPdf.file.openRead();
      var byteCount = 0;
      final progressStream = fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            byteCount += data.length;
            if (totalByteLength > 0) {
              scannedPdf.uploadProgress.value = (byteCount / totalByteLength).clamp(0.0, 1.0);
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
      print("Files: ${request.files.map((f) => "${f.field}: ${f.filename} (${f.length} bytes)").toList()}");
      print("-----------------------------------");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("--- PHYSICAL ATTENDANCE RESPONSE ---");
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
