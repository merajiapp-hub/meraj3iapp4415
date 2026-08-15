import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_profile.dart';

class StudentProvider with ChangeNotifier {
  StudentProfile _profile = StudentProfile(
    name: 'طالب متميز',
    grade: 'السنة الثالثة ثانوي',
    department: 'علوم تجريبية',
    school: 'ثانوية النجاح',
  );

  StudentProfile get profile => _profile;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
    
    // المزامنة التلقائية مع Firestore إذا كان المستخدم مسجلاً الدخول
    _syncWithFirestore();
  }

  Future<void> _syncWithFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).collection('data').doc('profile').get();
        if (doc.exists && doc.data() != null) {
          // دمج البيانات من Firestore (Firestore هو المصدر الأساسي)
          _profile = StudentProfile.fromMap(doc.data()!);
          notifyListeners();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_profile', _profile.toJson());
        }
      } catch (e) {
        debugPrint('Error syncing profile with Firestore: $e');
      }
    }
  }

  Future<void> updateProfile(StudentProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_profile', _profile.toJson());

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('data').doc('profile').set(
          _profile.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Error updating profile in Firestore: $e');
      }
    }
  }

  Future<void> updateField(String field, dynamic value) async {
    final map = _profile.toMap();
    map[field] = value;
    _profile = StudentProfile.fromMap(map);
    await updateProfile(_profile);
  }

  // يمكن الإبقاء على هذه الوظائف لكن يفضل الاعتماد على StatisticsProvider
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

