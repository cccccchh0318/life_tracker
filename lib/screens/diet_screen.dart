import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/diet_provider.dart';
import '../models/diet_model.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DietProvider>().loadRecordsForDate(_selectedDate);
    });
  }

  void _changeDate(int delta) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));
    context.read<DietProvider>().loadRecordsForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饮食'), centerTitle: false),
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
          // 营养摘要卡片
          Consumer<DietProvider>(
            builder: (_, dp, __) {
              final cal = dp.getDailyCalories(_selectedDate);
              final macros = dp.getDailyMacros(_selectedDate);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$cal', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(width: 4),
                            const Text('kcal', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MacroChip(label: '蛋白质', value: macros['protein'] ?? 0, color: Colors.blue),
                            _MacroChip(label: '碳水', value: macros['carbs'] ?? 0, color: Colors.orange),
                            _MacroChip(label: '脂肪', value: macros['fat'] ?? 0, color: Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // 餐食列表
          Expanded(
            child: Consumer<DietProvider>(
              builder: (_, dp, __) {
                final records = dp.getRecordsForDate(_selectedDate);
                if (records.isEmpty) {
                  return const Center(child: Text('今日暂无饮食记录', style: TextStyle(color: Colors.grey)));
                }
                final grouped = <String, List<DietRecord>>{};
                for (final r in records) {
                  grouped.putIfAbsent(r.mealType, () => []).add(r);
                }
                final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
                final mealNames = {'breakfast': '早餐', 'lunch': '午餐', 'dinner': '晚餐', 'snack': '零食'};
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: mealOrder
                      .where((m) => grouped.containsKey(m))
                      .map((m) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(mealNames[m]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                              ...grouped[m]!.map((r) => Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: ListTile(
                                      title: Text(r.foodName),
                                      subtitle: Text('蛋白质 ${r.protein}g  碳水 ${r.carbs}g  脂肪 ${r.fat}g'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('${r.calories} kcal', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                            onPressed: () => dp.deleteRecord(r.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          ))
                      .toList(),
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
    final foodCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String mealType = 'breakfast';

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
              const Text('添加饮食记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: mealType,
                decoration: const InputDecoration(labelText: '餐食类型', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
                  DropdownMenuItem(value: 'lunch', child: Text('午餐')),
                  DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
                  DropdownMenuItem(value: 'snack', child: Text('零食')),
                ],
                onChanged: (v) => setS(() => mealType = v ?? 'breakfast'),
              ),
              const SizedBox(height: 12),
              TextField(controller: foodCtrl, decoration: const InputDecoration(labelText: '食物名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '热量(kcal)', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: proteinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '蛋白质(g)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: carbsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '碳水(g)', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '脂肪(g)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (foodCtrl.text.trim().isEmpty) return;
                    context.read<DietProvider>().addRecord(DietRecord(
                      id: const Uuid().v4(),
                      mealType: mealType,
                      foodName: foodCtrl.text.trim(),
                      calories: int.tryParse(calCtrl.text) ?? 0,
                      protein: double.tryParse(proteinCtrl.text) ?? 0,
                      carbs: double.tryParse(carbsCtrl.text) ?? 0,
                      fat: double.tryParse(fatCtrl.text) ?? 0,
                      recordDate: _selectedDate,
                      note: '',
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

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${value.toStringAsFixed(1)}g', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
