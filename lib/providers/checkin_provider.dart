import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/checkin_model.dart';

import '../database/db_helper.dart';

class CheckinProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<CheckinHabit> _habits = [];
  Map<String, List<CheckinRecord>> _recordsByHabit = {};

  List<CheckinHabit> get habits => List.unmodifiable(_habits);
  Map<String, List<CheckinRecord>> get recordsByHabit =>
      Map.unmodifiable(_recordsByHabit);

  Future<void> loadHabits() async {
    final rows = await _db.queryAllCheckinHabits();
    _habits = rows.map((r) => CheckinHabit.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> loadRecords() async {
    final rows = await _db.queryAllCheckinRecords();
    final allRecords = rows.map((r) => CheckinRecord.fromMap(r)).toList();

    _recordsByHabit = {};
    for (final record in allRecords) {
      _recordsByHabit.putIfAbsent(record.habitId, () => []).add(record);
    }
    notifyListeners();
  }

  Future<void> addHabit(CheckinHabit habit) async {
    await _db.insertCheckinHabit(habit.toMap());
    _habits.add(habit);
    _recordsByHabit.putIfAbsent(habit.id, () => []);
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteCheckinHabit(id);
    // Also remove all records for this habit
    final records = _recordsByHabit[id] ?? [];
    for (final r in records) {
      await _db.deleteCheckinRecord(r.id);
    }
    _habits.removeWhere((h) => h.id == id);
    _recordsByHabit.remove(id);
    notifyListeners();
  }

  Future<void> checkin(String habitId, DateTime date, String note) async {
    // Prevent duplicate check-ins for the same day
    if (isCheckedIn(habitId, date)) return;

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final record = CheckinRecord(
      id: _uuid.v4(),
      habitId: habitId,
      date: dateStr,
      note: note,
    );

    await _db.insertCheckinRecord(record.toMap());
    _recordsByHabit.putIfAbsent(habitId, () => []).add(record);
    notifyListeners();
  }

  bool isCheckedIn(String habitId, DateTime date) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final records = _recordsByHabit[habitId] ?? [];
    return records.any((r) => r.date.startsWith(dateStr));
  }

  /// Returns the current consecutive-day streak for a habit.
  /// Counts backwards from today; a gap of more than one day breaks the streak.
  int getStreak(String habitId) {
    final records = _recordsByHabit[habitId] ?? [];
    if (records.isEmpty) return 0;

    // Collect unique check-in dates as DateTime (date-only)
    final dates = records
        .map((r) {
          final parts = r.date.split('-');
          if (parts.length < 3) return null;
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Streak must include today or yesterday to be considered active
    final mostRecent = dates.first;
    final diff = todayDate.difference(mostRecent).inDays;
    if (diff > 1) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final gap = dates[i - 1].difference(dates[i]).inDays;
      if (gap == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
