import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CheckinHabit {
  final String id;
  final String name;
  final String icon;
  final int color;
  final int targetDays;
  final DateTime createdAt;

  CheckinHabit({
    String? id,
    required this.name,
    this.icon = 'check_circle',
    int? color,
    this.targetDays = 7,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? Colors.deepPurple.value,
        createdAt = createdAt ?? DateTime.now();

  CheckinHabit copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    int? targetDays,
    DateTime? createdAt,
  }) {
    return CheckinHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetDays: targetDays ?? this.targetDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'target_days': targetDays,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CheckinHabit.fromMap(Map<String, dynamic> map) {
    return CheckinHabit(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: (map['icon'] as String?) ?? 'check_circle',
      color: map['color'] as int,
      targetDays: map['target_days'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'CheckinHabit(id: $id, name: $name, targetDays: $targetDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckinHabit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CheckinRecord {
  final String id;
  final String habitId;
  final DateTime date;
  final String note;

  CheckinRecord({
    String? id,
    required this.habitId,
    required this.date,
    this.note = '',
  }) : id = id ?? const Uuid().v4();

  CheckinRecord copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    String? note,
  }) {
    return CheckinRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory CheckinRecord.fromMap(Map<String, dynamic> map) {
    return CheckinRecord(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() {
    return 'CheckinRecord(id: $id, habitId: $habitId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckinRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
