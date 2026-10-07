import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  void showLoading({bool withDialog = true}) {
    _isLoading.value = true;
    if (withDialog && !(Get.isDialogOpen ?? false)) {
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
    if (Get.isDialogOpen ?? false) {
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
