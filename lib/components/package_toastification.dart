import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class useToastify {
  static void showErrorToast(
      BuildContext context, String title, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold)),
      description: Text(message, style: const TextStyle(color: Colors.black)),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 5),
      primaryColor: Color.fromARGB(255, 162, 46, 46),
      borderRadius: BorderRadius.circular(12.0),
      showProgressBar: true,
      dragToClose: true,
    );
  }

  static void showLoadingToast(
      BuildContext context, String title, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold)),
      description: Text(message, style: const TextStyle(color: Colors.black)),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 5),
      primaryColor: const Color(0xff562ea2),
      borderRadius: BorderRadius.circular(12.0),
      showProgressBar: true,
      dragToClose: true,
    );
  }
}
