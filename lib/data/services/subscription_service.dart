// lib/data/services/subscription_service.dart (로그 추가 버전)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/logger.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/models/subscription_plan.dart';

/// 구독 서비스 - 구독 상태 관리만 담당
class SubscriptionService {
  static const String _tag = 'SubscriptionService';
  static const String _subscriptionKey = 'user_subscription';

  /// 현재 구독 정보 조회
  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      logger.debug('📋 구독 정보 조회 시작', tag: _tag);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_subscriptionKey);

      if (jsonString == null) {
        logger.info('📝 저장된 구독 정보 없음 - 기본 무료 반환', tag: _tag);
        return SubscriptionModel.defaultFree;
      }

      logger.debug('📄 저장된 구독 정보 발견: ${jsonString.length}자', tag: _tag);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final subscription = SubscriptionModel.fromJson(json);

      logger.info('✅ 구독 정보 조회 완료:', tag: _tag);
      logger.info('  - 타입: ${subscription.type}', tag: _tag);
      logger.info('  - 상태: ${subscription.status}', tag: _tag);
      logger.info('  - 프리미엄: ${subscription.isPremium}', tag: _tag);
      logger.info('  - 체험: ${subscription.isTrial}', tag: _tag);
      logger.info('  - 만료: ${subscription.isExpired}', tag: _tag);

      return subscription;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 구독 정보 조회 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      logger.info('🔄 오류로 인해 기본 무료 구독 반환', tag: _tag);
      return SubscriptionModel.defaultFree;
    }
  }

  /// 구독 정보 저장
  Future<bool> saveSubscription(SubscriptionModel subscription) async {
    try {
      logger.info('💾 구독 정보 저장 시작:', tag: _tag);
      logger.info('  - 타입: ${subscription.type}', tag: _tag);
      logger.info('  - 상태: ${subscription.status}', tag: _tag);
      logger.info('  - 프리미엄: ${subscription.isPremium}', tag: _tag);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(subscription.toJson());

      logger.debug('📝 JSON 직렬화 완료: ${jsonString.length}자', tag: _tag);

      await prefs.setString(_subscriptionKey, jsonString);

      logger.info('✅ 구독 정보 저장 완료: ${subscription.type}', tag: _tag);

      // 저장 후 검증
      final saved = prefs.getString(_subscriptionKey);
      if (saved == jsonString) {
        logger.debug('✔️ 저장 검증 성공', tag: _tag);
      } else {
        logger.warning('⚠️ 저장 검증 실패 - 데이터 불일치', tag: _tag);
      }

      return true;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 구독 정보 저장 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 7일 무료 체험 시작
  Future<bool> startFreeTrial() async {
    try {
      logger.info('🎯 무료 체험 시작 요청', tag: _tag);
      final current = await getCurrentSubscription();

      if (current.isTrialUsed) {
        logger.warning('⚠️ 이미 체험판을 사용했음', tag: _tag);
        return false;
      }

      final trial = SubscriptionModel(
        type: SubscriptionType.premiumMonthly,
        status: SubscriptionStatus.trial,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isTrialUsed: true,
      );

      logger.debug('📋 체험판 구독 모델 생성:', tag: _tag);
      logger.debug('  - 시작: ${trial.startDate}', tag: _tag);
      logger.debug('  - 종료: ${trial.endDate}', tag: _tag);
      logger.debug('  - 남은 일수: ${trial.remainingDays}', tag: _tag);

      final success = await saveSubscription(trial);
      logger.info('🎉 무료 체험 시작 결과: $success', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 무료 체험 시작 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 구독 시작 (실제 구매)
  Future<bool> startSubscription(String planId) async {
    try {
      logger.info('🛒 구독 시작 요청: $planId', tag: _tag);

      final plan = SubscriptionPlan.findById(planId);
      if (plan == null) {
        logger.error('❌ 유효하지 않은 플랜 ID: $planId', tag: _tag);
        return false;
      }

      logger.debug('📋 플랜 정보:', tag: _tag);
      logger.debug('  - 이름: ${plan.name}', tag: _tag);
      logger.debug('  - 기간: ${plan.durationMonths}개월', tag: _tag);
      logger.debug('  - 가격: ${plan.formattedPrice}', tag: _tag);

      final subscriptionType =
          planId == 'premium_yearly'
              ? SubscriptionType.premiumYearly
              : SubscriptionType.premiumMonthly;

      final subscription = SubscriptionModel(
        type: subscriptionType,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: plan.durationMonths * 30)),
        isTrialUsed: true, // 구독 시작 시 체험 사용됨으로 처리
        productId: plan.productId,
      );

      logger.debug('📋 구독 모델 생성:', tag: _tag);
      logger.debug('  - 타입: ${subscription.type}', tag: _tag);
      logger.debug('  - 상태: ${subscription.status}', tag: _tag);
      logger.debug('  - 시작: ${subscription.startDate}', tag: _tag);
      logger.debug('  - 종료: ${subscription.endDate}', tag: _tag);
      logger.debug('  - 프리미엄: ${subscription.isPremium}', tag: _tag);

      final success = await saveSubscription(subscription);
      logger.info('🎉 구독 시작 완료: $success', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 구독 시작 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 구독 해지
  Future<bool> cancelSubscription() async {
    try {
      logger.info('🚫 구독 해지 요청', tag: _tag);
      final current = await getCurrentSubscription();

      logger.debug('📋 현재 구독:', tag: _tag);
      logger.debug('  - 타입: ${current.type}', tag: _tag);
      logger.debug('  - 상태: ${current.status}', tag: _tag);

      final cancelled = current.copyWith(status: SubscriptionStatus.cancelled);

      logger.debug('📋 해지된 구독:', tag: _tag);
      logger.debug('  - 타입: ${cancelled.type}', tag: _tag);
      logger.debug('  - 상태: ${cancelled.status}', tag: _tag);
      logger.debug('  - 프리미엄: ${cancelled.isPremium}', tag: _tag);

      final success = await saveSubscription(cancelled);
      logger.info('🎉 구독 해지 완료: $success', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 구독 해지 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 구독 복원 (앱스토어/플레이스토어 구매 복원)
  Future<bool> restoreSubscription() async {
    try {
      logger.info('🔄 구독 복원 시도', tag: _tag);
      // TODO: 실제 인앱결제 복원 로직 구현
      logger.debug('⚠️ 구독 복원 로직 미구현 - 성공으로 반환', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 구독 복원 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

// =============================================================================
// PROVIDERS - 모든 구독 관련 프로바이더
// =============================================================================

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  logger.debug('🏭 SubscriptionService 프로바이더 생성');
  return SubscriptionService();
});

// -----------------------------------------------------------------------------
// 구독 상태 관련 프로바이더
// -----------------------------------------------------------------------------

/// 현재 구독 정보 프로바이더
final currentSubscriptionProvider = FutureProvider<SubscriptionModel>((
  ref,
) async {
  logger.debug('🔍 currentSubscriptionProvider 호출');
  final service = ref.read(subscriptionServiceProvider);
  final result = await service.getCurrentSubscription();
  logger.info(
    '📋 currentSubscriptionProvider 결과: ${result.type}, isPremium: ${result.isPremium}',
  );
  return result;
});

/// 구독 상태 요약 프로바이더
final subscriptionStatusProvider = Provider<Map<String, dynamic>>((ref) {
  logger.debug('🔍 subscriptionStatusProvider 호출');
  final subscriptionAsync = ref.watch(currentSubscriptionProvider);

  return subscriptionAsync.when(
    loading: () {
      logger.debug('⏳ 구독 상태 로딩 중');
      return {'status': 'loading'};
    },
    error: (error, stack) {
      logger.error('❌ 구독 상태 오류: $error');
      return {'status': 'error', 'error': error.toString()};
    },
    data: (subscription) {
      final result = {
        'status': 'loaded',
        'isPremium': subscription.isPremium,
        'isTrial': subscription.isTrial,
        'isExpired': subscription.isExpired,
        'remainingDays': subscription.remainingDays,
        'subscriptionType': subscription.type.toString(),
      };
      logger.info('📋 구독 상태 요약: $result');
      return result;
    },
  );
});

// -----------------------------------------------------------------------------
// 구독 플랜 관련 프로바이더 (SubscriptionPlan 정적 메서드 사용)
// -----------------------------------------------------------------------------

/// 모든 구독 플랜 프로바이더
final subscriptionPlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  return SubscriptionPlan.defaultPlans;
});

/// 활성 구독 플랜 프로바이더 (현재는 모든 플랜이 활성)
final activeSubscriptionPlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  return SubscriptionPlan.defaultPlans;
});

/// 추천 구독 플랜 프로바이더
final recommendedPlanProvider = Provider<SubscriptionPlan?>((ref) {
  return SubscriptionPlan.popularPlan;
});

/// 가성비 최고 플랜 프로바이더
final bestValuePlanProvider = Provider<SubscriptionPlan>((ref) {
  return SubscriptionPlan.bestValuePlan;
});

/// 특정 플랜 조회 프로바이더
final planByIdProvider = Provider.family<SubscriptionPlan?, String>((
  ref,
  planId,
) {
  return SubscriptionPlan.findById(planId);
});

/// 기간별 플랜 조회 프로바이더
final planByDurationProvider = Provider.family<SubscriptionPlan?, int>((
  ref,
  months,
) {
  return SubscriptionPlan.findByDuration(months);
});

// -----------------------------------------------------------------------------
// 구독 액션 프로바이더
// -----------------------------------------------------------------------------

/// 무료 체험 시작 프로바이더
final startFreeTrialProvider = FutureProvider<bool>((ref) async {
  logger.debug('🔍 startFreeTrialProvider 호출');
  final service = ref.read(subscriptionServiceProvider);
  final success = await service.startFreeTrial();

  if (success) {
    logger.info('🔄 무료 체험 성공 - provider 새로고침');
    ref.invalidate(currentSubscriptionProvider);
  } else {
    logger.warning('⚠️ 무료 체험 실패');
  }

  return success;
});

///
