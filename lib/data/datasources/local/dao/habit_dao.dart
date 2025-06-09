import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../../../../core/logger.dart';
import '../../../dtos/habit_dto.dart';
import '../database.dart';

/// 습관 데이터 접근 객체 (DAO)
class HabitDao {
  // 로그 태그
  static const String _tag = 'HabitDao';

  /// 새 습관 삽입
  Future<bool> insertHabit(HabitDto habit) async {
    try {
      logger.debug('습관 삽입: ${habit.id}');
      final db = await AppDatabase.database;

      await db.insert(
        DatabaseConstants.habitsTable,
        habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      logger.info('습관 삽입 성공: ${habit.id}', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error(
        '습관 삽입 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 습관 업데이트
  Future<bool> updateHabit(HabitDto habit) async {
    try {
      logger.debug('습관 업데이트: ${habit.id}', tag: _tag);
      final db = await AppDatabase.database;

      await db.update(
        DatabaseConstants.habitsTable,
        habit.toMap(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );

      logger.info('습관 업데이트 성공: ${habit.id}', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error(
        '습관 업데이트 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 습관 삭제
  Future<bool> deleteHabit(String habitId) async {
    try {
      logger.debug('습관 삭제: $habitId', tag: _tag);
      final db = await AppDatabase.database;

      await db.delete(
        DatabaseConstants.habitsTable,
        where: 'id = ?',
        whereArgs: [habitId],
      );

      // 관련 로그도 삭제
      await db.delete(
        DatabaseConstants.habitLogsTable,
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      logger.info('습관 삭제 성공: $habitId', tag: _tag);
      return true;
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

  /// 특정 습관 가져오기
  Future<HabitDto?> getHabit(String habitId) async {
    try {
      logger.debug('습관 조회: $habitId', tag: _tag);
      final db = await AppDatabase.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.habitsTable,
        where: 'id = ?',
        whereArgs: [habitId],
      );

      if (maps.isEmpty) {
        logger.debug('습관 조회 결과 없음: $habitId', tag: _tag);
        return null;
      }

      logger.debug('습관 조회 성공: $habitId', tag: _tag);
      return HabitDtoExtension.fromMap(maps.first);
    } catch (e, stackTrace) {
      logger.error(
        '습관 조회 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 모든 습관 가져오기
  Future<List<HabitDto>> getAllHabits() async {
    try {
      logger.debug('모든 습관 조회', tag: _tag);
      final db = await AppDatabase.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.habitsTable,
        orderBy: 'createdAt ASC',
      );

      logger.debug('모든 습관 조회 결과: ${maps.length}개', tag: _tag);
      return maps.map((map) => HabitDtoExtension.fromMap(map)).toList();
    } catch (e, stackTrace) {
      logger.error(
        '모든 습관 조회 실패: ${e.toString()}',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// 특정 날짜의 습관 상태 가져오기
  Future<List<HabitDto>> getHabitsForDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      //logger.debug('날짜별 습관 조회: $dateStr', tag: _tag);

      final db = await AppDatabase.database;

      // 1. 모든 습관 조회
      final List<Map<String, dynamic>> habitMaps = await db.query(
        DatabaseConstants.habitsTable,
        orderBy: 'createdAt ASC',
      );

      if (habitMaps.isEmpty) {
        logger.debug('습관이 없음', tag: _tag);
        return [];
      }

      // 2. 해당 날짜의 로그 조회
      final List<Map<String, dynamic>> logMaps = await db.query(
        DatabaseConstants.habitLogsTable,
        where: 'date = ?',
        whereArgs: [dateStr],
      );

      // 3. 로그 데이터를 Map으로 변환
      final Map<String, Map<String, dynamic>> logsMap = {
        for (var log in logMaps) log['habitId'] as String: log,
      };

      // 4. 습관 데이터와 로그 데이터 병합
      List<HabitDto> habits = [];

      for (var habitMap in habitMaps) {
        final habitId = habitMap['id'] as String;
        final habit = HabitDtoExtension.fromMap(habitMap);

        // 해당 날짜에 로그가 있는지 확인
        if (logsMap.containsKey(habitId)) {
          final log = logsMap[habitId]!;
          // 습관의 완료 상태와 완료 시간 업데이트
          habits.add(
            habit.copyWith(
              isCompleted: (log['isCompleted'] as int) == 1,
              completedAt:
                  log['completedAt'] != null
                      ? DateTime.parse(log['completedAt'] as String)
                      : null,
            ),
          );
        } else {
          // 해당 날짜에 로그가 없으면 기본 상태 사용
          habits.add(habit.copyWith(isCompleted: false, completedAt: null));
        }
      }

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

  /// 습관 완료/미완료 상태 토글
  Future<bool> toggleHabit(
    String habitId,
    DateTime date,
    bool isCompleted,
  ) async {
    try {
      logger.debug('습관 토글: $habitId, 완료: $isCompleted', tag: _tag);
      final db = await AppDatabase.database;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final now = DateTime.now();

      // 트랜잭션 시작
      return await db.transaction((txn) async {
        // 1. 해당 날짜의 로그 확인
        final List<Map<String, dynamic>> logs = await txn.query(
          DatabaseConstants.habitLogsTable,
          where: 'habitId = ? AND date = ?',
          whereArgs: [habitId, dateStr],
        );

        // 2. 로그 업데이트 또는 삽입
        if (logs.isNotEmpty) {
          await txn.update(
            DatabaseConstants.habitLogsTable,
            {
              'isCompleted': isCompleted ? 1 : 0,
              'completedAt': isCompleted ? now.toIso8601String() : null,
            },
            where: 'habitId = ? AND date = ?',
            whereArgs: [habitId, dateStr],
          );
        } else {
          await txn.insert(DatabaseConstants.habitLogsTable, {
            'id': '$habitId-$dateStr',
            'habitId': habitId,
            'date': dateStr,
            'isCompleted': isCompleted ? 1 : 0,
            'completedAt': isCompleted ? now.toIso8601String() : null,
          });
        }

        // 3. 습관 스트릭(연속 달성) 계산 및 업데이트
        final streak = await _calculateStreak(txn, habitId, date);

        // 4. 습관 상태 업데이트
        await txn.update(
          DatabaseConstants.habitsTable,
          {'streak': streak, 'updatedAt': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [habitId],
        );

        logger.info(
          '습관 토글 성공: $habitId, 완료: $isCompleted, 스트릭: $streak',
          tag: _tag,
        );
        return true;
      });
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

  /// 습관의 연속 달성일(스트릭) 계산
  Future<int> _calculateStreak(
    Transaction txn,
    String habitId,
    DateTime date,
  ) async {
    logger.debug('스트릭 계산: $habitId', tag: _tag);

    // 오늘부터 과거까지 연속된 완료 상태 확인
    int streak = 0;
    DateTime currentDate = date;
    bool continueStreak = true;

    // 최대 31일까지만 확인 (성능 고려)
    for (int i = 0; i < 31 && continueStreak; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      final List<Map<String, dynamic>> logs = await txn.query(
        DatabaseConstants.habitLogsTable,
        where: 'habitId = ? AND date = ? AND isCompleted = 1',
        whereArgs: [habitId, dateStr],
      );

      // 해당 날짜에 완료된 로그가 있으면 스트릭 증가
      if (logs.isNotEmpty) {
        streak++;
        // 하루 전으로 이동
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // 완료되지 않은 날이 있으면 스트릭 중단
        continueStreak = false;
      }
    }

    logger.debug('스트릭 계산 결과: $habitId, $streak일', tag: _tag);
    return streak;
  }

  /// 주간 완료율 데이터 가져오기
  Future<Map<String, double>> getWeeklyProgress(DateTime date) async {
    try {
      logger.debug(
        '주간 완료율 조회: ${DateFormat('yyyy-MM-dd').format(date)}',
        tag: _tag,
      );

      // 현재 날짜가 포함된 주의 월요일 계산
      final int weekday = date.weekday;
      final DateTime monday = date.subtract(Duration(days: weekday - 1));

      // 결과 맵 (요일별 완료율)
      final Map<String, double> weeklyProgress = {};
      final List<String> dayNames = ['월', '화', '수', '목', '금', '토', '일'];

      // 각 요일별 완료율 계산
      for (int i = 0; i < 7; i++) {
        final DateTime currentDay = monday.add(Duration(days: i));
        final String dayName = dayNames[i];

        // 해당 날짜의 습관 목록 가져오기
        final habits = await getHabitsForDate(currentDay);

        // 완료율 계산
        if (habits.isEmpty) {
          weeklyProgress[dayName] = 0.0;
        } else {
          final completedCount = habits.where((h) => h.isCompleted).length;
          weeklyProgress[dayName] = completedCount / habits.length;
        }
      }

      logger.debug('주간 완료율 결과: $weeklyProgress', tag: _tag);
      return weeklyProgress;
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

  /// 가장 높은 스트릭을 가진 습관 가져오기
  Future<HabitDto?> getTopHabit() async {
    try {
      logger.debug('최고 스트릭 습관 조회', tag: _tag);
      final db = await AppDatabase.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.habitsTable,
        orderBy: 'streak DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        logger.debug('스트릭이 있는 습관 없음', tag: _tag);
        return null;
      }

      // 스트릭이 0인 습관은 반환하지 않음
      final habit = HabitDtoExtension.fromMap(maps.first);
      if (habit.streak <= 0) {
        logger.debug('스트릭이 0인 습관 제외', tag: _tag);
        return null;
      }

      logger.debug('최고 스트릭 습관: ${habit.id}, 스트릭: ${habit.streak}일', tag: _tag);
      return habit;
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
}
