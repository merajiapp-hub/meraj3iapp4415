import 'package:flutter/widgets.dart';

class VideoWebEmbed extends StatelessWidget {
  final String url;
  final String title;

  const VideoWebEmbed({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
