import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/results_service.dart';

class FavoriteResultItem {
  final StudentResult result;
  final ExamType examType;
  final String title;

  FavoriteResultItem({
    required this.result,
    required this.examType,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
        'result': {
          'id': result.id,
          'name': result.name,
          'school': result.school,
          'center': result.center,
          'wilaya': result.wilaya,
          'score': result.score,
          'averageScore': result.averageScore,
          'status': result.status,
          'rank': result.rank,
          'nationalRank': result.nationalRank,
          'branch': result.branch,
          'rawData': result.rawData,
        },
        'examType': examType.name,
        'title': title,
      };

  factory FavoriteResultItem.fromJson(Map<String, dynamic> j) {
    final res = j['result'] as Map<String, dynamic>;
    return FavoriteResultItem(
      result: StudentResult(
        id: res['id'] ?? '',
        name: res['name'] ?? '',
        school: res['school'] ?? '',
        center: res['center'] ?? '',
        wilaya: res['wilaya'] ?? '',
        score: res['score'] != null ? (res['score'] as num).toDouble() : null,
        averageScore: res['averageScore'] != null ? (res['averageScore'] as num).toDouble() : null,
        status: res['status'] ?? 'راسب',
        rank: res['rank'] ?? '',
        nationalRank: res['nationalRank'] ?? '',
        branch: res['branch'] ?? '',
        rawData: Map<String, String>.from(res['rawData'] ?? {}),
      ),
      examType: ExamType.values.firstWhere((e) => e.name == j['examType'], orElse: () => ExamType.concours),
      title: j['title'] ?? 'نتيجة',
    );
  }
}

class FavoriteResultsProvider extends ChangeNotifier {
  static const String _key = 'favorite_results_v1';
  static const String _recentsKey = 'recent_results_v1';

  final List<FavoriteResultItem> _items = [];
  final List<FavoriteResultItem> _recents = [];

  List<FavoriteResultItem> get items => _items;
  List<FavoriteResultItem> get recents => _recents;

  FavoriteResultsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load favorites
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List decoded = jsonDecode(data);
        _items.clear();
        for (final item in decoded) {
          _items.add(FavoriteResultItem.fromJson(item));
        }
      } catch (_) {}
    }

    // Load recents
    final recentsData = prefs.getString(_recentsKey);
    if (recentsData != null) {
      try {
        final List decoded = jsonDecode(recentsData);
        _recents.clear();
        for (final item in decoded) {
          _recents.add(FavoriteResultItem.fromJson(item));
        }
      } catch (_) {}
    }
    
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> _saveRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_recents.map((e) => e.toJson()).toList());
    await prefs.setString(_recentsKey, data);
  }

  void addRecent(StudentResult result, ExamType type, String title) {
    // Remove if exists to push it to the top
    _recents.removeWhere((e) => e.result.id == result.id && e.examType == type);
    _recents.insert(0, FavoriteResultItem(result: result, examType: type, title: title));
    
    // Keep only last 10 recents
    if (_recents.length > 10) {
      _recents.removeLast();
    }
    
    _saveRecents();
    notifyListeners();
  }

  bool isFavorite(String id, ExamType type) {
    return _items.any((e) => e.result.id == id && e.examType == type);
  }

  Future<void> toggleFavorite(StudentResult result, ExamType type, String title, BuildContext context) async {
    final index = _items.indexWhere((e) => e.result.id == result.id && e.examType == type);
    if (index >= 0) {
      _items.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإزالة من المفضلة'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      _items.insert(0, FavoriteResultItem(result: result, examType: type, title: title));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإضافة إلى المفضلة'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
    notifyListeners();
    await _save();
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _save();
  }
}
