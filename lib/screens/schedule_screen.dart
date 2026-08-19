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
  // order: Saturday (6), Sunday (7), Monday (1), Tuesday (2), Wednesday (3), Thursday (4), Friday (5)
  final List<int> _weekdaysOrder = [6, 7, 1, 2, 3, 4, 5];
  final List<String> _weekdayNames = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    int todayWeekday = DateTime.now().weekday;
    if (_weekdaysOrder.contains(todayWeekday)) {
      _selectedDay = todayWeekday;
    } else {
      _selectedDay = _weekdaysOrder[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = context.watch<ScheduleProvider>();
    final todayItems = schedule.getItemsForDay(_selectedDay);
    
    // Calculate today's stats
    int todaySessions = todayItems.length;
    double todayHours = 0;
    for (var item in todayItems) {
      final start = item.startTime.hour * 60 + item.startTime.minute;
      final end = item.endTime.hour * 60 + item.endTime.minute;
      int diff = end - start;
      if (diff < 0) diff += 24 * 60;
      todayHours += diff / 60.0;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('الجدول الدراسي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // البطاقة العلوية للإحصائيات
          _buildTopStatsCard(todaySessions, todayHours, isDark),
          
          const SizedBox(height: 24),
          
          // أيام الأسبوع (دوائر / أزرار متجاورة)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _weekdaysOrder.length,
              itemBuilder: (context, index) {
                final dayNum = _weekdaysOrder[index];
                final dayName = _weekdayNames[index];
                final isSelected = _selectedDay == dayNum;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = dayNum),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(left: 12),
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: Border.all(
                        color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey[200]!),
                      )
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName.substring(0, 3), // e.g. "السب" -> could just be the name
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // قائمة الحصص
          Expanded(
            child: todayItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد حصص مبرمجة في هذا اليوم',
                          style: GoogleFonts.tajawal(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                    itemCount: todayItems.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleItemCard(todayItems[index], isDark, schedule);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(_selectedDay),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTopStatsCard(int sessions, double hours, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('الحصص اليوم', '$sessions', Icons.auto_stories_rounded),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem('ساعات الدراسة', hours.toStringAsFixed(1), Icons.timer_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.tajawal(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item, bool isDark, ScheduleProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onLongPress: () => _showEditOrDeleteDialog(item, provider),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // مؤشر لوني على اليمين
                Container(
                  width: 6,
                  height: 80,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                
                // تفاصيل الحصة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.startTime.format(context)} - ${item.endTime.format(context)}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (item.teacher != null && item.teacher!.isNotEmpty) ...[
                            Icon(Icons.person_rounded, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.teacher!,
                                style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (item.room != null && item.room!.isNotEmpty) ...[
                            Icon(Icons.room_rounded, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              item.room!,
                              style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditOrDeleteDialog(ScheduleItem item, ScheduleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text('حذف الحصة', style: GoogleFonts.tajawal(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.removeItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text('إلغاء', style: GoogleFonts.tajawal()),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemDialog(int selectedWeekday) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final teacherController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.backgroundDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إضافة حصة جديدة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'المادة / المهمة',
                      labelStyle: GoogleFonts.tajawal(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: teacherController,
                          decoration: InputDecoration(
                            labelText: 'الأستاذ',
                            labelStyle: GoogleFonts.tajawal(),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: roomController,
                          decoration: InputDecoration(
                            labelText: 'القاعة',
                            labelStyle: GoogleFonts.tajawal(),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: const Icon(Icons.room_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات',
                      labelStyle: GoogleFonts.tajawal(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerBox(
                          title: 'من',
                          time: startTime,
                          isDark: isDark,
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: startTime);
                            if (time != null) setStateBuilder(() => startTime = time);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePickerBox(
                          title: 'إلى',
                          time: endTime,
                          isDark: isDark,
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: endTime);
                            if (time != null) setStateBuilder(() => endTime = time);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
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
                      child: Text('حفظ الحصة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePickerBox({required String title, required TimeOfDay time, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
