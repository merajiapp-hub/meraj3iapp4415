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
    final viewType = _registeredViewTypes.putIfAbsent(url, () {
      final id = 'video-embed-${_nextId++}';
      ui_web.platformViewRegistry.registerViewFactory(
        id,
        (int viewId) => web.HTMLIFrameElement()
          ..src = url
          ..title = title
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', 'true')
          ..setAttribute(
            'allow',
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
          ),
      );
      return id;
    });

    return HtmlElementView(viewType: viewType);
  }
}
