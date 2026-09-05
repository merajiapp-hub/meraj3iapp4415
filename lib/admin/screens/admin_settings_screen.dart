import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isMaintenance = false;
  final _maintenanceMessageController = TextEditingController();
  
  Map<String, bool> _featureFlags = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final maintenanceDoc = await _firestore.collection('app_settings').doc('maintenance').get();
      final featureDoc = await _firestore.collection('admin_settings').doc('feature_flags').get();

      if (maintenanceDoc.exists) {
        _isMaintenance = maintenanceDoc.data()?['isMaintenance'] ?? false;
        _maintenanceMessageController.text = maintenanceDoc.data()?['message'] ?? '';
      }

      if (featureDoc.exists && featureDoc.data() != null) {
        final Map<String, dynamic> data = featureDoc.data()!;
        _featureFlags = {
          'ai_enabled': data['ai_enabled'] ?? true,
          'competition_enabled': data['competition_enabled'] ?? true,
          'books_upload_enabled': data['books_upload_enabled'] ?? true,
          'quizzes_enabled': data['quizzes_enabled'] ?? true,
          'results_enabled': data['results_enabled'] ?? true,
        };
      } else {
        _featureFlags = {
          'ai_enabled': true,
          'competition_enabled': true,
          'books_upload_enabled': true,
          'quizzes_enabled': true,
          'results_enabled': true,
        };
      }
    } catch (e) {
      _showSnackBar('خطأ في تحميل الإعدادات: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMaintenanceSettings() async {
    try {
      await _firestore.collection('app_settings').doc('maintenance').set({
        'isMaintenance': _isMaintenance,
        'message': _maintenanceMessageController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _firestore.collection('admin_activity').add({
        'action': _isMaintenance ? 'تفعيل وضع الصيانة' : 'إيقاف وضع الصيانة',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      _showSnackBar('تم حفظ إعدادات الصيانة بنجاح');
    } catch (e) {
      _showSnackBar('خطأ في الحفظ: $e', isError: true);
    }
  }

  Future<void> _saveFeatureFlags() async {
    try {
      await _firestore.collection('admin_settings').doc('feature_flags').set(_featureFlags, SetOptions(merge: true));
      
      await _firestore.collection('admin_activity').add({
        'action': 'تحديث ميزات التطبيق',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      _showSnackBar('تم حفظ إعدادات الميزات بنجاح');
    } catch (e) {
      _showSnackBar('خطأ في الحفظ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات النظام والصيانة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          
          // Maintenance Mode Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'وضع الصيانة (Maintenance Mode)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _isMaintenance,
                      onChanged: (val) {
                        setState(() => _isMaintenance = val);
                      },
                      activeThumbColor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'عند تفعيل وضع الصيانة، لن يتمكن المستخدمون العاديون من الوصول إلى التطبيق وستظهر لهم شاشة الصيانة. سيتمكن المديرون من الوصول إلى لوحة الإدارة لإلغاء هذا الوضع.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maintenanceMessageController,
                  decoration: const InputDecoration(
                    labelText: 'رسالة الصيانة التي تظهر للمستخدم',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveMaintenanceSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                  child: const Text('حفظ إعدادات الصيانة'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feature Flags Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ميزات التطبيق (Feature Flags)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._featureFlags.entries.map((entry) => SwitchListTile(
                  title: Text(_getFeatureName(entry.key)),
                  value: entry.value,
                  onChanged: (val) {
                    setState(() {
                      _featureFlags[entry.key] = val;
                    });
                  },
                )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveFeatureFlags,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                  child: const Text('حفظ الميزات'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureName(String key) {
    switch(key) {
      case 'ai_enabled': return 'المساعد الذكي (AI)';
      case 'competition_enabled': return 'المسابقات';
      case 'books_upload_enabled': return 'رفع الكتب';
      case 'quizzes_enabled': return 'الاختبارات';
      case 'results_enabled': return 'النتائج';
      default: return key;
    }
  }
}
