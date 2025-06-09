// lib/presentation/screens/pattern/widgets/habit_correlation_chart.dart
// 수정된 습관 연관성 차트

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 습관 상관관계 차트 위젯
class HabitCorrelationChart extends ConsumerWidget {
  const HabitCorrelationChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.info('🔗 HabitCorrelationChart 위젯 빌드 시작');

    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    logger.info('📊 연관성 분석 - 현재 습관 수: ${habits.length}');

    // 차트의 높이 계산
    final chartHeight = math.max(200.0, habits.length * 40.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                '습관 연관성 분석',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // 설명
          Text(
            '각 습관이 다른 습관의 완료에 미치는 영향',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 15),

          // 차트
          if (habits.isEmpty)
            _buildEmptyState()
          else if (habits.length < 2)
            _buildInsufficientDataState()
          else
            FutureBuilder<Map<String, Map<String, double>>>(
              future: _calculateCorrelations(habits, repository),
              builder: (context, snapshot) {
                logger.debug('🔄 연관성 계산 상태: ${snapshot.connectionState}');

                if (snapshot.hasError) {
                  logger.error('❌ 연관성 계산 오류: ${snapshot.error}');
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData) {
                  logger.debug('⏳ 연관성 데이터 로딩 중...');
                  return SizedBox(
                    height: chartHeight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }

                final correlations = snapshot.data!;
                logger.info('✅ 연관성 계산 완료: ${correlations.length}개 습관');

                return SizedBox(
                  height: chartHeight,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final habitCorrelations = correlations[habit.id] ?? {};

                      // 상관관계 값 목록 생성
                      final values =
                          habits
                              .map(
                                (h) =>
                                    h.id == habit.id
                                        ? 1.0 // 자기 자신과는 1.0
                                        : (habitCorrelations[h.id] ?? 0.0),
                              )
                              .toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // 습관 이름
                            SizedBox(
                              width: 80,
                              child: Text(
                                habit.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // 상관관계 막대 그래프
                            Expanded(
                              child: Row(
                                children: List.generate(
                                  values.length,
                                  (i) => Expanded(
                                    child: Container(
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            i == index
                                                ? Colors
                                                    .blue
                                                    .shade600 // 자기 자신
                                                : Colors.blue.withOpacity(
                                                  values[i],
                                                ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

          const SizedBox(height: 15),

          // 설명
          if (habits.length >= 2)
            FutureBuilder<Map<String, Map<String, double>>>(
              future: _calculateCorrelations(habits, repository),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final correlations = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCorrelationDescription(habits, correlations),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // 습관 간 상관관계 계산 (개선된 버전)
  Future<Map<String, Map<String, double>>> _calculateCorrelations(
    List<Habit> habits,
    dynamic repository,
  ) async {
    logger.info('🔄 습관 상관관계 계산 시작: ${habits.length}개 습관');

    if (habits.length < 2) {
      logger.warning('⚠️ 습관이 2개 미만이므로 상관관계 계산 불가');
      return {};
    }

    final result = <String, Map<String, double>>{};
    for (final habit in habits) {
      result[habit.id] = {};
    }

    try {
      // 지난 30일간의 데이터로 상관관계 계산
      final today = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd');

      // 각 습관별 날짜별 완료 상태 맵 생성
      final habitCompletionMaps = <String, Map<String, bool>>{};
      for (final habit in habits) {
        habitCompletionMaps[habit.id] = {};
      }

      logger.debug('📅 최근 30일 데이터 수집 시작');
      int totalDataDays = 0;

      // 30일간의 데이터 수집
      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));
        final dateString = dateFormat.format(date);

        try {
          // 해당 날짜의 모든 습관 조회
          final habitsOnDate = await repository.getHabitsForDate(date);

          if (habitsOnDate != null && habitsOnDate.isNotEmpty) {
            totalDataDays++;

            // 각 습관의 완료 상태 저장
            for (final habit in habits) {
              // 해당 날짜에 이 습관이 있는지 찾기 (Null Safety 개선)
              Habit? habitOnDate;
              try {
                habitOnDate = habitsOnDate.firstWhere((h) => h.id == habit.id);
              } catch (e) {
                // 해당 습관이 그 날에 없으면 null
                habitOnDate = null;
              }

              // 습관이 있으면 완료 상태 저장
              if (habitOnDate != null) {
                habitCompletionMaps[habit.id]![dateString] =
                    habitOnDate.isCompleted;
              }
            }
          }
        } catch (e) {
          logger.warning('⚠️ 날짜 ${dateString} 데이터 수집 실패: $e');
        }
      }

      logger.info('📊 데이터 수집 완료: $totalDataDays일치 데이터');

      // 상관관계 계산 (각 습관 쌍에 대해)
      for (int i = 0; i < habits.length; i++) {
        for (int j = 0; j < habits.length; j++) {
          if (i == j) continue; // 자신과의 상관관계는 건너뛰기

          final habit1 = habits[i];
          final habit2 = habits[j];

          final completions1 = habitCompletionMaps[habit1.id] ?? {};
          final completions2 = habitCompletionMaps[habit2.id] ?? {};

          // 두 습관 모두 데이터가 있는 날짜만 찾기
          final commonDates =
              completions1.keys
                  .toSet()
                  .intersection(completions2.keys.toSet())
                  .toList();

          if (commonDates.isEmpty) continue;

          // 상관관계 계산
          int bothCompleted = 0;
          int habit1OnlyCompleted = 0;

          for (final date in commonDates) {
            final isCompleted1 = completions1[date] ?? false;
            final isCompleted2 = completions2[date] ?? false;

            if (isCompleted1 && isCompleted2) {
              bothCompleted++;
            } else if (isCompleted1 && !isCompleted2) {
              habit1OnlyCompleted++;
            }
          }

          // habit1이 완료되었을 때 habit2가 완료된 비율
          double correlation = 0.0;
          if (bothCompleted + habit1OnlyCompleted > 0) {
            correlation = bothCompleted / (bothCompleted + habit1OnlyCompleted);
          }

          // 상관관계 저장
          result[habit1.id]![habit2.id] = correlation;

          logger.debug(
            '🔗 ${habit1.name} -> ${habit2.name}: ${(correlation * 100).toInt()}%',
          );
        }
      }

      logger.info('✅ 상관관계 계산 완료');
      return result;
    } catch (e, stackTrace) {
      logger.error('❌ 상관관계 계산 실패: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '습관을 추가해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // 데이터 부족 상태 위젯
  Widget _buildInsufficientDataState() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_usage_outlined,
            size: 32,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '연관성 분석을 위해서는\n최소 2개 이상의 습관이 필요합니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 에러 상태 위젯
  Widget _buildErrorState(String error) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            '데이터 로드 중 오류가 발생했습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 상관관계 설명 생성
  String _getCorrelationDescription(
    List<Habit> habits,
    Map<String, Map<String, double>> correlations,
  ) {
    if (habits.length < 2 || correlations.isEmpty) {
      return '데이터가 충분하지 않습니다.';
    }

    // 가장 높은 상관관계 찾기
    double highestCorrelation = 0.0;
    String habit1Name = '';
    String habit2Name = '';

    for (int i = 0; i < habits.length; i++) {
      for (int j = 0; j < habits.length; j++) {
        if (i == j) continue;

        final habit1 = habits[i];
        final habit2 = habits[j];

        final correlation = correlations[habit1.id]?[habit2.id] ?? 0.0;

        if (correlation > highestCorrelation) {
          highestCorrelation = correlation;
          habit1Name = habit1.name;
          habit2Name = habit2.name;
        }
      }
    }

    if (highestCorrelation > 0.7) {
      return '🔥 "$habit1Name"를 완료하면 "$habit2Name"도 ${(highestCorrelation * 100).toInt()}% 확률로 완료됩니다!';
    } else if (highestCorrelation > 0.5) {
      return '✨ "$habit1Name"와 "$habit2Name"는 어느 정도 연관성을 보입니다. (${(highestCorrelation * 100).toInt()}%)';
    } else if (highestCorrelation > 0.3) {
      return '💡 "$habit1Name"와 "$habit2Name"는 약간의 연관성을 보입니다. (${(highestCorrelation * 100).toInt()}%)';
    } else {
      return '📊 습관들 간의 뚜렷한 연관성이 아직 나타나지 않았습니다. 더 많은 데이터가 쌓이면 패턴을 발견할 수 있어요!';
    }
  }
}
