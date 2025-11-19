// lib/domain/models/subscription_model.dart (로그 개선 버전)
import '../../core/logger.dart';

/// 구독 타입 enum
enum SubscriptionType { free, premiumMonthly, premiumYearly }

/// 구독 상태 enum
enum SubscriptionStatus { active, expired, cancelled, trial }

/// 구독 정보 모델
class SubscriptionModel {
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isTrialUsed;
  final String? productId;

  const SubscriptionModel({
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
    this.isTrialUsed = false,
    this.productId,
  });

  /// 무료 버전인지 확인
  bool get isFree {
    final result = type == SubscriptionType.free;
    logger.debug('📊 isFree 계산: $result (type: $type)');
    return result;
  }

  /// 프리미엄 버전인지 확인
  bool get isPremium {
    final isNotFree = type != SubscriptionType.free;
    final isActive = status == SubscriptionStatus.active;
    final isTrial = status == SubscriptionStatus.trial;
    final result = isNotFree && (isActive || isTrial);

    logger.debug('📊 isPremium 계산:');
    logger.debug('  - type != free: $isNotFree (type: $type)');
    logger.debug('  - status: $status');
    logger.debug('  - isActive: $isActive');
    logger.debug('  - isTrial: $isTrial');
    logger.debug('  - result: $result');

    return result;
  }

  /// 체험판인지 확인
  bool get isTrial {
    final result = status == SubscriptionStatus.trial;
    logger.debug('📊 isTrial 계산: $result (status: $status)');
    return result;
  }

  /// 만료 여부 확인
  bool get isExpired {
    if (endDate == null) {
      logger.debug('📊 isExpired: false (endDate가 null)');
      return false;
    }
    final now = DateTime.now();
    final result = now.isAfter(endDate!);
    logger.debug('📊 isExpired 계산: $result (now: $now, endDate: $endDate)');
    return result;
  }

  /// 남은 일수 계산
  int get remainingDays {
    if (endDate == null) {
      logger.debug('📊 remainingDays: 0 (endDate가 null)');
      return 0;
    }
    final remaining = endDate!.difference(DateTime.now()).inDays;
    final result = remaining > 0 ? remaining : 0;
    logger.debug('📊 remainingDays 계산: $result (endDate: $endDate)');
    return result;
  }

  /// JSON으로부터 생성
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    logger.debug('📄 SubscriptionModel.fromJson 시작: $json');

    final model = SubscriptionModel(
      type: _subscriptionTypeFromString(json['type'] as String? ?? 'free'),
      status: _subscriptionStatusFromString(
        json['status'] as String? ?? 'active',
      ),
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : null,
      endDate:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'] as String)
              : null,
      isTrialUsed: json['isTrialUsed'] as bool? ?? false,
      productId: json['productId'] as String?,
    );

    logger.debug('📄 SubscriptionModel.fromJson 완료: ${model.toDebugString()}');
    return model;
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    final json = {
      'type': _subscriptionTypeToString(type),
      'status': _subscriptionStatusToString(status),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isTrialUsed': isTrialUsed,
      'productId': productId,
    };

    logger.debug('📄 SubscriptionModel.toJson: $json');
    return json;
  }

  /// 복사본 생성
  SubscriptionModel copyWith({
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? isTrialUsed,
    String? productId,
  }) {
    final copied = SubscriptionModel(
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isTrialUsed: isTrialUsed ?? this.isTrialUsed,
      productId: productId ?? this.productId,
    );

    logger.debug('📄 SubscriptionModel.copyWith:');
    logger.debug('  - 원본: ${this.toDebugString()}');
    logger.debug('  - 복사본: ${copied.toDebugString()}');

    return copied;
  }

  /// 기본 무료 구독
  static const SubscriptionModel defaultFree = SubscriptionModel(
    type: SubscriptionType.free,
    status: SubscriptionStatus.active,
  );

  /// 디버그용 상세 문자열
  String toDebugString() {
    return 'SubscriptionModel('
        'type: $type, '
        'status: $status, '
        'isPremium: $isPremium, '
        'isTrial: $isTrial, '
        'isExpired: $isExpired, '
        'remainingDays: $remainingDays, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'isTrialUsed: $isTrialUsed, '
        'productId: $productId)';
  }

  @override
  String toString() {
    return 'SubscriptionModel(type: $type, status: $status, isPremium: $isPremium, isTrialUsed: $isTrialUsed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionModel &&
        other.type == type &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isTrialUsed == isTrialUsed &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        status.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        isTrialUsed.hashCode ^
        productId.hashCode;
  }

  // 헬퍼 메서드들 - enum을 문자열로 변환
  static String _subscriptionTypeToString(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return 'free';
      case SubscriptionType.premiumMonthly:
        return 'premium_monthly';
      case SubscriptionType.premiumYearly:
        return 'premium_yearly';
    }
  }

  static SubscriptionType _subscriptionTypeFromString(String typeString) {
    logger.debug('📊 타입 문자열 변환: $typeString');
    switch (typeString) {
      case 'free':
        return SubscriptionType.free;
      case 'premium_monthly':
        return SubscriptionType.premiumMonthly;
      case 'premium_yearly':
        return SubscriptionType.premiumYearly;
      default:
        logger.warning('⚠️ 알 수 없는 구독 타입: $typeString, free로 기본값 설정');
        return SubscriptionType.free;
    }
  }

  static String _subscriptionStatusToString(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.trial:
        return 'trial';
    }
  }

  static SubscriptionStatus _subscriptionStatusFromString(String statusString) {
    logger.debug('📊 상태 문자열 변환: $statusString');
    switch (statusString) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'trial':
        return SubscriptionStatus.trial;
      default:
        logger.warning('⚠️ 알 수 없는 구독 상태: $statusString, active로 기본값 설정');
        return SubscriptionStatus.active;
    }
  }
}
