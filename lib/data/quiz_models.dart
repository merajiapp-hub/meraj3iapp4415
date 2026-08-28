// ─── نماذج الاختبار ──────────────────────────────────────────────────────────

enum QuestionDifficulty { easy, medium, hard, veryHard }

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String? explanation;
  final QuestionDifficulty difficulty;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    this.explanation,
    this.difficulty = QuestionDifficulty.medium,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data, String documentId) {
    QuestionDifficulty diff = QuestionDifficulty.medium;
    if (data['difficulty'] != null) {
      switch (data['difficulty']) {
        case 'easy':
          diff = QuestionDifficulty.easy;
          break;
        case 'hard':
          diff = QuestionDifficulty.hard;
          break;
        case 'veryHard':
          diff = QuestionDifficulty.veryHard;
          break;
        case 'medium':
        default:
          diff = QuestionDifficulty.medium;
      }
    }

    return QuizQuestion(
      id: documentId,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      category: data['category'] ?? 'عام',
      explanation: data['explanation'],
      difficulty: diff,
    );
  }
}
