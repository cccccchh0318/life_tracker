import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/checkin_provider.dart';
import '../models/checkin_model.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  static const List<String> _emojis = ['🏃','💪','📚','🧘','💧','🥗','😴','🎯','✍️','🎵','🌿','❤️'];
  static const List<int> _colorValues = [
    0xFF5C6BC0, 0xFF26A69A, 0xFFEF5350,
    0xFFFF7043, 0xFF66BB6A, 0xFFAB47BC,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckinProvider>().loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打卡'), centerTitle: false),
      body: Consumer<CheckinProvider>(
        builder: (_, cp, __) {
          if (cp.habits.isEmpty) {
            return const Center(child: Text('还没有打卡习惯，点击 + 添加', style: TextStyle(color: Colors.grey)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: cp.habits.length,
            itemBuilder: (ctx, i) {
              final habit = cp.habits[i];
              final checked = cp.isCheckedIn(habit.id, DateTime.now());
              final streak = cp.getStreak(habit.id);
              return GestureDetector(
                onTap: () {
                  if (!checked) {
                    cp.checkin(habit.id, DateTime.now(), '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「${habit.name}」打卡成功！'), duration: const Duration(seconds: 1)),
                    );
                  }
                },
                onLongPress: () => _confirmDelete(context, cp, habit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: checked
                        ? Color(habit.color).withValues(alpha: 0.85)
                        : Color(habit.color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(habit.color).withValues(alpha: checked ? 0 : 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(habit.icon, style: const TextStyle(fontSize: 28)),
                          if (checked)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: checked ? Colors.white : null,
                            ),
                          ),
                          Text(
                            '连续 $streak 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: checked ? Colors.white70 : Colors.grey,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CheckinProvider cp, CheckinHabit habit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除习惯'),
        content: Text('确定删除「${habit.name}」及所有打卡记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              cp.deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = _emojis[0];
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
              const Text('新建习惯', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '习惯名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('选择图标', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis.map((e) => GestureDetector(
                  onTap: () => setS(() => selectedEmoji = e),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selectedEmoji == e
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: selectedEmoji == e
                          ? Border.all(color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              const Text('选择颜色', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                      boxShadow: selectedColor == c
                          ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    context.read<CheckinProvider>().addHabit(CheckinHabit(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      icon: selectedEmoji,
                      color: selectedColor,
                      targetDays: 7,
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
