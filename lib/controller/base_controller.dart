import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  void showLoading() {
    _isLoading.value = true;
    // We can still show a dialog if we want to block the UI
    if (!Get.isDialogOpen!) {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Color(0xff6388bd)),
        ),
        barrierDismissible: false,
      );
    }
  }

  void hideLoading() {
    _isLoading.value = false;
    if (Get.isDialogOpen!) {
      Get.back();
    }
  }

  void showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.greenAccent,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
