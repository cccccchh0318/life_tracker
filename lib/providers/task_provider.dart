import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../database/db_helper.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Task> _tasks = [];
  String _filter = 'all'; // 'all' | 'active' | 'completed'

  List<Task> get tasks => List.unmodifiable(_tasks);
  String get filter => _filter;

  List<Task> get filteredTasks {
    switch (_filter) {
      case 'active':
        return _tasks.where((t) => !t.isCompleted).toList();
      case 'completed':
        return _tasks.where((t) => t.isCompleted).toList();
      case 'all':
      default:
        return List.unmodifiable(_tasks);
    }
  }

  Future<void> loadTasks() async {
    final rows = await _db.queryAllTasks();
    _tasks = rows.map((r) => Task.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task.toMap());
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task.toMap());
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> toggleComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _tasks[index];
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _db.updateTask(updated.toMap());
    _tasks[index] = updated;
    notifyListeners();
  }

  void setFilter(String newFilter) {
    assert(
      ['all', 'active', 'completed'].contains(newFilter),
      'filter must be one of: all, active, completed',
    );
    _filter = newFilter;
    notifyListeners();
  }
}
