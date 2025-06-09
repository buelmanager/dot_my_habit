// lib/presentation/screens/pattern/widgets/habit_insights_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 습관 인사이트 요약 카드 위젯
class HabitInsightsSummary extends ConsumerWidget {
  const HabitInsightsSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _generateInsights(habits, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final insights = snapshot.data!;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '습관 인사이트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 핵심 인사이트들
              ...insights['insights']
                  .map<Widget>(
                    (insight) => _buildInsightItem(
                      insight['icon'] as IconData,
                      insight['title'] as String,
                      insight['description'] as String,
                      insight['color'] as Color,
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  /// 인사이트 데이터 생성
  Future<Map<String, dynamic>> _generateInsights(
    List<Habit> habits,
    dynamic repository,
  ) async {
    try {
      final insights = <Map<String, dynamic>>[];

      if (habits.isEmpty) {
        insights.add({
          'icon': Icons.add_circle_outline,
          'title': '첫 습관을 시작해보세요',
          'description': '작은 변화가 큰 결과를 만듭니다. 하루 5분부터 시작해보세요.',
          'color': Colors.green,
        });

        return {'insights': insights};
      }

      // 1. 가장 성공적인 습관
      final bestHabit = await _findBestHabit(habits, repository);
      if (bestHabit != null) {
        insights.add({
          'icon': Icons.star,
          'title': '가장 성공적인 습관',
          'description':
              '"${bestHabit['name']}"을 ${bestHabit['streak']}일째 꾸준히 하고 있어요!',
          'color': Colors.amber,
        });
      }

      // 2. 개선이 필요한 습관
      final strugglingHabit = await _findStrugglingHabit(habits, repository);
      if (strugglingHabit != null) {
        insights.add({
          'icon': Icons.trending_up,
          'title': '개선 기회',
          'description':
              '"${strugglingHabit['name']}"을 더 꾸준히 해보세요. 작은 목표부터 시작하면 도움이 됩니다.',
          'color': Colors.orange,
        });
      }

      // 3. 최적의 시간대
      final bestTime = await _findBestCompletionTime(habits, repository);
      if (bestTime != null) {
        insights.add({
          'icon': Icons.access_time,
          'title': '최적의 실행 시간',
          'description': '${bestTime['timeRange']}에 습관을 실행할 때 성공률이 높아요.',
          'color': Colors.blue,
        });
      }

      // 4. 연속 기록 격려
      final totalStreak = habits.fold(0, (sum, habit) => sum + habit.streak);
      if (totalStreak > 0) {
        insights.add({
          'icon': Icons.local_fire_department,
          'title': '연속 기록',
          'description': '총 ${totalStreak}일의 연속 기록을 달성했어요! 꾸준함이 성공의 열쇠입니다.',
          'color': Colors.red,
        });
      }

      // 5. 주간 패턴 분석
      final weekPattern = await _analyzeWeeklyPattern(habits, repository);
      if (weekPattern != null) {
        insights.add({
          'icon': Icons.calendar_view_week,
          'title': '주간 패턴',
          'description': weekPattern['message'],
          'color': Colors.purple,
        });
      }

      // 기본 인사이트가 없으면 격려 메시지
      if (insights.isEmpty) {
        insights.add({
          'icon': Icons.psychology,
          'title': '꾸준함의 힘',
          'description': '매일 조금씩이라도 실행하는 것이 중요합니다. 작은 성취가 모여 큰 변화를 만들어요.',
          'color': Colors.green,
        });
      }

      return {'insights': insights};
    } catch (e) {
      developer.log('인사이트 생성 실패: $e', name: 'HabitInsights');
      return {'insights': []};
    }
  }

  /// 가장 성공적인 습관 찾기
  Future<Map<String, dynamic>?> _findBestHabit(
    List<Habit> habits,
    dynamic repository,
  ) async {
    if (habits.isEmpty) return null;

    Habit? bestHabit;
    int maxStreak = 0;

    for (final habit in habits) {
      if (habit.streak > maxStreak) {
        maxStreak = habit.streak;
        bestHabit = habit;
      }
    }

    if (bestHabit != null && maxStreak > 2) {
      return {'name': bestHabit.name, 'streak': maxStreak};
    }

    return null;
  }

  /// 어려워하는 습관 찾기
  Future<Map<String, dynamic>?> _findStrugglingHabit(
    List<Habit> habits,
    dynamic repository,
  ) async {
    if (habits.isEmpty) return null;

    final today = DateTime.now();
    Map<String, double> completionRates = {};

    for (final habit in habits) {
      int completed = 0;
      int total = 0;

      // 최근 7일 체크
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        try {
          final habitsOnDate = await repository.getHabitsForDate(date);

          for (final habitOnDate in habitsOnDate) {
            if (habitOnDate.id == habit.id) {
              total++;
              if (habitOnDate.isCompleted) {
                completed++;
              }
              break;
            }
          }
        } catch (e) {
          // 에러 발생 시 해당 날짜 스킵
        }
      }

      if (total > 0) {
        completionRates[habit.name] = completed / total;
      }
    }

    // 완료율이 가장 낮은 습관 찾기
    String? strugglingHabitName;
    double minRate = 1.0;

    completionRates.forEach((name, rate) {
      if (rate < minRate && rate < 0.5) {
        minRate = rate;
        strugglingHabitName = name;
      }
    });

    if (strugglingHabitName != null) {
      return {'name': strugglingHabitName};
    }

    return null;
  }

  /// 최적의 완료 시간 찾기
  Future<Map<String, dynamic>?> _findBestCompletionTime(
    List<Habit> habits,
    dynamic repository,
  ) async {
    final hourlySuccess = <int, int>{};
    final hourlyTotal = <int, int>{};
    final today = DateTime.now();

    // 최근 14일 데이터 분석
    for (int day = 0; day < 14; day++) {
      final date = today.subtract(Duration(days: day));
      try {
        final habitsOnDate = await repository.getHabitsForDate(date);

        for (final habit in habitsOnDate) {
          if (habit.completedAt != null) {
            final hour = habit.completedAt!.hour;
            hourlyTotal[hour] = (hourlyTotal[hour] ?? 0) + 1;
            if (habit.isCompleted) {
              hourlySuccess[hour] = (hourlySuccess[hour] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        // 에러 발생 시 해당 날짜 스킵
      }
    }

    // 최고 성공률 시간대 찾기
    int bestHour = -1;
    double bestRate = 0.0;

    hourlyTotal.forEach((hour, total) {
      if (total >= 3) {
        // 최소 3회 이상의 데이터가 있는 시간대만
        final success = hourlySuccess[hour] ?? 0;
        final rate = success / total;
        if (rate > bestRate) {
          bestRate = rate;
          bestHour = hour;
        }
      }
    });

    if (bestHour != -1 && bestRate > 0.6) {
      String timeRange;
      if (bestHour < 6) {
        timeRange = '새벽 시간대';
      } else if (bestHour < 12) {
        timeRange = '오전 시간대';
      } else if (bestHour < 18) {
        timeRange = '오후 시간대';
      } else {
        timeRange = '저녁 시간대';
      }

      return {'timeRange': timeRange};
    }

    return null;
  }

  /// 주간 패턴 분석
  Future<Map<String, dynamic>?> _analyzeWeeklyPattern(
    List<Habit> habits,
    dynamic repository,
  ) async {
    final today = DateTime.now();
    final weekdayRates = <int, double>{};

    // 요일별 완료율 계산
    for (int weekday = 1; weekday <= 7; weekday++) {
      int completed = 0;
      int total = 0;

      // 최근 4주간 해당 요일 데이터
      for (int week = 0; week < 4; week++) {
        final targetDate = today.subtract(
          Duration(days: (today.weekday - weekday) + (week * 7)),
        );

        try {
          final habitsOnDate = await repository.getHabitsForDate(targetDate);
          for (final habit in habitsOnDate) {
            total++;
            if (habit.isCompleted) {
              completed++;
            }
          }
        } catch (e) {
          // 에러 발생 시 해당 날짜 스킵
        }
      }

      if (total > 0) {
        weekdayRates[weekday] = completed / total;
      }
    }

    if (weekdayRates.isNotEmpty) {
      // 가장 높은 완료율의 요일 찾기
      int bestDay = 1;
      double bestRate = 0.0;

      weekdayRates.forEach((day, rate) {
        if (rate > bestRate) {
          bestRate = rate;
          bestDay = day;
        }
      });

      final dayNames = ['', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

      if (bestRate > 0.7) {
        return {
          'message': '${dayNames[bestDay]}에 습관 실행률이 가장 높아요. 이 패턴을 활용해보세요!',
        };
      }
    }

    return null;
  }

  /// 인사이트 아이템 위젯
  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
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

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Container(
      height: 200,
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
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Container(
      height: 120,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 24,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              '인사이트를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
