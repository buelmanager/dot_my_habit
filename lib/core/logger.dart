import 'package:flutter/foundation.dart' as foundation;
import 'package:logger/logger.dart';

/// 앱 전역에서 사용할 로거 인스턴스
late Logger logger;

/// 로거 설정 초기화
void setupLogger() {
  logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    // 릴리즈 모드에서는 debug, verbose 로그 출력 안 함
    level: foundation.kReleaseMode ? Level.info : Level.debug,
    // 릴리즈 모드에서 에러만 출력하고 싶다면:
    // level: foundation.kReleaseMode ? Level.error : Level.debug,
  );
}

/// 특정 클래스에서 사용하기 위한 로거 확장
extension LoggerExtensions on Logger {
  /// 클래스 이름으로 태그된 디버그 로그 출력
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    this.d(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// 클래스 이름으로 태그된 정보 로그 출력
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    this.i(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// 클래스 이름으로 태그된 경고 로그 출력
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    this.w(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// 클래스 이름으로 태그된 에러 로그 출력
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    this.e(taggedMessage, error: error, stackTrace: stackTrace);
  }
}