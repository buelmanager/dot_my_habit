import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logger.dart';
import '../../../app_providers.dart';
import '../../common_widgets/enhanced_daily_view.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'widgets/home_header.dart';

/// 홈 화면
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _habitNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logger.info('HomeScreen 초기화');
  }

  @override
  void dispose() {
    logger.info('HomeScreen 해제');
    _habitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('HomeScreen 빌드');

    // HomeViewModel 관찰
    final viewModel = ref.watch(
        homeViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      // 상태바 스타일 설정
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 설정 버튼
            // Padding(
            //   padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.end,
            //     children: [
            //       IconButton(
            //         icon: const Icon(Icons.settings, size: 24),
            //         onPressed: () {
            //           logger.debug('설정 버튼 클릭');
            //           context.push(Routes.settings);
            //         },
            //       ),
            //     ],
            //   ),
            // ),

            // 목표 진행 요약 헤더
            _buildHomeHeader(context, state, viewModel),

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
            // 에러 표시
            else if (state.errorMessage != null)
              Expanded(
                child: _buildErrorView(context, state.errorMessage!, viewModel),
              )
            // 메인 콘텐츠
            else
              Expanded(child: _buildContent(context, state, viewModel)),
          ],
        ),
      ),
      // 습관 추가 버튼 (뷰 모드가 일간일 때만 표시)
      floatingActionButton:
          state.selectedViewIndex == 0
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                elevation: 2,
                onPressed: () {
                  logger.debug('습관 추가 버튼 클릭');
                  _showAddHabitDialog(context, viewModel);
                },
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  // 홈 헤더 위젯 빌드
  Widget _buildHomeHeader(
    BuildContext context,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    logger.debug('홈 헤더 빌드');

    return HomeHeader(
      selectedDate: state.selectedDate,
      habits: state.habits,
      onPreviousDay: () {
        logger.debug('이전 날짜 버튼 클릭');
        viewModel.goToPreviousDate();
      },
      onNextDay: () {
        logger.debug('다음 날짜 버튼 클릭');
        viewModel.goToNextDate();
      },
      onSelectDate: () {
        logger.debug('날짜 선택 버튼 클릭');
        _showDatePicker(context, viewModel);
      },
      onGoToToday: () {
        logger.debug('오늘로 이동 버튼 클릭');
        viewModel.goToToday();
      },
      weeklyProgress: state.weeklyProgress,
      topHabit: state.topHabit,
    );
  }

  // 메인 콘텐츠 빌드
  Widget _buildContent(
    BuildContext context,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    logger.debug('메인 콘텐츠 빌드: 뷰 모드=${state.selectedViewIndex}');

    // 현재 선택된 뷰 모드에 따라 다른 컴포넌트 반환
    switch (state.selectedViewIndex) {
      case 0: // 일간 뷰
        return RefreshIndicator(
          onRefresh: () async {
            logger.debug('새로고침 요청');
            await viewModel.refresh();
          },
          child: EnhancedDailyView(
            habits: state.habits,
            onToggle: viewModel.toggleHabit,
            selectedDate: state.selectedDate,
          ),
        );
      case 1: // 주간 뷰
        // TODO: 주간 뷰 구현
        return Center(
          child: Text(
            '주간 뷰는 아직 구현되지 않았습니다',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case 2: // 월간 뷰
        // TODO: 월간 뷰 구현
        return Center(
          child: Text(
            '월간 뷰는 아직 구현되지 않았습니다',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 에러 뷰 빌드
  Widget _buildErrorView(
    BuildContext context,
    String errorMessage,
    HomeViewModel viewModel,
  ) {
    logger.warning('에러 뷰 빌드: $errorMessage');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.black45),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                logger.debug('재시도 버튼 클릭');
                viewModel.refresh();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  // 날짜 선택 대화상자 표시
  void _showDatePicker(BuildContext context, HomeViewModel viewModel) async {
    logger.debug('날짜 선택 대화상자 표시');

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

  // 습관 추가 대화상자 표시
  void _showAddHabitDialog(BuildContext context, HomeViewModel viewModel) {
    logger.debug('습관 추가 대화상자 표시');

    _habitNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('습관 추가'),
          content: TextField(
            controller: _habitNameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '습관 이름 (12자 이내)',
              border: OutlineInputBorder(),
            ),
            maxLength: 12,
          ),
          actions: [
            TextButton(
              child: const Text('취소', style: TextStyle(color: Colors.black54)),
              onPressed: () {
                logger.debug('습관 추가 취소');
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('추가'),
              onPressed: () {
                final name = _habitNameController.text.trim();
                if (name.isNotEmpty) {
                  logger.debug('습관 추가 확인: $name');
                  viewModel.addHabit(name);
                  Navigator.of(context).pop();
                } else {
                  logger.debug('습관 이름이 비어있음, 추가하지 않음');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
