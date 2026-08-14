import 'dart:convert';

class StudentProfile {
  String name;
  String grade;
  String department;
  String school;
  String? avatarPath;
  int booksRead;
  int quizzesTaken;
  double progressLevel;
  List<String> achievements;

  StudentProfile({
    required this.name,
    required this.grade,
    required this.department,
    required this.school,
    this.avatarPath,
    this.booksRead = 0,
    this.quizzesTaken = 0,
    this.progressLevel = 0.0,
    this.achievements = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
      'department': department,
      'school': school,
      'avatarPath': avatarPath,
      'booksRead': booksRead,
      'quizzesTaken': quizzesTaken,
      'progressLevel': progressLevel,
      'achievements': achievements,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      name: map['name'] ?? 'طالب مميز',
      grade: map['grade'] ?? 'الثالث الثانوي',
      department: map['department'] ?? 'علوم تجريبية',
      school: map['school'] ?? 'ثانوية النجاح',
      avatarPath: map['avatarPath'],
      booksRead: map['booksRead'] ?? 0,
      quizzesTaken: map['quizzesTaken'] ?? 0,
      progressLevel: (map['progressLevel'] ?? 0.0).toDouble(),
      achievements: List<String>.from(map['achievements'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory StudentProfile.fromJson(String source) => StudentProfile.fromMap(json.decode(source));
}
