// lib/presentation/screens/pattern/pattern_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger.dart';
import '../../../app_providers.dart';
import '../../common_widgets/view_selector.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'views/pattern_summary_view.dart';
import 'views/pattern_weekly_view.dart';
import 'views/pattern_monthly_view.dart';
import 'views/pattern_analytics_view.dart';

/// 패턴 분석 화면
class PatternScreen extends ConsumerStatefulWidget {
  const PatternScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends ConsumerState<PatternScreen>
    with SingleTickerProviderStateMixin {
  late TabController _viewController;
  PageController? _pageController;

  // 패턴 탭 보기 모드 선택 인덱스 (0: 요약, 1: 주간, 2: 월간, 3: 분석)
  int _selectedViewIndex = 0;
  final List<String> _viewOptions = ['요약', '주간', '월간', '분석'];

  @override
  void initState() {
    super.initState();
    logger.info('PatternScreen 초기화');

    // 뷰 모드 탭 컨트롤러 초기화 (요약/주간/월간/분석)
    _viewController = TabController(length: 4, vsync: this);
    _pageController = PageController(initialPage: _selectedViewIndex);

    // 탭 변경 리스너
    _viewController.addListener(_handleViewChange);
  }

  void _handleViewChange() {
    if (!_viewController.indexIsChanging) {
      setState(() {
        _selectedViewIndex = _viewController.index;
      });

      // 페이지 이동
      if (_pageController != null && _pageController!.hasClients) {
        _pageController!.animateToPage(
          _selectedViewIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    logger.info('PatternScreen 해제');
    _viewController.removeListener(_handleViewChange);
    _viewController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //logger.debug('PatternScreen 빌드');

    // HomeViewModel 관찰
    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분
            _buildHeader(context, state),

            // 뷰 모드 선택 탭 (요약/주간/월간/분석)
            ViewSelector(
              titles: _viewOptions,
              selectedIndex: _selectedViewIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedViewIndex = index;
                });
                _viewController.animateTo(index);
              },
            ),

            // 로딩 중 표시
            if (state.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              )
            else
              // 페이지 뷰
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _selectedViewIndex = index;
                    });

                    if (_viewController.index != index) {
                      _viewController.animateTo(index);
                    }
                  },
                  children: const [
                    // 요약 뷰
                    PatternSummaryView(),

                    // 주간 뷰
                    PatternWeeklyView(),

                    // 월간 뷰
                    PatternMonthlyView(),

                    // 분석 뷰
                    PatternAnalyticsView(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 헤더 위젯
  Widget _buildHeader(BuildContext context, HomeState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 패턴 분석 타이틀
          const Text(
            '패턴 분석',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          // 날짜 선택기
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.06),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getDateRangeText(state.selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // 날짜 이동 버튼
                  if (_selectedViewIndex == 1 || _selectedViewIndex == 2)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            logger.debug('이전 날짜 버튼 클릭');
                            final viewModel = ref.read(homeViewModelProvider);
                            viewModel.goToPreviousDate();
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            logger.debug('다음 날짜 버튼 클릭');
                            final viewModel = ref.read(homeViewModelProvider);
                            viewModel.goToNextDate();
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showDatePicker(context),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 선택된 뷰에 따른 날짜 범위 텍스트 반환
  String _getDateRangeText(DateTime date) {
    switch (_selectedViewIndex) {
      case 1: // 주간 뷰
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.month}/${weekStart.day} ~ ${weekEnd.month}/${weekEnd.day}';
      case 2: // 월간 뷰
        return '${date.year}년 ${date.month}월';
      default: // 요약 뷰와 분석 뷰
        return '전체 기간';
    }
  }

  // 날짜 선택 대화상자
  void _showDatePicker(BuildContext context) async {
    logger.debug('날짜 선택 대화상자 표시');

    final viewModel = ref.read(homeViewModelProvider);
    final selectedDate = viewModel.state.selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      logger.debug('날짜 선택됨: $pickedDate');
      viewModel.setSelectedDate(pickedDate);
    } else {
      logger.debug('날짜 선택 취소 또는 같은 날짜 선택');
    }
  }
}
