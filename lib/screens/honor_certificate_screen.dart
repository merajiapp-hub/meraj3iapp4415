import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HonorCertificateScreen extends StatelessWidget {
  const HonorCertificateScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('شهادة التقدير')),
      body: uid == null
          ? const Center(child: Text('سجّل الدخول لعرض الشهادة.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('student_certificates')
                  .doc(certificateId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل الشهادة. حاول مجددًا.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doc = snapshot.data!;
                if (!doc.exists || doc.data()?['userId'] != uid) {
                  return const Center(
                    child: Text('هذه الشهادة غير موجودة أو لا تخص حسابك.'),
                  );
                }
                return _CertificateCard(data: doc.data()!);
              },
            ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final issuedAt = data['issuedAt'];
    final issuedDate = issuedAt is Timestamp
        ? DateFormat('yyyy/MM/dd').format(issuedAt.toDate())
        : '—';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFC69C3F),
                  Color(0xFFF6E6A8),
                  Color(0xFFC69C3F),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8D49A), width: 2),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 64,
                    color: Color(0xFFC69C3F),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MERAJ3I',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF0A6570),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data['title']?.toString() ?? 'شهادة تقدير',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF18334B),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تُمنح هذه الشهادة إلى',
                    style: GoogleFonts.tajawal(
                      color: Colors.blueGrey.shade700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['userName']?.toString() ?? 'الطالب',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF0A6570),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data['achievement']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF334155),
                      height: 1.8,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (data['quizTitle'] != null)
                    Text(
                      'الاختبار: ${data['quizTitle']}  •  النتيجة المسجلة: ${data['score'] ?? 0}%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        color: Colors.blueGrey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE8D49A)),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 12,
                    spacing: 24,
                    children: [
                      Text(
                        'رقم الشهادة: ${data['certificateNumber'] ?? '—'}',
                        style: GoogleFonts.tajawal(
                          color: Colors.blueGrey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'تاريخ الإصدار: $issuedDate',
                        style: GoogleFonts.tajawal(
                          color: Colors.blueGrey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'إدارة MERAJ3I',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF0A6570),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
