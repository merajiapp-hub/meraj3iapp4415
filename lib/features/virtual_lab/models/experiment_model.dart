import 'package:flutter/material.dart';

/// مرحلة تفاعلية من خطوات التجربة المخبرية
class ExperimentStep {
  final int number;
  final String title;
  final String instruction;
  final String hint;

  const ExperimentStep({
    required this.number,
    required this.title,
    required this.instruction,
    this.hint = '',
  });

  factory ExperimentStep.fromJson(Map<String, dynamic> json) {
    return ExperimentStep(
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'instruction': instruction,
      'hint': hint,
    };
  }
}

/// سؤال تقييمي بعد إنجاز التجربة الافتراضية
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

/// نموذج التجربة العلمية ثلاثية الأبعاد
class ExperimentModel {
  final String id;
  final String title;
  final String titleFr;
  final String subject; // 'chemistry' أو 'physics'
  final List<String> gradeLevels; // e.g. ['3AS', '4AS', 'Terminale', 'BAC D']
  final String description;
  final List<String> objectives;
  final List<String> safetyTips;
  final List<String> equipment;
  final int durationMinutes;
  final String difficulty; // 'easy', 'medium', 'hard'
  final bool isPro;
  final bool isPublished;
  final String htmlAssetPath;
  final String? chemicalFormula;
  final List<ExperimentStep> steps;
  final List<QuizQuestion> quizQuestions;
  final String conclusion;

  const ExperimentModel({
    required this.id,
    required this.title,
    this.titleFr = '',
    required this.subject,
    required this.gradeLevels,
    required this.description,
    this.objectives = const [],
    this.safetyTips = const [],
    this.equipment = const [],
    this.durationMinutes = 15,
    this.difficulty = 'medium',
    this.isPro = false,
    this.isPublished = true,
    required this.htmlAssetPath,
    this.chemicalFormula,
    this.steps = const [],
    this.quizQuestions = const [],
    this.conclusion = '',
  });

  bool get isChemistry => subject == 'chemistry';
  bool get isPhysics => subject == 'physics';

  String get subjectArabicName => isChemistry ? 'الكيمياء' : 'الفيزياء';

  IconData get subjectIcon => isChemistry ? Icons.biotech_rounded : Icons.offline_bolt_rounded;

  Color get subjectColor => isChemistry ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

  String get difficultyArabic {
    switch (difficulty) {
      case 'easy':
        return 'مبتدئ';
      case 'hard':
        return 'متقدم';
      case 'medium':
      default:
        return 'متوسط';
    }
  }

  factory ExperimentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ExperimentModel(
      id: docId ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      titleFr: json['titleFr']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'chemistry',
      gradeLevels: (json['gradeLevels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['4AS'],
      description: json['description']?.toString() ?? '',
      objectives: (json['objectives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      safetyTips: (json['safetyTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 15,
      difficulty: json['difficulty']?.toString() ?? 'medium',
      isPro: json['isPro'] == true,
      isPublished: json['isPublished'] != false,
      htmlAssetPath: json['htmlAssetPath']?.toString() ?? '',
      chemicalFormula: json['chemicalFormula']?.toString(),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => ExperimentStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizQuestions: (json['quizQuestions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conclusion: json['conclusion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'titleFr': titleFr,
      'subject': subject,
      'gradeLevels': gradeLevels,
      'description': description,
      'objectives': objectives,
      'safetyTips': safetyTips,
      'equipment': equipment,
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
      'isPro': isPro,
      'isPublished': isPublished,
      'htmlAssetPath': htmlAssetPath,
      'chemicalFormula': chemicalFormula,
      'steps': steps.map((e) => e.toJson()).toList(),
      'quizQuestions': quizQuestions.map((e) => e.toJson()).toList(),
      'conclusion': conclusion,
    };
  }
}
