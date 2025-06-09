import 'package:flutter/material.dart';

import '../../core/logger.dart';
import '../datasources/local/dao/habit_dao.dart';
import '../dtos/habit_dto.dart';
import '../models/habit.dart';

/// 습관 저장소 인터페이스
abstract class HabitRepository {
  /// 특정 날짜의 습관 목록 조회
  Future<List<Habit>> getHabitsForDate(DateTime date);

  /// 습관 추가
  Future<bool> addHabit(String name, {TimeOfDay? reminderTime});

  /// 습관 삭제
  Future<bool> deleteHabit(String habitId);

  /// 습관 이름 업데이트
  Future<bool> updateHabitName(String habitId, String newName);

  /// 습관 완료 상태 토글
  Future<bool> toggleHabit(String habitId, DateTime date, bool isCompleted);

  /// 주간 완료율 데이터 조회
  Future<Map<String, double>> getWeeklyProgress(DateTime date);

  /// 가장 스트릭이 높은 습관 조회
  Future<Habit?> getTopHabit();

  /// 모든 습관 데이터 내보내기
  Future<List<HabitDto>> exportAllHabits();

  /// 습관 데이터 가져오기 (백업에서 복원)
  Future<bool> importHabits(List<HabitDto> habits);
}

/// 습관 저장소 구현
class HabitRepositoryImpl implements HabitRepository {
  // 로그 태그
  static const String _tag = 'HabitRepository';

  // 데이터 소스
  final HabitDao _localDataSource;

  /// 생성자
  HabitRepositoryImpl({required HabitDao localDataSource})
    : _localDataSource = localDataSource;

  /// 특정 날짜의 습관 목록 조회
  @override
  Future<List<Habit>> getHabitsForDate(DateTime date) async {
    try {
      //logger.debug('날짜별 습관 조회: $date', tag: _tag);

      // 로컬 데이터 소스에서 조회
      final habitDtos = await _localDataSource.getHabitsForDate(date);

      // DTO를 모델로 변환
      final habits = habitDtos.map((dto) => HabitDto.toModel(dto)).toList();

      //logger.debug('날짜별 습관 조회 결과: ${habits.length}개', tag: _tag);
      return habits;
    } catch (e, stackTrace) {
      logger.error(
        '날짜별 습관 조회 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// 습관 추가
  @override
  Future<bool> addHabit(String name, {TimeOfDay? reminderTime}) async {
    try {
      logger.debug('습관 추가: $name', tag: _tag);

      // 새 습관 생성
      final habit = Habit.create(name: name, reminderTime: reminderTime);

      // DTO로 변환
      final habitDto = HabitDto.fromModel(habit);

      // 로컬 저장소에 저장
      final success = await _localDataSource.insertHabit(habitDto);

      logger.info('습관 추가 ${success ? '성공' : '실패'}: ${habit.id}', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '습관 추가 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 습관 삭제
  @override
  Future<bool> deleteHabit(String habitId) async {
    try {
      logger.debug('습관 삭제: $habitId', tag: _tag);

      // 로컬 저장소에서 삭제
      final success = await _localDataSource.deleteHabit(habitId);

      logger.info('습관 삭제 ${success ? '성공' : '실패'}: $habitId', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '습관 삭제 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 습관 이름 업데이트
  @override
  Future<bool> updateHabitName(String habitId, String newName) async {
    try {
      logger.debug('습관 이름 업데이트: $habitId, 새 이름: $newName', tag: _tag);

      // 기존 습관 조회
      final habitDto = await _localDataSource.getHabit(habitId);
      if (habitDto == null) {
        logger.warning('습관을 찾을 수 없음: $habitId', tag: _tag);
        return false;
      }

      // 이름 업데이트
      final updatedDto = habitDto.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );

      // 로컬 저장소에 업데이트
      final success = await _localDataSource.updateHabit(updatedDto);

      logger.info('습관 이름 업데이트 ${success ? '성공' : '실패'}: $habitId', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '습관 이름 업데이트 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 습관 완료 상태 토글
  @override
  Future<bool> toggleHabit(
    String habitId,
    DateTime date,
    bool isCompleted,
  ) async {
    try {
      logger.debug('습관 토글: $habitId, 날짜: $date, 완료: $isCompleted', tag: _tag);

      // 로컬 저장소에서 토글
      final success = await _localDataSource.toggleHabit(
        habitId,
        date,
        isCompleted,
      );

      logger.info('습관 토글 ${success ? '성공' : '실패'}: $habitId', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '습관 토글 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 주간 완료율 데이터 조회
  @override
  Future<Map<String, double>> getWeeklyProgress(DateTime date) async {
    try {
      logger.debug('주간 완료율 조회: $date', tag: _tag);
      return await _localDataSource.getWeeklyProgress(date);
    } catch (e, stackTrace) {
      logger.error(
        '주간 완료율 조회 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// 가장 스트릭이 높은 습관 조회
  @override
  Future<Habit?> getTopHabit() async {
    try {
      logger.debug('최고 스트릭 습관 조회', tag: _tag);

      final habitDto = await _localDataSource.getTopHabit();
      if (habitDto == null) {
        logger.debug('최고 스트릭 습관 없음', tag: _tag);
        return null;
      }

      return HabitDto.toModel(habitDto);
    } catch (e, stackTrace) {
      logger.error(
        '최고 스트릭 습관 조회 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 모든 습관 데이터 내보내기
  @override
  Future<List<HabitDto>> exportAllHabits() async {
    try {
      logger.debug('모든 습관 데이터 내보내기', tag: _tag);
      final habits = await _localDataSource.getAllHabits();
      logger.info('습관 ${habits.length}개 내보내기 성공', tag: _tag);
      return habits;
    } catch (e, stackTrace) {
      logger.error(
        '습관 데이터 내보내기 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// 습관 데이터 가져오기 (백업에서 복원)
  @override
  Future<bool> importHabits(List<HabitDto> habits) async {
    try {
      logger.debug('습관 데이터 가져오기: ${habits.length}개', tag: _tag);

      int successCount = 0;
      for (final habit in habits) {
        final success = await _localDataSource.insertHabit(habit);
        if (success) successCount++;
      }

      logger.info(
        '습관 데이터 가져오기 완료: $successCount/${habits.length}개 성공',
        tag: _tag,
      );
      return successCount > 0;
    } catch (e, stackTrace) {
      logger.error(
        '습관 데이터 가져오기 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
