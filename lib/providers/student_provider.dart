import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_profile.dart';

class StudentProvider with ChangeNotifier {
  StudentProfile _profile = StudentProfile(
    name: 'طالب متميز',
    grade: 'السنة الثالثة ثانوي',
    department: 'علوم تجريبية',
    school: 'ثانوية النجاح',
  );

  StudentProfile get profile => _profile;

  StudentProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileData = prefs.getString('student_profile');
    if (profileData != null) {
      _profile = StudentProfile.fromJson(profileData);
      notifyListeners();
    }
  }

  Future<void> updateProfile(StudentProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_profile', _profile.toJson());
  }

  Future<void> incrementBooksRead() async {
    _profile.booksRead++;
    await updateProfile(_profile);
  }

  Future<void> incrementQuizzesTaken() async {
    _profile.quizzesTaken++;
    await updateProfile(_profile);
  }

  Future<void> updateProgressLevel(double level) async {
    _profile.progressLevel = level;
    await updateProfile(_profile);
  }
}
