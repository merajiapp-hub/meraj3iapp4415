int? academicOrdinalOrder(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll(RegExp(r'\s+'), ' ');
  const ordinals = {
    'الحادي عشر': 11,
    'الحادية عشرة': 11,
    'الثاني عشر': 12,
    'الثانية عشرة': 12,
    'الثالث عشر': 13,
    'الثالثة عشرة': 13,
    'العاشر': 10,
    'العاشرة': 10,
    'التاسع': 9,
    'التاسعة': 9,
    'الثامن': 8,
    'الثامنة': 8,
    'السابع': 7,
    'السابعة': 7,
    'السادس': 6,
    'السادسة': 6,
    'الخامس': 5,
    'الخامسة': 5,
    'الرابع': 4,
    'الرابعة': 4,
    'الثالث': 3,
    'الثالثة': 3,
    'الثاني': 2,
    'الثانية': 2,
    'الاول': 1,
    'الاولى': 1,
  };
  for (final entry in ordinals.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }

  final withoutYears = normalized.replaceAll(RegExp(r'\d{4}'), '');
  final numeric = RegExp(r'\d{1,2}').firstMatch(withoutYears);
  return numeric == null ? null : int.tryParse(numeric.group(1)!);
}

int compareAcademicLabels(String a, String b) {
  final aOrdinal = academicOrdinalOrder(a);
  final bOrdinal = academicOrdinalOrder(b);
  if (aOrdinal != null && bOrdinal != null && aOrdinal != bOrdinal) {
    return aOrdinal.compareTo(bOrdinal);
  }

  final aYear = RegExp(r'\d{4}').firstMatch(a);
  final bYear = RegExp(r'\d{4}').firstMatch(b);
  if (aYear != null && bYear != null) {
    final yearOrder = int.parse(
      bYear.group(0)!,
    ).compareTo(int.parse(aYear.group(0)!));
    if (yearOrder != 0) return yearOrder;
  }

  return a.toLowerCase().compareTo(b.toLowerCase());
}
