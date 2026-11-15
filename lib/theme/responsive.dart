import 'package:flutter/material.dart';

/// مساعِد التصميم المتجاوب والتكيفي لجميع الشاشات (الهواتف، الأجهزة اللوحية، والحواسيب)
class ResponsiveHelper {
  ResponsiveHelper._();

  /// هل الشاشة صغيرة جداً (هواتف قديمة أو ضيقة)
  static bool isSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// هل الشاشة هاتف عادي
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  /// هل الشاشة جهاز لوحي (Tablet / Foldable)
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }

  /// هل الشاشة حاسوب أو شاشة عريضة
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// هل الشاشة طويلة نسبياً (هواتف حديثة بأبعاد 20:9 أو 21:9)
  static bool isTall(BuildContext context) =>
      MediaQuery.sizeOf(context).height > 820;

  /// حساب الهامش الأفقي الديناميكي حسب عرض الشاشة
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return 32.0;
    if (w >= 600) return 24.0;
    if (w < 360) return 10.0;
    return 16.0;
  }

  /// منشئ شبكة مرن ومتكيف تلقائياً مع أبعاد الشاشة بدون تثبيت عدد الأعمدة
  static SliverGridDelegateWithMaxCrossAxisExtent gridDelegate({
    double maxExtent = 240.0,
    double childAspectRatio = 1.0,
    double spacing = 12.0,
    double? mainAxisExtent,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxExtent,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      mainAxisExtent: mainAxisExtent,
    );
  }
}

/// ودجت نص ذكي متجاوب يمنع خروج النص (Overflow) ويصغّر الخط تلقائياً عند ضيق الشاشة
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final AlignmentGeometry alignment;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.right,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.alignment = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      ),
    );
  }
}
