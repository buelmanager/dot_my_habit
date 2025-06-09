// lib/presentation/screens/pattern/widgets/ai_pattern_prediction.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// AI 패턴 예측 위젯
class AIPatternPrediction extends ConsumerWidget {
  const AIPatternPrediction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final weeklyProgress = viewModel.state.weeklyProgress;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _preparePredictionData(habits, weeklyProgress, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final predictionParams = snapshot.data!;

        return Consumer(
          builder: (context, ref, child) {
            final aiPredictionAsync = ref.watch(
              aiPredictionProvider(predictionParams),
            );

            return aiPredictionAsync.when(
              data: (prediction) => _buildPredictionCard(prediction),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(),
            );
          },
        );
      },
    );
  }

  /// 예측을 위한 데이터 준비
  Future<Map<String, dynamic>> _preparePredictionData(
    List<Habit> habits,
    Map<String, double> weeklyProgress,
    dynamic repository,
  ) async {
    try {
      logger.debug('🔮 AI 예측 데이터 준비 시작');

      // 월간 트렌드 계산
      final today = DateTime.now();
      final monthlyTrends = <String, dynamic>{};

      // 최근 4주간의 주간 완료율 추이
      final weeklyTrends = <double>[];

      for (int week = 0; week < 4; week++) {
        final weekStart = today.subtract(
          Duration(days: (week * 7) + today.weekday - 1),
        );

        logger.debug(
          '📅 Week $week 데이터 수집: ${weekStart.toString().split(' ')[0]}',
        );

        try {
          final weekProgress = await repository.getWeeklyProgress(weekStart);

          if (weekProgress != null && weekProgress.isNotEmpty) {
            // 타입 안전한 평균 계산
            double weekAvg = 0.0;
            double totalSum = 0.0;
            int validCount = 0;

            // Map의 각 값을 안전하게 double로 변환
            weekProgress.forEach((key, value) {
              if (value != null) {
                double doubleValue;
                if (value is double) {
                  doubleValue = value;
                } else if (value is int) {
                  doubleValue = value.toDouble();
                } else if (value is num) {
                  doubleValue = value.toDouble();
                } else {
                  // String이나 다른 타입인 경우 파싱 시도
                  try {
                    doubleValue = double.parse(value.toString());
                  } catch (e) {
                    logger.warning('⚠️ 값 파싱 실패 ($key: $value), 0.0으로 대체');
                    doubleValue = 0.0;
                  }
                }
                totalSum += doubleValue;
                validCount++;
              }
            });

            if (validCount > 0) {
              weekAvg = totalSum / validCount;
              weeklyTrends.insert(0, weekAvg); // 시간순으로 정렬 (가장 오래된 것부터)
              logger.debug(
                '📊 Week $week 평균: ${(weekAvg * 100).toStringAsFixed(1)}%',
              );
            } else {
              logger.debug('📊 Week $week: 유효한 데이터 없음');
              weeklyTrends.insert(0, 0.0);
            }
          } else {
            logger.debug('📊 Week $week: 데이터 없음');
            weeklyTrends.insert(0, 0.0);
          }
        } catch (e) {
          logger.warning('⚠️ Week $week 데이터 수집 실패: $e');
          weeklyTrends.insert(0, 0.0);
        }
      }

      logger.debug(
        '📈 주간 트렌드 데이터: ${weeklyTrends.map((v) => '${(v * 100).toStringAsFixed(1)}%').join(', ')}',
      );

      monthlyTrends['weeklyTrends'] = weeklyTrends;
      monthlyTrends['trendDirection'] = _calculateTrendDirection(weeklyTrends);
      monthlyTrends['consistency'] = _calculateConsistency(weeklyTrends);

      logger.info('✅ AI 예측 데이터 준비 완료');

      return {
        'habits': habits,
        'weeklyProgress': weeklyProgress,
        'monthlyTrends': monthlyTrends,
      };
    } catch (e) {
      logger.error('❌ AI 예측 데이터 준비 실패: $e');

      // 에러 발생 시 기본값 반환
      final fallbackTrends = <double>[0.0, 0.0, 0.0, 0.0];
      return {
        'habits': habits,
        'weeklyProgress': weeklyProgress,
        'monthlyTrends': {
          'weeklyTrends': fallbackTrends,
          'trendDirection': 'stable',
          'consistency': 0.5,
        },
      };
    }
  }

  /// 트렌드 방향 계산
  String _calculateTrendDirection(List<double> trends) {
    if (trends.length < 2) return 'stable';

    try {
      final firstHalf = trends.take(trends.length ~/ 2).toList();
      final secondHalf = trends.skip(trends.length ~/ 2).toList();

      // 타입 안전한 평균 계산
      double firstAvg = 0.0;
      double secondAvg = 0.0;

      if (firstHalf.isNotEmpty) {
        firstAvg =
            firstHalf.fold<double>(0.0, (sum, value) => sum + value) /
            firstHalf.length;
      }

      if (secondHalf.isNotEmpty) {
        secondAvg =
            secondHalf.fold<double>(0.0, (sum, value) => sum + value) /
            secondHalf.length;
      }

      const threshold = 0.1; // 10% 차이

      if (secondAvg > firstAvg + threshold) {
        return 'improving';
      } else if (secondAvg < firstAvg - threshold) {
        return 'declining';
      } else {
        return 'stable';
      }
    } catch (e) {
      logger.warning('⚠️ 트렌드 방향 계산 실패: $e');
      return 'stable';
    }
  }

  /// 일관성 계산
  double _calculateConsistency(List<double> trends) {
    if (trends.length < 2) return 1.0;

    try {
      // 평균 계산
      final mean =
          trends.fold<double>(0.0, (sum, value) => sum + value) / trends.length;

      // 분산 계산
      double variance = 0.0;
      for (final value in trends) {
        final diff = value - mean;
        variance += diff * diff;
      }
      variance /= trends.length;

      // 일관성은 분산의 역수 (0.0 ~ 1.0)
      // 분산이 클수록 일관성은 낮아짐
      if (variance == 0.0) {
        return 1.0; // 완전히 일관됨
      }

      // 정규화된 일관성 점수 (0.0 ~ 1.0)
      final consistency = 1.0 / (1.0 + variance * 10.0); // 10.0은 스케일링 팩터
      return consistency.clamp(0.0, 1.0);
    } catch (e) {
      logger.warning('⚠️ 일관성 계산 실패: $e');
      return 0.5; // 기본값
    }
  }

  /// 예측 카드 위젯
  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final predictions = prediction['predictions'] as Map<String, dynamic>?;
    final riskFactors = List<String>.from(prediction['riskFactors'] ?? []);
    final opportunities = List<String>.from(prediction['opportunities'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_outlined,
                  size: 20,
                  color: Colors.indigo.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 패턴 예측',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PREDICT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 예측 요약
          if (predictions != null) _buildPredictionSummary(predictions),

          const SizedBox(height: 20),

          // 위험 요소와 기회
          Row(
            children: [
              // 위험 요소
              Expanded(
                child: _buildFactorSection(
                  '주의할 점',
                  riskFactors.take(2).toList(),
                  Icons.warning_outlined,
                  Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 12),
              // 기회
              Expanded(
                child: _buildFactorSection(
                  '개선 기회',
                  opportunities.take(2).toList(),
                  Icons.lightbulb_outlined,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 실행 계획
          if (prediction['actionPlan'] != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 18,
                    color: Colors.indigo.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '추천 액션 플랜',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prediction['actionPlan'],
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 예측 요약 위젯
  Widget _buildPredictionSummary(Map<String, dynamic> predictions) {
    final nextWeek = predictions['nextWeekSuccess'] as Map<String, dynamic>?;
    final nextMonth = predictions['nextMonthGoal'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다음 주 예측
          if (nextWeek != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      size: 16,
                      color: Colors.indigo.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '다음 주 성공 예측',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        nextWeek['probability'] ?? '75%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextWeek['reasoning'] ?? '현재 패턴 유지 시 성공 가능성 높음',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          if (nextWeek != null && nextMonth != null) const SizedBox(height: 12),

          // 다음 달 목표
          if (nextMonth != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: Colors.purple.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '다음 달 전망',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nextMonth['achievement'] ?? '목표 달성 가능성 높음',
                  style: const TextStyle(fontSize: 12),
                ),
                if (nextMonth['bestHabit'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '성공 예상: ${nextMonth['bestHabit']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 요소 섹션 위젯
  Widget _buildFactorSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(fontSize: 11, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(
            'AI가 패턴을 예측하고 있습니다...',
            style: TextStyle(fontSize: 14, color: Colors.indigo.shade700),
          ),
        ],
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'AI 예측을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
