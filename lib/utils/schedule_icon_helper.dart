import 'package:flutter/material.dart';

/// مساعد أيقونات وألوان الحصص الدراسية الذكي
class ScheduleIconHelper {
  ScheduleIconHelper._();

  /// قائمة الأيقونات التعليمية المتاحة للاختيار
  static const List<ScheduleIconDef> availableIcons = [
    ScheduleIconDef('calculate', Icons.calculate_rounded, 'الرياضيات'),
    ScheduleIconDef('science', Icons.science_rounded, 'الفيزياء والكيمياء'),
    ScheduleIconDef('biotech', Icons.biotech_rounded, 'العلوم الطبيعية'),
    ScheduleIconDef('psychology', Icons.psychology_rounded, 'الفلسفة والمنطق'),
    ScheduleIconDef('menu_book', Icons.menu_book_rounded, 'اللغة العربية'),
    ScheduleIconDef('mosque', Icons.auto_stories_rounded, 'التربية الإسلامية'),
    ScheduleIconDef('translate', Icons.translate_rounded, 'اللغة الفرنسية'),
    ScheduleIconDef('language', Icons.language_rounded, 'اللغة الإنجليزية'),
    ScheduleIconDef('public', Icons.public_rounded, 'التاريخ والجغرافيا'),
    ScheduleIconDef('laptop', Icons.laptop_chromebook_rounded, 'المعلوماتية'),
    ScheduleIconDef('fitness', Icons.fitness_center_rounded, 'التربية البدنية'),
    ScheduleIconDef('palette', Icons.palette_rounded, 'الرسم والفنون'),
    ScheduleIconDef('quiz', Icons.quiz_rounded, 'امتحان / اختبار'),
    ScheduleIconDef('school', Icons.school_rounded, 'حصة عامة'),
    ScheduleIconDef('timer', Icons.timer_rounded, 'مراجعة / تقوية'),
    ScheduleIconDef('edit_note', Icons.edit_note_rounded, 'أعمال تطبيقية'),
    ScheduleIconDef('lightbulb', Icons.lightbulb_rounded, 'نشاط علمي'),
    ScheduleIconDef('star', Icons.star_rounded, 'حصة متميزة'),
  ];

  /// لوحة الألوان الأكاديمية العصرية
  static const List<Color> academicColors = [
    Color(0xFF2563EB), // أزرق ملكي
    Color(0xFF7C3AED), // بنفسجي
    Color(0xFF059669), // أخضر زمردي
    Color(0xFF0F766E), // تركوازي مراجعي
    Color(0xFF047857), // أخضر إسلامي
    Color(0xFFD97706), // كهرماني
    Color(0xFFEA580C), // برتقالي دافئ
    Color(0xFFDC2626), // أحمر قرمزي
    Color(0xFF4338CA), // نيلي داكن
    Color(0xFFB45309), // برونزي
    Color(0xFFC026D3), // فوشيا
    Color(0xFF0284C7), // سماوي زاهي
  ];

  /// المواد الشائعة للاختيار السريع مع ألوانها وأيقوناتها
  static const List<ScheduleSubjectTemplate> commonTemplates = [
    ScheduleSubjectTemplate('الرياضيات', Color(0xFF2563EB), 'calculate', Icons.calculate_rounded),
    ScheduleSubjectTemplate('الفيزياء والكيمياء', Color(0xFF7C3AED), 'science', Icons.science_rounded),
    ScheduleSubjectTemplate('العلوم الطبيعية', Color(0xFF059669), 'biotech', Icons.biotech_rounded),
    ScheduleSubjectTemplate('الفلسفة', Color(0xFFD97706), 'psychology', Icons.psychology_rounded),
    ScheduleSubjectTemplate('اللغة العربية', Color(0xFF0F766E), 'menu_book', Icons.menu_book_rounded),
    ScheduleSubjectTemplate('التربية الإسلامية', Color(0xFF047857), 'mosque', Icons.auto_stories_rounded),
    ScheduleSubjectTemplate('اللغة الفرنسية', Color(0xFF4338CA), 'translate', Icons.translate_rounded),
    ScheduleSubjectTemplate('اللغة الإنجليزية', Color(0xFFB45309), 'language', Icons.language_rounded),
    ScheduleSubjectTemplate('التاريخ والجغرافيا', Color(0xFFC026D3), 'public', Icons.public_rounded),
    ScheduleSubjectTemplate('المعلوماتية', Color(0xFF0284C7), 'laptop', Icons.laptop_chromebook_rounded),
  ];

