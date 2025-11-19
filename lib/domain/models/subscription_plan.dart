// lib/domain/models/subscription_plan.dart (습관 제한 5개로 수정)
import 'package:flutter/foundation.dart';

/// 구독 플랜 모델
@immutable
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int price; // 원 단위
  final String? originalPrice; // 할인 전 가격 (표시용)
  final String? discountText; // 할인율 텍스트
  final int durationMonths;
  final bool isPopular; // 인기 뱃지
  final String? badge; // 추가 뱃지 텍스트
  final String productId; // 앱스토어/플레이스토어 상품 ID
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountText,
    required this.durationMonths,
    this.isPopular = false,
    this.badge,
    required this.productId,
    required this.features,
  });

  /// 월간 단가 계산
  double get monthlyPrice => price / durationMonths;

  /// 가격 포맷팅 (천 단위 콤마)
  String get formattedPrice {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  /// 월간 단가 포맷팅
  String get formattedMonthlyPrice {
    final monthly = (price / durationMonths).round();
    return '${monthly.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  /// 추천 여부 (인기 뱃지와 동일)
  bool get isRecommended => isPopular;

  /// 기간 텍스트
  String get durationText {
    if (durationMonths == 1) {
      return '월간';
    } else if (durationMonths == 12) {
      return '연간';
    } else {
      return '${durationMonths}개월';
    }
  }

  /// 원래 가격 포맷팅
  String get formattedOriginalPrice {
    if (originalPrice == null) return '';
    return '${originalPrice!.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  /// 절약 금액 포맷팅
  String get formattedSavings {
    if (originalPrice == null) return '';

    final original = int.tryParse(originalPrice!.replaceAll(',', ''));
    if (original == null) return '';

    final savings = original - price;
    if (savings <= 0) return '';

    return '${savings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 절약';
  }

  /// 미리 정의된 구독 플랜들
  static final List<SubscriptionPlan> defaultPlans = [
    // 월간 플랜
    SubscriptionPlan(
      id: 'premium_monthly',
      name: '프리미엄 월간',
      description: '한 달 동안 모든 기능을 사용해보세요',
      price: 2900,
      durationMonths: 1,
      productId: 'dot_premium_monthly',
      features: [
        '무제한 습관 추가',
        'AI 인사이트 & 예측',
        '상세 리포트 & 통계',
        '데이터 백업/복원',
        '광고 제거',
      ],
    ),

    // 연간 플랜 (인기)
    SubscriptionPlan(
      id: 'premium_yearly',
      name: '프리미엄 연간',
      description: '1년 동안 모든 기능 + 추가 혜택',
      price: 29000,
      originalPrice: '34800',
      discountText: '17% 할인',
      durationMonths: 12,
      isPopular: true,
      badge: '인기',
      productId: 'dot_premium_yearly',
      features: [
        '무제한 습관 추가',
        'AI 인사이트 & 예측',
        '상세 리포트 & 통계',
        '데이터 백업/복원',
        '광고 제거',
        '월간 대비 17% 할인',
      ],
    ),

    // 6개월 플랜 (선택사항)
    SubscriptionPlan(
      id: 'premium_6months',
      name: '프리미엄 6개월',
      description: '6개월 동안 모든 기능 사용',
      price: 15900,
      originalPrice: '17400',
      discountText: '9% 할인',
      durationMonths: 6,
      productId: 'dot_premium_6months',
      features: [
        '무제한 습관 추가',
        'AI 인사이트 & 예측',
        '상세 리포트 & 통계',
        '데이터 백업/복원',
        '광고 제거',
        '월간 대비 9% 할인',
      ],
    ),
  ];

  /// 특정 기간의 플랜 찾기
  static SubscriptionPlan? findByDuration(int months) {
    return defaultPlans.firstWhere(
      (plan) => plan.durationMonths == months,
      orElse: () => defaultPlans.first,
    );
  }

  /// ID로 플랜 찾기
  static SubscriptionPlan? findById(String id) {
    try {
      return defaultPlans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 인기 플랜 찾기
  static SubscriptionPlan? get popularPlan {
    try {
      return defaultPlans.firstWhere((plan) => plan.isPopular);
    } catch (e) {
      return null;
    }
  }

  /// 가장 저렴한 월 단가 플랜 찾기
  static SubscriptionPlan get bestValuePlan {
    return defaultPlans.reduce(
      (a, b) => a.monthlyPrice < b.monthlyPrice ? a : b,
    );
  }

  /// 플랜 비교용 데이터 (습관 개수 5개로 수정)
  static Map<String, List<dynamic>> getComparisonData() {
    return {
      'features': [
        {'name': '기본 습관 추적', 'free': true, 'premium': true},
        {'name': '습관 개수', 'free': '최대 5개', 'premium': '무제한'},
        {'name': 'AI 인사이트', 'free': false, 'premium': true},
        {'name': '상세 리포트', 'free': false, 'premium': true},
        {'name': '데이터 백업', 'free': false, 'premium': true},
        {'name': '커스텀 테마', 'free': false, 'premium': true},
        {'name': '위젯 지원', 'free': false, 'premium': true},
        {'name': '광고', 'free': '표시됨', 'premium': '제거됨'},
        {'name': '고객 지원', 'free': '기본', 'premium': '우선'},
      ],
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionPlan &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.originalPrice == originalPrice &&
        other.discountText == discountText &&
        other.durationMonths == durationMonths &&
        other.isPopular == isPopular &&
        other.badge == badge &&
        other.productId == productId &&
        listEquals(other.features, features);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        originalPrice.hashCode ^
        discountText.hashCode ^
        durationMonths.hashCode ^
        isPopular.hashCode ^
        badge.hashCode ^
        productId.hashCode ^
        features.hashCode;
  }

  @override
  String toString() {
    return 'SubscriptionPlan('
        'id: $id, '
        'name: $name, '
        'description: $description, '
        'price: $price, '
        'originalPrice: $originalPrice, '
        'discountText: $discountText, '
        'durationMonths: $durationMonths, '
        'isPopular: $isPopular, '
        'badge: $badge, '
        'productId: $productId, '
        'features: $features'
        ')';
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountText': discountText,
      'durationMonths': durationMonths,
      'isPopular': isPopular,
      'badge': badge,
      'productId': productId,
      'features': features,
    };
  }

  /// JSON 역직렬화
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      originalPrice: json['originalPrice'] as String?,
      discountText: json['discountText'] as String?,
      durationMonths: json['durationMonths'] as int,
      isPopular: json['isPopular'] as bool? ?? false,
      badge: json['badge'] as String?,
      productId: json['productId'] as String,
      features: List<String>.from(json['features'] as List),
    );
  }

  /// 복사본 생성
  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? originalPrice,
    String? discountText,
    int? durationMonths,
    bool? isPopular,
    String? badge,
    String? productId,
    List<String>? features,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountText: discountText ?? this.discountText,
      durationMonths: durationMonths ?? this.durationMonths,
      isPopular: isPopular ?? this.isPopular,
      badge: badge ?? this.badge,
      productId: productId ?? this.productId,
      features: features ?? this.features,
    );
  }
}
