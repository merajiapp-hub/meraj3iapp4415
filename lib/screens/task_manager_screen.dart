import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_item.dart';
import '../widgets/app_dropdown.dart';
import '../theme/app_theme.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  int _currentIndex = 0; // Default to Today's Tasks

  final List<String> _tabTitles = [
    'مهام اليوم',
    'جميع المراجعات',
    'الجدول العام',
  ];

  final List<String> _tabEmojis = ['🎯', '📚', '🗓️'];

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    int selectedDay = DateTime.now().weekday;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);
    bool notify = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final modalBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
            final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
            
            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: BoxDecoration(
                color: modalBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)
                ]
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
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)
                        ),
                      ),
                    ),
                    Text(
                      'إضافة مراجعة',
                      style: GoogleFonts.tajawal(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text('المادة / العنوان', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.tajawal(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'مثال: رياضيات - الدوال',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppDropdown<int>(
                      label: 'اليوم',
                      value: selectedDay,
                      items: List.generate(7, (index) {
                        int day = index + 1;
                        return DropdownMenuItem(value: day, child: Text(_getDayName(day), style: GoogleFonts.tajawal(color: textColor)));
                      }),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('البدء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: startTime);
                                  if (time != null) setModalState(() => startTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor), 
                                    borderRadius: BorderRadius.circular(16),
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(startTime.format(context), style: GoogleFonts.tajawal(color: textColor)),
                                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
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
                              Text('الانتهاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: endTime);
                                  if (time != null) setModalState(() => endTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor), 
                                    borderRadius: BorderRadius.circular(16),
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(endTime.format(context), style: GoogleFonts.tajawal(color: textColor)),
                                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
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
                    Text('ملاحظات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: GoogleFonts.tajawal(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'مثال: حل تمارين صفحة 40',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.accentColor : AppTheme.primaryColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (isDark ? AppTheme.accentColor : AppTheme.primaryColor).withValues(alpha: 0.2)),
                      ),
                      child: SwitchListTile(
                        value: notify,
                        onChanged: (val) => setModalState(() => notify = val),
                        title: Text('تفعيل التنبيه', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                        subtitle: Text('تنبيه قبل 10 دقائق من موعد المراجعة', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                        activeThumbColor: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  color: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                                  notify: notify,
                                  notifyMinutesBefore: 10,
                                ));
                                Navigator.pop(ctx);
                              }
                            },
                            child: Text('حفظ المراجعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('إلغاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
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

  Widget _buildTabIcon(int index, bool isDark) {
    bool isActive = _currentIndex == index;
    final activeColor = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_tabEmojis[index], style: const TextStyle(fontSize: 20)),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                _tabTitles[index],
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: activeColor,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAllReviewsTab(ScheduleProvider provider, bool isDark) {
    bool hasItems = false;
    for (int i = 1; i <= 7; i++) {
      if (provider.getItemsForDay(i).isNotEmpty) {
        hasItems = true;
        break;
      }
    }

    final List<int> daysOrder = [7, 1, 2, 3, 4, 5, 6];
    final List<String> daysNames = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    final textColor = isDark ? Colors.white : Colors.black87;
    final primary = isDark ? AppTheme.accentColor : AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'جميع المراجعات',
            style: GoogleFonts.tajawal(color: primary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        if (!hasItems)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.calendar_today_outlined, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('لا توجد مراجعات مجدولة', style: GoogleFonts.tajawal(color: isDark ? Colors.white54 : Colors.grey, fontSize: 18)),
                const SizedBox(height: 6),
                Text('أضف حصصك من تبويب "الجدول العام"', style: GoogleFonts.tajawal(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          )
        else
          for (int idx = 0; idx < daysOrder.length; idx++) ...[
            if (provider.getItemsForDay(daysOrder[idx]).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      daysNames[idx],
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
                    ),
                  ],
                ),
              ),
              ...provider.getItemsForDay(daysOrder[idx]).map((item) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.color.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                          if (item.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item.description, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${item.startTime.format(context)} - ${item.endTime.format(context)}',
                          style: GoogleFonts.tajawal(color: item.color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              )),
            ],
          ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTodayTasksTab(ScheduleProvider provider, bool isDark) {
    int today = DateTime.now().weekday;
    final todayItems = provider.getItemsForDay(today);
    int completedCount = todayItems.where((t) => t.isCompleted).length;
    int totalCount = todayItems.length;

    final primary = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مهام اليوم – ${_getDayName(today)}',
                style: GoogleFonts.tajawal(color: primary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/$totalCount',
                    style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completedCount / totalCount,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppTheme.accentColor : const Color(0xFF10B981)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (todayItems.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.task_alt, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('لا توجد مهام لهذا اليوم', style: GoogleFonts.tajawal(color: isDark ? Colors.white54 : Colors.grey, fontSize: 18)),
                const SizedBox(height: 6),
                Text('أضف حصصك الدراسية من تبويب "الجدول العام"', style: GoogleFonts.tajawal(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: todayItems.length,
            itemBuilder: (ctx, i) {
              final item = todayItems[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isCompleted 
                      ? (isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isCompleted 
                        ? Colors.green.withValues(alpha: 0.5) 
                        : (isDark ? Colors.white10 : Colors.grey.shade200)
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 46, decoration: BoxDecoration(color: item.isCompleted ? Colors.green : item.color, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 12),
                    Checkbox(
                      value: item.isCompleted,
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: (val) => provider.toggleItemCompletion(item, context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              color: item.isCompleted ? (isDark ? Colors.white38 : Colors.grey) : textColor,
                            ),
                          ),
                          if (item.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item.description, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13)),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text('${item.startTime.format(context)} - ${item.endTime.format(context)}',
                                  style: GoogleFonts.tajawal(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildScheduleTab(ScheduleProvider provider, bool isDark) {
    final List<int> daysOrder = [7, 1, 2, 3, 4, 5, 6]; 
    final List<String> daysNames = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final primary = isDark ? AppTheme.accentColor : AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _showAddSessionModal(context),
          child: Container(
            margin: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text('إضافة حصة مراجعة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 20)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                      border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16), 
                              child: Text('الوقت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primary))
                            )
                          )
                        ),
                        Container(width: 1, height: 50, color: isDark ? Colors.white10 : Colors.grey.shade200),
                        for (String day in daysNames)
                          SizedBox(
                            width: 140,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16), 
                                child: Text(day, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primary))
                              )
                            )
                          ),
                      ],
                    ),
                  ),
                  for (int h = 5; h <= 23; h++)
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16), 
                                child: Text('${h.toString().padLeft(2, '0')}:00', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.bold))
                              )
                            )
                          ),
                          Container(width: 1, height: 70, color: isDark ? Colors.white10 : Colors.grey.shade200),
                          for (int dayNum in daysOrder)
                            SizedBox(
                              width: 140,
                              height: 70,
                              child: Container(
                                decoration: BoxDecoration(border: Border(left: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100))),
                                child: _buildCellContent(provider, dayNum, h),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCellContent(ScheduleProvider provider, int dayNum, int hour) {
    final items = provider.getItemsForDay(dayNum).where((item) => item.startTime.hour == hour).toList();
    if (items.isEmpty) return const SizedBox();

    final item = items.first;
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.title,
            style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: item.color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.description,
                style: GoogleFonts.tajawal(fontSize: 9, color: item.color.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppTheme.deepBlueGradient : const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('منظم الوقت والمهام', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('نظم وقتك، وحقق أهدافك بنجاح', style: GoogleFonts.tajawal(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 180, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabIcon(0, isDark),
                  _buildTabIcon(1, isDark),
                  _buildTabIcon(2, isDark),
                ],
              ),
            ),
          ),
          
          Positioned.fill(
            top: 280,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  if (_currentIndex == 0) _buildTodayTasksTab(scheduleProvider, isDark),
                  if (_currentIndex == 1) _buildAllReviewsTab(scheduleProvider, isDark),
                  if (_currentIndex == 2) _buildScheduleTab(scheduleProvider, isDark),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40, right: 16,
            child: SafeArea(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
