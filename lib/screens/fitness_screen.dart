import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/fitness_provider.dart';
import '../models/fitness_model.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FitnessProvider>().loadRecordsForDate(_selectedDate);
    });
  }

  void _changeDate(int delta) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));
    context.read<FitnessProvider>().loadRecordsForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健身'), centerTitle: false),
      body: Column(
        children: [
          // 日期选择器
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                Text(
                  DateFormat('yyyy年MM月dd日').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
              ],
            ),
          ),
          // 周热量柱状图
          Consumer<FitnessProvider>(
            builder: (_, fp, __) {
              final weekly = fp.getWeeklyCalories();
              final maxVal = weekly.isEmpty ? 1 : weekly.reduce((a, b) => a > b ? a : b);
              final days = ['一','二','三','四','五','六','日'];
              final today = DateTime.now().weekday - 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('本周消耗热量', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: BarChart(
                            BarChartData(
                              maxY: maxVal > 0 ? maxVal.toDouble() * 1.3 : 100,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Text(
                                      days[v.toInt() % 7],
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(7, (i) {
                                final isToday = i == today;
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: weekly.length > i ? weekly[i].toDouble() : 0,
                                      color: isToday
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                                      width: 18,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // 今日训练列表
          Expanded(
            child: Consumer<FitnessProvider>(
              builder: (_, fp, __) {
                final records = fp.getRecordsForDate(_selectedDate);
                if (records.isEmpty) {
                  return const Center(child: Text('今日暂无训练记录', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        title: Text(r.workoutType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${r.duration}分钟  ${r.sets}组×${r.reps}次'
                          '${r.weight > 0 ? '  ${r.weight}kg' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${r.calories}kcal', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () => fp.deleteRecord(r.id),
                            ),
                          ],
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
    final typeCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加训练记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: '训练类型（如：深蹲、跑步）', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '时长(分钟)', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '消耗(kcal)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: setsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '组数', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '次数', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '重量(kg)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (typeCtrl.text.trim().isEmpty) return;
                    context.read<FitnessProvider>().addRecord(FitnessRecord(
                      id: const Uuid().v4(),
                      workoutType: typeCtrl.text.trim(),
                      duration: int.tryParse(durationCtrl.text) ?? 0,
                      calories: int.tryParse(calCtrl.text) ?? 0,
                      sets: int.tryParse(setsCtrl.text) ?? 0,
                      reps: int.tryParse(repsCtrl.text) ?? 0,
                      weight: double.tryParse(weightCtrl.text) ?? 0,
                      note: noteCtrl.text.trim(),
                      recordDate: _selectedDate,
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
