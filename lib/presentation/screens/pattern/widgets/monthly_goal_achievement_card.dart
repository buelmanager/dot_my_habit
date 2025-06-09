// lib/presentation/screens/pattern/widgets/monthly_goal_achievement_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';

/// 월간 목표 달성률 카드 위젯
class MonthlyGoalAchievementCard extends ConsumerWidget {
  const MonthlyGoalAchievementCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final selectedDate = viewModel.state.selectedDate;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMonthlyGoalData(selectedDate, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          developer.log(
            '월간 목표 데이터 로드 에러: ${snapshot.error}',
            name: 'MonthlyGoalCard',
          );
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final goalData = snapshot.data!;
        final monthlyRate = goalData['monthlyCompletionRate'] as double;
        final totalDays = goalData['totalDays'] as int;
        final activeDays = goalData['activeDays'] as int;
        final totalHabits = goalData['totalHabits'] as int;
        final completedHabits = goalData['completedHabits'] as int;
        final currentStreak = goalData['currentStreak'] as int;
        final bestStreak = goalData['bestStreak'] as int;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedDate.year}년 ${selectedDate.month}월 목표',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '전체 달성률',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getAchievementColor(monthlyRate),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(monthlyRate * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 진행률 바
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: monthlyRate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 통계 그리드
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '활동 일수',
                      '$activeDays/$totalDays일',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      '완료 습관',
                      '$completedHabits/$totalHabits개',
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '현재 연속',
                      '$currentStreak일',
                      Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      '최고 연속',
                      '$bestStreak일',
                      Icons.emoji_events_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 격려 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMotivationIcon(monthlyRate),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMotivationMessage(monthlyRate, currentStreak),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 월간 목표 데이터 가져오기
  Future<Map<String, dynamic>> _fetchMonthlyGoalData(
    DateTime selectedDate,
    dynamic repository,
  ) async {
    try {
      developer.log(
        '월간 목표 데이터 로드 시작: ${selectedDate.year}-${selectedDate.month}',
        name: 'MonthlyGoalCard',
      );

      final now = DateTime.now();
      final isCurrentMonth =
          selectedDate.year == now.year && selectedDate.month == now.month;
      final daysInMonth =
          DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      final maxDay = isCurrentMonth ? now.day : daysInMonth;

      int totalHabits = 0;
      int completedHabits = 0;
      int activeDays = 0;
      int currentStreak = 0;
      int bestStreak = 0;
      int tempStreak = 0;

      // 월간 데이터 수집
      for (int day = 1; day <= maxDay; day++) {
        final date = DateTime(selectedDate.year, selectedDate.month, day);

        try {
          final habits = await repository.getHabitsForDate(date);

          if (habits.isNotEmpty) {
            activeDays++;
            int dayCompleted = 0;
            int dayTotal = 0;

            for (final habit in habits) {
              dayTotal++;
              totalHabits++;
              if (habit.isCompleted) {
                completedHabits++;
                dayCompleted++;
              }
            }

            // 연속 기록 계산
            if (dayCompleted > 0) {
              tempStreak++;
              bestStreak = bestStreak > tempStreak ? bestStreak : tempStreak;
            } else {
              tempStreak = 0;
            }

            developer.log(
              'Day $day: $dayCompleted/$dayTotal habits completed',
              name: 'MonthlyGoalCard',
            );
          }
        } catch (e) {
          developer.log('Day $day 데이터 로드 에러: $e', name: 'MonthlyGoalCard');
        }
      }

      // 현재 연속 기록 계산 (마지막부터 역순으로)
      for (int day = maxDay; day >= 1; day--) {
        final date = DateTime(selectedDate.year, selectedDate.month, day);

        try {
          final habits = await repository.getHabitsForDate(date);

          if (habits.isNotEmpty) {
            bool hasCompletedHabits = false;
            for (final habit in habits) {
              if (habit.isCompleted) {
                hasCompletedHabits = true;
                break;
              }
            }

            if (hasCompletedHabits) {
              currentStreak++;
            } else {
              break;
            }
          } else {
            break;
          }
        } catch (e) {
          developer.log(
            'Current streak day $day 에러: $e',
            name: 'MonthlyGoalCard',
          );
          break;
        }
      }

      final monthlyCompletionRate =
          totalHabits > 0 ? completedHabits / totalHabits : 0.0;

      developer.log(
        '월간 목표 데이터: 달성률 ${(monthlyCompletionRate * 100).toInt()}%, 활동 $activeDays/$maxDay일, 습관 $completedHabits/$totalHabits개',
        name: 'MonthlyGoalCard',
      );

      return {
        'monthlyCompletionRate': monthlyCompletionRate,
        'totalDays': maxDay,
        'activeDays': activeDays,
        'totalHabits': totalHabits,
        'completedHabits': completedHabits,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
      };
    } catch (e, stackTrace) {
      developer.log('월간 목표 데이터 로드 실패: $e', name: 'MonthlyGoalCard');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 통계 아이템 위젯
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 달성률에 따른 색상 반환
  Color _getAchievementColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    if (rate >= 0.4) return Colors.blue;
    return Colors.red.withOpacity(0.8);
  }

  /// 격려 아이콘 반환
  IconData _getMotivationIcon(double rate) {
    if (rate >= 0.8) return Icons.emoji_events;
    if (rate >= 0.6) return Icons.trending_up;
    if (rate >= 0.3) return Icons.psychology;
    return Icons.favorite;
  }

  /// 격려 메시지 반환
  String _getMotivationMessage(double rate, int streak) {
    if (rate >= 0.9) {
      return '완벽해요! 이번 달 목표를 거의 달성했습니다. 🏆';
    } else if (rate >= 0.7) {
      return '훌륭합니다! 꾸준히 좋은 결과를 보이고 있어요. 💪';
    } else if (rate >= 0.5) {
      return '좋은 진전이에요! 조금만 더 노력하면 목표 달성 가능해요. 📈';
    } else if (rate >= 0.3) {
      return '시작이 좋습니다! 작은 변화가 큰 결과를 만들어요. 🌱';
    } else if (streak > 0) {
      return '$streak일 연속 중이에요! 포기하지 말고 계속해봐요. 🔥';
    } else {
      return '새로운 시작! 오늘부터 하나씩 해나가봐요. ✨';
    }
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              '데이터를 불러올 수 없습니다',
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
