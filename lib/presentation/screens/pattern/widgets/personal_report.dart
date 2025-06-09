// lib/presentation/screens/pattern/widgets/personal_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 개인 리포트 위젯
class PersonalReport extends ConsumerWidget {
  const PersonalReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>>(
        future: _generateReportData(habits, repository),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
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
              height: 200,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            );
          }

          final reportData = snapshot.data!;
          final bestHabit = reportData['bestHabit'] as Habit?;
          final worstHabit = reportData['worstHabit'] as Habit?;
          final optimalTime = reportData['optimalTime'] as String;
          final predictedCompletionRate = reportData['predictedCompletionRate'] as int;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                const Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '개인 리포트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 강점 습관
                if (bestHabit != null)
                  _buildReportSection(
                    '가장 잘하는 습관',
                    '${bestHabit.name}',
                    '${bestHabit.streak}일 연속으로 실천하고 있어요. 정말 대단해요!',
                    Icons.thumb_up_outlined,
                    Colors.black,
                  ),

                if (bestHabit != null)
                  const SizedBox(height: 15),

                // 개선 필요 습관
                if (worstHabit != null && bestHabit != null && worstHabit.id != bestHabit.id)
                  _buildReportSection(
                    '개선이 필요한 습관',
                    '${worstHabit.name}',
                    '조금 더 신경써보세요. 매일 조금씩 실천하면 습관이 됩니다.',
                    Icons.trending_up,
                    Colors.black54,
                  ),

                if (worstHabit != null && bestHabit != null && worstHabit.id != bestHabit.id)
                  const SizedBox(height: 15),

                // 최적 시간대
                _buildReportSection(
                  '최적의 습관 실천 시간',
                  optimalTime,
                  '이 시간대에 습관을 완료하면 성공률이 높아요.',
                  Icons.access_time_outlined,
                  Colors.black,
                ),

                const SizedBox(height: 20),

                // 미래 예측
                Text(
                  '앞으로의 예측',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '현재 추세라면 다음 달 평균 완료율은 $predictedCompletionRate% 정도가 될 것으로 예상됩니다.',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // 개인 리포트 데이터 생성
  Future<Map<String, dynamic>> _generateReportData(
      List<Habit> habits,
      dynamic repository
      ) async {
    final result = <String, dynamic>{};

    // 1. 가장 스트릭이 높은 습관 찾기
    Habit? bestHabit;
    if (habits.isNotEmpty) {
      bestHabit = await repository.getTopHabit();
      result['bestHabit'] = bestHabit;
    }

    // 2. 가장 완료율이 낮은 습관 찾기
    if (habits.length > 1) {
      final completionRates = <String, double>{};
      final today = DateTime.now();

      // 각 습관의 최근 완료율 계산
      for (final habit in habits) {
        int completedDays = 0;
        int totalDays = 14;  // 최근 14일 확인

        for (int day = 0; day < totalDays; day++) {
          final date = today.subtract(Duration(days: day));
          final habitsOnDate = await repository.getHabitsForDate(date);

          final habitOnDate = habitsOnDate.firstWhere(
                  (h) => h.id == habit.id,
              orElse: () => null
          );

          if (habitOnDate != null && habitOnDate.isCompleted) {
            completedDays++;
          }
        }

        completionRates[habit.id] = completedDays / totalDays;
      }

      // 완료율이 가장 낮은 습관 찾기
      double lowestRate = 1.0;
      Habit? worstHabit;

      for (final habit in habits) {
        final rate = completionRates[habit.id] ?? 0.0;
        if (rate < lowestRate) {
          lowestRate = rate;
          worstHabit = habit;
        }
      }

      result['worstHabit'] = worstHabit;
    }

    // 3. 최적의 습관 완료 시간 찾기
    String optimalTime = '알 수 없음';
    if (habits.isNotEmpty) {
      final hourlySuccessRates = await _calculateHourlySuccessRates(habits, repository);
      if (hourlySuccessRates.isNotEmpty) {
        // 가장 성공률이 높은 시간대 찾기
        int bestHour = 0;
        double bestRate = 0.0;

        hourlySuccessRates.forEach((hour, rate) {
          if (rate > bestRate) {
            bestRate = rate;
            bestHour = hour;
          }
        });

        // 시간대 포맷팅
        final startHour = bestHour;
        final endHour = (bestHour + 2) % 24; // 2시간 구간

        optimalTime = '${startHour.toString().padLeft(2, '0')}시 ~ ${endHour.toString().padLeft(2, '0')}시';
      }
    }
    result['optimalTime'] = optimalTime;

    // 4. 다음 달 예상 완료율 계산
    int predictedCompletionRate = 70; // 기본값

    if (habits.isNotEmpty) {
      // 최근 월간 완료율 추세 분석
      final today = DateTime.now();
      final thisMonth = DateTime(today.year, today.month, 1);
      final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1, 1);

      // 이번 달 완료율
      final thisMonthRate = await _calculateMonthCompletionRate(habits, thisMonth, repository);

      // 지난 달 완료율
      final lastMonthRate = await _calculateMonthCompletionRate(habits, lastMonth, repository);

      // 변화량 계산 및 다음 달 예측
      if (thisMonthRate > 0 && lastMonthRate > 0) {
        final monthlyChange = thisMonthRate - lastMonthRate;

        // 단순 선형 예측 (최대 100%, 최소 0%)
        predictedCompletionRate = ((thisMonthRate + monthlyChange) * 100).toInt();
        predictedCompletionRate = predictedCompletionRate.clamp(0, 100);
      } else if (thisMonthRate > 0) {
        // 이번 달 데이터만 있는 경우
        predictedCompletionRate = (thisMonthRate * 100).toInt();
      }
    }
    result['predictedCompletionRate'] = predictedCompletionRate;

    return result;
  }

  // 시간대별 습관 성공률 계산
  Future<Map<int, double>> _calculateHourlySuccessRates(
      List<Habit> habits,
      dynamic repository
      ) async {
    final result = <int, double>{};

    // 시간대별 완료 횟수와 전체 시도 횟수
    final completions = <int, int>{};
    final attempts = <int, int>{};

    // 최근 30일간 데이터 분석
    final today = DateTime.now();
    for (int day = 0; day < 30; day++) {
      final date = today.subtract(Duration(days: day));
      final habitsOnDate = await repository.getHabitsForDate(date);

      if (habitsOnDate.isEmpty) continue;

      for (final habit in habitsOnDate) {
        if (habit.completedAt != null) {
          final hour = habit.completedAt!.hour;

          // 성공 횟수 증가
          completions[hour] = (completions[hour] ?? 0) + (habit.isCompleted ? 1 : 0);

          // 시도 횟수 증가
          attempts[hour] = (attempts[hour] ?? 0) + 1;
        }
      }
    }

    // 각 시간대별 성공률 계산
    attempts.forEach((hour, count) {
      if (count > 0) {
        result[hour] = (completions[hour] ?? 0) / count;
      }
    });

    return result;
  }

  // 특정 월의 완료율 계산
  Future<double> _calculateMonthCompletionRate(
      List<Habit> habits,
      DateTime month,
      dynamic repository
      ) async {
    int totalHabits = 0;
    int completedHabits = 0;

    // 해당 월의 일수
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);

      // 미래 날짜는 건너뛰기
      if (date.isAfter(today)) break;

      final habitsOnDate = await repository.getHabitsForDate(date);

      int len = habitsOnDate.length;
      int whereLen = habitsOnDate.where((h) => h.isCompleted);


      totalHabits += len;
      completedHabits += whereLen;
    }

    return totalHabits > 0 ? completedHabits / totalHabits : 0.0;
  }

  // 리포트 섹션 위젯
  Widget _buildReportSection(
      String title,
      String value,
      String description,
      IconData icon,
      Color iconColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.7),
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}