import 'package:flutter/material.dart';
import '../models/experiment_model.dart';
import '../models/lab_progress_model.dart';
import '../services/virtual_lab_service.dart';

class VirtualLabProvider extends ChangeNotifier {
  final VirtualLabService _service = VirtualLabService();

  String _selectedGrade = 'all';
  String _selectedSubject = 'all'; // 'all', 'chemistry', 'physics'
  String _searchQuery = '';
  LabProgress _progress = const LabProgress();
  bool _isLoading = true;

  String get selectedGrade => _selectedGrade;
  String get selectedSubject => _selectedSubject;
  String get searchQuery => _searchQuery;
  LabProgress get progress => _progress;
  bool get isLoading => _isLoading;

  VirtualLabProvider() {
    loadProgress();
  }

  Future<void> loadProgress([String? userId]) async {
    _isLoading = true;
    notifyListeners();
    _progress = await _service.getProgress(userId);
    _isLoading = false;
    notifyListeners();
  }

  void setGrade(String grade) {
    if (_selectedGrade != grade) {
      _selectedGrade = grade;
      notifyListeners();
    }
  }

  void setSubject(String subject) {
    if (_selectedSubject != subject) {
      _selectedSubject = subject;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> completeExperiment({
    required String? userId,
    required String experimentId,
    int? quizScore,
  }) async {
    await _service.saveExperimentCompleted(
      userId: userId,
      experimentId: experimentId,
      quizScore: quizScore,
    );
    await loadProgress(userId);
  }

  List<ExperimentModel> filterExperiments(List<ExperimentModel> all) {
    return all.where((exp) {
      if (!exp.isPublished) return false;

      // تصفية الشعبة والمستوى
      if (_selectedGrade != 'all') {
        if (!exp.gradeLevels.contains(_selectedGrade)) return false;
      }

      // تصفية المادة
      if (_selectedSubject != 'all') {
        if (exp.subject != _selectedSubject) return false;
      }

      // تصفية البحث
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = exp.title.toLowerCase().contains(q);
        final matchTitleFr = exp.titleFr.toLowerCase().contains(q);
        final matchDesc = exp.description.toLowerCase().contains(q);
        final matchFormula = exp.chemicalFormula?.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchTitleFr && !matchDesc && !matchFormula) return false;
      }

      return true;
    }).toList();
  }
}
