// lib/presentation/screens/pattern/widgets/habit_prediction_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 습관 예측 카드 위젯
class HabitPredictionCard extends ConsumerWidget {
  const HabitPredictionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    // 실제 데이터 기반으로 가장 유망한 습관 찾기
    return FutureBuilder<Map<String, dynamic>?>(
        future: _findMostPromisingHabit(habits, repository),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink(); // 데이터가 없으면 표시 안 함
          }

          final habitData = snapshot.data!;
          final selectedHabit = habitData['habit'] as Habit;
          final daysToTarget = habitData['daysToTarget'] as int;
          final daysCompleted = selectedHabit.streak;
          final progress = daysCompleted / daysToTarget;

          // 예상 완료일
          final now = DateTime.now();
          final remainingDays = daysToTarget - daysCompleted;
          final targetDate = now.add(Duration(days: remainingDays));
          final targetMonth = targetDate.month;
          final targetDay = targetDate.day;

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
                    Icon(Icons.insights, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '습관 형성 예측',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 선택된 습관 정보
                Text(
                  '"${selectedHabit.name}" 습관',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // 진행 상황
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    minHeight: 10,
                  ),
                ),

                const SizedBox(height: 10),

                // 진행 상태 정보
                Text(
                  '현재 $daysCompleted일째 (${(progress * 100).toInt()}% 진행)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // 예측 정보
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 24,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '습관 형성 예상 완료일',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$targetMonth월 $targetDay일 (앞으로 $remainingDays일)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 도움말
                Text(
                  '일반적으로 새로운 습관을 형성하는 데는 약 21일이 소요됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  /// 가장 유망한 습관 찾기 (스트릭 대비 완료율이 높은 습관)
  Future<Map<String, dynamic>?> _findMostPromisingHabit(
      List<Habit> habits,
      dynamic repository
      ) async {
    if (habits.isEmpty) return null;

    // 최소 3일 이상의 스트릭이 있는 습관만 필터링
    final streakHabits = habits.where((h) => h.streak >= 3).toList();
    if (streakHabits.isEmpty) return null;

    // 각 습관의 최근 2주간 완료율 계산
    final completionRates = <String, double>{};
    final today = DateTime.now();

    for (final habit in streakHabits) {
      int completedDays = 0;
      int totalDays = 14;  // 최근 14일 확인

      for (int day = 0; day < totalDays; day++) {
        final date = today.subtract(Duration(days: day));
        final habits = await repository.getHabitsForDate(date);

        final habitOnDate = habits.firstWhere(
                (h) => h.id == habit.id,
            orElse: () => habit.copyWith(isCompleted: false)
        );

        if (habitOnDate.isCompleted) {
          completedDays++;
        }
      }

      completionRates[habit.id] = completedDays / totalDays;
    }

    // 완료율과 스트릭을 고려하여 가장 유망한 습관 선택
    Habit? mostPromisingHabit;
    double highestScore = 0;

    for (final habit in streakHabits) {
      final completionRate = completionRates[habit.id] ?? 0;
      // 스트릭과 완료율을 모두 고려한 점수 계산
      final score = habit.streak * 0.3 + completionRate * 0.7;

      if (score > highestScore) {
        highestScore = score;
        mostPromisingHabit = habit;
      }
    }

    if (mostPromisingHabit == null) return null;

    // 습관 형성에 필요한 총 일수 계산 (더 규칙적으로 하는 습관은 더 빨리 형성됨)
    final habitCompletionRate = completionRates[mostPromisingHabit.id] ?? 0.5;
    // 완료율이 높을수록 습관 형성이 빠름 (기본 21일에서 조정)
    final daysToTarget = (habitCompletionRate >= 0.8) ? 21 :
    (habitCompletionRate >= 0.6) ? 28 : 35;

    return {
      'habit': mostPromisingHabit,
      'daysToTarget': daysToTarget,
      'completionRate': habitCompletionRate,
    };
  }
}