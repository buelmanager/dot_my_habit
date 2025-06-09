// lib/presentation/screens/pattern/widgets/habit_recommendations_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/dtos/habit_dto.dart';
import '../../../../data/models/habit.dart';

/// 습관 추천 카드 위젯
class HabitRecommendationsCard extends ConsumerWidget {
  const HabitRecommendationsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final repository = ref.read(habitRepositoryProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _generateRecommendations(habits, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final recommendations = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
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
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI 습관 추천',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 추천 설명
              Text(
                '현재 패턴을 분석하여 맞춤형 습관을 추천해드려요',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 20),

              // 추천 리스트
              ...recommendations
                  .map(
                    (rec) => _buildRecommendationItem(
                      rec['icon'] as IconData,
                      rec['title'] as String,
                      rec['description'] as String,
                      rec['difficulty'] as String,
                      rec['category'] as String,
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  /// 습관 추천 생성
  Future<List<Map<String, dynamic>>> _generateRecommendations(
    List<Habit> habits,
    dynamic repository,
  ) async {
    try {
      final recommendations = <Map<String, dynamic>>[];

      // 현재 습관 분석
      final analysis = await _analyzeCurrentHabits(habits, repository);

      // 추천 로직
      if (habits.isEmpty) {
        // 초보자용 추천
        recommendations.addAll(_getBeginnerRecommendations());
      } else {
        // 기존 습관 기반 추천
        recommendations.addAll(_getPersonalizedRecommendations(analysis));
      }

      // 최대 3개 추천
      return recommendations.take(3).toList();
    } catch (e) {
      developer.log('습관 추천 생성 실패: $e', name: 'HabitRecommendations');
      return _getDefaultRecommendations();
    }
  }

  /// 현재 습관 분석
  Future<Map<String, dynamic>> _analyzeCurrentHabits(
    List<Habit> habits,
    dynamic repository,
  ) async {
    final categories = <String, int>{};
    final times = <int, int>{};
    double avgCompletionRate = 0.0;
    int totalStreak = 0;

    for (final habit in habits) {
      // 카테고리 분석 (간단한 키워드 기반)
      final category = _categorizeHabit(habit.name);
      categories[category] = (categories[category] ?? 0) + 1;

      // 시간 분석
      if (habit.reminderTime != null) {
        final hour = habit.reminderTime!.hour;
        times[hour] = (times[hour] ?? 0) + 1;
      }

      totalStreak += habit.streak;
    }

    // 완료율 계산 (최근 7일)
    if (habits.isNotEmpty) {
      int totalCompleted = 0;
      int totalPossible = 0;
      final today = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        try {
          List<HabitDto> habitsOnDate = await repository.getHabitsForDate(date);
          totalPossible += habitsOnDate.length;

          for (final habit in habitsOnDate) {
            if (habit.isCompleted) {
              totalCompleted++;
            }
          }
        } catch (e) {
          // 에러 발생 시 스킵
        }
      }

      if (totalPossible > 0) {
        avgCompletionRate = totalCompleted / totalPossible;
      }
    }

    return {
      'categories': categories,
      'preferredTimes': times,
      'completionRate': avgCompletionRate,
      'totalStreak': totalStreak,
      'habitCount': habits.length,
    };
  }

  /// 습관 카테고리 분류
  String _categorizeHabit(String habitName) {
    final name = habitName.toLowerCase();

    if (name.contains('운동') ||
        name.contains('걷기') ||
        name.contains('뛰기') ||
        name.contains('헬스') ||
        name.contains('요가')) {
      return 'exercise';
    } else if (name.contains('독서') ||
        name.contains('책') ||
        name.contains('공부') ||
        name.contains('학습')) {
      return 'learning';
    } else if (name.contains('물') ||
        name.contains('수분') ||
        name.contains('건강') ||
        name.contains('비타민')) {
      return 'health';
    } else if (name.contains('명상') ||
        name.contains('일기') ||
        name.contains('감사') ||
        name.contains('휴식')) {
      return 'mindfulness';
    } else if (name.contains('정리') ||
        name.contains('청소') ||
        name.contains('계획')) {
      return 'productivity';
    }

    return 'general';
  }

  /// 초보자용 추천
  List<Map<String, dynamic>> _getBeginnerRecommendations() {
    return [
      {
        'icon': Icons.local_drink,
        'title': '물 마시기',
        'description': '하루 8잔의 물을 마셔보세요. 건강한 습관의 첫걸음입니다.',
        'difficulty': '쉬움',
        'category': '건강',
      },
      {
        'icon': Icons.directions_walk,
        'title': '10분 산책',
        'description': '매일 10분씩 산책하며 몸과 마음을 건강하게 유지하세요.',
        'difficulty': '쉬움',
        'category': '운동',
      },
      {
        'icon': Icons.menu_book,
        'title': '5분 독서',
        'description': '하루 5분 독서로 지식을 쌓고 집중력을 기르세요.',
        'difficulty': '쉬움',
        'category': '학습',
      },
    ];
  }

  /// 개인화된 추천
  List<Map<String, dynamic>> _getPersonalizedRecommendations(
    Map<String, dynamic> analysis,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    final categories = analysis['categories'] as Map<String, int>;
    final completionRate = analysis['completionRate'] as double;
    final habitCount = analysis['habitCount'] as int;

    // 부족한 카테고리 추천
    if (!categories.containsKey('exercise')) {
      recommendations.add({
        'icon': Icons.fitness_center,
        'title': '스트레칭',
        'description': '몸의 긴장을 풀고 유연성을 높이는 10분 스트레칭을 추천해요.',
        'difficulty': '보통',
        'category': '운동',
      });
    }

    if (!categories.containsKey('mindfulness')) {
      recommendations.add({
        'icon': Icons.psychology,
        'title': '감사 일기',
        'description': '하루 3가지 감사한 일을 적어보며 긍정적인 마음가짐을 기르세요.',
        'difficulty': '쉬움',
        'category': '마음챙김',
      });
    }

    if (!categories.containsKey('learning') && completionRate > 0.7) {
      recommendations.add({
        'icon': Icons.school,
        'title': '새로운 기술 학습',
        'description': '현재 습관을 잘 유지하고 있어서 새로운 도전을 추천해요!',
        'difficulty': '어려움',
        'category': '학습',
      });
    }

    // 완료율이 낮으면 쉬운 습관 추천
    if (completionRate < 0.5) {
      recommendations.add({
        'icon': Icons.timer,
        'title': '1분 명상',
        'description': '부담 없는 1분 명상으로 마음의 평온을 찾아보세요.',
        'difficulty': '쉬움',
        'category': '마음챙김',
      });
    }

    // 습관이 많으면 정리 추천
    if (habitCount > 3) {
      recommendations.add({
        'icon': Icons.cleaning_services,
        'title': '작업 공간 정리',
        'description': '깔끔한 환경에서 더 효율적으로 습관을 유지할 수 있어요.',
        'difficulty': '보통',
        'category': '생산성',
      });
    }

    return recommendations.isEmpty
        ? _getDefaultRecommendations()
        : recommendations;
  }

  /// 기본 추천
  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'icon': Icons.wb_sunny,
        'title': '아침 스트레칭',
        'description': '상쾌한 하루를 위한 5분 아침 스트레칭을 시작해보세요.',
        'difficulty': '쉬움',
        'category': '건강',
      },
      {
        'icon': Icons.edit_note,
        'title': '하루 계획 세우기',
        'description': '매일 아침 오늘의 목표를 3가지 적어보세요.',
        'difficulty': '쉬움',
        'category': '생산성',
      },
      {
        'icon': Icons.bedtime,
        'title': '일정한 수면 시간',
        'description': '건강한 삶의 기본, 규칙적인 수면 패턴을 만들어보세요.',
        'difficulty': '보통',
        'category': '건강',
      },
    ];
  }

  /// 추천 아이템 위젯
  Widget _buildRecommendationItem(
    IconData icon,
    String title,
    String description,
    String difficulty,
    String category,
  ) {
    Color difficultyColor;
    switch (difficulty) {
      case '쉬움':
        difficultyColor = Colors.green;
        break;
      case '보통':
        difficultyColor = Colors.orange;
        break;
      case '어려움':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.purple.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: difficultyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.category,
                size: 14,
                color: Colors.purple.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.purple.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
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
              size: 24,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              '추천을 불러올 수 없습니다',
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
