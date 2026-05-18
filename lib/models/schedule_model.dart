import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Schedule {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final int color;
  final DateTime createdAt;

  Schedule({
    String? id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    int? color,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? Colors.deepPurple.value,
        createdAt = createdAt ?? DateTime.now();

  Schedule copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    int? color,
    DateTime? createdAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay ? 1 : 0,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      isAllDay: (map['is_all_day'] as int) == 1,
      color: map['color'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Duration get duration => endTime.difference(startTime);

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool occursOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return startTime.isBefore(dayEnd) && endTime.isAfter(dayStart);
  }

  @override
  String toString() {
    return 'Schedule(id: $id, title: $title, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
