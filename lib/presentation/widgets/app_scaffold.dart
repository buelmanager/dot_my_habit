// lib/presentation/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import 'dot_bottom_navigation_bar.dart';

/// 앱 스캐폴드 - 하단 네비게이션 바를 포함한 공통 레이아웃
class AppScaffold extends ConsumerStatefulWidget {
  /// 네비게이션 페이지 인덱스
  final int pageIndex;

  /// 페이지 내용 위젯
  final Widget child;

  /// 생성자
  const AppScaffold({
    Key? key,
    required this.pageIndex,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    logger.debug('AppScaffold build, 페이지 인덱스: ${widget.pageIndex}');

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: DotBottomNavigationBar(
        currentIndex: widget.pageIndex,
      ),
      // FAB이 있을 경우 네비게이션 바와 겹치지 않도록 설정
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}