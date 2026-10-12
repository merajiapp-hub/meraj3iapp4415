import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/competition_model.dart';
import '../../../services/admin_activity_service.dart';
import '../admin_guard.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  final Set<String> _savingIds = {};

  Future<void> _setPublished(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isPublished,
  ) async {
    setState(() => _savingIds.add(doc.id));
    final competition = CompetitionModel.fromJson(doc.id, doc.data());
    try {
      await doc.reference.update({
        'is_published': isPublished,
        'isPublished': isPublished,
        'isActive': isPublished,
        'active': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AdminActivityService.log(
        type: AdminActivityType.settingChanged,
        title: isPublished ? 'نشر نتائج مسابقة' : 'إيقاف نتائج مسابقة',
        description:
            '${isPublished ? 'تم تفعيل' : 'تم إيقاف'} نتائج ${competition.title}.',
        metadata: {'competitionId': doc.id, 'isPublished': isPublished},
      );
      if (mounted) {
        _showMessage(
          isPublished
              ? 'تم تفعيل نتائج ${competition.title}'
              : 'تم إيقاف نتائج ${competition.title}',
          Colors.green,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('تعذر تحديث النتائج: $error', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _savingIds.remove(doc.id));
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.tajawal()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(
            'إدارة نتائج المسابقات',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('competition_results')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل المسابقات: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(color: Colors.redAccent),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final aOrder = (a.data()['order'] as num?)?.toInt() ?? 999;
                final bOrder = (b.data()['order'] as num?)?.toInt() ?? 999;
                final orderComparison = aOrder.compareTo(bOrder);
                return orderComparison != 0
                    ? orderComparison
                    : a.id.compareTo(b.id);
              });

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد مسابقات في قاعدة البيانات.',
                  style: GoogleFonts.tajawal(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final competition = CompetitionModel.fromJson(
                  doc.id,
                  doc.data(),
                );
                final isPublished = competition.isPublished;
                final isSaving = _savingIds.contains(doc.id);

                return Card(
                  color: const Color(0xFF1E293B),
                  child: SwitchListTile(
                    value: isPublished,
                    onChanged: isSaving
                        ? null
                        : (value) => _setPublished(doc, value),
                    title: Text(
                      competition.title,
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${isPublished ? 'منشورة' : 'متوقفة'} • ${competition.link.isEmpty ? 'لا يوجد رابط' : competition.link}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(color: Colors.white60),
                    ),
                    secondary: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            competition.displayIcon,
                            color: isPublished
                                ? const Color(0xFF4ADE80)
                                : Colors.white38,
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
