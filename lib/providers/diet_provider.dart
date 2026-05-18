import 'package:flutter/foundation.dart';
import '../models/diet_model.dart';
import '../database/db_helper.dart';

class DietProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<DietRecord> _records = [];
  DateTime _selectedDate = DateTime.now();

  List<DietRecord> get records => List.unmodifiable(_records);
  DateTime get selectedDate => _selectedDate;

  String _datePrefix(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> loadRecords() async {
    final rows = await _db.queryAllDietRecords();
    _records = rows.map((r) => DietRecord.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> loadRecordsForDate(DateTime date) async {
    final rows = await _db.queryDietRecordsByDate(_datePrefix(date));
    _records = rows.map((r) => DietRecord.fromMap(r)).toList();
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> addRecord(DietRecord record) async {
    await _db.insertDietRecord(record.toMap());
    _records.add(record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteDietRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  int getDailyCalories(DateTime date) {
    final prefix = _datePrefix(date);
    return _records
        .where((r) => r.recordDate.startsWith(prefix))
        .fold(0, (sum, r) => sum + r.calories);
  }

  Map<String, double> getDailyMacros(DateTime date) {
    final prefix = _datePrefix(date);
    final dayRecords = _records.where((r) => r.recordDate.startsWith(prefix));
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final r in dayRecords) {
      protein += r.protein;
      carbs += r.carbs;
      fat += r.fat;
    }
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
