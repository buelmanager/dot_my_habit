// lib/presentation/screens/pattern/widgets/habit_achievements_collection.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// 습관 성취 배지 컬렉션 위젯
class HabitAchievementsCollection extends ConsumerWidget {
  const HabitAchievementsCollection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateAchievements(habits, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final achievementData = snapshot.data!;
        final achievements =
            achievementData['achievements'] as List<Map<String, dynamic>>;
        final stats = achievementData['stats'] as Map<String, dynamic>;

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
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '성취 배지',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${achievements.where((a) => a['unlocked'] == true).length}/${achievements.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 통계 요약
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '총 연속일',
                      '${stats['totalStreak']}일',
                      Icons.local_fire_department,
                    ),
                    _buildStatItem(
                      '완료 습관',
                      '${stats['totalCompleted']}개',
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      '활동 일수',
                      '${stats['activeDays']}일',
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 배지 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return _buildAchievementBadge(
                    achievement['icon'] as IconData,
                    achievement['title'] as String,
                    achievement['description'] as String,
                    achievement['unlocked'] as bool,
                    achievement['progress'] as double,
                    achievement['color'] as Color,
                  );
                },
              ),

              const SizedBox(height: 16),

              // 다음 목표
              if (achievements.any((a) => !a['unlocked']))
                _buildNextGoal(achievements.firstWhere((a) => !a['unlocked'])),
            ],
          ),
        );
      },
    );
  }

  /// 성취 계산
  Future<Map<String, dynamic>> _calculateAchievements(
    List<Habit> habits,
    dynamic repository,
  ) async {
    try {
      // 통계 수집
      int totalStreak = 0;
      int totalCompleted = 0;
      int activeDays = 0;
      final today = DateTime.now();

      // 습관별 스트릭 합계
      for (final habit in habits) {
        totalStreak += habit.streak;
      }

      // 최근 30일 활동 분석
      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));
        try {
          final habitsOnDate = await repository.getHabitsForDate(date);

          if (habitsOnDate.isNotEmpty) {
            activeDays++;
            for (final habit in habitsOnDate) {
              if (habit.isCompleted) {
                totalCompleted++;
              }
            }
          }
        } catch (e) {
          // 에러 발생 시 스킵
        }
      }

      final stats = {
        'totalStreak': totalStreak,
        'totalCompleted': totalCompleted,
        'activeDays': activeDays,
        'habitCount': habits.length,
      };

      // 배지 정의 및 계산
      final achievements = <Map<String, dynamic>>[];

      // 동기 배지들 추가
      achievements.addAll(_calculateFirstStepBadge(habits.isNotEmpty));
      achievements.addAll(_calculateStreakBadges(totalStreak));
      achievements.addAll(_calculateCompletionBadges(totalCompleted));
      achievements.addAll(_calculateConsistencyBadges(activeDays));
      achievements.addAll(_calculateHabitCountBadges(habits.length));

      // 비동기 배지 추가
      final perfectionistBadges = await _calculatePerfectionistBadge(
        habits,
        repository,
      );
      achievements.addAll(perfectionistBadges);

      developer.log(
        '성취 계산 완료: ${achievements.where((a) => a['unlocked']).length}/${achievements.length} 달성',
        name: 'Achievements',
      );

      return {'achievements': achievements, 'stats': stats};
    } catch (e) {
      developer.log('성취 계산 실패: $e', name: 'Achievements');
      return {
        'achievements': <Map<String, dynamic>>[],
        'stats': {
          'totalStreak': 0,
          'totalCompleted': 0,
          'activeDays': 0,
          'habitCount': 0,
        },
      };
    }
  }

  /// 첫걸음 배지
  List<Map<String, dynamic>> _calculateFirstStepBadge(bool hasHabits) {
    return [
      {
        'icon': Icons.flag,
        'title': '첫걸음',
        'description': '첫 번째 습관 추가',
        'unlocked': hasHabits,
        'progress': hasHabits ? 1.0 : 0.0,
        'color': Colors.green,
      },
    ];
  }

  /// 연속 기록 배지들
  List<Map<String, dynamic>> _calculateStreakBadges(int totalStreak) {
    final streakMilestones = [
      {
        'days': 3,
        'title': '시작',
        'icon': Icons.play_arrow,
        'color': Colors.green,
      },
      {
        'days': 7,
        'title': '일주일',
        'icon': Icons.calendar_view_week,
        'color': Colors.blue,
      },
      {
        'days': 21,
        'title': '습관화',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {'days': 50, 'title': '달인', 'icon': Icons.star, 'color': Colors.orange},
      {
        'days': 100,
        'title': '전설',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
    ];

    return streakMilestones.map((milestone) {
      final days = milestone['days'] as int;
      final unlocked = totalStreak >= days;
      final progress = totalStreak >= days ? 1.0 : totalStreak / days;

      return {
        'icon': milestone['icon'] as IconData,
        'title': milestone['title'] as String,
        'description': '$days일 연속 달성',
        'unlocked': unlocked,
        'progress': progress,
        'color': milestone['color'] as Color,
      };
    }).toList();
  }

  /// 완료 개수 배지들
  List<Map<String, dynamic>> _calculateCompletionBadges(int totalCompleted) {
    final completionMilestones = [
      {'count': 10, 'title': '초보', 'icon': Icons.looks_one},
      {'count': 50, 'title': '숙련', 'icon': Icons.looks_two},
      {'count': 100, 'title': '고수', 'icon': Icons.looks_3},
    ];

    return completionMilestones.map((milestone) {
      final count = milestone['count'] as int;
      final unlocked = totalCompleted >= count;
      final progress = totalCompleted >= count ? 1.0 : totalCompleted / count;

      return {
        'icon': milestone['icon'] as IconData,
        'title': milestone['title'] as String,
        'description': '$count개 습관 완료',
        'unlocked': unlocked,
        'progress': progress,
        'color': Colors.teal,
      };
    }).toList();
  }

  /// 일관성 배지들
  List<Map<String, dynamic>> _calculateConsistencyBadges(int activeDays) {
    return [
      {
        'icon': Icons.schedule,
        'title': '꾸준함',
        'description': '15일 활동',
        'unlocked': activeDays >= 15,
        'progress': activeDays >= 15 ? 1.0 : activeDays / 15,
        'color': Colors.indigo,
      },
    ];
  }

  /// 습관 개수 배지들
  List<Map<String, dynamic>> _calculateHabitCountBadges(int habitCount) {
    return [
      {
        'icon': Icons.collections,
        'title': '컬렉터',
        'description': '5개 습관 보유',
        'unlocked': habitCount >= 5,
        'progress': habitCount >= 5 ? 1.0 : habitCount / 5,
        'color': Colors.pink,
      },
    ];
  }

  /// 완벽주의자 배지
  Future<List<Map<String, dynamic>>> _calculatePerfectionistBadge(
    List<Habit> habits,
    dynamic repository,
  ) async {
    if (habits.isEmpty) {
      return [
        {
          'icon': Icons.done,
          'title': '완벽',
          'description': '7일 연속 100%',
          'unlocked': false,
          'progress': 0.0,
          'color': Colors.red,
        },
      ];
    }

    // 최근 7일 완료율 체크
    int perfectDays = 0;
    final today = DateTime.now();

    for (int day = 0; day < 7; day++) {
      final date = today.subtract(Duration(days: day));
      try {
        final habitsOnDate = await repository.getHabitsForDate(date);

        if (habitsOnDate.isNotEmpty) {
          bool allCompleted = true;
          for (final habit in habitsOnDate) {
            if (!habit.isCompleted) {
              allCompleted = false;
              break;
            }
          }
          if (allCompleted) {
            perfectDays++;
          } else {
            break; // 연속성이 끊어짐
          }
        } else {
          break; // 데이터가 없으면 연속성 끊어짐
        }
      } catch (e) {
        break;
      }
    }

    return [
      {
        'icon': Icons.workspace_premium,
        'title': '완벽',
        'description': '7일 연속 100%',
        'unlocked': perfectDays >= 7,
        'progress': perfectDays / 7,
        'color': Colors.red,
      },
    ];
  }

  /// 통계 아이템 위젯
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.amber.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }

  /// 배지 위젯
  Widget _buildAchievementBadge(
    IconData icon,
    String title,
    String description,
    bool unlocked,
    double progress,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(title, description, unlocked, progress),
      child: Container(
        decoration: BoxDecoration(
          color:
              unlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                unlocked
                    ? color.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (!unlocked && progress > 0)
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    color: color.withOpacity(0.3),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                Icon(
                  icon,
                  size: 24,
                  color: unlocked ? color : Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: unlocked ? color : Colors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 다음 목표 위젯
  Widget _buildNextGoal(Map<String, dynamic> nextAchievement) {
    final progress = nextAchievement['progress'] as double;
    final color = nextAchievement['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                '다음 목표',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${nextAchievement['title']} - ${nextAchievement['description']}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% 달성',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 배지 상세 정보 표시
  void _showBadgeDetails(
    String title,
    String description,
    bool unlocked,
    double progress,
  ) {
    // 배지 탭 시 상세 정보 표시 (간단한 스낵바)
    // 실제 구현에서는 다이얼로그나 바텀시트 사용 가능
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Container(
      height: 300,
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
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
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
              '배지를 불러올 수 없습니다',
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
