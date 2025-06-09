// lib/presentation/screens/pattern/views/pattern_weekly_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../../app_providers.dart';
import '../widgets/weekly_heatmap_chart.dart';
import '../widgets/weekly_habit_item.dart';

/// 패턴 분석 주간 화면
class PatternWeeklyView extends ConsumerWidget {
  const PatternWeeklyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('PatternWeeklyView 빌드');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final selectedDate = state.selectedDate;
    final repository = ref.read(habitRepositoryProvider);

    // 현재 주의 시작일(월요일) 계산
    final int weekday = selectedDate.weekday;
    final DateTime weekStart = selectedDate.subtract(
      Duration(days: weekday - 1),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주간 히트맵 차트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: WeeklyHeatmapChart(),
          ),

          const SizedBox(height: 24),

          // 주간 습관 리스트 섹션 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              '주간 습관 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
          ),

          // 습관별 주간 데이터 표시
          if (habits.isEmpty)
            _buildEmptyState()
          else
            FutureBuilder<Map<String, Map<String, bool>>>(
              future: _fetchWeeklyHabitData(habits, weekStart, repository),
              builder: (context, snapshot) {
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

                final weeklyHabitData = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children:
                        habits
                            .map(
                              (habit) => WeeklyHabitItem(
                                habit: habit,
                                completionData: weeklyHabitData[habit.id] ?? {},
                                weekStart: weekStart,
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

  /// 주간 습관 데이터 가져오기
  Future<Map<String, Map<String, bool>>> _fetchWeeklyHabitData(
    List<Habit> habits,
    DateTime weekStart,
    dynamic repository,
  ) async {
    // 결과 데이터 맵: habitId -> (dateString -> isCompleted)
    final Map<String, Map<String, bool>> result = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    // 습관 ID별 맵 초기화
    for (final habit in habits) {
      result[habit.id] = {};
    }

    // 7일간의 데이터 가져오기
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateString = dateFormat.format(date);

      // 해당 날짜의 습관 목록 조회
      final habitsOnDate = await repository.getHabitsForDate(date);

      // 각 습관의 완료 상태 저장
      for (final habitOnDate in habitsOnDate) {
        if (result.containsKey(habitOnDate.id)) {
          result[habitOnDate.id]![dateString] = habitOnDate.isCompleted;
        }
      }
    }

    return result;
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
            Icons.view_week_outlined,
            size: 48,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '습관을 추가하면 주간 패턴이 표시됩니다',
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
