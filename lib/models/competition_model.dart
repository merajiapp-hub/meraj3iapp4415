// models/competition_model.dart
// نموذج ديناميكي — لا يعتمد على enum ثابت
// أي مفتاح جديد في Remote Config يظهر تلقائياً

/// نوع المسابقة لتحديد طريقة عرض ومعالجة النتائج
enum CompetitionType {
  concours,       // كونكور — معدل/200
  brevet,         // بريفية — معدل/20
  bac,            // باكالوريا — معدل/20
  complementary,  // تكميلي — معدل/20
  excellence,     // امتياز — معدل/20
  generic,        // أي نوع جديد — يُعامل مثل bac
}

class CompetitionModel {
  /// المفتاح الفريد من Remote Config (مثل: "concours", "brevet", "my_new_exam")
  final String rawKey;
  final CompetitionType type;
  final String title;
  final String link;
  final bool isPublished;
  final String? emoji;
  final String? subtitle;
  final String? color; // hex color مثل "#0D9488"
  final int order;    // ترتيب العرض

  const CompetitionModel({
    required this.rawKey,
    required this.type,
    required this.title,
    required this.link,
    required this.isPublished,
    this.emoji,
    this.subtitle,
    this.color,
    this.order = 99,
  });

  /// إنشاء من JSON مع rawKey
  factory CompetitionModel.fromJson(String key, Map<String, dynamic> json) {
    final type = _inferType(key, json);
    return CompetitionModel(
      rawKey: key,
      type: type,
      title: json['title'] as String? ?? _defaultTitle(key, type),
      link: json['link'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? false,
      emoji: json['emoji'] as String?,
      subtitle: json['subtitle'] as String?,
      color: json['color'] as String?,
      order: json['order'] as int? ?? _defaultOrder(key),
    );
  }

  // ─── حدّد نوع المسابقة من المفتاح ─────────────────────────────────

  static CompetitionType _inferType(String key, Map<String, dynamic> json) {
    // أولاً: إذا أرسل المستخدم النوع صراحةً
    if (json['type'] is String) {
      switch ((json['type'] as String).toLowerCase()) {
        case 'concours': return CompetitionType.concours;
        case 'brevet': return CompetitionType.brevet;
        case 'bac': return CompetitionType.bac;
        case 'complementary': return CompetitionType.complementary;
        case 'excellence': return CompetitionType.excellence;
        default: return CompetitionType.generic;
      }
    }
    // ثانياً: استنتاج من المفتاح
    final k = key.toLowerCase();
    if (k.contains('excellence')) return CompetitionType.excellence;
    if (k.startsWith('concours')) return CompetitionType.concours;
    if (k.startsWith('brevet')) return CompetitionType.brevet;
    if (k.startsWith('bac')) return CompetitionType.bac;
    if (k.contains('complementary') || k.contains('rattrapage')) return CompetitionType.complementary;
    return CompetitionType.generic;
  }

  // ─── قيم افتراضية بحسب المفتاح ────────────────────────────────────

  static String _defaultTitle(String key, CompetitionType type) {
    switch (type) {
      case CompetitionType.concours: return 'كونكور 2026';
      case CompetitionType.brevet: return 'ابريفة 2026';
      case CompetitionType.bac: return 'الباكلوريا – الدورة العادية';
      case CompetitionType.complementary: return 'الباكلوريا – الدورة التكميلية';
      case CompetitionType.excellence: return 'نتائج الامتياز';
      case CompetitionType.generic: return key.replaceAll('_', ' ');
    }
  }

  static int _defaultOrder(String key) {
    const orders = {
      'concours': 0,
      'brevet': 1,
      'bac': 2,
      'complementary': 3,
      'concours_excellence': 4,
      'brevet_excellence': 5,
    };
    return orders[key] ?? 99;
  }

  // ─── خصائص العرض ──────────────────────────────────────────────────

  String get displayEmoji {
    if (emoji != null && emoji!.isNotEmpty) return emoji!;
    switch (type) {
      case CompetitionType.concours: return '🏆';
      case CompetitionType.brevet: return '📚';
      case CompetitionType.bac: return '🎓';
      case CompetitionType.complementary: return '🔄';
      case CompetitionType.excellence: return '⭐';
      case CompetitionType.generic: return '📝';
    }
  }

  String get displaySubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle!;
    switch (type) {
      case CompetitionType.concours: return "مسابقة دخول السنة الأولى إعدادية";
      case CompetitionType.brevet: return "مسابقة ختم الدروس الإعدادية (BEPC)";
      case CompetitionType.bac: return 'الباكلوريا – الدورة العادية';
      case CompetitionType.complementary: return 'الباكلوريا – الدورة التكميلية';
      case CompetitionType.excellence: return "نتائج الامتياز الوطنية";
      case CompetitionType.generic: return "نتائج المسابقة";
    }
  }

  bool get isExcellence => type == CompetitionType.excellence;
  bool get isConcours => type == CompetitionType.concours;
  bool get isBrevet => type == CompetitionType.brevet;
  bool get isBac => type == CompetitionType.bac;
  bool get isComplementary => type == CompetitionType.complementary;

  // مفاتيح قديمة للتوافق مع الكود السابق
  CompetitionKey? get key {
    switch (rawKey) {
      case 'concours': return CompetitionKey.concours;
      case 'brevet': return CompetitionKey.brevet;
      case 'bac': return CompetitionKey.bac;
      case 'complementary': return CompetitionKey.complementary;
      case 'concours_excellence': return CompetitionKey.concoursExcellence;
      case 'brevet_excellence': return CompetitionKey.brevetExcellence;
      default: return null;
    }
  }
}

/// للتوافق مع الكود القديم فقط — لا تُستخدم في كود جديد
enum CompetitionKey {
  concours,
  brevet,
  bac,
  complementary,
  concoursExcellence,
  brevetExcellence,
}
