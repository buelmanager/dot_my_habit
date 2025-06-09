// lib/presentation/screens/pattern/views/pattern_summary_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../../app_providers.dart';
import '../widgets/summary_card.dart';
import '../widgets/habit_progress_card.dart';
import '../widgets/longest_streak_card.dart';
import '../widgets/weekly_pattern_chart.dart';

/// 패턴 분석 요약 화면
class PatternSummaryView extends ConsumerWidget {
  const PatternSummaryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('PatternSummaryView 빌드');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final repository = ref.read(habitRepositoryProvider);

    // 가장 길게 유지한 습관 찾기
    return FutureBuilder<Habit?>(
      future: repository.getTopHabit(),
      builder: (context, snapshot) {
        // 최장 스트릭 습관
        final longestStreakHabit = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 요약 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PatternSummaryCard(),
              ),

              const SizedBox(height: 24),

              // 습관별 성과 섹션 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  '습관별 성과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.9),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 습관 성과 리스트
              if (habits.isEmpty)
                _buildEmptyState()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children:
                        habits
                            .map((habit) => HabitProgressCard(habit: habit))
                            .toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // 가장 긴 연속 기록
              if (longestStreakHabit != null && longestStreakHabit.streak > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LongestStreakCard(habit: longestStreakHabit),
                ),

              const SizedBox(height: 24),

              // 주간 패턴 섹션 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  '주간 패턴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.9),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 주간 패턴 차트
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: WeeklyPatternChart(),
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '습관을 추가하면 분석이 시작됩니다',
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