  /// استرجاع الأيقونة المناسبة بدقة فائقة وضمان عدم الفقدان
  static IconData resolveIcon(String? iconName, [String? title]) {
    final name = (iconName ?? '').trim().toLowerCase();

    // 1. مطابقة مباشرة بالاسم المخزن
    switch (name) {
      case 'calculate':
      case 'math':
        return Icons.calculate_rounded;
      case 'science':
      case 'chemistry':
      case 'physics':
        return Icons.science_rounded;
      case 'biotech':
      case 'eco':
      case 'biology':
        return Icons.biotech_rounded;
      case 'psychology':
      case 'philosophy':
        return Icons.psychology_rounded;
      case 'menu_book':
      case 'book':
      case 'arabic':
        return Icons.menu_book_rounded;
      case 'mosque':
      case 'islamic':
        return Icons.auto_stories_rounded;
      case 'translate':
      case 'french':
        return Icons.translate_rounded;
      case 'language':
      case 'english':
        return Icons.language_rounded;
      case 'public':
      case 'history':
      case 'geography':
        return Icons.public_rounded;
      case 'laptop':
      case 'computer':
        return Icons.laptop_chromebook_rounded;
      case 'fitness':
      case 'sport':
        return Icons.fitness_center_rounded;
      case 'palette':
      case 'art':
        return Icons.palette_rounded;
      case 'quiz':
      case 'exam':
        return Icons.quiz_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'star':
        return Icons.star_rounded;
    }

    // 2. تحليل العنوان الذكي إذا لم يتطابق الاسم
    if (title != null && title.trim().isNotEmpty) {
      final t = title.trim().toLowerCase();
      if (t.contains('رياض') || t.contains('حساب') || t.contains('جبر') || t.contains('هندس') || t.contains('math')) {
        return Icons.calculate_rounded;
      }
      if (t.contains('فيز') || t.contains('كيم') || t.contains('science') || t.contains('physics')) {
        return Icons.science_rounded;
      }
      if (t.contains('طبيع') || t.contains('أحياء') || t.contains('بيولوج') || t.contains('eco') || t.contains('bio')) {
        return Icons.biotech_rounded;
      }
      if (t.contains('فلسف') || t.contains('منطق') || t.contains('تفكير')) {
        return Icons.psychology_rounded;
      }
      if (t.contains('عرب') || t.contains('نحو') || t.contains('أدب') || t.contains('بلاغ') || t.contains('نصوص')) {
        return Icons.menu_book_rounded;
      }
      if (t.contains('إسلام') || t.contains('قرآن') || t.contains('دين') || t.contains('توحيد') || t.contains('فقه') || t.contains('حديث')) {
        return Icons.auto_stories_rounded;
      }
      if (t.contains('فرنس') || t.contains('français') || t.contains('french')) {
        return Icons.translate_rounded;
      }
      if (t.contains('إنجليز') || t.contains('انكليز') || t.contains('english')) {
        return Icons.language_rounded;
      }
      if (t.contains('تاريخ') || t.contains('جغراف') || t.contains('اجتماع') || t.contains('مدني')) {
        return Icons.public_rounded;
      }
      if (t.contains('حاسوب') || t.contains('معلومات') || t.contains('برمج') || t.contains('إعلام آلي') || t.contains('computer')) {
        return Icons.laptop_chromebook_rounded;
      }
      if (t.contains('رياضة') || t.contains('بدن') || t.contains('sport')) {
        return Icons.fitness_center_rounded;
      }
      if (t.contains('رسم') || t.contains('فنون') || t.contains('تشكيل')) {
        return Icons.palette_rounded;
      }
      if (t.contains('اختبار') || t.contains('امتحان') || t.contains('تقييم') || t.contains('فرض') || t.contains('exam')) {
        return Icons.quiz_rounded;
      }
    }

    return Icons.menu_book_rounded;
  }

