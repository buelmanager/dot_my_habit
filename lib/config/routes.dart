/// 앱 라우트 정의
class Routes {
  // 프라이빗 생성자 - 인스턴스화 방지
  Routes._();

  /// 온보딩 화면
  static const String onboarding = '/onboarding';

  static const String home = '/';

  /// 통계 화면
  static const String statistics = '/statistics';

  /// 설정 화면
  static const String settings = '/settings';

  /// 구독 화면 (새로 추가)
  static const String subscription = '/subscription';
}
