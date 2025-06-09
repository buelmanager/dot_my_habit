// lib/presentation/screens/pattern/widgets/habit_progress_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../data/models/habit.dart';

/// 습관 진행 카드 위젯
class HabitProgressCard extends ConsumerWidget {
  /// 습관 정보
  final Habit habit;

  /// 생성자
  const HabitProgressCard({
    Key? key,
    required this.habit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 저장소에서 실제 데이터 조회
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<double>(
      // 최근 30일 완료율 데이터 가져오기
        future: _getCompletionRate(repository),
        builder: (context, snapshot) {
          // 기본값 30%
          final progress = snapshot.hasData ? snapshot.data! : 0.3;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                // 습관 이름 및 진행률
                Row(
                  children: [
                    // 점 아이콘
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 습관 이름
                    Expanded(
                      child: Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 진행률 텍스트
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 진행률 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 10),

                // 추가 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 스트릭 정보
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.streak}일째',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),

                    // 최근 완료일
                    Text(
                      _getLastCompletionText(habit),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
    );
  }

  // 최근 30일 완료율 계산
  Future<double> _getCompletionRate(dynamic repository) async {
    final today = DateTime.now();
    int completedDays = 0;
    int totalDays = 30;  // 최근 30일간 데이터 확인

    for (int i = 0; i < totalDays; i++) {
      final date = today.subtract(Duration(days: i));
      final habits = await repository.getHabitsForDate(date);

      // 해당 습관 찾기
      final habitOnDate = habits.firstWhere(
              (h) => h.id == habit.id,
          orElse: () => habit.copyWith(isCompleted: false)
      );

      if (habitOnDate.isCompleted) {
        completedDays++;
      }
    }

    return completedDays / totalDays;
  }

  // 최근 완료일 텍스트 생성
  String _getLastCompletionText(Habit habit) {
    if (habit.isCompleted) {
      if (habit.completedAt != null) {
        // 오늘인지 확인
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final completedDate = DateTime(
            habit.completedAt!.year,
            habit.completedAt!.month,
            habit.completedAt!.day
        );

        if (completedDate == today) {
          return '최근 완료: 오늘';
        } else {
          // 날짜 포맷
          return '최근 완료: ${DateFormat('MM/dd').format(habit.completedAt!)}';
        }
      } else {
        return '최근 완료: 오늘';
      }
    } else {
      return '미완료';
    }
  }
}