import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_item.dart';


class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  int _currentIndex = 2; // Default to Today's Tasks (Target)

  final List<String> _tabTitles = [
    'تحليل الوقت والمواد',
    'جميع المراجعات المجدولة',
    'مهام اليوم',
    'الجدول العام',
  ];

  final List<String> _tabEmojis = ['📊', '📚', '🎯', '🗓️'];

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'الإثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: return 'الجمعة';
      case 6: return 'السبت';
      case 7: return 'الأحد';
      default: return '';
    }
  }

  void _showAddSessionModal(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    int selectedDay = DateTime.now().weekday;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تفاصيل المراجعة',
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0284C7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text('المادة / العنوان', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'مثال: رياضيات - الدوال',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 16),
                    Text('اليوم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedDay,
                          isExpanded: true,
                          items: List.generate(7, (index) {
                            int day = index + 1; // 1 to 7
                            return DropdownMenuItem(value: day, child: Text(_getDayName(day), style: GoogleFonts.tajawal()));
                          }),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedDay = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('البدء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: startTime);
                                  if (time != null) setModalState(() => startTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(startTime.format(context), style: GoogleFonts.tajawal()),
                                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الانتهاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: endTime);
                                  if (time != null) setModalState(() => endTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(endTime.format(context), style: GoogleFonts.tajawal()),
                                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('ملاحظات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'مثال: حل تمارين صفحة 40',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (titleController.text.isNotEmpty) {
                                final provider = Provider.of<ScheduleProvider>(context, listen: false);
                                provider.addItem(ScheduleItem(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: titleController.text,
                                  description: notesController.text,
                                  weekday: selectedDay,
                                  startTime: startTime,
                                  endTime: endTime,
                                  color: Colors.blue, // Default color
                                ));
                                Navigator.pop(ctx);
                              }
                            },
                            child: Text('حفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('إلغاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF64748B))),
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
    );
  }

  Widget _buildTabIcon(int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFEF9C3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(_tabEmojis[index], style: const TextStyle(fontSize: 26)),
          ),
          if (isActive)
            Positioned(
              bottom: 4,
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle),
              ),
            ),
          if (isActive && index == 3) // Only show dark tooltip for calendar
            Positioned(
              bottom: -36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tabTitles[index],
                  style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return Column(
      children: [
        Text(
          _tabTitles[0],
          style: GoogleFonts.tajawal(color: const Color(0xFF0284C7), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 350,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              RotatedBox(
                quarterTurns: 3,
                child: Text('لا بيانات', style: GoogleFonts.tajawal(color: Colors.grey.shade400, fontSize: 16)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'توزيع ساعات المراجعة حسب المادة (نسبة مئوية)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildAdviceCard(),
      ],
    );
  }

  Widget _buildAllReviewsTab(ScheduleProvider provider) {
    bool hasItems = false;
    for (int i = 1; i <= 7; i++) {
      if (provider.getItemsForDay(i).isNotEmpty) {
        hasItems = true;
        break;
      }
    }

    return Column(
      children: [
        Text(
          _tabTitles[1],
          style: GoogleFonts.tajawal(color: const Color(0xFF0284C7), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (!hasItems)
          Text('الجدول فارغ.', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('هناك مراجعات مجدولة.', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14)),
          ),
        const SizedBox(height: 32),
        _buildAdviceCard(),
      ],
    );
  }

  Widget _buildTodayTasksTab(ScheduleProvider provider) {
    int today = DateTime.now().weekday;
    final todayItems = provider.getItemsForDay(today);

    return Column(
      children: [
        Text(
          _tabTitles[2],
          style: GoogleFonts.tajawal(color: const Color(0xFF0284C7), fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'اليوم هو: ${_getDayName(today)} (تأكد من إضافة مهام لهذا اليوم)',
          style: GoogleFonts.tajawal(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 32),
        if (todayItems.isEmpty)
          Text('لا توجد مراجعات مجدولة لهذا اليوم.', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: todayItems.length,
            itemBuilder: (ctx, i) {
              final item = todayItems[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, color: item.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (item.description.isNotEmpty) Text(item.description, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${item.startTime.format(context)} - ${item.endTime.format(context)}', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 32),
        _buildAdviceCard(),
      ],
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE047), width: 1.5),
      ),
      child: Column(
        children: [
          Text('ابدأ بالأصعب في الصباح.', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF334155))),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD97706)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text('نصيحة أخرى', style: GoogleFonts.tajawal(color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(ScheduleProvider provider) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAddSessionModal(context),
          child: Container(
            margin: const EdgeInsets.only(top: 24, bottom: 24, left: 40, right: 40),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFCA8A04),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFFCA8A04).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white),
                const SizedBox(width: 8),
                Text('إضافة حصة مراجعة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  children: [
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('الثلاثاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)))))),
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('الإثنين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)))))),
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('الأحد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)))))),
                    Container(width: 1, height: 40, color: const Color(0xFFD97706)),
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('الوقت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)))))),
                  ],
                ),
              ),
              for (int h = 5; h <= 12; h++)
                Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      Expanded(child: Container()),
                      Expanded(child: Container()),
                      Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade100))))),
                      Container(width: 1, height: 50, color: const Color(0xFFD97706)),
                      Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('${h.toString().padLeft(2, '0')}:00', style: GoogleFonts.tajawal(color: const Color(0xFF475569), fontWeight: FontWeight.bold))))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('منظم الوقت والمهام', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('نظم وقتك، حقق أهدافك', style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 170, left: 24, right: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabIcon(0),
                      _buildTabIcon(1),
                      _buildTabIcon(2),
                      _buildTabIcon(3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Positioned.fill(
            top: 260,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  if (_currentIndex == 0) _buildAnalysisTab(),
                  if (_currentIndex == 1) _buildAllReviewsTab(scheduleProvider),
                  if (_currentIndex == 2) _buildTodayTasksTab(scheduleProvider),
                  if (_currentIndex == 3) _buildScheduleTab(scheduleProvider),
                  
                  const SizedBox(height: 40),
                  Text('جميع الحقوق محفوظة مراجعي 2025 ©', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40, right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
