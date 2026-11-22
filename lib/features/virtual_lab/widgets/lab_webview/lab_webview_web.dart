import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildLabWebView({
  required String htmlPath,
  required String viewId,
  void Function(String message)? onMessageReceived,
}) {
  final registeredViewType = 'lab-iframe-$viewId';

  // تسجيل عنصر IFrame في متصفح الويب
  ui_web.platformViewRegistry.registerViewFactory(registeredViewType, (int id) {
    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = htmlPath;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.backgroundColor = '#0b1320';
    iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope';
    return iframe;
  });

  return HtmlElementView(viewType: registeredViewType);
}
