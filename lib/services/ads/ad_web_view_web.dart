import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredSlots = {};

Widget buildAdSensePlatformView({
  required String publisherId,
  required String slotId,
  required double width,
  required double height,
}) {
  final viewType = 'adsense-banner-$slotId';
  if (!_registeredSlots.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '${height}px';
      container.style.display = 'flex';
      container.style.justifyContent = 'center';
      container.style.alignItems = 'center';
      container.style.overflow = 'hidden';

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.style.width = '100%';
      ins.style.height = '${height}px';
      ins.setAttribute('data-ad-client', publisherId);
      ins.setAttribute('data-ad-slot', slotId);
      ins.setAttribute('data-ad-format', 'auto');
      ins.setAttribute('data-full-width-responsive', 'true');

      container.appendChild(ins);

      final script = web.document.createElement('script') as web.HTMLScriptElement;
      script.text = '(adsbygoogle = window.adsbygoogle || []).push({});';
      container.appendChild(script);

      return container;
    });
    _registeredSlots.add(viewType);
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