  /// ضمان لون آمن وغير شفاف وواضح دائماً
  static Color getSafeColor(Color color, {bool isDark = false}) {
    if (color.a == 0 || (color.toARGB32() & 0xFF000000) == 0) {
      return const Color(0xFF0F766E);
    }
    // في الوضع الليلي إذا كان اللون شديد القتامة نرفعه قليلاً
    if (isDark && color.computeLuminance() < 0.1) {
      return const Color(0xFF14B8A6);
    }
    // في الوضع الفاتح إذا كان شديد البياض نعتمه
    if (!isDark && color.computeLuminance() > 0.85) {
      return const Color(0xFF0F766E);
    }
    return color;
  }

  /// اقتراح تلقائي للأيقونة واللون بمجرد كتابة اسم المادة
  static (Color, String, IconData) suggestForTitle(String title) {
    final t = title.trim().toLowerCase();

    if (t.contains('رياض') || t.contains('math')) {
      return (const Color(0xFF2563EB), 'calculate', Icons.calculate_rounded);
    }
    if (t.contains('فيز') || t.contains('كيم') || t.contains('physics')) {
      return (const Color(0xFF7C3AED), 'science', Icons.science_rounded);
    }
    if (t.contains('طبيع') || t.contains('أحياء') || t.contains('بيولوج')) {
      return (const Color(0xFF059669), 'biotech', Icons.biotech_rounded);
    }
    if (t.contains('فلسف') || t.contains('منطق')) {
      return (const Color(0xFFD97706), 'psychology', Icons.psychology_rounded);
    }
    if (t.contains('عرب') || t.contains('نحو') || t.contains('أدب')) {
      return (const Color(0xFF0F766E), 'menu_book', Icons.menu_book_rounded);
    }
    if (t.contains('إسلام') || t.contains('قرآن') || t.contains('دين')) {
      return (const Color(0xFF047857), 'mosque', Icons.auto_stories_rounded);
    }
    if (t.contains('فرنس')) {
      return (const Color(0xFF4338CA), 'translate', Icons.translate_rounded);
    }
    if (t.contains('إنجليز') || t.contains('english')) {
      return (const Color(0xFFB45309), 'language', Icons.language_rounded);
    }
    if (t.contains('تاريخ') || t.contains('جغراف')) {
      return (const Color(0xFFC026D3), 'public', Icons.public_rounded);
    }
    if (t.contains('حاسوب') || t.contains('معلومات') || t.contains('برمج')) {
      return (const Color(0xFF0284C7), 'laptop', Icons.laptop_chromebook_rounded);
    }
    if (t.contains('رياضة') || t.contains('بدن')) {
      return (const Color(0xFFEA580C), 'fitness', Icons.fitness_center_rounded);
    }
    if (t.contains('رسم') || t.contains('فنون')) {
      return (const Color(0xFFD946EF), 'palette', Icons.palette_rounded);
    }

    return (const Color(0xFF0F766E), 'menu_book', Icons.menu_book_rounded);
  }
}

class ScheduleIconDef {
  final String key;
  final IconData icon;
  final String label;

  const ScheduleIconDef(this.key, this.icon, this.label);
}

class ScheduleSubjectTemplate {
  final String title;
  final Color color;
  final String iconKey;
  final IconData icon;

  const ScheduleSubjectTemplate(this.title, this.color, this.iconKey, this.icon);
}
