import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../models/habit.dart';

/// 습관 DTO - JSON 직렬화/역직렬화를 위한 클래스
class HabitDto {
  final String id;
  final String name;
  final bool isCompleted;
  final bool isEmphasized;
  final int streak;
  final DateTime? completedAt;
  final String? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 기본 생성자
  HabitDto({
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

  /// JSON에서 DTO 생성
  factory HabitDto.fromJson(Map<String, dynamic> json) {
    return HabitDto(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isEmphasized: json['isEmphasized'] as bool? ?? false,
      streak: json['streak'] as int? ?? 0,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      reminderTime: json['reminderTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// DTO를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'isEmphasized': isEmphasized,
      'streak': streak,
      'completedAt': completedAt?.toIso8601String(),
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Habit 모델에서 DTO 생성
  factory HabitDto.fromModel(Habit habit) {
    logger.debug('Habit 모델에서 DTO 생성: ${habit.id}');
    return HabitDto(
      id: habit.id,
      name: habit.name,
      isCompleted: habit.isCompleted,
      isEmphasized: habit.isEmphasized,
      streak: habit.streak,
      completedAt: habit.completedAt,
      reminderTime: habit.reminderTime?.toFormattedString(),
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
    );
  }

  /// DTO에서 Habit 모델 생성
  static Habit toModel(HabitDto dto) {
    ///logger.debug('DTO에서 Habit 모델 생성: ${dto.id}');
    return Habit(
      id: dto.id,
      name: dto.name,
      isCompleted: dto.isCompleted,
      isEmphasized: dto.isEmphasized,
      streak: dto.streak,
      completedAt: dto.completedAt,
      reminderTime: TimeOfDayExtension.fromString(dto.reminderTime),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  /// 복사 생성자 - 불변성 패턴을 위해 사용
  HabitDto copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    bool? isEmphasized,
    int? streak,
    DateTime? completedAt,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitDto(
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
}

/// DB 사용을 위한 확장 메서드
extension HabitDtoExtension on HabitDto {
  /// Map 형태로 변환 (SQLite 용)
  Map<String, dynamic> toMap() {
    logger.debug('HabitDto를 Map으로 변환: $id');
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted ? 1 : 0, // SQLite는 boolean을 지원하지 않음
      'isEmphasized': isEmphasized ? 1 : 0,
      'streak': streak,
      'completedAt': completedAt?.toIso8601String(),
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// DB Map에서 DTO 생성
  static HabitDto fromMap(Map<String, dynamic> map) {
    //logger.debug('Map에서 HabitDto 생성: ${map['id']}');
    return HabitDto(
      id: map['id'] as String,
      name: map['name'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      isEmphasized: (map['isEmphasized'] as int) == 1,
      streak: map['streak'] as int,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'] as String)
              : null,
      reminderTime: map['reminderTime'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
