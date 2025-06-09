import 'package:dot_my_habit/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/local/dao/habit_dao.dart';
import 'data/repositories/habit_repository.dart';
import 'data/services/backup_service.dart';
import 'data/services/ai_habit_analysis_service.dart';
import 'core/logger.dart';

/// HabitDao 프로바이더
final habitDaoProvider = Provider<HabitDao>((ref) {
  logger.debug('🗃 HabitDao 프로바이더 생성');
  return HabitDao();
});

/// 습관 저장소 프로바이더
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  logger.debug('📚 HabitRepository 프로바이더 생성');
  final habitDao = ref.watch(habitDaoProvider);
  return HabitRepositoryImpl(localDataSource: habitDao);
});

/// 백업 서비스 프로바이더
final backupServiceProvider = Provider<BackupService>((ref) {
  logger.debug('💾 BackupService 프로바이더 생성');
  final habitRepository = ref.watch(habitRepositoryProvider);
  return BackupService(habitRepository: habitRepository);
});

/// AI 습관 분석 서비스 프로바이더 (싱글톤)
final aiHabitAnalysisServiceProvider = Provider<AIHabitAnalysisService>((ref) {
  logger.debug('🤖 AIHabitAnalysisService 프로바이더 생성');
  return AIHabitAnalysisService();
});

/// AI 분석 데이터 프로바이더 (Future)
final aiInsightsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final requestId = DateTime.now().millisecondsSinceEpoch;
      logger.info('🎯 AI 인사이트 요청 시작 (ID: $requestId)');
      logger.debug('📊 요청 파라미터 키: ${params.keys.toList()}');

      try {
        final aiService = ref.watch(aiHabitAnalysisServiceProvider);

        // 할당량 체크를 위한 초기화 시도
        if (!aiService.isInitialized) {
          logger.info('🚀 AI 서비스 초기화 시도 (ID: $requestId)');
          try {
            await aiService.initialize();
            if (aiService.isInitialized) {
              logger.info('✅ AI 서비스 초기화 완료 (ID: $requestId)');
            }
          } catch (e) {
            logger.warning('⚠️ AI 서비스 초기화 실패, 폴백 모드 사용 (ID: $requestId): $e');
            // 초기화 실패해도 계속 진행 (폴백 응답 제공)
          }
        }

        logger.debug('🔄 AI 인사이트 생성 요청 (ID: $requestId)');
        final result = await aiService.generatePersonalizedInsights(
          habits: params['habits'] ?? [],
          weeklyProgress: params['weeklyProgress'] ?? {},
          monthlyData: params['monthlyData'] ?? {},
          totalCompletedHabits: params['totalCompletedHabits'] ?? 0,
          totalHabits: params['totalHabits'] ?? 0,
          activeDays: params['activeDays'] ?? 0,
        );

        logger.info('🎉 AI 인사이트 요청 완료 (ID: $requestId)');
        logger.debug('📋 응답 키: ${result.keys.toList()}');

        return result;
      } catch (e, stackTrace) {
        logger.error(
          '❌ AI 인사이트 요청 실패 (ID: $requestId): $e',
          error: e,
          stackTrace: stackTrace,
        );

        // 할당량 초과 등의 에러 시에도 폴백 응답 제공
        logger.info('🔄 폴백 응답 제공 (ID: $requestId)');
        return {
          'mainInsight': '습관 데이터를 분석 중입니다.',
          'performance': {'level': 'analyzing', 'description': '데이터 처리 중'},
          'patterns': ['규칙적인 실행이 핵심입니다.'],
          'recommendations': ['꾸준히 계속해보세요.'],
          'motivation': '매일 조금씩 발전하고 있어요! 🌟',
          'isOffline': true, // 오프라인 모드 표시
        };
      }
    });

