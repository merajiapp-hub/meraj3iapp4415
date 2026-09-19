import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/admin_activity_service.dart';
import '../../../services/admin_login_activity_service.dart';
import '../../../services/admin_user_profile_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminUserDetailScreen({
    super.key,
    required this.uid,
    required this.userData,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}
class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.userData);
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (doc.exists && mounted) {
      setState(() => _data = doc.data() ?? {});
    }
  }

  Future<void> _sendPasswordReset() async {
    final profile = AdminUserProfile.fromUidAndData(widget.uid, _data);
    final email = profile.email;

    if (email == 'غير متوفر') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد بريد مرتبط بهذا الحساب. لا يمكن إرسال رابط استعادة مباشرة.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await AdminActivityService.log(
        type: AdminActivityType.passwordForced,
        title: 'استعادة كلمة المرور',
        description: 'تم إرسال رابط استعادة لك حساب المستخدم ${profile.fullName}',
        targetUserId: widget.uid,
        targetUserName: profile.fullName,
        metadata: {
          'email': email,
          'method': 'sendPasswordResetEmail',
        },
      );

      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء إجراء استعادة كلمة المرور بنجاح.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'فشل في إرسال رابط الاستعادة')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSuspension(bool suspend) async {
    final profile = AdminUserProfile.fromUidAndData(widget.uid, _data);

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'isSuspended': suspend,
        'accountStatus': suspend ? 'suspended' : 'active',
        'status': suspend ? 'suspended' : 'active',
        'suspensionReason': suspend ? 'تم التوقف من قبل الإدارة' : '',
        'reason': suspend ? 'تم التوقف من قبل الإدارة' : '',
        'suspendedAt': suspend ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'suspensionStartAt': suspend ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'suspensionEndAt': suspend ? null : FieldValue.delete(),
        'suspendedBy': suspend ? 'admin' : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await AdminActivityService.log(
        type: suspend ? AdminActivityType.userSuspended : AdminActivityType.userReactivated,
        title: suspend ? 'تعليق حساب' : 'إعادة تفعيل حساب',
        description: suspend
            ? 'تم تعليق حساب المستخدم ${profile.fullName}'
            : 'تم تفعيل حساب المستخدم ${profile.fullName}',
        targetUserId: widget.uid,
        targetUserName: profile.fullName,
      );

      await _refresh();

      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(suspend ? 'تم تعليق الحساب بنجاح' : 'تم تفعيل الحساب بنجاح')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUserAccount() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائياً؟'),
        content: const Text(
          'سيتم حذف ملف المستخدم من Firestore وإزالته من لوحة الإدارة. '
          'حذف حساب Firebase Auth نفسه من حساب إداري آخر يحتاج Cloud Functions وخطة Blaze. '
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).delete();
      const message = 'تم حذف ملف المستخدم من Firestore بنجاح';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الحساب: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _safeValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'غير متوفر';
  }

  @override
  Widget build(BuildContext context) {
    final profile = AdminUserProfile.fromUidAndData(widget.uid, _data);
    final isSuspended = _data['isSuspended'] == true || _data['accountStatus'] == 'suspended';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('تفاصيل المستخدم', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profile.photoUrl.isNotEmpty ? NetworkImage(profile.photoUrl) : null,
                            backgroundColor: Colors.teal.withValues(alpha: 0.2),
                            child: profile.photoUrl.isEmpty
                                ? Text(
                                    profile.fullName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSuspended ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isSuspended ? 'موقوف' : 'نشط',
                              style: TextStyle(
                                color: isSuspended ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _smallBadge('طريقة الدخول: ${profile.provider}'),
                              _smallBadge('تاريخ التسجيل: ${AdminUserProfile.formatDate(profile.createdAt)}'),
                              _smallBadge('آخر تسجيل دخول: ${AdminUserProfile.formatDate(profile.lastLoginAt)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoCard('المعلومات الشخصية', [
                    _infoRow(Icons.person, 'الاسم الكامل', profile.fullName),
                    _infoRow(Icons.person_2, 'اسم المستخدم', profile.username),
                    _infoRow(Icons.transgender, 'الجنس', profile.gender),
                    _infoRow(Icons.photo, 'الصورة الشخصية', profile.photoUrl.isEmpty ? 'غير متوفر' : 'متوفر'),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('معلومات تسجيل الدخول', [
                    _infoRow(Icons.email_rounded, 'البريد', profile.email),
                    _infoRow(Icons.phone_rounded, 'رقم الهاتف', profile.phone),
                    _infoRow(Icons.login_rounded, 'طريقة تسجيل الدخول', profile.provider),
                    _infoRow(Icons.fingerprint_rounded, 'UID', widget.uid),
                    _infoRow(Icons.info_rounded, 'حالة الحساب', profile.status),
                    _infoRow(Icons.calendar_today_rounded, 'تاريخ إنشاء الحساب', AdminUserProfile.formatDate(profile.createdAt)),
                    _infoRow(Icons.access_time_rounded, 'آخر تسجيل دخول', AdminUserProfile.formatDate(profile.lastLoginAt)),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('نشاط الحساب', [
                    _infoRow(Icons.history_rounded, 'آخر نشاط', _safeValue(_data, ['lastActivity', 'lastSeenAt', 'lastLoginAt'])),
                    _infoRow(Icons.event_rounded, 'تاريخ الإنشاء', _safeValue(_data, ['createdAt', 'accountCreatedAt'])),
                    _infoRow(Icons.block_rounded, 'سبب الإيقاف', _safeValue(_data, ['suspensionReason', 'reason'])),
                    _infoRow(Icons.delete_forever_rounded, 'تاريخ الإيقاف', _safeValue(_data, ['suspendedAt', 'suspensionStartAt'])),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('الأجهزة والجلسات', [
                    _infoRow(Icons.phone_android_rounded, 'الجهاز', _safeValue(_data, ['deviceName', 'deviceModel', 'device'])),
                    _infoRow(Icons.desktop_windows_rounded, 'المنصة', _safeValue(_data, ['platform', 'os', 'operatingSystem'])),
                    _infoRow(Icons.app_shortcut_rounded, 'إصدار التطبيق', _safeValue(_data, ['appVersion', 'version'])),
                    _infoRow(Icons.language_rounded, 'المتصفح', _safeValue(_data, ['browser', 'browserName'])),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('البيانات المرتبطة', [
                    _infoRow(Icons.folder_rounded, 'الملاحظات', _safeValue(_data, ['notesCount', 'notes'])),
                    _infoRow(Icons.favorite_rounded, 'المفضلة', _safeValue(_data, ['favoritesCount', 'favorites'])),
                    _infoRow(Icons.download_rounded, 'التنزيلات', _safeValue(_data, ['downloadsCount', 'downloads'])),
                    _infoRow(Icons.task_alt_rounded, 'المهام', _safeValue(_data, ['tasksCount', 'tasks'])),
                  ]),
                  const SizedBox(height: 16),
                  _loginActivitySection(profile),
                  const SizedBox(height: 16),
                  _contactSection(profile),
                  const SizedBox(height: 16),
                  _sectionTitle('إجراءات الإدارة'),
                  const SizedBox(height: 10),
                  _adminActionButton(
                    icon: Icons.copy_rounded,
                    label: 'نسخ UID',
                    color: Colors.blue,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: widget.uid));
                      if (!mounted) return;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ UID بنجاح')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.email_rounded,
                    label: 'نسخ البريد',
                    color: Colors.orange,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: profile.email == 'غير متوفر' ? '' : profile.email),
                      );
                      if (!mounted) return;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ البريد')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.phone_rounded,
                    label: 'نسخ رقم الهاتف',
                    color: Colors.green,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: profile.phone == 'غير متوفر' ? '' : profile.phone),
                      );
                      if (!mounted) return;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رقم الهاتف')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.lock_reset_rounded,
                    label: 'إرسال رابط استعادة كلمة المرور',
                    color: Colors.purple,
                    onTap: _sendPasswordReset,
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: isSuspended ? Icons.check_circle_rounded : Icons.block_rounded,
                    label: isSuspended ? 'إعادة تفعيل الحساب' : 'تعليق الحساب',
                    color: isSuspended ? Colors.green : Colors.red,
                    onTap: () => _toggleSuspension(!isSuspended),
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.delete_forever_rounded,
                    label: 'حذف الحساب نهائياً',
                    color: Colors.red,
                    onTap: _deleteUserAccount,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _loginActivitySection(AdminUserProfile profile) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'نشاط تسجيل الدخول',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_data['needsSupport'] == true)
                  const Chip(
                    avatar: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                    label: Text('يحتاج إلى مساعدة'),
                    labelStyle: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _infoRow(
              Icons.error_outline_rounded,
              'المحاولات الفاشلة المتتالية',
              '${_data['failedLoginAttempts'] ?? 0}',
            ),
            _infoRow(
              Icons.access_time_rounded,
              'آخر دخول ناجح',
              AdminLoginActivityService.formatDate(_data['lastLoginSuccessAt']),
            ),
            _infoRow(
              Icons.warning_amber_rounded,
              'آخر محاولة فاشلة',
              '${AdminLoginActivityService.formatDate(_data['lastLoginFailureAt'])} - ${AdminLoginActivityService.resultLabel((_data['lastLoginFailureReason'] ?? '').toString())}',
            ),
            const Divider(),
            StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: AdminLoginActivityService.streamForUser(widget.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Text(
                    'تعذر تحميل سجل الدخول. تحقق من فهرس Firestore أو صلاحيات الإدارة.',
                    style: TextStyle(color: Colors.orange),
                  );
                }
                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return const Text(
                    'لا توجد محاولات مسجلة لهذا الحساب.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Column(
                  children: docs.map(_loginAttemptTile).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginAttemptTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final result = (data['result'] ?? '').toString();
    final successful = result == 'success';
    final color = successful ? Colors.green : Colors.redAccent;
    final device = [data['platform'], data['deviceType'], data['deviceModel']]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' / ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(successful ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AdminLoginActivityService.resultLabel(result),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('الوقت: ${AdminLoginActivityService.formatDate(data['createdAt'])}'),
                Text('الطريقة: ${AdminLoginActivityService.methodLabel((data['method'] ?? '').toString())}'),
                if ((data['identifierMasked'] ?? '').toString().isNotEmpty)
                  Text('المعرّف: ${data['identifierMasked']}'),
                Text('الجهاز: ${device.isEmpty ? 'غير متوفر' : device}'),
                Text('الإصدار: ${data['appVersion'] ?? 'غير متوفر'}'),
                Text('المحاولات المتتالية: ${data['consecutiveFailedAttempts'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactSection(AdminUserProfile profile) {
    final hasEmail = profile.email != 'غير متوفر';
    final hasPhone = profile.phone != 'غير متوفر';
    return _infoCard('التواصل مع المستخدم', [
      if (hasPhone)
        _adminActionButton(
          icon: Icons.copy_rounded,
          label: 'نسخ رقم الهاتف',
          color: Colors.green,
          onTap: () => _copyValue(profile.phone, 'تم نسخ رقم الهاتف'),
        ),
      if (hasPhone) const SizedBox(height: 8),
      if (hasPhone)
        _adminActionButton(
          icon: Icons.chat_rounded,
          label: 'فتح WhatsApp',
          color: Colors.teal,
          onTap: () => _openWhatsApp(profile.phone),
        ),
      if (hasEmail) const SizedBox(height: 8),
      if (hasEmail)
        _adminActionButton(
          icon: Icons.email_rounded,
          label: 'إرسال بريد إلكتروني',
          color: Colors.orange,
          onTap: () => _openEmail(profile.email),
        ),
      if (!hasPhone && !hasEmail)
        const Text('لا توجد معلومات اتصال متاحة في ملف المستخدم.', style: TextStyle(color: Colors.grey)),
    ]);
  }

  Future<void> _copyValue(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/${digits.replaceFirst('+', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {'subject': 'مساعدة في تسجيل الدخول إلى MERAJ3I'});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

