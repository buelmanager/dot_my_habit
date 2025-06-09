import 'package:flutter/material.dart';

/// 앱에서 사용되는 색상 상수
class AppColors {
  // 프라이빗 생성자 - 인스턴스화 방지
  AppColors._();

  /// 기본 흑백 테마
  static const Color primary = Colors.black;
  static const Color background = Colors.white;

  /// 텍스트 색상
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textHint = Color(0xFFBBBBBB);

  /// 배경 색상 변형
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// 그레이스케일
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  /// 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// 점(Dot) 색상 - 기본 흑백
  static const Color dotEmpty = Colors.transparent;
  static const Color dotFilled = Colors.black;
  static const Color dotBorder = Colors.black;

  /// 프리미엄 테마 컬러 - 모노톤 팔레트
  static const Map<String, Color> premiumColors = {
    // 블루 그레이
    'blueGrey': Color(0xFF607D8B),
    // 세피아
    'sepia': Color(0xFF8D6E63),
    // 딥 퍼플
    'deepPurple': Color(0xFF673AB7),
    // 딥 틸
    'deepTeal': Color(0xFF00796B),
    // 다크 올리브
    'darkOlive': Color(0xFF556B2F),
  };

  /// 주간 완료율 색상
  static Color getCompletionRateColor(double rate) {
    if (rate >= 0.9) {
      return primary;
    } else if (rate >= 0.6) {
      return primary.withOpacity(0.8);
    } else if (rate >= 0.3) {
      return primary.withOpacity(0.6);
    } else {
      return primary.withOpacity(0.4);
    }
  }
}