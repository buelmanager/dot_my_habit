// lib/presentation/screens/pattern/widgets/ai_habit_recommendations.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// AI 기반 습관 추천 카드 위젯
class AIHabitRecommendations extends ConsumerWidget {
  const AIHabitRecommendations({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final weeklyProgress = viewModel.state.weeklyProgress;

    return FutureBuilder<Map<String, dynamic>>(
      future: _prepareRecommendationData(habits, weeklyProgress),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final recommendationParams = snapshot.data!;

        return Consumer(
          builder: (context, ref, child) {
            final aiRecommendationsAsync = ref.watch(
              aiRecommendationsProvider(recommendationParams),
            );

            return aiRecommendationsAsync.when(
              data:
                  (recommendations) => _buildRecommendationsCard(
                    context,
                    recommendations,
                    viewModel,
                  ),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(),
            );
          },
        );
      },
    );
  }

  /// 추천을 위한 데이터 준비
  Future<Map<String, dynamic>> _prepareRecommendationData(
    List<Habit> habits,
    Map<String, double> weeklyProgress,
  ) async {
    try {
      // 평균 완료율 계산
      double averageCompletionRate = 0.0;
      if (weeklyProgress.isNotEmpty) {
        final total = weeklyProgress.values.fold<double>(
          0.0,
          (sum, value) => sum + value,
        );
        averageCompletionRate = total / weeklyProgress.length;
      }

      return {
        'currentHabits': habits,
        'weeklyProgress': weeklyProgress,
        'averageCompletionRate': averageCompletionRate,
      };
    } catch (e) {
      logger.error('AI 추천 데이터 준비 실패: $e');
      rethrow;
    }
  }

  /// 추천 카드 위젯
  Widget _buildRecommendationsCard(
    BuildContext context,
    List<Map<String, dynamic>> recommendations,
    dynamic viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withOpacity(0.1), Colors.cyan.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
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
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 습관 추천',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SMART',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 설명
          Text(
            '당신의 현재 습관 패턴을 분석하여 맞춤형 습관을 추천합니다',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 20),

          // 추천 습관들
          ...recommendations
              .map(
                (recommendation) => _buildRecommendationItem(
                  context,
                  recommendation,
                  viewModel,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  /// 추천 아이템 위젯
  Widget _buildRecommendationItem(
    BuildContext context,
    Map<String, dynamic> recommendation,
    dynamic viewModel,
  ) {
    // 안전한 데이터 추출 (여러 키 시도)
    final title = _getRecommendationField(recommendation, [
      'title',
      'name',
      'habitName',
    ], '새로운 습관');
    final description = _getRecommendationField(recommendation, [
      'description',
      'desc',
      'detail',
    ], '건강한 새로운 습관입니다.');
    final difficulty = _getRecommendationField(recommendation, [
      'difficulty',
      'level',
    ], '보통');
    final timeRequired = _getRecommendationField(recommendation, [
      'timeRequired',
      'time',
      'duration',
    ], '5분');
    final category = _getRecommendationField(recommendation, [
      'category',
      'type',
    ], '일반');

    // benefits 배열 안전 추출
    List<String> benefits = [];
    try {
      if (recommendation['benefits'] is List) {
        benefits = List<String>.from(recommendation['benefits']);
      } else if (recommendation['benefit'] is List) {
        benefits = List<String>.from(recommendation['benefit']);
      } else if (recommendation['advantages'] is List) {
        benefits = List<String>.from(recommendation['advantages']);
      }
    } catch (e) {
      logger.debug('⚠️ benefits 파싱 실패: $e');
    }

    if (benefits.isEmpty) {
      benefits = ['건강 개선', '습관 형성'];
    }

    // startingTip 안전 추출
    final startingTip = _getRecommendationField(recommendation, [
      'startingTip',
      'tip',
      'advice',
      'suggestion',
    ], '작은 것부터 시작해보세요.');

    logger.debug('📝 추천 아이템 렌더링: $title');

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
          // 상단: 제목과 난이도
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildDifficultyBadge(difficulty),
            ],
          ),

          const SizedBox(height: 8),

          // 설명
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // 정보 태그들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoTag(
                Icons.category_outlined,
                category,
                Colors.teal.shade600,
              ),
              _buildInfoTag(
                Icons.access_time,
                timeRequired,
                Colors.blue.shade600,
              ),
              if (benefits.isNotEmpty)
                _buildInfoTag(
                  Icons.star_outline,
                  benefits.first,
                  Colors.orange.shade600,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 시작 팁
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    startingTip,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 액션 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed:
                    () => _showHabitDetails(context, {
                      'title': title,
                      'description': description,
                      'benefits': benefits,
                      'category': category,
                      'difficulty': difficulty,
                      'timeRequired': timeRequired,
                      'startingTip': startingTip,
                    }),
                icon: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.teal.shade600,
                ),
                label: Text(
                  '자세히',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    () => _addRecommendedHabit(context, title, viewModel),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가하기', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 추천 필드 안전 추출 헬퍼 메서드
  String _getRecommendationField(
    Map<String, dynamic> recommendation,
    List<String> possibleKeys,
    String defaultValue,
  ) {
    for (final key in possibleKeys) {
      if (recommendation[key] != null &&
          recommendation[key].toString().isNotEmpty) {
        return recommendation[key].toString();
      }
    }
    return defaultValue;
  }

  /// 습관 상세 정보 보기 (수정 버전)
  void _showHabitDetails(BuildContext context, Map<String, dynamic> habitData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(habitData['title'] ?? '습관 정보'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habitData['description'] ?? ''),
                  const SizedBox(height: 16),

                  // 카테고리 및 난이도
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          habitData['category'] ?? '일반',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${habitData['difficulty']} (${habitData['timeRequired']})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 기대 효과
                  if (habitData['benefits'] != null &&
                      habitData['benefits'] is List)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '기대 효과:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        ...List<String>.from(
                          habitData['benefits'],
                        ).map((benefit) => Text('• $benefit')),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // 시작 팁
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '시작 팁',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(habitData['startingTip'] ?? '작은 것부터 시작해보세요.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  /// 추천 습관 추가하기 (수정 버전)
  void _addRecommendedHabit(
    BuildContext context,
    String habitTitle,
    dynamic viewModel,
  ) {
    // 습관 추가 확인 다이얼로그
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('습관 추가'),
            content: Text('\'$habitTitle\' 습관을 추가하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.addHabit(habitTitle);

                  // 성공 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('\'$habitTitle\' 습관이 추가되었습니다!'),
                      backgroundColor: Colors.teal.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  /// 난이도 배지 위젯
  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty) {
      case '쉬움':
        color = Colors.green;
        break;
      case '보통':
        color = Colors.orange;
        break;
      case '어려움':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// 정보 태그 위젯
  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity, // 가로 전체 차지
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withOpacity(0.1), Colors.cyan.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            'AI가 맞춤 습관을 추천하고 있습니다...',
            textAlign: TextAlign.center, // 텍스트 중앙 정렬
            style: TextStyle(fontSize: 14, color: Colors.teal.shade700),
          ),
        ],
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Container(
      width: double.infinity, // 가로 전체 차지
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withOpacity(0.1), Colors.cyan.withOpacity(0.1)],
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
              size: 32,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'AI 추천을 불러올 수 없습니다',
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
