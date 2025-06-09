// lib/presentation/screens/pattern/views/pattern_monthly_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../../app_providers.dart';
import '../widgets/monthly_calendar_heatmap.dart';
import '../widgets/monthly_goal_achievement_card.dart';
import '../widgets/habit_rank_item.dart';

/// 패턴 분석 월간 화면
class PatternMonthlyView extends ConsumerWidget {
  const PatternMonthlyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('PatternMonthlyView 빌드');
    developer.log('PatternMonthlyView 빌드', name: 'PatternMonthlyView');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월간 목표 달성률 카드 (MonthlyTrendChart 대신)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MonthlyGoalAchievementCard(),
          ),
          const SizedBox(height: 24),
          // 월간 캘린더 히트맵
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MonthlyCalendarHeatmap(),
          ),

          const SizedBox(height: 24),

          // 상위 습관 섹션 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              '이번 달 상위 습관',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
          ),

          // 습관 랭킹 리스트
          if (habits.isEmpty)
            _buildEmptyState()
          else
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getHabitRankings(habits, repository),
              builder: (context, snapshot) {
                // 에러 처리
                if (snapshot.hasError) {
                  developer.log(
                    '습관 랭킹 로드 에러: ${snapshot.error}',
                    name: 'PatternMonthlyView',
                  );
                  return _buildEmptyState();
                }

                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                final rankedHabits = snapshot.data!;

                if (rankedHabits.isEmpty) {
                  return _buildEmptyState();
                }

                developer.log(
                  '습관 랭킹 로드 완료: ${rankedHabits.length}개',
                  name: 'PatternMonthlyView',
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children:
                        rankedHabits
                            .take(3)
                            .map(
                              (rankData) => HabitRankItem(
                                habit: rankData['habit'],
                                rank: rankData['rank'],
                                completionRate: rankData['completionRate'],
                              ),
                            )
                            .toList(),
                  ),
                );
              },
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // 습관 랭킹 계산
  Future<List<Map<String, dynamic>>> _getHabitRankings(
    List<Habit> habits,
    dynamic repository,
  ) async {
    try {
      developer.log(
        '습관 랭킹 계산 시작: ${habits.length}개 습관',
        name: 'PatternMonthlyView',
      );

      if (habits.isEmpty) return [];

      final results = <Map<String, dynamic>>[];
      final selectedDate = DateTime.now();

      // 이번 달의 일수 계산
      final daysInMonth =
          DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      final today = DateTime.now();
      final maxDay =
          selectedDate.year == today.year && selectedDate.month == today.month
              ? today.day
              : daysInMonth;

      // 각 습관별로 이번 달 완료율 계산
      for (final habit in habits) {
        int totalDays = 0;
        int completedDays = 0;

        // 이번 달의 각 날짜별 체크
        for (int day = 1; day <= maxDay; day++) {
          final date = DateTime(selectedDate.year, selectedDate.month, day);

          try {
            // 해당 날짜의 습관 목록 조회
            final habitsOnDate = await repository.getHabitsForDate(date);

            // 해당 습관 찾기
            bool habitFound = false;
            bool habitCompleted = false;

            for (final habitOnDate in habitsOnDate) {
              if (habitOnDate.id == habit.id) {
                habitFound = true;
                habitCompleted = habitOnDate.isCompleted;
                break;
              }
            }

            if (habitFound) {
              totalDays++;
              if (habitCompleted) {
                completedDays++;
              }
            }
          } catch (e) {
            developer.log(
              'Day $day 데이터 로드 에러 (습관 ${habit.name}): $e',
              name: 'PatternMonthlyView',
            );
          }
        }

        // 완료율 계산
        final completionRate = totalDays > 0 ? completedDays / totalDays : 0.0;

        developer.log(
          '습관 "${habit.name}": $completedDays/$totalDays = ${(completionRate * 100).toInt()}%',
          name: 'PatternMonthlyView',
        );

        results.add({
          'habit': habit,
          'completionRate': completionRate,
          'completedDays': completedDays,
          'totalDays': totalDays,
          'rank': 0, // 일단 0으로 초기화
        });
      }

      // 완료율 기준으로 정렬
      results.sort(
        (a, b) => (b['completionRate'] as double).compareTo(
          a['completionRate'] as double,
        ),
      );

      // 랭킹 할당
      for (int i = 0; i < results.length; i++) {
        results[i]['rank'] = i + 1;
      }

      developer.log(
        '습관 랭킹 계산 완료: ${results.length}개 습관 정렬됨',
        name: 'PatternMonthlyView',
      );

      return results;
    } catch (e, stackTrace) {
      developer.log('습관 랭킹 계산 실패: $e', name: 'PatternMonthlyView');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '습관을 추가하면 월간 패턴이 표시됩니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
