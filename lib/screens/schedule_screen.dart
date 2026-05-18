import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  static const List<int> _colorValues = [
    0xFF5C6BC0, 0xFF26A69A, 0xFFEF5350,
    0xFFFF7043, 0xFF66BB6A, 0xFFAB47BC,
  ];

  List<DateTime> _weekDays(DateTime base) {
    final monday = base.subtract(Duration(days: base.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays(_selectedDate);
    return Scaffold(
      appBar: AppBar(title: const Text('日程'), centerTitle: false),
      body: Column(
        children: [
          // 周视图
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isToday = day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['一','二','三','四','五','六','日'][day.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : (isToday ? Theme.of(context).colorScheme.primary : null),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // 日程列表
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (_, sp, __) {
                final schedules = sp.getSchedulesForDate(_selectedDate);
                if (schedules.isEmpty) {
                  return const Center(child: Text('今日无日程', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (ctx, i) {
                    final s = schedules[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(s.color),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: s.isAllDay
                            ? const Text('全天')
                            : Text('${DateFormat('HH:mm').format(s.startTime)} - ${DateFormat('HH:mm').format(s.endTime)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => sp.deleteSchedule(s.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    DateTime startTime = _selectedDate.copyWith(hour: 9, minute: 0);
    DateTime endTime = _selectedDate.copyWith(hour: 10, minute: 0);
    bool isAllDay = false;
    int selectedColor = _colorValues[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('新建日程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '日程名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('全天'),
                value: isAllDay,
                onChanged: (v) => setS(() => isAllDay = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (!isAllDay) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text('开始: ${DateFormat('MM/dd HH:mm').format(startTime)}'),
                  onPressed: () async {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(startTime));
                    if (t != null) setS(() => startTime = startTime.copyWith(hour: t.hour, minute: t.minute));
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text('结束: ${DateFormat('MM/dd HH:mm').format(endTime)}'),
                  onPressed: () async {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(endTime));
                    if (t != null) setS(() => endTime = endTime.copyWith(hour: t.hour, minute: t.minute));
                  },
                ),
              ],
              const SizedBox(height: 12),
              const Text('颜色', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: _colorValues.map((c) => GestureDetector(
                  onTap: () => setS(() => selectedColor = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: selectedColor == c ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 6)] : null,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    context.read<ScheduleProvider>().addSchedule(Schedule(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: '',
                      startTime: startTime,
                      endTime: endTime,
                      isAllDay: isAllDay,
                      color: selectedColor,
                      createdAt: DateTime.now(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('添加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
