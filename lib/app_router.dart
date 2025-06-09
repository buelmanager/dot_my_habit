import 'package:dot_my_habit/presentation/screens/home/home_screen.dart';
import 'package:dot_my_habit/presentation/screens/pattern/pattern_screen.dart';
import 'package:dot_my_habit/presentation/settings/settings_screen.dart';
import 'package:dot_my_habit/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/routes.dart';
import 'core/logger.dart';

/// GoRouter 프로바이더
final appRouterProvider = Provider<GoRouter>((ref) {
  logger.debug('앱 라우터 생성');

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    observers: [RouterObserver()],
    routes: [
      // 온보딩 화면
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) {
          logger.debug('온보딩 화면으로 라우팅');
          return Container(); //const OnboardingScreen();
        },
      ),

      // 기본 쉘 - 홈 화면
      ShellRoute(
        builder: (context, state, child) {
          // 현재 경로에 따라 페이지 인덱스 결정
          final location = state.uri.toString();
          int pageIndex = 0;

          if (location.startsWith(Routes.statistics)) {
            pageIndex = 1;
          } else if (location.startsWith(Routes.settings)) {
            pageIndex = 2;
          }

          return AppScaffold(pageIndex: pageIndex, child: child);
        },
        routes: [
          // 홈 화면
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (context, state) {
              logger.debug('홈 화면으로 라우팅');
              return const HomeScreen();
            },
            routes: [
              // 습관 상세
              GoRoute(
                path: 'habit/:id',
                name: 'habit_detail',
                builder: (context, state) {
                  final habitId = state.pathParameters['id'];
                  logger.debug('습관 상세 화면으로 라우팅: $habitId');
                  // TODO: 구현 필요
                  return const Scaffold(body: Center(child: Text('습관 상세')));
                },
              ),
            ],
          ),

          // 패턴 분석 화면 (기존 통계 화면 대체)
          GoRoute(
            path: Routes.statistics, // 기존 경로 사용
            name: 'pattern',
            builder: (context, state) {
              logger.debug('패턴 분석 화면으로 라우팅');
              return const PatternScreen();
            },
          ),

          // 설정 화면
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            builder: (context, state) {
              logger.debug('설정 화면으로 라우팅');
              return const SettingsScreen();
            },
          ),
        ],
      ),
    ],

    // 오류 발생 시 페이지
    errorBuilder: (context, state) {
      logger.error('라우팅 오류: ${state.error}');
      return Scaffold(
        appBar: AppBar(
          title: const Text('페이지를 찾을 수 없습니다'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(Routes.home),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('경로: ${state.uri.toString()}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

/// 라우터 이벤트 관찰을 위한 옵저버
class RouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.debug(
      '라우터: didPush ${route.settings.name} from ${previousRoute?.settings.name}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.debug(
      '라우터: didPop ${route.settings.name} to ${previousRoute?.settings.name}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logger.debug(
      '라우터: didReplace ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.debug(
      '라우터: didRemove ${route.settings.name} with previous ${previousRoute?.settings.name}',
    );
    super.didRemove(route, previousRoute);
  }
}
