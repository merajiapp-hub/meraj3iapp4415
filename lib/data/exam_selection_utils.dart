// exam_selection_utils.dart
// أداة مساعدة لاستخراج قوائم المسابقات والشعب والمواد والفصول من مستندات Firestore

class ExamSelectionUtils {
  // المسابقات الوطنية الثلاث المدعومة
  static const List<String> competitions = ['Concours', 'Brevet', 'Baccalauréat'];

  // شعب البكالوريا
  static const List<String> bacStreams = ['7D', '7C', '7LM', '7LO'];

  /// تطبيع قيمة المسابقة لضمان التطابق مع القيم الموحدة
  static String normalizeCompetition(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == 'concours' || t == 'المسابقات الوطنية') return 'Concours';
    if (t == 'brevet' || t == 'bevet' || t == 'البريفيه' || t == 'البروفيه') return 'Brevet';
    if (t.startsWith('bac') || t == 'البكالوريا') return 'Baccalauréat';
    return raw ?? '';
  }

  /// هل المسابقة صالحة؟
  static bool isValidCompetition(String? value) {
    if (value == null) return false;
    return competitions.contains(normalizeCompetition(value));
  }

  /// استخراج المواد المتاحة لمسابقة وشعبة معينة
  static List<String> subjectsFromDocs(
    List<Map<String, dynamic>> docs, {
    String? competition,
    String? stream,
  }) {
    final filtered = docs.where((doc) {
      if (competition != null && competition.isNotEmpty) {
        final docComp = normalizeCompetition(
            (doc['competition'] ?? doc['examType'] ?? '').toString());
        if (docComp != competition) return false;
      }
      if (stream != null &&
          stream.isNotEmpty &&
          competition == 'Baccalauréat') {
        final docStream =
            (doc['stream'] ?? doc['division'] ?? doc['section'] ?? '').toString().trim();
        if (docStream != stream) return false;
      }
      return true;
    });

    final subjects = filtered
        .map((doc) => (doc['subject'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return subjects;
  }

  /// استخراج الفصول المتاحة لمادة ومسابقة وشعبة معينة
  static List<String> chaptersForSubject(
    List<Map<String, dynamic>> docs,
    String subject, {
    String? competition,
    String? stream,
  }) {
    final filtered = docs.where((doc) {
      if ((doc['subject'] ?? '').toString().trim() != subject) return false;
      if (competition != null && competition.isNotEmpty) {
        final docComp = normalizeCompetition(
            (doc['competition'] ?? doc['examType'] ?? '').toString());
        if (docComp != competition) return false;
      }
      if (stream != null &&
          stream.isNotEmpty &&
          competition == 'Baccalauréat') {
        final docStream =
            (doc['stream'] ?? doc['division'] ?? doc['section'] ?? '').toString().trim();
        if (docStream != stream) return false;
      }
      return true;
    });

    final chapters = filtered
        .map((doc) =>
            (doc['chapter'] ?? doc['chapterId'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return chapters;
  }

  /// احسب نجوم الأداء (1-5)
  static int starsForScore(int scorePct) {
    if (scorePct >= 80) return 5;
    if (scorePct >= 60) return 4;
    if (scorePct >= 40) return 3;
    if (scorePct >= 20) return 2;
    return 1;
  }

  /// وصف الأداء
  static String performanceLabel(int scorePct) {
    if (scorePct >= 80) return 'ممتاز';
    if (scorePct >= 60) return 'جيد';
    if (scorePct >= 40) return 'مقبول';
    if (scorePct >= 20) return 'ضعيف';
    return 'يحتاج مراجعة';
  }
}
