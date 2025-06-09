// lib/presentation/screens/pattern/widgets/summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';

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
        // 기본값 30%
        final completionRate = snapshot.hasData ? snapshot.data! : 0.3;
        final percentValue = (completionRate * 100).toInt();

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
                  final weeklyCompletionRate =
                      summaryData['weeklyCompletionRate'] as double;
                  final monthlyCompletionRate =
                      summaryData['monthlyCompletionRate'] as double;
                  final averageCompletionTime =
                      summaryData['averageCompletionTime'] as String;

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
    // 최근 30일 데이터 조회
    final today = DateTime.now();
    int totalHabits = 0;
    int completedHabits = 0;

    // 지난 30일 동안의 데이터 확인
    for (int day = 0; day < 30; day++) {
      final date = today.subtract(Duration(days: day));
      final habits = await repository.getHabitsForDate(date);

      if (habits.isEmpty) continue;

      int len = habits.length;
      int whereLen = habits.where((h) => h.isCompleted);
      totalHabits += len;
      completedHabits += whereLen;
    }

    // 완료율 계산
    return totalHabits > 0 ? completedHabits / totalHabits : 0.0;
  }

  // 요약 데이터 가져오기
  Future<Map<String, dynamic>> _getSummaryData(dynamic repository) async {
    final result = <String, dynamic>{};
    final today = DateTime.now();

    // 1. 주간 완료율 계산
    final weeklyProgress = await repository.getWeeklyProgress(today);
    double weeklySum = 0.0;

    if (weeklyProgress.isNotEmpty) {
      for (final rate in weeklyProgress.values) {
        weeklySum += rate;
      }
      result['weeklyCompletionRate'] = weeklySum / weeklyProgress.length;
    } else {
      result['weeklyCompletionRate'] = 0.0;
    }

    // 2. 월간 완료율 계산
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    int monthlyTotalHabits = 0;
    int monthlyCompletedHabits = 0;

    for (int day = 1; day <= today.day; day++) {
      final date = DateTime(today.year, today.month, day);
      final habits = await repository.getHabitsForDate(date);

      if (habits.isEmpty) continue;

      int len = habits.length;
      int whereLen = habits.where((h) => h.isCompleted);

      monthlyTotalHabits += len;
      monthlyCompletedHabits += whereLen;
    }

    result['monthlyCompletionRate'] =
        monthlyTotalHabits > 0
            ? monthlyCompletedHabits / monthlyTotalHabits
            : 0.0;

    // 3. 평균 완료 시간 계산
    final completionTimes = <int, int>{}; // 시간별 완료 횟수
    int totalCompletions = 0;

    // 최근 30일 간의 완료 시간 데이터 수집
    for (int day = 0; day < 30; day++) {
      final date = today.subtract(Duration(days: day));
      final habits = await repository.getHabitsForDate(date);

      for (final habit in habits) {
        if (habit.isCompleted && habit.completedAt != null) {
          final hour = habit.completedAt!.hour;
          completionTimes[hour] = (completionTimes[hour] ?? 0) + 1;
          totalCompletions++;
        }
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

    // 시간을 '오전 10:00' 형식으로 변환
    final timeFormat = DateFormat('a h:mm', 'ko_KR');
    final timeStr = timeFormat.format(
      DateTime(today.year, today.month, today.day, mostFrequentHour, 0),
    );

    result['averageCompletionTime'] = timeStr;

    return result;
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
