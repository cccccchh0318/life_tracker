import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务'), centerTitle: false),
      body: Column(
        children: [
          // 过滤器
          Consumer<TaskProvider>(
            builder: (_, tp, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final f in [('全部', 'all'), ('进行中', 'active'), ('已完成', 'completed')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.$1),
                        selected: tp.filter == f.$2,
                        onSelected: (_) => tp.setFilter(f.$2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (_, tp, __) {
                final tasks = tp.filteredTasks;
                if (tasks.isEmpty) {
                  return const Center(child: Text('暂无任务', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) {
                    final task = tasks[i];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            title: const Text('删除任务'),
                            content: Text('确定删除「${task.title}」？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) => tp.deleteTask(task.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => tp.toggleComplete(task.id),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          subtitle: task.dueDate != null
                              ? Text(DateFormat('MM/dd HH:mm').format(task.dueDate!), style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: _PriorityBadge(priority: task.priority),
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
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int priority = 0;
    DateTime? dueDate;

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
              const Text('新建任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '任务名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: priority,
                decoration: const InputDecoration(labelText: '优先级', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('低')),
                  DropdownMenuItem(value: 1, child: Text('中')),
                  DropdownMenuItem(value: 2, child: Text('高')),
                ],
                onChanged: (v) => setS(() => priority = v ?? 0),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dueDate == null ? '设置截止时间' : DateFormat('MM/dd HH:mm').format(dueDate!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setS(() => dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    context.read<TaskProvider>().addTask(Task(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      dueDate: dueDate,
                      isCompleted: false,
                      priority: priority,
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

class _PriorityBadge extends StatelessWidget {
  final int priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    const labels = ['低', '中', '高'];
    const colors = [Colors.green, Colors.orange, Colors.red];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[priority].withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(labels[priority], style: TextStyle(color: colors[priority], fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
