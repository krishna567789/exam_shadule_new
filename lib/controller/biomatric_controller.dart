import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class BiometricController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  XFile? regImage;
  XFile? liveImage;
  XFile? rightThumb;
  XFile? leftThumb;

  bool isProcessingLiveImage = false;
  bool isProcessingRightThumb = false;
  bool isProcessingLeftThumb = false;

  // Function to pick the live image (front-facing camera)

  Future<void> pickLiveImage(ImageSource source) async {
    // Check and request camera and location permissions
    PermissionStatus camera = await Permission.camera.status;
    PermissionStatus location = await Permission.location.status;

    // Request permissions if not granted

    if (!camera.isGranted || !location.isGranted) {
      await Permission.camera.request();
      await Permission.location.request();
    }

    // Check if permissions are granted
    camera = await Permission.camera.status;
    location = await Permission.location.status;

    if (camera.isGranted && location.isGranted) {
      try {
        final pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          liveImage = pickedFile;
          isProcessingLiveImage = false;
          notifyListeners(); // Notify listeners for UI updates
        } else {
          print("No live image selected");
        }
      } catch (error) {
        print("Error capturing live image: $error");
      }
    } else {
      print("Please enable camera and location permissions.");
    }
  }

  // Function to pick the left thumb image
  Future<void> pickLeftThumbImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        leftThumb = pickedFile;
        isProcessingLeftThumb = false;
        notifyListeners(); // Notify listeners for UI updates
      } else {
        print("No left thumb image selected");
      }
    } catch (error) {
      print("Error capturing left thumb image: $error");
    }
  }

  // Validate if both the images (live and left thumb) are selected
  bool validateImages() {
    if (liveImage == null) {
      return false; // Live image not selected
    }
    if (leftThumb == null) {
      return false; // Left thumb image not selected
    }
    return true; // Both images selected
  }

  // A method to display a message if images are not validated
  String get validationMessage {
    if (liveImage == null && leftThumb == null) {
      return 'Please capture both images (live image and left thumb).';
    } else if (liveImage == null) {
      return 'Please capture a live image.';
    } else if (leftThumb == null) {
      return 'Please capture the left thumb image.';
    }
    return '';
  }
}








//Its running code of the Biomatric_screen Dont remove this code its a backup code

