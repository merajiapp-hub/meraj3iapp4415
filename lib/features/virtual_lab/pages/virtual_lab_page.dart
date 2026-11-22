import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../models/experiment_model.dart';
import '../providers/virtual_lab_provider.dart';
import '../services/virtual_lab_service.dart';
import '../widgets/experiment_card.dart';

class VirtualLabPage extends StatelessWidget {
  const VirtualLabPage({super.key});

  static const List<String> gradeLevels = [
    'all',
    '3AS',
    '4AS',
    'Terminale',
    'BAC D',
    'BAC C',
    '6AF',
  ];

  String _formatGradeName(String code) {
    switch (code) {
      case 'all':
        return 'الكل';
      case '3AS':
        return '3 إعدادية (3AS)';
      case '4AS':
        return '4 إعدادية (Brevet)';
      case 'Terminale':
        return 'السنة الختامية';
      case 'BAC D':
        return 'باك علمي (D)';
      case 'BAC C':
        return 'باك رياضي (C)';
      case '6AF':
        return '6 سادسة أساسي';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VirtualLabProvider>(
      create: (_) => VirtualLabProvider(),
      child: const _VirtualLabView(),
    );
  }
}

class _VirtualLabView extends StatefulWidget {
  const _VirtualLabView();

  @override
  State<_VirtualLabView> createState() => _VirtualLabViewState();
}

class _VirtualLabViewState extends State<_VirtualLabView> {
  final _searchCtrl = TextEditingController();
  final _service = VirtualLabService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF070F18) : const Color(0xFFF8FAFC);
    final labProvider = context.watch<VirtualLabProvider>();
    final user = context.watch<AuthProvider>().user;
    final isUserPro = context.watch<AuthProvider>().isPro;

    return Scaffold(
      backgroundColor: bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<List<ExperimentModel>>(
          stream: _service.streamExperiments(),
          initialData: VirtualLabService.defaultExperiments,
          builder: (context, snapshot) {
            final allExperiments = snapshot.data ?? VirtualLabService.defaultExperiments;
            final filtered = labProvider.filterExperiments(allExperiments);
            final progress = labProvider.progress;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── شريط الرأس الاحترافي ─────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 180,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.science_rounded, color: Color(0xFF34D399), size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المختبر الافتراضي 3D',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'تجارب الفيزياء والكيمياء التفاعلية الحية',
                                        style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── ملخص إنجازات الطالب وشريط البحث ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        // بطاقة إحصائيات الإنجاز
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131D2E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'تجارب مكتملة',
                                '${progress.completedExperiments.length} / ${allExperiments.length}',
                                Icons.verified_rounded,
                                const Color(0xFF10B981),
                                isDark,
                              ),
                              _buildStatItem(
                                'الوقت في المختبر',
                                '${progress.totalMinutesSpent} دقيقة',
                                Icons.timer_rounded,
                                const Color(0xFF3B82F6),
                                isDark,
                              ),
                              _buildStatItem(
                                'العضوية',
                                isUserPro ? 'PRO 👑' : 'عادي (Free)',
                                Icons.workspace_premium_rounded,
                                const Color(0xFFF59E0B),
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // حقل البحث الذكي
                        TextField(
                          controller: _searchCtrl,
                          onChanged: labProvider.setSearchQuery,
                          style: GoogleFonts.tajawal(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن تجربة، تفاعل، أو قانون علمي...',
                            hintStyle: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      labProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF131D2E) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // أزرار تصفية المادة (كيمياء، فيزياء)
                        Row(
                          children: [
                            _buildSubjectFilterChip(
                              label: 'جميع المواد',
                              value: 'all',
                              icon: Icons.science_rounded,
                              isSelected: labProvider.selectedSubject == 'all',
                              onTap: () => labProvider.setSubject('all'),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildSubjectFilterChip(
                              label: 'الكيمياء ⚗️',
                              value: 'chemistry',
                              icon: Icons.biotech_rounded,
                              isSelected: labProvider.selectedSubject == 'chemistry',
                              onTap: () => labProvider.setSubject('chemistry'),
                              isDark: isDark,
                              activeColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            _buildSubjectFilterChip(
                              label: 'الفيزياء ⚡',
                              value: 'physics',
                              icon: Icons.offline_bolt_rounded,
                              isSelected: labProvider.selectedSubject == 'physics',
                              onTap: () => labProvider.setSubject('physics'),
                              isDark: isDark,
                              activeColor: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // شريط تصفية المستويات الدراسية والشعب
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: VirtualLabPage.gradeLevels.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final grade = VirtualLabPage.gradeLevels[idx];
                              final isSelected = labProvider.selectedGrade == grade;
                              return InkWell(
                                onTap: () => labProvider.setGrade(grade),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF312E81)
                                        : (isDark ? const Color(0xFF131D2E) : Colors.white),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF818CF8)
                                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      VirtualLabPage()._formatGradeName(grade),
                                      style: GoogleFonts.tajawal(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── شبكة كروت التجارب ─────────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.science_outlined, size: 54, color: isDark ? Colors.white38 : Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'لم يتم العثور على تجارب مطابقة للبحث أو التصفية',
                            style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final exp = filtered[index];
                          final isCompleted = progress.isCompleted(exp.id);
                          final score = progress.getScore(exp.id);

                          return ExperimentCard(
                            experiment: exp,
                            isCompleted: isCompleted,
                            score: score,
                            isUserPro: isUserPro,
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSubjectFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color activeColor = const Color(0xFF6366F1),
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : (isDark ? const Color(0xFF131D2E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
