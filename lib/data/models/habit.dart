import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 습관 모델 클래스
class Habit extends Equatable {
  /// 습관 고유 식별자
  final String id;

  /// 습관 이름
  final String name;

  /// 완료 여부
  final bool isCompleted;

  /// 강조 표시 여부
  final bool isEmphasized;

  /// 연속 달성 일수
  final int streak;

  /// 완료 시간
  final DateTime? completedAt;

  /// 알림 시간 (옵션)
  final TimeOfDay? reminderTime;

  /// 생성 날짜
  final DateTime createdAt;

  /// 마지막 업데이트 날짜
  final DateTime updatedAt;

  /// 기본 생성자
  const Habit({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.isEmphasized = false,
    this.streak = 0,
    this.completedAt,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 새 습관 생성을 위한 팩토리 생성자
  factory Habit.create({
    required String name,
    TimeOfDay? reminderTime,
  }) {
    final now = DateTime.now();
    return Habit(
      id: const Uuid().v4(),
      name: name,
      reminderTime: reminderTime,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 복사 생성자 - 불변성 패턴을 위해 사용
  Habit copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    bool? isEmphasized,
    int? streak,
    DateTime? completedAt,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      isEmphasized: isEmphasized ?? this.isEmphasized,
      streak: streak ?? this.streak,
      completedAt: completedAt ?? this.completedAt,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    isCompleted,
    isEmphasized,
    streak,
    completedAt,
    reminderTime,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'Habit(id: $id, name: $name, isCompleted: $isCompleted, streak: $streak)';
}

/// TimeOfDay 클래스 확장
extension TimeOfDayExtension on TimeOfDay {
  /// TimeOfDay를 String으로 변환
  String toFormattedString() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// String을 TimeOfDay로 변환
  static TimeOfDay? fromString(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return null;
    }

    final parts = timeString.split(':');
    if (parts.length != 2) {
      return null;
    }

    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}