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
    final rawDifficulty = data['difficulty']?.toString().trim();
    if (rawDifficulty != null) {
      switch (rawDifficulty) {
        case 'easy':
        case 'سهل':
          diff = QuestionDifficulty.easy;
          break;
        case 'hard':
        case 'صعب':
          diff = QuestionDifficulty.hard;
          break;
        case 'veryHard':
        case 'متقدم':
          diff = QuestionDifficulty.veryHard;
          break;
        case 'medium':
        case 'متوسط':
        default:
          diff = QuestionDifficulty.medium;
      }
    }

    final rawOptions = data['options'] ?? data['answers'] ?? const [];
    final options = List<String>.from(rawOptions is List ? rawOptions : const []);
    var correctIndex = (data['correctIndex'] as num?)?.toInt();
    if (correctIndex == null) {
      final answer = data['correctAnswer']?.toString();
      correctIndex = answer == null ? 0 : options.indexOf(answer);
      if (correctIndex < 0) correctIndex = int.tryParse(answer ?? '') ?? 0;
    }

    return QuizQuestion(
      id: documentId,
      question: data['question'] ?? data['text'] ?? '',
      options: options,
      correctIndex: correctIndex.clamp(0, options.isEmpty ? 0 : options.length - 1),
      category: data['category'] ?? data['subject'] ?? 'عام',
      explanation: data['explanation'],
      difficulty: diff,
    );
  }
}
