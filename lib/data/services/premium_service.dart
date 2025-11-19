// lib/data/services/premium_service.dart (습관 제한 5개로 수정)
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../../domain/models/subscription_model.dart';
import 'subscription_service.dart';

/// 프리미엄 기능 관리 서비스
class PremiumService {
  static const String _tag = 'PremiumService';
  final SubscriptionService _subscriptionService;

  PremiumService({required SubscriptionService subscriptionService})
    : _subscriptionService = subscriptionService;

  /// 무료 버전 습관 제한 개수 (3개 → 5개로 변경)
  static const int freeHabitLimit = 5;

  /// 현재 구독 정보 확인
  Future<SubscriptionModel> _getCurrentSubscription() async {
    logger.debug('🔍 현재 구독 정보 조회 시작', tag: _tag);
    final subscription = await _subscriptionService.getCurrentSubscription();
    logger.info(
      '📋 현재 구독 정보: type=${subscription.type}, status=${subscription.status}, isPremium=${subscription.isPremium}',
      tag: _tag,
    );
    return subscription;
  }

  /// 프리미엄 사용자인지 확인
  Future<bool> isPremiumUser() async {
    logger.debug('⭐ 프리미엄 사용자 여부 확인 시작', tag: _tag);
    final subscription = await _getCurrentSubscription();
    final isPremium = subscription.isPremium;
    logger.info(
      '✅ 프리미엄 사용자 확인 결과: $isPremium (type: ${subscription.type}, status: ${subscription.status})',
      tag: _tag,
    );
    return isPremium;
  }

  /// 무제한 습관 추가 가능 여부
  Future<bool> canAddUnlimitedHabits() async {
    logger.debug('🔢 무제한 습관 추가 권한 확인', tag: _tag);
    final canAdd = await isPremiumUser();
    logger.info('📝 무제한 습관 추가 가능: $canAdd', tag: _tag);
    return canAdd;
  }

  /// 습관 추가 가능 여부 확인 (무료 사용자 5개 제한)
  Future<bool> canAddHabit(int currentHabitCount) async {
    logger.debug('🔍 습관 추가 가능 여부 확인: 현재 $currentHabitCount개', tag: _tag);
    final isPremium = await isPremiumUser();

    if (isPremium) {
      logger.info('✅ 프리미엄 사용자 - 무제한 습관 추가 가능', tag: _tag);
      return true;
    }

    final canAdd = currentHabitCount < freeHabitLimit;
    logger.info(
      '📊 무료 사용자 - 습관 추가 가능: $canAdd ($currentHabitCount/$freeHabitLimit)',
      tag: _tag,
    );
    return canAdd;
  }

