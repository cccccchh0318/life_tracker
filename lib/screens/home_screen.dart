import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/diet_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  static const List<String> _weekdays = ['星期一','星期二','星期三','星期四','星期五','星期六','星期日'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<ScheduleProvider>().loadSchedules();
      context.read<CheckinProvider>().loadHabits();
      context.read<DietProvider>().loadRecordsForDate(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _weekdayStr => _weekdays[_now.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // 时间卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(_now),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_now.year}年${_now.month}月${_now.day}日  $_weekdayStr',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('今日概览', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // 统计卡片网格
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  // 任务
                  Consumer<TaskProvider>(
                    builder: (_, tp, __) {
                      final total = tp.tasks.length;
                      final done = tp.tasks.where((t) => t.isCompleted).length;
                      return _StatCard(
                        icon: Icons.task_alt,
                        label: '任务',
                        value: '$done / $total',
                        subtitle: '已完成',
                        color: Colors.blue,
                      );
                    },
                  ),
                  // 日程
                  Consumer<ScheduleProvider>(
                    builder: (_, sp, __) {
                      final count = sp.getSchedulesForDate(DateTime.now()).length;
                      return _StatCard(
                        icon: Icons.calendar_today,
                        label: '日程',
                        value: '$count',
                        subtitle: '今日安排',
                        color: Colors.orange,
                      );
                    },
                  ),
                  // 打卡
                  Consumer<CheckinProvider>(
                    builder: (_, cp, __) {
                      final total = cp.habits.length;
                      final done = cp.habits.where((h) => cp.isCheckedIn(h.id, DateTime.now())).length;
                      return _StatCard(
                        icon: Icons.check_circle,
                        label: '打卡',
                        value: '$done / $total',
                        subtitle: '今日完成',
                        color: Colors.green,
                      );
                    },
                  ),
                  // 饮食
                  Consumer<DietProvider>(
                    builder: (_, dp, __) {
                      final cal = dp.getDailyCalories(DateTime.now());
                      return _StatCard(
                        icon: Icons.restaurant,
                        label: '热量',
                        value: '$cal',
                        subtitle: 'kcal 今日',
                        color: Colors.red,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