// import 'dart:developer';
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class BiometricCaptureController extends GetxController {
//   Rx<File?> storedFace = Rx<File?>(null);
//   Rx<File?> liveFace = Rx<File?>(null);
//
//   bool isProcessingRightThumb = false;
//   bool isProcessingLeftThumb = false;
//   XFile? rightThumb;
//   XFile? leftThumb;
//
//   RxBool isMatching = false.obs;
//   final ImagePicker _picker = ImagePicker();
//
//   void setStoredImage(String path) {
//     storedFace.value = File(path);
//   }
//
//   Future<void> pickRightThumbImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       leftThumb = pickedFile;
//       isProcessingLeftThumb = true;
//       isProcessingLeftThumb = false;
//     }
//   }
//
//   Future<void> pickLiveImage() async {
//     // var camera = Permission.camera;
//     // Permission location = Permission.camera;
//     // if(camera.status.isGranted || location.status.isGranted) {
//     try {
//       final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//       if (pickedFile != null) {
//         liveFace.value = File(pickedFile.path);
//         isMatching.value = true;
//         await compareFaces();
//         // }
//       }
//     }
//     catch(error){
//       print("Error : $error");
//     }
//   }
//
//   Future<void> compareFaces() async {
//     if (storedFace.value == null || liveFace.value == null) {
//       print("❌ Missing images for comparison!");
//       return;
//     }
//
//     final storedInputImage = InputImage.fromFile(storedFace.value!);
//     final liveInputImage = InputImage.fromFile(liveFace.value!);
//
//     final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
//       performanceMode: FaceDetectorMode.fast,
//       enableClassification: true,
//       enableLandmarks: true,
//     ));
//
//     final storedFaces = await faceDetector.processImage(storedInputImage);
//     final liveFaces = await faceDetector.processImage(liveInputImage);
//
//     faceDetector.close();
//
//     if (storedFaces.isNotEmpty && liveFaces.isNotEmpty) {
//       double similarityScore = compareFaceFeatures(storedFaces.first, liveFaces.first);
//
//       if (similarityScore >= 0.9 && similarityScore <= 1.1) {
//         Get.snackbar("Success", "✅ Face Matched Successfully!",backgroundColor: Colors.green);
//         print("✅ Face Matched Successfully!");
//       } else {
//         Get.snackbar("Error ❌", "❌ Face Mismatch: Ratio not within range!",backgroundColor: Colors.red);
//         print("❌ Face Mismatch: Ratio not within range!");
//       }
//     } else {
//       Get.snackbar("Error ❌", "❌ Face Not Detected!",backgroundColor: Colors.green);
//       print("❌ Face Not Detected!");
//     }
//     isMatching.value = false;
//   }
//
//   double compareFaceFeatures(Face face1, Face face2) {
//     double ratioEar = computeRatio(face1, face2, FaceLandmarkType.rightEar, FaceLandmarkType.leftEar);
//     double ratioEye = computeRatio(face1, face2, FaceLandmarkType.rightEye, FaceLandmarkType.leftEye);
//     double ratioCheek = computeRatio(face1, face2, FaceLandmarkType.rightCheek, FaceLandmarkType.leftCheek);
//     double ratioMouth = computeRatio(face1, face2, FaceLandmarkType.rightMouth, FaceLandmarkType.leftMouth);
//     double ratioNoseToMouth = computeRatio(face1, face2, FaceLandmarkType.noseBase, FaceLandmarkType.bottomMouth);
//
//     double ratio = (ratioEye + ratioEar + ratioCheek + ratioMouth + ratioNoseToMouth) / 5;
//     log(ratio.toString(), name: "Face Similarity Ratio");
//     return ratio;
//   }
//
//   double computeRatio(Face face1, Face face2, FaceLandmarkType type1, FaceLandmarkType type2) {
//     double dist1 = euclideanDistance(face1.landmarks[type1]?.position, face1.landmarks[type2]?.position);
//     double dist2 = euclideanDistance(face2.landmarks[type1]?.position, face2.landmarks[type2]?.position);
//     return dist1 / dist2;
//   }
//
//   double euclideanDistance(dynamic p1, dynamic p2) {
//     if (p1 == null || p2 == null) return double.infinity;
//
//     Offset offset1 = (p1 is Offset) ? p1 : Offset(p1.x.toDouble(), p1.y.toDouble());
//     Offset offset2 = (p2 is Offset) ? p2 : Offset(p2.x.toDouble(), p2.y.toDouble());
//
//     return math.sqrt((offset1.dx - offset2.dx) * (offset1.dx - offset2.dx) +
//         (offset1.dy - offset2.dy) * (offset1.dy - offset2.dy));
//   }
// }


///second trayel code
/////
// // import 'dart:developer';
// // import 'dart:io';
// // import 'dart:math' as math;
// // import 'package:exam_shadule_new/models/download_model/download_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:google_ml_kit/google_ml_kit.dart';
// //
// // class BiometricCaptureScreen extends StatefulWidget {
// //   final ShiftModel storedImagePath;
// //   const BiometricCaptureScreen({super.key, required this.storedImagePath});
// //
// //   @override
// //   BiometricCaptureScreenState createState() => BiometricCaptureScreenState();
// // }
// //
// // class BiometricCaptureScreenState extends State<BiometricCaptureScreen> {
// //   File? storedFace;
// //   File? liveFace;
// //   final ImagePicker _picker = ImagePicker();
// //   bool isMatching = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     storedFace = File(widget.storedImagePath.photo);// Local file path
// //   }
// //
// //   Future<void> pickLiveImage() async {
// //     final pickedFile = await _picker.pickImage(source: ImageSource.camera);
// //     if (pickedFile != null) {
// //       setState(() {
// //         liveFace = File(pickedFile.path);
// //         isMatching = true;
// //       });
// //
// //       await compareFaces();
// //     }
// //   }
// //
// //   Future<void> compareFaces() async {
// //     if (storedFace == null || liveFace == null) {
// //       print("❌ Missing images for comparison!");
// //       return;
// //     }
// //
// //     final storedInputImage = InputImage.fromFile(storedFace!);
// //     final liveInputImage = InputImage.fromFile(liveFace!);
// //
// //     final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
// //       performanceMode: FaceDetectorMode.fast,
// //       enableClassification: true,
// //       enableLandmarks: true,
// //     ));
// //
// //     final storedFaces = await faceDetector.processImage(storedInputImage);
// //     final liveFaces = await faceDetector.processImage(liveInputImage);
// //
// //     faceDetector.close();
// //
// //     if (storedFaces.isNotEmpty && liveFaces.isNotEmpty) {
// //
// //       double similarityScore = compareFaceFeatures(storedFaces.first, liveFaces.first);
// //
// //       if (similarityScore >= 0.9 && similarityScore <= 1.1) {
// //         print("✅ Face Matched Successfully!");
// //         setState(() => isMatching = false);
// //       } else {
// //         print("❌ Face Mismatch: Ratio not within range!");
// //         setState(() => isMatching = false);
// //       }
// //     } else {
// //       print("❌ Face Not Detected!");
// //       setState(() => isMatching = false);
// //     }
// //   }
// //
// //   double compareFaceFeatures(Face face1, Face face2) {
// //     double distEar1 = euclideanDistance(face1.landmarks[FaceLandmarkType.rightEar]?.position,
// //         face1.landmarks[FaceLandmarkType.leftEar]?.position);
// //
// //     double distEar2 = euclideanDistance(face2.landmarks[FaceLandmarkType.rightEar]?.position,
// //         face2.landmarks[FaceLandmarkType.leftEar]?.position);
// //     double ratioEar = distEar1 / distEar2;
// //
// //     double distEye1 = euclideanDistance(face1.landmarks[FaceLandmarkType.rightEye]?.position,
// //         face1.landmarks[FaceLandmarkType.leftEye]?.position);
// //     double distEye2 = euclideanDistance(face2.landmarks[FaceLandmarkType.rightEye]?.position,
// //         face2.landmarks[FaceLandmarkType.leftEye]?.position);
// //     double ratioEye = distEye1 / distEye2;
// //
// //     double distCheek1 = euclideanDistance(face1.landmarks[FaceLandmarkType.rightCheek]?.position,
// //         face1.landmarks[FaceLandmarkType.leftCheek]?.position);
// //     double distCheek2 = euclideanDistance(face2.landmarks[FaceLandmarkType.rightCheek]?.position,
// //         face2.landmarks[FaceLandmarkType.leftCheek]?.position);
// //     double ratioCheek = distCheek1 / distCheek2;
// //
// //     double distMouth1 = euclideanDistance(face1.landmarks[FaceLandmarkType.rightMouth]?.position ,
// //         face1.landmarks[FaceLandmarkType.leftMouth]?.position);
// //     double distMouth2 = euclideanDistance(face2.landmarks[FaceLandmarkType.rightMouth]?.position,
// //         face2.landmarks[FaceLandmarkType.leftMouth]?.position);
// //     double ratioMouth = distMouth1 / distMouth2;
// //
// //     double distNoseToMouth1 = euclideanDistance(face1.landmarks[FaceLandmarkType.noseBase]?.position,
// //         face1.landmarks[FaceLandmarkType.bottomMouth]?.position);
// //     double distNoseToMouth2 = euclideanDistance(face2.landmarks[FaceLandmarkType.noseBase]?.position,
// //         face2.landmarks[FaceLandmarkType.bottomMouth]?.position );
// //     double ratioNoseToMouth = distNoseToMouth1 / distNoseToMouth2;
// //
// //     double ratio = (ratioEye + ratioEar + ratioCheek + ratioMouth + ratioNoseToMouth) / 5;
// //
// //     log(ratio.toString(), name: "Face Similarity Ratio");
// //     return ratio;
// //   }
// //
// //   double euclideanDistance(dynamic p1, dynamic p2) {
// //     if (p1 == null || p2 == null) return double.infinity;
// //
// //     Offset offset1 = (p1 is Offset) ? p1 : Offset(p1.x.toDouble(), p1.y.toDouble());
// //     Offset offset2 = (p2 is Offset) ? p2 : Offset(p2.x.toDouble(), p2.y.toDouble());
// //
// //     return math.sqrt((offset1.dx - offset2.dx) * (offset1.dx - offset2.dx) +
// //         (offset1.dy - offset2.dy) * (offset1.dy - offset2.dy));
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Biometric Face Matching")),
// //       body: Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             if (storedFace != null) Image.file(storedFace!, height: 100),
// //             ElevatedButton(
// //               onPressed: isMatching ? null : pickLiveImage,
// //               child: isMatching ? CircularProgressIndicator() : const Text("Capture Face"),
// //             ),
// //             if (liveFace != null) Image.file(liveFace!, height: 100),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

