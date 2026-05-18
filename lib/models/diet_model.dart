import 'package:uuid/uuid.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => MealType.snack,
    );
  }
}

class DietRecord {
  final String id;
  final String mealType;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime recordDate;
  final String note;

  DietRecord({
    String? id,
    required this.mealType,
    required this.foodName,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    DateTime? recordDate,
    this.note = '',
  })  : id = id ?? const Uuid().v4(),
        recordDate = recordDate ?? DateTime.now();

  DietRecord copyWith({
    String? id,
    String? mealType,
    String? foodName,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? recordDate,
    String? note,
  }) {
    return DietRecord(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      recordDate: recordDate ?? this.recordDate,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'record_date': recordDate.toIso8601String(),
      'note': note,
    };
  }

  factory DietRecord.fromMap(Map<String, dynamic> map) {
    return DietRecord(
      id: map['id'] as String,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      recordDate: DateTime.parse(map['record_date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  double get totalMacros => protein + carbs + fat;

  MealType get mealTypeEnum => MealType.fromString(mealType);

  bool isOnDate(DateTime date) {
    return recordDate.year == date.year &&
        recordDate.month == date.month &&
        recordDate.day == date.day;
  }

  @override
  String toString() {
    return 'DietRecord(id: $id, foodName: $foodName, mealType: $mealType, calories: $calories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DietRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
