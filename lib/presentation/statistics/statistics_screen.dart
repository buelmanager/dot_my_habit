// lib/presentation/screens/statistics/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart'; // Provider 정의가 있는 파일 임포트
import '../../../core/logger.dart';
import '../viewmodels/home_viewmodel.dart';

/// 통계 화면 (패턴 시각화)
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedViewIndex = 0; // 0: 주간, 1: 월간, 2: 연간
  final List<String> _viewOptions = ['주간', '월간', '연간'];

  @override
  void initState() {
    super.initState();
    logger.info('StatisticsScreen 초기화');
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('StatisticsScreen 빌드');

    // 뷰모델 관찰
    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '패턴',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildViewSelector(),
          ),
        ),
      ),
      body: SafeArea(
        child: _buildSelectedView(state),
      ),
    );
  }

  /// 뷰 선택 세그먼트 컨트롤
  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(
          _viewOptions.length,
              (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedViewIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: _selectedViewIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _selectedViewIndex == index
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                      : [],
                ),
                child: Text(
                  _viewOptions[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedViewIndex == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedViewIndex == index
                        ? Colors.black
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 선택된 뷰에 따른 내용 표시
  Widget _buildSelectedView(HomeState state) {
    if (state.habits.isEmpty) {
      return const Center(
        child: Text(
          '아직 습관이 없습니다.\n홈 화면에서 습관을 추가해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      );
    }

    switch (_selectedViewIndex) {
      case 0:
        return _buildWeeklyView(state);
      case 1:
        return _buildMonthlyView(state);
      case 2:
        return _buildYearlyView(state);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 주간 패턴 뷰
  Widget _buildWeeklyView(HomeState state) {
    // TODO: 주간 패턴 구현
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week,
              size: 64,
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              '주간 패턴 시각화',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '여기에 주간 패턴 시각화가 표시됩니다.\n${state.habits.length}개의 습관이 있습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 월간 패턴 뷰
  Widget _buildMonthlyView(HomeState state) {
    // TODO: 월간 패턴 구현
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_month,
              size: 64,
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              '월간 패턴 시각화',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '여기에 월간 패턴 시각화가 표시됩니다.\n${state.habits.length}개의 습관이 있습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 연간 패턴 뷰
  Widget _buildYearlyView(HomeState state) {
    // TODO: 연간 패턴 구현
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              '연간 패턴 시각화',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '여기에 연간 패턴 시각화가 표시됩니다.\n${state.habits.length}개의 습관이 있습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}