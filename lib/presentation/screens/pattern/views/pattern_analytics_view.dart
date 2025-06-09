// lib/presentation/screens/pattern/views/pattern_analytics_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../../app_providers.dart';
import '../widgets/habit_correlation_chart.dart';
import '../widgets/time_of_day_chart.dart';
import '../widgets/habit_prediction_card.dart';
import '../widgets/personal_report.dart';

/// 패턴 분석 심층 분석 화면
class PatternAnalyticsView extends ConsumerWidget {
  const PatternAnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('PatternAnalyticsView 빌드');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habits.isEmpty)
            _buildEmptyState()
          else
            FutureBuilder<bool>(
              // 분석에 충분한 데이터가 있는지 확인
              future: _hasEnoughData(habits, repository),
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

                final hasEnoughData = snapshot.data!;

                if (!hasEnoughData) {
                  return _buildEmptyState();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 습관 상관관계 분석
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: HabitCorrelationChart(),
                    ),

                    const SizedBox(height: 24),

                    // 시간대별 완료 패턴
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TimeOfDayChart(),
                    ),

                    const SizedBox(height: 24),

                    // 습관 달성 예측
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: HabitPredictionCard(),
                    ),

                    const SizedBox(height: 24),

                    // 개인 리포트
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PersonalReport(),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 심층 분석에 충분한 데이터가 있는지 확인
  Future<bool> _hasEnoughData(List<Habit> habits, dynamic repository) async {
    if (habits.isEmpty) return false;

    // 최소 7일 이상의 데이터가 필요
    int dataPointsCount = 0;
    final today = DateTime.now();

    // 최근 14일간 데이터 확인
    for (int day = 0; day < 14; day++) {
      final date = today.subtract(Duration(days: day));
      final habitsOnDate = await repository.getHabitsForDate(date);

      if (habitsOnDate.isNotEmpty) {
        // 해당 날짜에 완료된 습관이 있는지 확인
        final hasCompleted = habitsOnDate.any((h) => h.isCompleted);
        if (hasCompleted) {
          dataPointsCount++;
        }
      }
    }

    // 최소 7일 이상의 데이터가 있어야 함
    return dataPointsCount >= 7;
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 400,
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
            Icons.analytics_outlined,
            size: 64,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            '충분한 데이터가 쌓이면\n심층 분석이 활성화됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '최소 7일 이상의 습관 데이터가 필요합니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
