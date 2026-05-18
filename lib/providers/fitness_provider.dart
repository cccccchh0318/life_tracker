import 'package:flutter/foundation.dart';
import '../models/fitness_model.dart';
import '../database/db_helper.dart';

class FitnessProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<FitnessRecord> _records = [];
  DateTime _selectedDate = DateTime.now();

  List<FitnessRecord> get records => List.unmodifiable(_records);
  DateTime get selectedDate => _selectedDate;

  String _datePrefix(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> loadRecords() async {
    final rows = await _db.queryAllFitnessRecords();
    _records = rows.map((r) => FitnessRecord.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> loadRecordsForDate(DateTime date) async {
    final rows = await _db.queryFitnessRecordsByDate(_datePrefix(date));
    _records = rows.map((r) => FitnessRecord.fromMap(r)).toList();
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> addRecord(FitnessRecord record) async {
    await _db.insertFitnessRecord(record.toMap());
    _records.add(record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteFitnessRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Returns total calories burned for each of the last 7 days,
  /// index 0 = 6 days ago, index 6 = today.
  List<int> getWeeklyCalories() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final prefix = _datePrefix(day);
      return _records
          .where((r) => r.recordDate.toIso8601String().startsWith(prefix))
          .fold(0, (sum, r) => sum + r.calories);
    });
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<FitnessRecord> getRecordsForDate(DateTime date) {
    return _records
        .where((r) =>
            r.recordDate.year == date.year &&
            r.recordDate.month == date.month &&
            r.recordDate.day == date.day)
        .toList();
  }
}