/// AI 습관 추천 프로바이더 (Future)
final aiRecommendationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final requestId = DateTime.now().millisecondsSinceEpoch;
      logger.info('💡 AI 추천 요청 시작 (ID: $requestId)');

      try {
        final aiService = ref.watch(aiHabitAnalysisServiceProvider);

        // 초기화 시도 (실패해도 계속 진행)
        if (!aiService.isInitialized) {
          logger.info('🚀 AI 서비스 초기화 (추천, ID: $requestId)');
          try {
            await aiService.initialize();
          } catch (e) {
            logger.warning('⚠️ AI 초기화 실패, 폴백 추천 사용 (ID: $requestId)');
          }
        }

        logger.debug('🔄 AI 추천 생성 요청 (ID: $requestId)');
        final result = await aiService.generateHabitRecommendations(
          currentHabits: params['currentHabits'] ?? [],
          weeklyProgress: params['weeklyProgress'] ?? {},
          averageCompletionRate: params['averageCompletionRate'] ?? 0.0,
        );

        logger.info('🎉 AI 추천 요청 완료 (ID: $requestId): ${result.length}개 추천');
        return result;
      } catch (e, stackTrace) {
        logger.error(
          '❌ AI 추천 요청 실패 (ID: $requestId): $e',
          error: e,
          stackTrace: stackTrace,
        );

        // 에러 시 기본 추천 제공
        logger.info('🔄 기본 추천 제공 (ID: $requestId)');
        return [
          {
            'name': '물 마시기',
            'description': '하루 8잔의 물을 마시는 습관',
            'difficulty': 'easy',
            'category': 'health',
            'reason': '건강한 생활의 기본입니다.',
          },
          {
            'name': '10분 걷기',
            'description': '매일 10분씩 가볍게 산책하기',
            'difficulty': 'easy',
            'category': 'health',
            'reason': '간단하지만 효과적인 운동입니다.',
          },
        ];
      }
    });

/// AI 패턴 예측 프로바이더 (Future)
final aiPredictionProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final requestId = DateTime.now().millisecondsSinceEpoch;
      logger.info('🔮 AI 예측 요청 시작 (ID: $requestId)');

      try {
        final aiService = ref.watch(aiHabitAnalysisServiceProvider);

        // AI 서비스 초기화 확인
        if (!aiService.isInitialized) {
          logger.info('🚀 AI 서비스 초기화 (예측, ID: $requestId)');
          await aiService.initialize();
        }

        logger.debug('🔄 AI 예측 생성 요청 (ID: $requestId)');
        final result = await aiService.generatePatternPrediction(
          habits: params['habits'] ?? [],
          weeklyProgress: params['weeklyProgress'] ?? {},
          monthlyTrends: params['monthlyTrends'] ?? {},
        );

        logger.info('🎉 AI 예측 요청 완료 (ID: $requestId)');
        return result;
      } catch (e, stackTrace) {
        logger.error(
          '❌ AI 예측 요청 실패 (ID: $requestId): $e',
          error: e,
          stackTrace: stackTrace,
        );

        // 재설정 시도
        if (e.toString().contains('LateInitializationError')) {
          logger.warning('🔄 AI 서비스 재설정 (예측, ID: $requestId)');
          final aiService = ref.watch(aiHabitAnalysisServiceProvider);
          aiService.reset();
        }

        rethrow;
      }
    });

/// 홈 뷰모델 프로바이더
final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  logger.debug('🏠 HomeViewModel 프로바이더 생성');
  final habitRepository = ref.watch(habitRepositoryProvider);
  return HomeViewModel(habitRepository: habitRepository);
});

/// AI 상태 모니터링 프로바이더
final aiStatusProvider = Provider<Map<String, dynamic>>((ref) {
  logger.debug('📊 AI 상태 모니터링 프로바이더 호출');

  final aiService = ref.watch(aiHabitAnalysisServiceProvider);

  final status = {
    'isInitialized': aiService.isInitialized,
    'initializationError': aiService.initializationError,
    'timestamp': DateTime.now().toIso8601String(),
    'serviceHashCode': aiService.hashCode, // 인스턴스 추적용
  };

  logger.debug('📋 AI 상태: $status');
  return status;
});

/// AI 서비스 수동 초기화 프로바이더 (디버깅용)
final aiInitializationProvider = FutureProvider<bool>((ref) async {
  logger.info('🔧 AI 서비스 수동 초기화 시작');

  try {
    final aiService = ref.watch(aiHabitAnalysisServiceProvider);

    if (!aiService.isInitialized) {
      await aiService.initialize();
      logger.info('✅ AI 서비스 수동 초기화 완료');
      return true;
    } else {
      logger.info('♻️ AI 서비스가 이미 초기화되어 있음');
      return true;
    }
  } catch (e, stackTrace) {
    logger.error('❌ AI 서비스 수동 초기화 실패: $e', error: e, stackTrace: stackTrace);
    return false;
  }
});
