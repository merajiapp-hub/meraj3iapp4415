class ExamSelectionUtils {
  static List<String> subjectsFromDocs(List<Map<String, dynamic>> docs) {
    final subjects = docs
        .map((doc) => (doc['subject'] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }

  static List<String> chaptersForSubject(List<Map<String, dynamic>> docs, String subject) {
    final chapters = docs
        .where((doc) => (doc['subject'] ?? '').toString().trim() == subject)
        .map((doc) => (doc['chapter'] ?? doc['section'] ?? 'عام').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    chapters.sort();
    return chapters;
  }
}
