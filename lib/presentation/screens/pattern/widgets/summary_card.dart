// lib/presentation/screens/pattern/widgets/summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 패턴 요약 카드 위젯
class PatternSummaryCard extends ConsumerWidget {
  /// 생성자
  const PatternSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final repository = ref.read(habitRepositoryProvider);

    // 전체 완료율 가져오기
    return FutureBuilder<double>(
      future: _getOverallCompletionRate(repository),
      builder: (context, snapshot) {
        // 로딩 중이거나 에러가 있을 때 기본값 사용
        final completionRate = snapshot.hasData ? snapshot.data! : 0.0;
        final percentValue = (completionRate * 100).toInt();

        logger.info('=== 전체 완료율 UI 표시 ===');
        logger.info('전체 완료율: ${(completionRate * 100).toStringAsFixed(1)}%');

        String statusMessage;
        IconData statusIcon;

        if (completionRate >= 0.8) {
          statusMessage = '습관 형성이 잘 되고 있습니다!';
          statusIcon = Icons.sentiment_very_satisfied;
        } else if (completionRate >= 0.5) {
          statusMessage = '꾸준히 노력하고 있습니다.';
          statusIcon = Icons.sentiment_satisfied;
        } else if (completionRate >= 0.3) {
          statusMessage = '조금 더 노력해 보세요.';
          statusIcon = Icons.sentiment_neutral;
        } else {
          statusMessage = '새로운 시작을 해봐요.';
          statusIcon = Icons.sentiment_dissatisfied;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 상단 진행률 표시
              Row(
                children: [
                  // 원형 진행률
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        // 배경 원
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 8,
                            backgroundColor: Colors.black.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black.withOpacity(0.1),
                            ),
                          ),
                        ),
                        // 진행률 원
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: completionRate,
                            strokeWidth: 8,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        // 중앙 텍스트
                        Center(
                          child: Text(
                            '$percentValue%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // 오른쪽 상태 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '전체 완료율',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 이모지 아이콘
                  Icon(statusIcon, size: 32, color: Colors.black),
                ],
              ),

              const SizedBox(height: 15),

              // 하단 요약 정보 - 각각 실제 데이터 요청
              FutureBuilder<Map<String, dynamic>>(
                future: _getSummaryData(repository),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    logger.error('요약 데이터 로드 실패: ${snapshot.error}');
                    // 에러가 발생해도 기본값으로 표시
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('주간 완료율', '0%'),
                        _buildSummaryItem('월간 완료율', '0%'),
                        _buildSummaryItem('평균 완료 시간', '-'),
                      ],
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }

                  final summaryData = snapshot.data!;
                  logger.info('=== 요약 데이터 UI 표시 ===');
                  logger.info('요약 데이터: $summaryData');

                  final weeklyCompletionRate =
                      summaryData['weeklyCompletionRate'] as double;
                  final monthlyCompletionRate =
                      summaryData['monthlyCompletionRate'] as double;
                  final averageCompletionTime =
                      summaryData['averageCompletionTime'] as String;

                  logger.info(
                    '주간 완료율 UI: ${(weeklyCompletionRate * 100).toInt()}%',
                  );
                  logger.info(
                    '월간 완료율 UI: ${(monthlyCompletionRate * 100).toInt()}%',
                  );
                  logger.info('평균 완료 시간 UI: $averageCompletionTime');

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        '주간 완료율',
                        '${(weeklyCompletionRate * 100).toInt()}%',
                      ),
                      _buildSummaryItem(
                        '월간 완료율',
                        '${(monthlyCompletionRate * 100).toInt()}%',
                      ),
                      _buildSummaryItem('평균 완료 시간', averageCompletionTime),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 전체 완료율 계산 (저장소에서 가져오기)
  Future<double> _getOverallCompletionRate(dynamic repository) async {
    try {
      logger.info('📊 === 전체 완료율 계산 시작 ===');

      // 최근 30일 데이터 조회
      final today = DateTime.now();
      int totalHabits = 0;
      int completedHabits = 0;
      int daysWithHabits = 0;

      logger.info(
        '🗓️ 최근 30일 데이터 분석 시작 (${DateFormat('yyyy-MM-dd').format(today)}부터 역순)',
      );

      // 지난 30일 동안의 데이터 확인
      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));
        final habits = await repository.getHabitsForDate(date);

