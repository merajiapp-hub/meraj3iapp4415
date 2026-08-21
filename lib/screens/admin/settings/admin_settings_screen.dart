import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  // Feature Flags (from Firestore admin_settings)
  Map<String, bool> _featureFlags = {};
  bool _maintenanceMode = false;
  bool _loadingFlags = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingFlags = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('feature_flags')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _featureFlags = {
            'ai_enabled': data['ai_enabled'] == true,
            'competition_enabled': data['competition_enabled'] == true,
            'books_upload_enabled': data['books_upload_enabled'] == true,
            'quizzes_enabled': data['quizzes_enabled'] == true,
            'results_enabled': data['results_enabled'] == true,
          };
          _maintenanceMode = data['maintenance_mode'] == true;
        });
      } else {
        // Defaults
        setState(() {
          _featureFlags = {
            'ai_enabled': true,
            'competition_enabled': true,
            'books_upload_enabled': true,
            'quizzes_enabled': true,
            'results_enabled': true,
          };
          _maintenanceMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تحميل الإعدادات: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingFlags = false);
    }
  }

  Future<void> _saveFlags() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        ..._featureFlags,
        'maintenance_mode': _maintenanceMode,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Validate before saving
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('feature_flags')
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم حفظ الإعدادات بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في الحفظ: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleMaintenance(bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('⚠️ تفعيل وضع الصيانة',
              style: TextStyle(color: Colors.white)),
          content: const Text(
              'سيؤثر ذلك على جميع المستخدمين. هل أنت متأكد؟',
              style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.grey))),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _maintenanceMode = true);
                },
                child: const Text('تفعيل',
                    style: TextStyle(color: Colors.orange))),
          ],
        ),
      );
    } else {
      setState(() => _maintenanceMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('إعدادات النظام',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.grey,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'الميزات'),
            Tab(text: 'الصيانة'),
            Tab(text: 'أدوات'),
          ],
        ),
      ),
      body: _loadingFlags
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeatureFlagsTab(),
                _buildMaintenanceTab(),
                _buildAdvancedToolsTab(),
              ],
            ),
    );
  }

  Widget _buildFeatureFlagsTab() {
    final flagLabels = {
      'ai_enabled': {'label': 'MERAJ3I AI', 'icon': Icons.psychology},
      'competition_enabled': {'label': 'التنافس', 'icon': Icons.emoji_events},
      'books_upload_enabled': {'label': 'رفع الكتب', 'icon': Icons.upload_file},
      'quizzes_enabled': {'label': 'الاختبارات', 'icon': Icons.quiz},
      'results_enabled': {'label': 'النتائج', 'icon': Icons.bar_chart},
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'يمكنك تفعيل أو تعطيل الميزات دون تحديث التطبيق.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ..._featureFlags.entries.map((entry) {
          final info = flagLabels[entry.key];
          return Card(
            color: const Color(0xFF1E1E1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 10),
            child: SwitchListTile(
              activeThumbColor: Colors.tealAccent,
              secondary: Icon(
                info?['icon'] as IconData? ?? Icons.toggle_on,
                color:
                    entry.value ? Colors.tealAccent : Colors.grey,
              ),
              title: Text(
                info?['label'] as String? ?? entry.key,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                entry.value ? '🟢 مفعّل' : '🔴 معطّل',
                style: TextStyle(
                    color: entry.value ? Colors.green : Colors.red,
                    fontSize: 12),
              ),
              value: entry.value,
              onChanged: (v) =>
                  setState(() => _featureFlags[entry.key] = v),
            ),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(
                _isSaving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _isSaving ? null : _saveFlags,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: _maintenanceMode
              ? Colors.orange.withValues(alpha: 0.15)
              : const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.engineering,
                  size: 60,
                  color: _maintenanceMode ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  _maintenanceMode ? '⚠️ وضع الصيانة مفعّل' : 'وضع الصيانة معطّل',
                  style: TextStyle(
                    color: _maintenanceMode ? Colors.orange : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _maintenanceMode
                      ? 'المستخدمون الآن يرون شاشة الصيانة ولا يمكنهم استخدام التطبيق.'
                      : 'التطبيق يعمل بشكل طبيعي لجميع المستخدمين.',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _maintenanceMode
                          ? Colors.green
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_maintenanceMode
                        ? Icons.check_circle
                        : Icons.warning),
                    label: Text(
                      _maintenanceMode
                          ? 'إيقاف وضع الصيانة'
                          : 'تفعيل وضع الصيانة',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () =>
                        _toggleMaintenance(!_maintenanceMode),
                  ),
                ),
                if (_maintenanceMode) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveFlags,
                      child: const Text('حفظ وتطبيق الآن',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildAdvancedToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'أدوات متقدمة لتحديث النظام وحماية البيانات.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // Shorebird
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.system_update_alt, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('تحديثات Shorebird (OTA)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                    'يتطلب تفعيل تحديثات الهواء (OTA) إعداد حساب Shorebird وتنفيذ الأمر "shorebird init" من الـ Terminal الخاص بالمطور.',
                    style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('قم بتنفيذ shorebird release android من سطر الأوامر'),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تعليمات التحديث'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Backup
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_sync, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('النسخ الاحتياطي للبيانات',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                    'يتطلب أخذ نسخة احتياطية إعداد Google Cloud Storage Bucket وإعطاء صلاحيات IAM في مشروع Firebase لتشغيل Cloud Function للنسخ.',
                    style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('ميزة النسخ الاحتياطي الآلي قيد التطوير'),
                        backgroundColor: Colors.orange,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      foregroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('بدء النسخ الاحتياطي (قريباً)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
