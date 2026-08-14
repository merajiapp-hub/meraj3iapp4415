import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_item.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'الجدول الدراسي',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
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
              ),
            ),
          ),
          
          // ── Calendar ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TableCalendar<ScheduleItem>(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'شهر',
                  CalendarFormat.week: 'أسبوع',
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  formatButtonDecoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: GoogleFonts.cairo(),
                  weekendTextStyle: GoogleFonts.cairo(color: Colors.red),
                ),
              ),
            ),
          ),

          // ── Schedule List ──────────────────────────────────────────
          Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              final items = provider.getItemsForDay(_selectedDay!);
              
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد مهام أو حصص في هذا اليوم',
                          style: GoogleFonts.cairo(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _buildScheduleItem(item, isDark, provider);
                  },
                  childCount: items.length,
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom nav padding
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
          child: Icon(
            item.isCompleted ? Icons.check_circle : Icons.schedule,
            color: item.color,
          ),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat.jm('ar').format(item.startTime)} - ${DateFormat.jm('ar').format(item.endTime)}',
                  style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            item.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            color: item.isCompleted ? AppTheme.primaryColor : Colors.grey,
          ),
          onPressed: () => provider.toggleItemCompletion(item),
        ),
        onLongPress: () {
          // Delete option
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('حذف المهمة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Text('هل تريد بالتأكيد حذف هذه المهمة؟', style: GoogleFonts.cairo()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                TextButton(
                  onPressed: () {
                    provider.removeItem(item);
                    Navigator.pop(ctx);
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

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'التفاصيل (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                        child: Text(startTime.format(context)),
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
                        child: Text(endTime.format(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  
                  final day = _selectedDay ?? _focusedDay;
                  final startDateTime = DateTime(day.year, day.month, day.day, startTime.hour, startTime.minute);
                  final endDateTime = DateTime(day.year, day.month, day.day, endTime.hour, endTime.minute);

                  final newItem = ScheduleItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    startTime: startDateTime,
                    endTime: endDateTime,
                    color: AppTheme.primaryColor,
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
