import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../services/drive_url_service.dart';

class DrivePdfPreview extends StatelessWidget {
  const DrivePdfPreview({super.key, required this.url});

  final String url;

  static final Map<String, String> _registeredViewTypes = <String, String>{};
  static int _nextViewTypeId = 0;

  @override
  Widget build(BuildContext context) {
    final viewType = _registeredViewTypes.putIfAbsent(url, () {
      final newViewType = 'drive-pdf-preview-${_nextViewTypeId++}';
      ui_web.platformViewRegistry.registerViewFactory(
        newViewType,
        (int viewId) => web.HTMLIFrameElement()
          ..src = DriveUrlService.buildEmbedUrl(url)
          ..title = 'معاينة ملف PDF'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', 'true'),
      );
      return newViewType;
    });

    return HtmlElementView(viewType: viewType);
  }
}
