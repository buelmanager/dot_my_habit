import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/theme.dart';
import '../core/logger.dart';
import '../data/datasources/local/database.dart';
import '../data/services/ai_habit_analysis_service.dart';
import '../app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시스템 UI 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 로깅 초기화
  setupLogger();
  logger.info('앱 시작');

  try {
    // 환경 변수 로드 (.env 파일)
    await dotenv.load(fileName: "assets/.env");
    logger.info('환경 변수 로드 완료');

    // 로컬 데이터베이스 초기화
    await AppDatabase.initialize();
    logger.info('로컬 데이터베이스 초기화 완료');

    // AI 서비스 초기화
    try {
      await AIHabitAnalysisService().initialize();
      logger.info('AI 습관 분석 서비스 초기화 완료');
    } catch (e) {
      logger.warning('AI 서비스 초기화 실패 (API 키 확인 필요): $e');
      // AI 서비스 초기화에 실패해도 앱은 계속 실행
    }

    // 앱 실행
    runApp(const ProviderScope(child: DotHabitApp()));
  } catch (e, stack) {
    logger.error('앱 초기화 실패', error: e, stackTrace: stack);
    // 사용자에게 오류 알림 표시
    runApp(const AppInitErrorScreen());
  }
}

/// 메인 앱 위젯
class DotHabitApp extends ConsumerWidget {
  const DotHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.debug('DotHabitApp 빌드');

    // GoRouter 인스턴스 가져오기
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '점(Dot) - AI 습관 분석',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

/// 앱 초기화 오류 화면
class AppInitErrorScreen extends StatelessWidget {
  const AppInitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('앱 초기화 중 오류가 발생했습니다', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'AI 기능을 사용하려면 API 키 설정이 필요합니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 앱 재시작 시도
                  restartApp();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void restartApp() {
    // 앱 재시작 로직
    WidgetsBinding.instance.reassembleApplication();
  }
}
