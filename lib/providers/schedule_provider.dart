import 'package:flutter/foundation.dart';
import '../models/schedule_model.dart';
import '../database/db_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Schedule> _schedules = [];
  DateTime _selectedDate = DateTime.now();

  List<Schedule> get schedules => List.unmodifiable(_schedules);
  DateTime get selectedDate => _selectedDate;

  Future<void> loadSchedules() async {
    final rows = await _db.queryAllSchedules();
    _schedules = rows.map((r) => Schedule.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _db.insertSchedule(schedule.toMap());
    _schedules.add(schedule);
    notifyListeners();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _db.updateSchedule(schedule.toMap());
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    await _db.deleteSchedule(id);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<Schedule> getSchedulesForDate(DateTime date) {
    final prefix =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return _schedules
        .where((s) => s.startTime.toIso8601String().startsWith(prefix))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
