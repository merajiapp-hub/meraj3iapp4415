class ExamSelectionUtils {
  static bool _isCompetitionName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'concours' ||
        normalized == 'brevet' ||
        normalized == 'baccalauréat' ||
        normalized == 'baccalaureat' ||
        normalized == 'الباكالوريا' ||
        normalized == 'البكالوريا' ||
        normalized == 'البروفيه' ||
        normalized == 'التوجيهي';
  }

  static List<String> subjectsFromDocs(List<Map<String, dynamic>> docs) {
    final subjects = docs
        .map((doc) => (doc['subject'] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    final competitionSubjects = subjects.where(_isCompetitionName).toList();
    if (competitionSubjects.isNotEmpty) {
      competitionSubjects.sort();
      return competitionSubjects;
    }

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
