import 'dart:ui';

import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 16.0,
    );
  }
}