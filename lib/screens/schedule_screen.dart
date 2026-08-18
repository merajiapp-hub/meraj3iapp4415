import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_item.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // order: Saturday (6), Sunday (7), Monday (1), Tuesday (2), Wednesday (3), Thursday (4), Friday (5)
  final List<int> _weekdaysOrder = [6, 7, 1, 2, 3, 4, 5];
  final List<String> _weekdayNames = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Select today's tab by default
    int todayWeekday = DateTime.now().weekday;
    int index = _weekdaysOrder.indexOf(todayWeekday);
    if (index != -1) {
      _tabController.index = index;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = context.watch<ScheduleProvider>();
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'الجدول الأسبوعي',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B6B58), Color(0xFF13A286)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // الإحصائيات
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('مجموع الحصص', schedule.getTotalSessions().toString(), Icons.library_books),
                            _buildStatCard('إجمالي الساعات', schedule.getTotalHours().toStringAsFixed(1), Icons.schedule),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                tabs: _weekdayNames.map((name) => Tab(text: name)).toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _weekdaysOrder.map((weekday) {
            final items = schedule.getItemsForDay(weekday);
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد حصص في هذا اليوم',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildScheduleItem(items[index], isDark, schedule);
              },
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(_weekdaysOrder[_tabController.index]),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleItem item, bool isDark, ScheduleProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(color: item.color, width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.book, color: item.color),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (item.teacher != null && item.teacher!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'الأستاذ: ${item.teacher}',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (item.room != null && item.room!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.room, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'القاعة: ${item.room}',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${item.startTime.format(context)} - ${item.endTime.format(context)}',
                  style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        onLongPress: () {
          // Edit or Delete option
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('خيارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Text('ماذا تريد أن تفعل؟', style: GoogleFonts.cairo()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    provider.removeItem(item);
                  },
                  child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddItemDialog(int selectedWeekday) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final teacherController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('إضافة للجدول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'المادة / المهمة',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'التفاصيل (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: teacherController,
                          decoration: InputDecoration(
                            labelText: 'الأستاذ',
                            labelStyle: GoogleFonts.cairo(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: roomController,
                          decoration: InputDecoration(
                            labelText: 'القاعة',
                            labelStyle: GoogleFonts.cairo(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.room_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('وقت البداية:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: startTime);
                          if (time != null) setStateBuilder(() => startTime = time);
                        },
                        child: Text(startTime.format(context), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('وقت النهاية:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: endTime);
                          if (time != null) setStateBuilder(() => endTime = time);
                        },
                        child: Text(endTime.format(context), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;

                  final newItem = ScheduleItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    weekday: selectedWeekday,
                    startTime: startTime,
                    endTime: endTime,
                    color: AppTheme.primaryColor,
                    teacher: teacherController.text.trim(),
                    room: roomController.text.trim(),
                  );

                  context.read<ScheduleProvider>().addItem(newItem);
                  Navigator.pop(ctx);
                },
                child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
