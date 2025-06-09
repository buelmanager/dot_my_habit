// lib/presentation/screens/pattern/views/pattern_analytics_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

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
    developer.log('PatternAnalyticsView 빌드', name: 'PatternAnalyticsView');
    print('PatternAnalyticsView 빌드');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final repository = ref.read(habitRepositoryProvider);

    developer.log(
      '분석 화면 - 습관 수: ${habits.length}',
      name: 'PatternAnalyticsView',
    );
    print('분석 화면 - 습관 수: ${habits.length}');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habits.isEmpty)
            _buildEmptyState(
              '습관을 추가하면 분석이 시작됩니다',
              '습관 추가 후 데이터가 쌓이면 상세한 분석 결과를 확인할 수 있습니다.',
            )
          else
            FutureBuilder<Map<String, dynamic>>(
              // 분석 데이터 로드
              future: _loadAnalyticsData(habits, repository),
              builder: (context, snapshot) {
                // 에러 처리
                if (snapshot.hasError) {
                  developer.log(
                    '분석 데이터 로드 에러: ${snapshot.error}',
                    name: 'PatternAnalyticsView',
                  );
                  print('분석 데이터 로드 에러: ${snapshot.error}');

                  return _buildEmptyState(
                    '데이터 로드 중 오류가 발생했습니다',
                    '잠시 후 다시 시도해 주세요.',
                  );
                }

                // 로딩 중
                if (!snapshot.hasData) {
                  developer.log('분석 데이터 로딩 중...', name: 'PatternAnalyticsView');
                  print('분석 데이터 로딩 중...');

                  return const SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '분석 데이터를 로드하고 있습니다...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final analyticsData = snapshot.data!;
                final hasEnoughData = analyticsData['hasEnoughData'] as bool;
                final totalDataPoints = analyticsData['totalDataPoints'] as int;
                final daysWithData = analyticsData['daysWithData'] as int;

                developer.log(
                  '분석 데이터 로드 완료 - 충분한 데이터: $hasEnoughData, 총 데이터 포인트: $totalDataPoints, 데이터가 있는 날: $daysWithData',
                  name: 'PatternAnalyticsView',
                );
                print(
                  '분석 데이터 로드 완료 - 충분한 데이터: $hasEnoughData, 총 데이터 포인트: $totalDataPoints, 데이터가 있는 날: $daysWithData',
                );

                if (!hasEnoughData) {
                  return _buildInsufficientDataState(
                    daysWithData,
                    totalDataPoints,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 분석 상태 헤더
                    _buildAnalyticsHeader(daysWithData, totalDataPoints),

                    const SizedBox(height: 24),

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

  /// 분석 데이터 로드
  Future<Map<String, dynamic>> _loadAnalyticsData(
    List<Habit> habits,
    dynamic repository,
  ) async {
    try {
      developer.log('분석 데이터 로드 시작', name: 'PatternAnalyticsView');
      print('분석 데이터 로드 시작');

      if (habits.isEmpty) {
        return {
          'hasEnoughData': false,
          'totalDataPoints': 0,
          'daysWithData': 0,
          'reason': 'no_habits',
        };
      }

      // 최근 30일간 데이터 확인
      int totalDataPoints = 0;
      int daysWithData = 0;
      int daysWithCompletedHabits = 0;
      final today = DateTime.now();

      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));

        try {
          final habitsOnDate = await repository.getHabitsForDate(date);

          if (habitsOnDate.isNotEmpty) {
            daysWithData++;
            int habitCount = habitsOnDate.length;
            totalDataPoints += habitCount;

            // 완료된 습관이 있는지 확인
            bool hasCompletedHabits = false;
            int completedCount = 0;
            for (final habit in habitsOnDate) {
              if (habit.isCompleted) {
                hasCompletedHabits = true;
                completedCount++;
              }
            }

            if (hasCompletedHabits) {
              daysWithCompletedHabits++;
            }

            developer.log(
              'Day $day (${date.toString().split(' ')[0]}): $habitCount habits, $completedCount completed',
              name: 'PatternAnalyticsView',
            );
          }
        } catch (e) {
          developer.log('Day $day 데이터 로드 에러: $e', name: 'PatternAnalyticsView');
          print('Day $day 데이터 로드 에러: $e');
        }
      }

      developer.log(
        '분석 데이터 수집 완료 - 데이터가 있는 날: $daysWithData, 완료된 습관이 있는 날: $daysWithCompletedHabits, 총 데이터 포인트: $totalDataPoints',
        name: 'PatternAnalyticsView',
      );
      print(
        '분석 데이터 수집 완료 - 데이터가 있는 날: $daysWithData, 완료된 습관이 있는 날: $daysWithCompletedHabits, 총 데이터 포인트: $totalDataPoints',
      );

      // 분석에 충분한 데이터 조건:
      // 1. 최소 7일 이상의 데이터가 있어야 함
      // 2. 최소 5일 이상 완료된 습관이 있어야 함
      // 3. 총 데이터 포인트가 20개 이상이어야 함
      final hasEnoughData =
          daysWithData >= 7 &&
          daysWithCompletedHabits >= 5 &&
          totalDataPoints >= 20;

      developer.log(
        '분석 가능 여부: $hasEnoughData (조건: 데이터 7일+=${daysWithData >= 7}, 완료 5일+=${daysWithCompletedHabits >= 5}, 포인트 20+=${totalDataPoints >= 20})',
        name: 'PatternAnalyticsView',
      );
      print(
        '분석 가능 여부: $hasEnoughData (조건: 데이터 7일+=${daysWithData >= 7}, 완료 5일+=${daysWithCompletedHabits >= 5}, 포인트 20+=${totalDataPoints >= 20})',
      );

      return {
        'hasEnoughData': hasEnoughData,
        'totalDataPoints': totalDataPoints,
        'daysWithData': daysWithData,
        'daysWithCompletedHabits': daysWithCompletedHabits,
      };
    } catch (e, stackTrace) {
      developer.log('분석 데이터 로드 실패: $e', name: 'PatternAnalyticsView');
      print('분석 데이터 로드 실패: $e');
      print('Stack trace: $stackTrace');

      rethrow;
    }
  }

  /// 분석 상태 헤더
  Widget _buildAnalyticsHeader(int daysWithData, int totalDataPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 24,
            color: Colors.black.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '분석 활성화됨',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysWithData일의 데이터, $totalDataPoints개의 습관 기록 분석',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '활성',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 데이터 부족 상태 위젯
  Widget _buildInsufficientDataState(int daysWithData, int totalDataPoints) {
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
            Icons.pending_actions_outlined,
            size: 64,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          const Text(
            '조금 더 데이터가 필요해요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            '현재 $daysWithData일의 데이터가 수집되었습니다.\n심층 분석을 위해 최소 7일의 완성된 데이터가 필요합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '분석 활성화 조건',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 최소 7일 이상의 습관 기록\n• 최소 5일 이상 완료된 습관\n• 총 20개 이상의 습관 데이터',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 일반 빈 상태 위젯
  Widget _buildEmptyState(String title, String description) {
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
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.4),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
