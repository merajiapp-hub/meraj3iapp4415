import 'package:flutter/material.dart';

Widget buildLabWebView({
  required String htmlPath,
  required String viewId,
  void Function(String message)? onMessageReceived,
}) {
  return Container(
    color: const Color(0xFF0C1424),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.science_rounded, size: 48, color: Color(0xFF38BDF8)),
          SizedBox(height: 12),
          Text(
            'محاكاة المختبر الافتراضي 3D',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'المحاكاة قيد التهيئة في نظامك...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
