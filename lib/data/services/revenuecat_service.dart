import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/logger.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/models/subscription_plan.dart';

/// RevenueCat 기반 구독 서비스
class RevenueCatService {
  static const String _tag = 'RevenueCatService';
  static const String _subscriptionKey = 'user_subscription';

  // RevenueCat API 키 (실제 사용 시 환경변수나 secure storage 사용)
  static const String _apiKeyApple = 'appl_YOUR_APPLE_API_KEY';
  static const String _apiKeyGoogle = 'goog_YOUR_GOOGLE_API_KEY';

  // 구독 상품 ID (App Store Connect에서 설정한 ID와 일치해야 함)
  static const String _monthlyProductId = 'dot_premium_monthly';
  static const String _yearlyProductId = 'dot_premium_yearly';
  static const String _sixMonthsProductId = 'dot_premium_6months';

  // 엔타이틀먼트 ID (RevenueCat 대시보드에서 설정)
  static const String _premiumEntitlementId = 'premium';

  bool _isInitialized = false;

  /// RevenueCat 초기화
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        logger.debug('RevenueCat 이미 초기화됨', tag: _tag);
        return true;
      }

      logger.info('RevenueCat 초기화 시작', tag: _tag);

      // 플랫폼별 API 키 설정
      final apiKey = Platform.isIOS ? _apiKeyApple : _apiKeyGoogle;

      // RevenueCat 설정
      final configuration = PurchasesConfiguration(apiKey);

      if (kDebugMode) {
        // 디버그 모드에서는 로그 활성화
        await Purchases.setLogLevel(LogLevel.debug);
      }

      await Purchases.configure(configuration);

      // 사용자 ID 설정 (선택사항 - 익명 사용자도 가능)
      // await Purchases.logIn('user_unique_id');

      // 구매 업데이트 리스너 설정
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      _isInitialized = true;
      logger.info('RevenueCat 초기화 완료', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'RevenueCat 초기화 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 고객 정보 업데이트 리스너
  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    logger.debug('고객 정보 업데이트됨', tag: _tag);
    _updateLocalSubscriptionFromCustomerInfo(customerInfo);
  }

  /// 이용 가능한 구독 상품 조회
  Future<List<StoreProduct>> getAvailableProducts() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      logger.debug('구독 상품 조회 시작', tag: _tag);

      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        logger.warning('현재 활성화된 오퍼링이 없음', tag: _tag);
        return [];
      }

      final products =
          offerings.current!.availablePackages
              .map((package) => package.storeProduct)
              .toList();

      logger.info('구독 상품 ${products.length}개 조회 완료', tag: _tag);

      for (final product in products) {
        logger.debug(
          '상품: ${product.identifier} - ${product.title} - ${product.priceString}',
          tag: _tag,
        );
      }

      return products;
    } catch (e, stackTrace) {
      logger.error(
        '구독 상품 조회 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// 현재 구독 상태 조회
  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // RevenueCat에서 최신 고객 정보 조회
      final customerInfo = await Purchases.getCustomerInfo();

      // RevenueCat 정보를 로컬 모델로 변환
      final subscription = _convertToSubscriptionModel(customerInfo);

      // 로컬에도 저장
      await _saveSubscriptionLocally(subscription);

      logger.debug('현재 구독 상태: ${subscription.type}', tag: _tag);
      return subscription;
    } catch (e, stackTrace) {
      logger.error(
        '구독 상태 조회 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      // RevenueCat 실패 시 로컬 데이터 사용
      return await _getLocalSubscription();
    }
  }

  /// 구독 구매
  Future<bool> purchaseSubscription(String planId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      logger.info('구독 구매 시작: $planId', tag: _tag);

      // 상품 ID 매핑
      final productId = _mapPlanIdToProductId(planId);
      if (productId == null) {
        logger.error('유효하지 않은 플랜 ID: $planId', tag: _tag);
        return false;
      }

      // 오퍼링에서 패키지 찾기
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        logger.error('활성화된 오퍼링이 없음', tag: _tag);
        return false;
      }

      // 해당 상품 패키지 찾기
      Package? targetPackage;
      for (final package in currentOffering.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          targetPackage = package;
          break;
        }
      }

      if (targetPackage == null) {
        logger.error('상품을 찾을 수 없음: $productId', tag: _tag);
        return false;
      }

      // 구매 실행
      logger.debug('구매 실행: ${targetPackage.storeProduct.title}', tag: _tag);
      final purchaserInfo = await Purchases.purchasePackage(targetPackage);

      // 구매 성공 확인
      final isPremium =
          purchaserInfo.entitlements.all[_premiumEntitlementId]?.isActive ??
          false;

      if (isPremium) {
        logger.info('구독 구매 성공: $planId', tag: _tag);

        // 로컬 구독 정보 업데이트
        final subscription = _convertToSubscriptionModel(purchaserInfo);
        await _saveSubscriptionLocally(subscription);

        return true;
      } else {
        logger.warning('구매했지만 프리미엄 활성화되지 않음', tag: _tag);
        return false;
      }
    } catch (e, stackTrace) {
      logger.error('구독 구매 실패: $e', tag: _tag, error: e, stackTrace: stackTrace);

      // 사용자 취소인 경우 따로 처리
      if (e.toString().contains('purchase_cancelled') ||
          e.toString().contains('user_cancelled')) {
        logger.info('사용자가 구매를 취소함', tag: _tag);
      }

      return false;
    }
  }

  /// 구매 복원
  Future<bool> restorePurchases() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      logger.info('구매 복원 시작', tag: _tag);

      final customerInfo = await Purchases.restorePurchases();

      // 복원된 구독 정보 확인
      final isPremium =
          customerInfo.entitlements.all[_premiumEntitlementId]?.isActive ??
          false;

      if (isPremium) {
        logger.info('구매 복원 성공', tag: _tag);

        // 로컬 구독 정보 업데이트
        final subscription = _convertToSubscriptionModel(customerInfo);
        await _saveSubscriptionLocally(subscription);

        return true;
      } else {
        logger.info('복원할 구매가 없음', tag: _tag);
        return false;
      }
    } catch (e, stackTrace) {
      logger.error('구매 복원 실패: $e', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 7일 무료 체험 시작 (로컬만)
  Future<bool> startFreeTrial() async {
    try {
      final current = await _getLocalSubscription();

      if (current.isTrialUsed) {
        logger.warning('이미 체험판을 사용했음', tag: _tag);
        return false;
      }

      final trial = SubscriptionModel(
        type: SubscriptionType.premiumMonthly,
        status: SubscriptionStatus.trial,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isTrialUsed: true,
      );

      await _saveSubscriptionLocally(trial);
      logger.info('무료 체험 시작 완료', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error(
        '무료 체험 시작 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// RevenueCat CustomerInfo를 SubscriptionModel로 변환
  SubscriptionModel _convertToSubscriptionModel(CustomerInfo customerInfo) {
    final premiumEntitlement =
        customerInfo.entitlements.all[_premiumEntitlementId];

    if (premiumEntitlement == null || !premiumEntitlement.isActive) {
      return SubscriptionModel.defaultFree;
    }

    // 구독 타입 결정
    SubscriptionType type = SubscriptionType.premiumMonthly;
    if (premiumEntitlement.productIdentifier == _yearlyProductId) {
      type = SubscriptionType.premiumYearly;
    } else if (premiumEntitlement.productIdentifier == _sixMonthsProductId) {
      // 6개월 플랜이 있다면 추가 enum 필요
      type = SubscriptionType.premiumMonthly; // 임시로 월간으로 처리
    }

    // 구독 상태 결정
    SubscriptionStatus status = SubscriptionStatus.active;
    if (premiumEntitlement.willRenew == false) {
      status = SubscriptionStatus.cancelled;
    }

    return SubscriptionModel(
      type: type,
      status: status,
      startDate:
          premiumEntitlement.originalPurchaseDate != null
              ? DateTime.parse(premiumEntitlement.originalPurchaseDate!)
              : null,
      endDate:
          premiumEntitlement.expirationDate != null
              ? DateTime.parse(premiumEntitlement.expirationDate!)
              : null,
      isTrialUsed: true, // RevenueCat 구독자는 체험 사용한 것으로 간주
      productId: premiumEntitlement.productIdentifier,
    );
  }

  /// 플랜 ID를 RevenueCat 상품 ID로 매핑
  String? _mapPlanIdToProductId(String planId) {
    switch (planId) {
      case 'premium_monthly':
        return _monthlyProductId;
      case 'premium_yearly':
        return _yearlyProductId;
      case 'premium_6months':
        return _sixMonthsProductId;
      default:
        return null;
    }
  }

  /// RevenueCat 정보로 로컬 구독 정보 업데이트
  void _updateLocalSubscriptionFromCustomerInfo(CustomerInfo customerInfo) {
    final subscription = _convertToSubscriptionModel(customerInfo);
    _saveSubscriptionLocally(subscription);
  }

  /// 로컬 구독 정보 저장
  Future<void> _saveSubscriptionLocally(SubscriptionModel subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(subscription.toJson());
      await prefs.setString(_subscriptionKey, jsonString);
      logger.debug('로컬 구독 정보 저장 완료', tag: _tag);
    } catch (e) {
      logger.error('로컬 구독 정보 저장 실패: $e', tag: _tag);
    }
  }

  /// 로컬 구독 정보 조회
  Future<SubscriptionModel> _getLocalSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_subscriptionKey);

      if (jsonString == null) {
        return SubscriptionModel.defaultFree;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SubscriptionModel.fromJson(json);
    } catch (e) {
      logger.error('로컬 구독 정보 조회 실패: $e', tag: _tag);
      return SubscriptionModel.defaultFree;
    }
  }

  /// 서비스 정리
  void dispose() {
    logger.debug('RevenueCat 서비스 정리', tag: _tag);
    // 필요시 리스너 정리
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// RevenueCat 서비스 프로바이더
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

/// RevenueCat 초기화 프로바이더
final revenueCatInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  return await service.initialize();
});

/// 현재 구독 정보 프로바이더 (RevenueCat 기반)
final currentSubscriptionProvider = FutureProvider<SubscriptionModel>((
  ref,
) async {
  final service = ref.read(revenueCatServiceProvider);
  return await service.getCurrentSubscription();
});

/// 이용 가능한 구독 상품 프로바이더
final availableProductsProvider = FutureProvider<List<StoreProduct>>((
  ref,
) async {
  final service = ref.read(revenueCatServiceProvider);
  return await service.getAvailableProducts();
});

/// 구독 구매 프로바이더
final purchaseSubscriptionProvider = FutureProvider.family<bool, String>((
  ref,
  planId,
) async {
  final service = ref.read(revenueCatServiceProvider);
  final success = await service.purchaseSubscription(planId);

  if (success) {
    // 구독 정보 새로고침
    ref.invalidate(currentSubscriptionProvider);
  }

  return success;
});

/// 구매 복원 프로바이더
final restorePurchasesProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  final success = await service.restorePurchases();

  if (success) {
    // 구독 정보 새로고침
    ref.invalidate(currentSubscriptionProvider);
  }

  return success;
});

/// 무료 체험 시작 프로바이더
final startFreeTrialProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  final success = await service.startFreeTrial();

  if (success) {
    // 구독 정보 새로고침
    ref.invalidate(currentSubscriptionProvider);
  }

  return success;
});

/// 구독 상태 요약 프로바이더
final subscriptionStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final subscriptionAsync = ref.watch(currentSubscriptionProvider);

  return subscriptionAsync.when(
    loading: () => {'status': 'loading'},
    error: (error, stack) => {'status': 'error', 'error': error.toString()},
    data:
        (subscription) => {
          'status': 'loaded',
          'isPremium': subscription.isPremium,
          'isTrial': subscription.isTrial,
          'isExpired': subscription.isExpired,
          'remainingDays': subscription.remainingDays,
          'subscriptionType': subscription.type.toString(),
        },
  );
});
