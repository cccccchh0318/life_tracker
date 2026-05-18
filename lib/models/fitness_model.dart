import 'package:uuid/uuid.dart';

class FitnessRecord {
  final String id;
  final String workoutType;
  final int duration; // in minutes
  final int calories;
  final int sets;
  final int reps;
  final double weight; // in kg
  final String note;
  final DateTime recordDate;

  FitnessRecord({
    String? id,
    required this.workoutType,
    this.duration = 0,
    this.calories = 0,
    this.sets = 0,
    this.reps = 0,
    this.weight = 0.0,
    this.note = '',
    DateTime? recordDate,
  })  : id = id ?? const Uuid().v4(),
        recordDate = recordDate ?? DateTime.now();

  FitnessRecord copyWith({
    String? id,
    String? workoutType,
    int? duration,
    int? calories,
    int? sets,
    int? reps,
    double? weight,
    String? note,
    DateTime? recordDate,
  }) {
    return FitnessRecord(
      id: id ?? this.id,
      workoutType: workoutType ?? this.workoutType,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      recordDate: recordDate ?? this.recordDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_type': workoutType,
      'duration': duration,
      'calories': calories,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'note': note,
      'record_date': recordDate.toIso8601String(),
    };
  }

  factory FitnessRecord.fromMap(Map<String, dynamic> map) {
    return FitnessRecord(
      id: map['id'] as String,
      workoutType: map['workout_type'] as String,
      duration: map['duration'] as int,
      calories: map['calories'] as int,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      recordDate: DateTime.parse(map['record_date'] as String),
    );
  }

  int get totalVolume => sets * reps;

  double get totalWeightLifted => sets * reps * weight;

  String get durationFormatted {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool isOnDate(DateTime date) {
    return recordDate.year == date.year &&
        recordDate.month == date.month &&
        recordDate.day == date.day;
  }

  @override
  String toString() {
    return 'FitnessRecord(id: $id, workoutType: $workoutType, duration: $duration min, calories: $calories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FitnessRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
