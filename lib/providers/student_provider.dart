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
        // Also update the root user document for leaderboard querying
        await _firestore.collection('users').doc(user.uid).set({
          'points': _profile.points,
          'booksRead': _profile.booksRead,
          'completedTasks': _profile.completedTasks,
          'quizzesTaken': _profile.quizzesTaken,
          'progressLevel': _profile.progressLevel,
          'name': _profile.name, // Ensure name is synced
        }, SetOptions(merge: true));
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

  Future<void> incrementBooksRead() async {
    _profile.booksRead++;
    await calculatePointsAndUpdate();
  }

  Future<void> incrementQuizzesTaken(double score) async {
    _profile.quizzesTaken++;
    // We can add the score to points, but for now we'll just recalculate based on stats
    // A better approach is to store sum of scores, but we can do a simplified point addition
    _profile.points += score.toInt();
    await calculatePointsAndUpdate();
  }

  Future<void> incrementCompletedTasks() async {
    _profile.completedTasks++;
    await calculatePointsAndUpdate();
  }

  Future<void> updateProgressLevel(double level) async {
    _profile.progressLevel = level;
    await calculatePointsAndUpdate();
  }

  Future<void> calculatePointsAndUpdate() async {
    // Basic point calculation
    // int newPoints = 0;
    // newPoints += _profile.booksRead * 50;
    // newPoints += _profile.completedTasks * 20;
    // newPoints += _profile.quizzesTaken * 10;
    // adding existing points (from quiz scores) back in, or just relying on this formula.
    // Let's actually just update points directly from activities or here.
    // If we only rely on formula, we lose specific quiz scores unless stored.
    // So let's make points cumulative instead of recalculated from scratch.
    // We just call updateProfile.
    await updateProfile(_profile);
  }

  Future<void> addPoints(int amount) async {
    _profile.points += amount;
    await updateProfile(_profile);
  }
}