  /// AI 인사이트 사용 가능 여부
  Future<bool> canUseAIInsights() async {
    logger.debug('🤖 AI 인사이트 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('🧠 AI 인사이트 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 상세 리포트 사용 가능 여부
  Future<bool> canUseDetailedReports() async {
    logger.debug('📊 상세 리포트 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('📈 상세 리포트 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 데이터 백업/복원 사용 가능 여부
  Future<bool> canUseDataBackup() async {
    logger.debug('💾 데이터 백업 권한 확인 시작', tag: _tag);

    try {
      final subscription = await _getCurrentSubscription();
      logger.debug('📋 구독 정보 상세: ${subscription.toString()}', tag: _tag);

      final isPremium = subscription.isPremium;
      final canUse = isPremium;

      logger.info('🔐 데이터 백업 권한 확인 완료:', tag: _tag);
      logger.info('  - 구독 타입: ${subscription.type}', tag: _tag);
      logger.info('  - 구독 상태: ${subscription.status}', tag: _tag);
      logger.info('  - 프리미엄 여부: $isPremium', tag: _tag);
      logger.info('  - 백업 사용 가능: $canUse', tag: _tag);

      return canUse;
    } catch (e, stackTrace) {
      logger.error(
        '❌ 데이터 백업 권한 확인 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      // 오류 시 기본적으로 false 반환 (안전한 기본값)
      return false;
    }
  }

  /// 커스텀 테마 사용 가능 여부
  Future<bool> canUseCustomThemes() async {
    logger.debug('🎨 커스텀 테마 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('🖌️ 커스텀 테마 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 위젯 지원 사용 가능 여부
  Future<bool> canUseWidgets() async {
    logger.debug('📱 위젯 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('🔧 위젯 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 광고 제거 여부
  Future<bool> isAdFree() async {
    logger.debug('🚫 광고 제거 상태 확인', tag: _tag);
    final isAdFree = await isPremiumUser();
    logger.info('📺 광고 제거 상태: $isAdFree', tag: _tag);
    return isAdFree;
  }

  /// 고급 통계 사용 가능 여부
  Future<bool> canUseAdvancedStats() async {
    logger.debug('📈 고급 통계 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('📊 고급 통계 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 패턴 분석 사용 가능 여부
  Future<bool> canUsePatternAnalysis() async {
    logger.debug('🔍 패턴 분석 권한 확인', tag: _tag);
    final canUse = await isPremiumUser();
    logger.info('🧩 패턴 분석 사용 가능: $canUse', tag: _tag);
    return canUse;
  }

  /// 습관 제한 메시지 생성 (5개 제한으로 수정)
  String getHabitLimitMessage(int currentCount) {
    final remaining = freeHabitLimit - currentCount;
    if (remaining > 0) {
      return '무료 버전에서는 $remaining개의 습관을 더 추가할 수 있습니다.';
    } else {
      return '무료 버전에서는 최대 $freeHabitLimit개의 습관만 추가할 수 있습니다.\n프리미엄으로 업그레이드하여 무제한으로 습관을 추가해보세요!';
    }
  }

  /// 프리미엄 기능 안내 메시지
  String getPremiumFeatureMessage(String featureName) {
    return '$featureName 기능은 프리미엄 전용입니다.\n프리미엄으로 업그레이드하여 모든 기능을 사용해보세요!';
  }

  /// 기능별 프리미엄 요구 확인 및 에러 처리
  Future<bool> checkPremiumAccess(String featureName) async {
    logger.debug('🔐 프리미엄 접근 권한 확인: $featureName', tag: _tag);
    final isPremium = await isPremiumUser();

    if (!isPremium) {
      logger.warning('⚠️ 프리미엄 기능 접근 시도: $featureName', tag: _tag);
    } else {
      logger.info('✅ 프리미엄 기능 접근 허용: $featureName', tag: _tag);
    }

    return isPremium;
  }

  /// 프리미엄 기능별 제한 확인
  Future<Map<String, bool>> getAllPremiumFeatures() async {
    logger.debug('📋 모든 프리미엄 기능 상태 확인', tag: _tag);
    final isPremium = await isPremiumUser();

    final features = {
      'unlimitedHabits': isPremium,
      'aiInsights': isPremium,
      'detailedReports': isPremium,
      'dataBackup': isPremium,
      'customThemes': isPremium,
      'widgets': isPremium,
      'adFree': isPremium,
      'advancedStats': isPremium,
      'patternAnalysis': isPremium,
    };

    logger.info('📊 프리미엄 기능 상태 요약: $features', tag: _tag);
    return features;
  }

  /// 구독 정보 요약
  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    logger.debug('📄 구독 정보 요약 생성', tag: _tag);
    final subscription = await _getCurrentSubscription();

    final summary = {
      'isPremium': subscription.isPremium,
      'isTrial': subscription.isTrial,
      'isExpired': subscription.isExpired,
      'remainingDays': subscription.remainingDays,
      'subscriptionType': subscription.type.toString(),
      'subscriptionStatus': subscription.status.toString(),
      'habitLimit':
          subscription.isPremium ? 'unlimited' : freeHabitLimit.toString(),
    };

    logger.info('📋 구독 정보 요약 완료: $summary', tag: _tag);
    return summary;
  }

  /// 프리미엄 혜택 목록
  static List<String> getPremiumBenefits() {
    return [
      '무제한 습관 추가',
      'AI 인사이트 & 예측',
      '상세 리포트 & 통계',
      '데이터 백업/복원',
      '커스텀 테마',
      '위젯 지원',
      '광고 제거',
      '고급 패턴 분석',
      '우선 고객 지원',
      '새 기능 먼저 체험',
    ];
  }

  /// 무료 버전 제한 사항 (5개로 수정)
  static Map<String, dynamic> getFreeLimitations() {
    return {
      'maxHabits': freeHabitLimit,
      'aiInsights': false,
      'detailedReports': false,
      'dataBackup': false,
      'customThemes': false,
      'widgets': false,
      'ads': true,
      'advancedStats': false,
      'patternAnalysis': false,
    };
  }
}

/// 프리미엄 서비스 프로바이더
final premiumServiceProvider = Provider<PremiumService>((ref) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return PremiumService(subscriptionService: subscriptionService);
});

/// 프리미엄 사용자 여부 프로바이더
final isPremiumUserProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.isPremiumUser();
});

/// 습관 추가 가능 여부 프로바이더
final canAddHabitProvider = FutureProvider.family<bool, int>((
  ref,
  currentCount,
) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canAddHabit(currentCount);
});

/// 무제한 습관 추가 가능 여부 프로바이더
final canAddUnlimitedHabitsProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canAddUnlimitedHabits();
});

/// AI 인사이트 사용 가능 여부 프로바이더
final canUseAIInsightsProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseAIInsights();
});

/// 상세 리포트 사용 가능 여부 프로바이더
final canUseDetailedReportsProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseDetailedReports();
});

/// 데이터 백업 사용 가능 여부 프로바이더
final canUseDataBackupProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseDataBackup();
});

/// 커스텀 테마 사용 가능 여부 프로바이더
final canUseCustomThemesProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseCustomThemes();
});

/// 위젯 사용 가능 여부 프로바이더
final canUseWidgetsProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseWidgets();
});

/// 광고 제거 여부 프로바이더
final isAdFreeProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.isAdFree();
});

/// 고급 통계 사용 가능 여부 프로바이더
final canUseAdvancedStatsProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUseAdvancedStats();
});

/// 패턴 분석 사용 가능 여부 프로바이더
final canUsePatternAnalysisProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.canUsePatternAnalysis();
});

/// 모든 프리미엄 기능 상태 프로바이더
final allPremiumFeaturesProvider = FutureProvider<Map<String, bool>>((
  ref,
) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.getAllPremiumFeatures();
});

/// 구독 정보 요약 프로바이더
final subscriptionSummaryProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final premiumService = ref.read(premiumServiceProvider);
  return await premiumService.getSubscriptionSummary();
});
