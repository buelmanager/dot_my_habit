// lib/presentation/screens/pattern/widgets/ai_insights_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';
import '../../../../data/models/habit.dart';

/// AI 기반 인사이트 요약 카드 위젯
class AIInsightsSummary extends ConsumerWidget {
  const AIInsightsSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.info('🎯 AIInsightsSummary 위젯 빌드 시작');

    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final weeklyProgress = viewModel.state.weeklyProgress;
    final repository = ref.read(habitRepositoryProvider);

    logger.info('📊 현재 습관 수: ${habits.length}');
    logger.info('📈 주간 진행률: $weeklyProgress');

    return FutureBuilder<Map<String, dynamic>>(
      future: _prepareAIAnalysisData(habits, weeklyProgress, repository),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.error('❌ AI 분석 데이터 준비 오류: ${snapshot.error}');
          developer.log(
            'AI 분석 데이터 준비 오류',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          logger.debug('⏳ AI 분석 데이터 로딩 중...');
          return _buildLoadingState('데이터 준비 중...');
        }

        final analysisParams = snapshot.data!;
        logger.info('✅ AI 분석 데이터 준비 완료: ${analysisParams.keys}');
        logger.debug('📋 분석 파라미터: $analysisParams');

        return Consumer(
          builder: (context, ref, child) {
            logger.debug('🔄 AI 인사이트 프로바이더 호출');
            final aiInsightsAsync = ref.watch(
              aiInsightsProvider(analysisParams),
            );

            return aiInsightsAsync.when(
              data: (insights) {
                logger.info('🎉 AI 인사이트 데이터 수신 성공');
                logger.debug('💡 인사이트 내용: $insights');
                return _buildInsightsCard(insights);
              },
              loading: () {
                logger.debug('🔄 AI 인사이트 생성 중...');
                return _buildLoadingState('AI가 분석 중...');
              },
              error: (error, stack) {
                logger.error('❌ AI 인사이트 생성 실패: $error');
                developer.log('AI 인사이트 생성 실패', error: error, stackTrace: stack);
                return _buildErrorState(error.toString());
              },
            );
          },
        );
      },
    );
  }

  /// AI 분석을 위한 데이터 준비
  Future<Map<String, dynamic>> _prepareAIAnalysisData(
    List<Habit> habits,
    Map<String, double> weeklyProgress,
    dynamic repository,
  ) async {
    try {
      logger.info('🛠 AI 분석 데이터 준비 시작');
      final startTime = DateTime.now();

      // 월간 데이터 수집
      final today = DateTime.now();
      int totalCompletedHabits = 0;
      int totalHabits = 0;
      int activeDays = 0;

      logger.debug('📅 최근 30일 데이터 분석 시작');

      // 최근 30일 데이터 분석
      for (int day = 0; day < 30; day++) {
        final date = today.subtract(Duration(days: day));
        List<Habit> habitsOnDate = await repository.getHabitsForDate(date);

        if (habitsOnDate.isNotEmpty) {
          activeDays++;
          totalHabits += habitsOnDate.length;
          int dayCompletedCount =
              habitsOnDate.where((h) => h.isCompleted).length;
          totalCompletedHabits += dayCompletedCount;

          if (day < 7) {
            // 최근 7일만 상세 로그
            logger.debug(
              '📊 ${date.toString().split(' ')[0]}: ${dayCompletedCount}/${habitsOnDate.length} 완료',
            );
          }
        }
      }

      // 월간 트렌드 데이터 생성
      final monthlyData = {
        'averageCompletionRate':
            totalHabits > 0 ? totalCompletedHabits / totalHabits : 0.0,
        'totalHabits': habits.length,
        'longestStreak':
            habits.isNotEmpty
                ? habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b)
                : 0,
        'activeDaysRatio': activeDays / 30,
      };

      final analysisData = {
        'habits': habits,
        'weeklyProgress': weeklyProgress,
        'monthlyData': monthlyData,
        'totalCompletedHabits': totalCompletedHabits,
        'totalHabits': totalHabits,
        'activeDays': activeDays,
      };

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      logger.info('✅ AI 분석 데이터 준비 완료 (소요시간: ${duration.inMilliseconds}ms)');
      logger.info('📈 월간 데이터 요약:');
      logger.info('  - 활성 일수: $activeDays/30일');
      logger.info('  - 총 습관 수행: $totalCompletedHabits/$totalHabits회');
      logger.info(
        '  - 평균 완료율: ${(monthlyData['averageCompletionRate']! * 100).toStringAsFixed(1)}%',
      );
      logger.info('  - 최장 스트릭: ${monthlyData['longestStreak']}일');

      return analysisData;
    } catch (e, stackTrace) {
      logger.error('❌ AI 분석 데이터 준비 실패: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    logger.debug('🎨 인사이트 카드 렌더링 시작');

    // AI 응답 검증
    final hasMainInsight =
        insights.containsKey('mainInsight') && insights['mainInsight'] != null;

    // AI 응답에서 실제로 받는 키들을 확인하고 매핑
    final patterns = insights['patterns'] as List<dynamic>? ?? [];
    final recommendations = insights['recommendations'] as List<dynamic>? ?? [];

    // patterns를 strengths로, recommendations를 improvements로 매핑
    final strengths = patterns.take(2).map((e) => e.toString()).toList();
    final improvements =
        recommendations.take(2).map((e) => e.toString()).toList();

    final hasStrengths = strengths.isNotEmpty;
    final hasImprovements = improvements.isNotEmpty;

    logger.info('🔍 AI 응답 검증:');
    logger.info('  - 핵심 인사이트: $hasMainInsight');
    logger.info('  - 강점 데이터: $hasStrengths (${strengths.length}개)');
    logger.info('  - 개선점 데이터: $hasImprovements (${improvements.length}개)');
    logger.debug('  - 패턴 데이터: ${patterns.length}개');
    logger.debug('  - 추천 데이터: ${recommendations.length}개');

    if (!hasMainInsight) {
      logger.warning('⚠️ AI 응답에 핵심 인사이트가 없음');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.indigo.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (AI 상태 표시 추가)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 20,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 인사이트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // AI 응답 상태 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      hasMainInsight
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasMainInsight ? Icons.check_circle : Icons.warning,
                      size: 12,
                      color: hasMainInsight ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasMainInsight ? 'LIVE' : 'LIMITED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasMainInsight ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 메인 인사이트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.deepPurple.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '핵심 인사이트',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insights['mainInsight'] ?? '분석 중입니다...',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // 디버그 정보 표시 (개발 모드에서만)
                if (!hasMainInsight) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Debug: AI 응답 형식이 예상과 다릅니다. 원본: ${insights.toString().substring(0, 100)}...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 강점과 개선점 (높이 맞춤 수정)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 강점 (patterns를 사용)
                Expanded(
                  child: _buildInsightSection(
                    '강점',
                    strengths,
                    Icons.star_outline,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                // 개선점 (recommendations를 사용)
                Expanded(
                  child: _buildInsightSection(
                    '개선점',
                    improvements,
                    Icons.trending_up,
                    Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 격려 메시지
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 18,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insights['motivation'] ?? '계속 노력하고 있는 모습이 멋져요!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 다음 목표와 팁
          _buildActionItems(insights),

          // 연결 상태 표시 (개발용)
          const SizedBox(height: 12),
          _buildConnectionStatus(hasMainInsight),
        ],
      ),
    );
  }

  /// AI 연결 상태 표시 위젯
  Widget _buildConnectionStatus(bool hasValidResponse) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasValidResponse ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasValidResponse ? 'AI 연결 활성화됨' : 'AI 연결 제한됨 (API 키 확인 필요)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            hasValidResponse ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: hasValidResponse ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  /// 인사이트 섹션 위젯 (높이 맞춤 수정)
  Widget _buildInsightSection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    logger.debug('📝 인사이트 섹션 렌더링: $title (${items.length}개 아이템)');

    return Container(
      height: double.infinity, // 부모의 높이에 맞춤
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty)
                  Text(
                    '• 데이터 분석 중...',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  )
                else
                  ...items
                      .take(2)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $item',
                            style: const TextStyle(fontSize: 11, height: 1.3),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 아이템 위젯
  Widget _buildActionItems(Map<String, dynamic> insights) {
    return Column(
      children: [
        // 다음 목표
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 16,
                color: Colors.deepPurple.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '다음 목표',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insights['nextGoal'] ?? '꾸준히 실행하기',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 개인화된 팁
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 16,
                color: Colors.deepPurple.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '맞춤 팁',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insights['personalizedTip'] ?? '매일 같은 시간에 실행해보세요.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState(String message) {
    logger.debug('⏳ 로딩 상태 표시: $message');

    return Container(
      width: double.infinity, // 가로 전체 차지
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.indigo.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center, // 텍스트 중앙 정렬
            style: TextStyle(fontSize: 14, color: Colors.deepPurple.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateTime.now().toString().split('.')[0]}',
            textAlign: TextAlign.center, // 텍스트 중앙 정렬
            style: TextStyle(
              fontSize: 10,
              color: Colors.deepPurple.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(String errorMessage) {
    logger.error('❌ 에러 상태 표시: $errorMessage');

    return Container(
      width: double.infinity, // 가로 전체 차지
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.indigo.withOpacity(0.1),
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
              size: 32,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI 분석을 불러올 수 없습니다',
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'API 키 설정 및 네트워크 연결을 확인해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            // 에러 세부사항 표시 (개발용)
            Container(
              width: double.infinity, // 에러 컨테이너도 전체 너비
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  const Text(
                    'Debug Info:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage.length > 100
                        ? '${errorMessage.substring(0, 100)}...'
                        : errorMessage,
                    style: const TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
