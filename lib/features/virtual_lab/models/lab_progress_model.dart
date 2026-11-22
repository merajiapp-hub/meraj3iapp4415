class LabProgress {
  final Set<String> completedExperiments;
  final Map<String, int> quizScores; // experimentId -> percentage (0-100)
  final int totalMinutesSpent;

  const LabProgress({
    this.completedExperiments = const {},
    this.quizScores = const {},
    this.totalMinutesSpent = 0,
  });

  bool isCompleted(String experimentId) => completedExperiments.contains(experimentId);

  int? getScore(String experimentId) => quizScores[experimentId];

  factory LabProgress.fromJson(Map<String, dynamic> json) {
    final completedList = (json['completedExperiments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final scoresMap = (json['quizScores'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        {};

    return LabProgress(
      completedExperiments: completedList.toSet(),
      quizScores: scoresMap,
      totalMinutesSpent: (json['totalMinutesSpent'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedExperiments': completedExperiments.toList(),
      'quizScores': quizScores,
      'totalMinutesSpent': totalMinutesSpent,
    };
  }
}