        if (habits.isEmpty) {
          // logger.debug('  ${DateFormat('yyyy-MM-dd').format(date)}: 습관 없음');
          continue;
        }

        daysWithHabits++;
        int dayTotal = habits.length;

        // 타입 안전한 방식으로 완료된 습관 수 계산
        int dayCompleted = 0;
        for (final habit in habits) {
          if (habit is Habit && habit.isCompleted) {
            dayCompleted++;
          }
        }

        totalHabits += dayTotal;
        completedHabits += dayCompleted;

        logger.info(
          '  ${DateFormat('yyyy-MM-dd').format(date)}: $dayCompleted/$dayTotal 완료 (${dayTotal > 0 ? ((dayCompleted / dayTotal) * 100).toStringAsFixed(1) : "0.0"}%)',
        );
      }

      // 완료율 계산
      final completionRate =
          totalHabits > 0 ? completedHabits / totalHabits : 0.0;

      logger.info('📈 === 전체 완료율 계산 결과 ===');
      logger.info('총 분석 기간: 30일');
      logger.info('습관이 있던 날수: $daysWithHabits일');
      logger.info('총 습관 수행 횟수: $totalHabits회');
      logger.info('총 완료 횟수: $completedHabits회');
      logger.info('전체 완료율: ${(completionRate * 100).toStringAsFixed(2)}%');
      logger.info('====================');

      return completionRate;
    } catch (e, stackTrace) {
      logger.error('❌ 전체 완료율 계산 실패', error: e, stackTrace: stackTrace);
      return 0.0;
    }
  }

  // 요약 데이터 가져오기
  Future<Map<String, dynamic>> _getSummaryData(dynamic repository) async {
    try {
      logger.info('📊 === 요약 데이터 계산 시작 ===');

      final result = <String, dynamic>{};
      final today = DateTime.now();

      // 1. 주간 완료율 계산
      logger.info('📅 주간 완료율 계산 중...');
      final weeklyProgress = await repository.getWeeklyProgress(today);
      logger.info('주간 진행률 원본 데이터: $weeklyProgress');

      if (weeklyProgress.isNotEmpty) {
        double weeklySum = 0.0;
        int validDays = 0;

        weeklyProgress.forEach((day, rate) {
          logger.info('  $day: ${(rate * 100).toStringAsFixed(1)}%');
          weeklySum += rate;
          validDays++;
        });

        result['weeklyCompletionRate'] = weeklySum / weeklyProgress.length;
        logger.info(
          '주간 완료율 계산: $weeklySum / $validDays = ${(result['weeklyCompletionRate'] * 100).toStringAsFixed(2)}%',
        );
      } else {
        result['weeklyCompletionRate'] = 0.0;
        logger.warning('주간 데이터 없음, 0%로 설정');
      }

      // 2. 월간 완료율 계산
      logger.info('📅 월간 완료율 계산 중...');
      int monthlyTotalHabits = 0;
      int monthlyCompletedHabits = 0;
      int monthDaysWithHabits = 0;

      logger.info(
        '이번 달 분석 기간: ${today.year}년 ${today.month}월 1일 ~ ${today.day}일',
      );

      for (int day = 1; day <= today.day; day++) {
        final date = DateTime(today.year, today.month, day);
        final habits = await repository.getHabitsForDate(date);

        if (habits.isEmpty) continue;

        monthDaysWithHabits++;
        int dayTotal = habits.length;

        // 타입 안전한 방식으로 완료된 습관 수 계산
        int dayCompleted = 0;
        for (final habit in habits) {
          if (habit is Habit && habit.isCompleted) {
            dayCompleted++;
          }
        }

        monthlyTotalHabits += dayTotal;
        monthlyCompletedHabits += dayCompleted;

        logger.info('  ${day}일: $dayCompleted/$dayTotal 완료');
      }

      result['monthlyCompletionRate'] =
          monthlyTotalHabits > 0
              ? monthlyCompletedHabits / monthlyTotalHabits
              : 0.0;

      logger.info('월간 완료율 계산 결과:');
      logger.info('  습관이 있던 날수: $monthDaysWithHabits일');
      logger.info('  총 습관 수행 횟수: $monthlyTotalHabits회');
      logger.info('  총 완료 횟수: $monthlyCompletedHabits회');
      logger.info(
        '  월간 완료율: ${(result['monthlyCompletionRate'] * 100).toStringAsFixed(2)}%',
      );

      // 3. 평균 완료 시간 계산
      logger.info('⏰ 평균 완료 시간 계산 중...');
      final completionTimes = <int, int>{}; // 시간별 완료 횟수
      int totalCompletedWithTime = 0;

      // 최근 30일 간의 완료 시간 데이터 수집
      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));
        final habits = await repository.getHabitsForDate(date);

        for (final habit in habits) {
          if (habit is Habit &&
              habit.isCompleted &&
              habit.completedAt != null) {
            final hour = habit.completedAt!.hour;
            completionTimes[hour] = (completionTimes[hour] ?? 0) + 1;
            totalCompletedWithTime++;
          }
        }
      }

      logger.info('완료 시간 데이터 수집 결과:');
      logger.info('  완료 시간이 기록된 총 횟수: $totalCompletedWithTime회');

      if (completionTimes.isNotEmpty) {
        // 시간대별 완료 횟수 출력
        final sortedHours = completionTimes.keys.toList()..sort();
        for (final hour in sortedHours) {
          final count = completionTimes[hour]!;
          final percentage = (count / totalCompletedWithTime * 100)
              .toStringAsFixed(1);
          logger.info('  ${hour}시: ${count}회 ($percentage%)');
        }
      }

      // 가장 빈도가 높은 시간 찾기
      int mostFrequentHour = 15; // 기본값: 오후 3시
      int maxCount = 0;

      completionTimes.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentHour = hour;
        }
      });

      // 시간을 '오전/오후 시간' 형식으로 변환
      String timeStr;
      if (completionTimes.isEmpty) {
        timeStr = '-'; // 데이터가 없을 때
        logger.info('완료 시간 데이터 없음');
      } else {
        if (mostFrequentHour == 0) {
          timeStr = '오전 12시';
        } else if (mostFrequentHour < 12) {
          timeStr = '오전 ${mostFrequentHour}시';
        } else if (mostFrequentHour == 12) {
          timeStr = '오후 12시';
        } else {
          timeStr = '오후 ${mostFrequentHour - 12}시';
        }
        logger.info(
          '가장 많이 완료한 시간: $mostFrequentHour시 (${maxCount}회) -> $timeStr',
        );
      }

      result['averageCompletionTime'] = timeStr;

      logger.info('📊 === 요약 데이터 계산 완료 ===');
      logger.info('최종 결과:');
      logger.info(
        '  주간 완료율: ${(result['weeklyCompletionRate'] * 100).toStringAsFixed(2)}%',
      );
      logger.info(
        '  월간 완료율: ${(result['monthlyCompletionRate'] * 100).toStringAsFixed(2)}%',
      );
      logger.info('  평균 완료 시간: ${result['averageCompletionTime']}');
      logger.info('====================');

      return result;
    } catch (e, stackTrace) {
      logger.error('❌ 요약 데이터 계산 실패', error: e, stackTrace: stackTrace);

      // 기본값 반환
      return {
        'weeklyCompletionRate': 0.0,
        'monthlyCompletionRate': 0.0,
        'averageCompletionTime': '-',
      };
    }
  }

  // 요약 아이템 위젯
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }
}
