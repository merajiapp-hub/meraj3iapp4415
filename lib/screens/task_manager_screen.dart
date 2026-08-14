import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _showAddTaskModal(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedSubject;
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 1));

    final provider = Provider.of<TaskProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'إضافة جلسة دراسة',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان المهمة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: GoogleFonts.tajawal(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'المادة الدراسية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: provider.subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: GoogleFonts.tajawal(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedSubject = val),
                    initialValue: selectedSubject,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startTime),
                            );
                            if (time != null) {
                              setModalState(
                                () => startTime = DateTime(
                                  startTime.year,
                                  startTime.month,
                                  startTime.day,
                                  time.hour,
                                  time.minute,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow_outlined),
                          label: Text(
                            'البداية: ${TimeOfDay.fromDateTime(startTime).format(context)}',
                            style: GoogleFonts.tajawal(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endTime),
                            );
                            if (time != null) {
                              setModalState(
                                () => endTime = DateTime(
                                  endTime.year,
                                  endTime.month,
                                  endTime.day,
                                  time.hour,
                                  time.minute,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.stop_outlined),
                          label: Text(
                            'النهاية: ${TimeOfDay.fromDateTime(endTime).format(context)}',
                            style: GoogleFonts.tajawal(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            selectedSubject != null) {
                          final task = StudyTask(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text,
                            subject: selectedSubject!,
                            startTime: startTime,
                            endTime: endTime,
                            notificationId: provider.getNextNotifId(),
                          );
                          provider.addTask(task);

                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        'بدء الجلسة الآن',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final tasks = provider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'منظم الدراسة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskModal(context),
        icon: const Icon(Icons.add_task),
        label: Text(
          'إضافة جلسة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
      ),
      body: tasks.isEmpty
          ? _buildEmptyState()
          : _buildTasksList(tasks, provider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد جلسات مجدولة حالياً',
            style: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة جلسة',
            style: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<StudyTask> tasks, TaskProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isRunning =
            task.startTime.isBefore(DateTime.now()) &&
            task.endTime.isAfter(DateTime.now());
        final isFinished = task.endTime.isBefore(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: isRunning
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  child: Icon(
                    isRunning
                        ? Icons.play_arrow
                        : (isFinished
                              ? Icons.check_circle
                              : Icons.timer_outlined),
                    color: isRunning
                        ? Colors.green
                        : (isFinished ? Colors.grey : AppTheme.primaryColor),
                  ),
                ),
                title: Text(
                  task.title,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: isFinished ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.subject,
                      style: GoogleFonts.tajawal(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => provider.deleteTask(task.id),
                ),
              ),
              if (isRunning) _buildCountdownBar(task),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildCountdownBar(StudyTask task) {
    final now = DateTime.now();
    final total = task.endTime.difference(task.startTime).inSeconds;
    final remaining = task.endTime.difference(now).inSeconds;
    final progress = (total - remaining) / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المتبقي من الجلسة',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(Duration(seconds: remaining)),
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
