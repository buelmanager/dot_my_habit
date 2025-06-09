// lib/presentation/screens/pattern/views/pattern_analytics_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../../app_providers.dart';
import '../widgets/ai_insights_summary.dart';
import '../widgets/ai_habit_recommendations.dart';
import '../widgets/ai_pattern_prediction.dart';
import '../widgets/habit_achievements_collection.dart';
import '../widgets/habit_correlation_chart.dart';

/// 패턴 분석 심층 분석 화면 (AI 통합)
class PatternAnalyticsView extends ConsumerWidget {
  const PatternAnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('PatternAnalyticsView 빌드');
    developer.log('PatternAnalyticsView 빌드', name: 'PatternAnalyticsView');

    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final habits = state.habits;
    final repository = ref.read(habitRepositoryProvider);

    developer.log(
      '분석 화면 - 습관 수: ${habits.length}',
      name: 'PatternAnalyticsView',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habits.isEmpty)
            _buildEmptyState(
              '습관을 추가하면 AI 분석이 시작됩니다',
              '습관 추가 후 데이터가 쌓이면 AI가 상세한 분석 결과를 제공합니다.',
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

                  return _buildEmptyState(
                    '데이터 로드 중 오류가 발생했습니다',
                    '잠시 후 다시 시도해 주세요.',
                  );
                }

                // 로딩 중
                if (!snapshot.hasData) {
                  developer.log('분석 데이터 로딩 중...', name: 'PatternAnalyticsView');

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
                            'AI가 분석 데이터를 준비하고 있습니다...',
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

                if (!hasEnoughData) {
                  return _buildInsufficientDataState(
                    daysWithData,
                    totalDataPoints,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // 분석 상태 헤더
                    _buildAnalyticsHeader(daysWithData, totalDataPoints),

                    const SizedBox(height: 24),
                    // 성취 배지 컬렉션
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: HabitAchievementsCollection(),
                    ),

                    const SizedBox(height: 24),

                    // ✨ AI 인사이트 요약 (새로 추가)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AIInsightsSummary(),
                    ),

                    // AI 패턴 예측 (새로 추가)
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: AIPatternPrediction(),
                    // ),
                    const SizedBox(height: 24),

                    // ✨ AI 습관 추천 (새로 추가)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AIHabitRecommendations(),
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

      if (habits.isEmpty) {
        return {
          'hasEnoughData': false,
          'totalDataPoints': 0,
          'daysWithData': 0,
          'reason': 'no_habits',
        };
      }

      // 최근 14일간 데이터 확인
      int totalDataPoints = 0;
      int daysWithData = 0;
      int daysWithCompletedHabits = 0;
      final today = DateTime.now();

      for (int day = 0; day < 14; day++) {
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
        }
      }

      developer.log(
        '분석 데이터 수집 완료 - 데이터가 있는 날: $daysWithData, 완료된 습관이 있는 날: $daysWithCompletedHabits, 총 데이터 포인트: $totalDataPoints',
        name: 'PatternAnalyticsView',
      );

      // 분석에 충분한 데이터 조건
      final hasEnoughData =
          daysWithData >= 3 &&
          daysWithCompletedHabits >= 1 &&
          totalDataPoints >= 6;

      developer.log(
        '분석 가능 여부: $hasEnoughData (조건: 데이터 3일+=${daysWithData >= 3}, 완료 1일+=${daysWithCompletedHabits >= 1}, 포인트 6+=${totalDataPoints >= 6})',
        name: 'PatternAnalyticsView',
      );

      return {
        'hasEnoughData': hasEnoughData,
        'totalDataPoints': totalDataPoints,
        'daysWithData': daysWithData,
        'daysWithCompletedHabits': daysWithCompletedHabits,
      };
    } catch (e, stackTrace) {
      developer.log('분석 데이터 로드 실패: $e', name: 'PatternAnalyticsView');
      rethrow;
    }
  }

  /// 분석 상태 헤더
  Widget _buildAnalyticsHeader(int daysWithData, int totalDataPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.05),
            Colors.black.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 24,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 분석 활성화됨',
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
              'LIVE',
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
            'AI가 분석할 데이터를 수집하고 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            '현재 $daysWithData일의 데이터가 수집되었습니다.\nAI 분석을 위해 최소 3일의 완성된 데이터가 필요합니다.',
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
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 분석 활성화 조건',
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
                  '• 최소 3일 이상의 습관 기록\n• 최소 1일 이상 완료된 습관\n• 꾸준한 습관 실행 패턴',
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
            Icons.psychology_outlined,
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
