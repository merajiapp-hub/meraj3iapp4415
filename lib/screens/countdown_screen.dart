import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownEvent {
  String name;
  DateTime date;
  Color color;

  _CountdownEvent({required this.name, required this.date, required this.color});

  int get daysLeft => date.difference(DateTime.now()).inDays;
  bool get isPast => date.isBefore(DateTime.now());
}

class _CountdownScreenState extends State<CountdownScreen> {
  final List<_CountdownEvent> _events = [];
  Timer? _timer;

  static const _prefsKey = 'countdown_events_v1';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    // Refresh every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    
    if (mounted) {
      setState(() {
        _events.clear();
        if (saved == null || saved.isEmpty) {
          // أحداث افتراضية عند فتح الشاشة لأول مرة
          _events.addAll([
            _CountdownEvent(
              name: 'ختم الدروس الإعدادية (BEPC)',
              date: DateTime(2026, 5, 26),
              color: AppTheme.primaryColor,
            ),
            _CountdownEvent(
              name: 'الباكلوريا (BAC)',
              date: DateTime(2026, 6, 1),
              color: Colors.orange,
            ),
          ]);
          _saveEvents();
        } else {
          for (var s in saved) {
            final parts = s.split('|');
            if (parts.length >= 3) {
              _events.add(_CountdownEvent(
                name: parts[0],
                date: DateTime.parse(parts[1]),
                color: Color(int.parse(parts[2])),
              ));
            }
          }
        }
        _events.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _events
        .map((e) => '${e.name}|${e.date.toIso8601String()}|${e.color.toARGB32()}')
        .toList();
    await prefs.setStringList(_prefsKey, list);
  }

  void _addEvent() async {
    final colors = [
      AppTheme.primaryColor, Colors.orange, Colors.purple,
      Colors.red, Colors.blue, Colors.teal,
    ];
    String name = '';
    DateTime? picked;
    Color selectedColor = colors[0];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('إضافة حدث', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'اسم الامتحان / الحدث',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => name = v,
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (d != null) setDialogState(() => picked = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        picked != null
                            ? '${picked!.day}/${picked!.month}/${picked!.year}'
                            : 'اختر التاريخ',
                        style: GoogleFonts.cairo(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: selectedColor == c ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && picked != null) {
                  setState(() {
                    _events.add(_CountdownEvent(name: name, date: picked!, color: selectedColor));
                    _events.sort((a, b) => a.date.compareTo(b.date));
                  });
                  _saveEvents();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('العد التنازلي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('إضافة حدث', style: GoogleFonts.cairo(color: Colors.white)),
      ),
      body: _events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_off_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أحداث بعد',
                    style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف امتحاناً أو حدثاً مهماً',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _events.length,
              itemBuilder: (context, i) {
                final event = _events[i];
                final days = event.daysLeft;
                final isPast = event.isPast;

                return Dismissible(
                  key: Key('${event.name}_${event.date}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => _events.removeAt(i));
                    _saveEvents();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: event.color.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: event.color.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [event.color, event.color.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isPast ? '✓' : '${days.abs()}',
                                style: GoogleFonts.poppins(
                                  fontSize: isPast ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                isPast ? 'انتهى' : 'يوم',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white70,
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
                              Text(
                                event.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${event.date.day}/${event.date.month}/${event.date.year}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPast
                                    ? 'انتهى منذ ${days.abs()} يوم'
                                    : days == 0
                                        ? 'اليوم! 🎯'
                                        : 'تبقى $days يوم',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPast
                                      ? Colors.grey
                                      : days <= 7
                                          ? Colors.red
                                          : event.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
