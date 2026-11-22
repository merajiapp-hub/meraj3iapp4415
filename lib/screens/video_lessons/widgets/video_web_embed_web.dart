import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class VideoWebEmbed extends StatelessWidget {
  final String url;
  final String title;

  const VideoWebEmbed({super.key, required this.url, required this.title});

  static final Map<String, String> _registeredViewTypes = {};
  static int _nextId = 0;

  @override
  Widget build(BuildContext context) {
    final isDrive = url.contains('drive.google.com');
    final viewType = _registeredViewTypes.putIfAbsent(url, () {
      final id = 'video-embed-${_nextId++}';
      ui_web.platformViewRegistry.registerViewFactory(
        id,
        (int viewId) {
          final iframe = web.HTMLIFrameElement()
            ..src = url
            ..title = title
            ..style.border = '0'
            ..style.width = '100%'
            ..style.height = isDrive ? 'calc(100% + 56px)' : '100%'
            ..setAttribute('allowfullscreen', 'true')
            ..setAttribute(
              'allow',
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
            );
          if (isDrive) {
            iframe.style.marginTop = '-56px';
          }
          return iframe;
        },
      );
      return id;
    });

    return HtmlElementView(viewType: viewType);
  }
}
