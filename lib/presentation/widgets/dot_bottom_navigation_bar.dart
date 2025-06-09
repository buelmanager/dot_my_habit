// lib/presentation/widgets/dot_bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../core/logger.dart';

/// 앱 하단 네비게이션 바
class DotBottomNavigationBar extends StatefulWidget {
  /// 현재 선택된 인덱스
  final int currentIndex;

  /// 생성자
  const DotBottomNavigationBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<DotBottomNavigationBar> createState() => _DotBottomNavigationBarState();
}

class _DotBottomNavigationBarState extends State<DotBottomNavigationBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.currentIndex);
  }

  @override
  void didUpdateWidget(DotBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _tabController.animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('DotBottomNavigationBar build, 현재 인덱스: ${widget.currentIndex}');

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black38,
        indicatorColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index != widget.currentIndex) {
            switch (index) {
              case 0:
                logger.debug('네비게이션: 오늘 버튼 클릭');
                context.go(Routes.home);
                break;
              case 1:
                logger.debug('네비게이션: 패턴 버튼 클릭');
                context.go(Routes.statistics);
                break;
              case 2:
                logger.debug('네비게이션: 설정 버튼 클릭');
                context.go(Routes.settings);
                break;
            }
          }
        },
        tabs: const [
          Tab(icon: Icon(Icons.circle_outlined, size: 22), text: '오늘'),
          Tab(icon: Icon(Icons.grid_4x4_outlined, size: 22), text: '패턴'),
          Tab(icon: Icon(Icons.settings_outlined, size: 22), text: '설정'),
        ],
      ),
    );
  }
}