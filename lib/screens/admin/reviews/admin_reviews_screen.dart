import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedStars = 0;
  String _sort = 'newest';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtered(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final filtered = docs.where((doc) {
      final data = doc.data();
      final name = (data['userName'] ?? '').toString().toLowerCase();
      final email = (data['userEmail'] ?? data['email'] ?? '').toString().toLowerCase();
      final uid = (data['uid'] ?? doc.id).toString().toLowerCase();
      final phone = (data['userPhone'] ?? data['phone'] ?? '').toString().toLowerCase();
      final search = _query.toLowerCase();
      final ratingMatches = _selectedStars == 0 || ((data['rating'] ?? 0) as num).round() == _selectedStars;
      return ratingMatches &&
          (search.isEmpty ||
              name.contains(search) ||
              email.contains(search) ||
              uid.contains(search) ||
              phone.contains(search));
    }).toList();

    filtered.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aTime = (aData['createdAt'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0;
      final bTime = (bData['createdAt'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0;
      final aRating = ((aData['rating'] ?? 0) as num).toDouble();
      final bRating = ((bData['rating'] ?? 0) as num).toDouble();
      switch (_sort) {
        case 'highest':
          return bRating.compareTo(aRating);
        case 'lowest':
          return aRating.compareTo(bRating);
        case 'newest':
        default:
          return bTime.compareTo(aTime);
      }
    });

    return filtered;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('آراء المستخدمين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم / البريد / UID / الهاتف',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: _query.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ) : null,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 0),
                      ...List.generate(5, (index) => index + 1).map((star) => _buildFilterChip('$star نجوم', star)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sort,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                    DropdownMenuItem(value: 'highest', child: Text('الأعلى')),
                    DropdownMenuItem(value: 'lowest', child: Text('الأقل')),
                  ],
                  onChanged: (value) => setState(() => _sort = value ?? 'newest'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('reviews').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final filtered = _filtered(docs);

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد تقييمات', style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final rating = ((data['rating'] ?? 0) as num).toDouble();
                    final userName = (data['userName'] ?? 'مستخدم').toString();
                    final email = (data['userEmail'] ?? data['email'] ?? '').toString();
                    final phone = (data['userPhone'] ?? data['phone'] ?? '').toString();
                    final uid = (data['uid'] ?? doc.id).toString();
                    final comment = (data['text'] ?? '').toString();
                    final timestamp = (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal.withValues(alpha: 0.2),
                                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(email.isNotEmpty ? email : 'بدون بريد', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (comment.isNotEmpty)
                              Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metaChip('UID', uid),
                                if (phone.isNotEmpty) _metaChip('الهاتف', phone),
                                _metaChip('التاريخ', intl.DateFormat('dd/MM/yyyy', 'ar').format(timestamp)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Clipboard.setData(ClipboardData(text: uid)),
                                    child: Text('نسخ UID', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Clipboard.setData(ClipboardData(text: email)),
                                    child: Text('نسخ البريد', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Clipboard.setData(ClipboardData(text: phone)),
                                    child: Text('نسخ الهاتف', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int stars) {
    final selected = _selectedStars == stars;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.amber.withValues(alpha: 0.25),
        labelStyle: TextStyle(color: selected ? Colors.amber : Colors.grey, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF1E1E1E),
        onSelected: (_) => setState(() => _selectedStars = stars),
      ),
    );
  }

  Widget _metaChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$title: $value', style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}
