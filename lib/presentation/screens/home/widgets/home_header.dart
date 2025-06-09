import 'package:flutter/material.dart';

import '../../../../../core/logger.dart';
import '../../../../../data/models/habit.dart';
import '../../../common_widgets/date_selector.dart';
import '../../../common_widgets/progress_circle.dart';
import '../../../common_widgets/top_habit_card.dart';
import '../../../common_widgets/weekly_progress_bar.dart';

/// 홈 헤더 위젯
class HomeHeader extends StatefulWidget {
  /// 선택된 날짜
  final DateTime selectedDate;

  /// 습관 목록
  final List<Habit> habits;

  /// 주간 진행률 데이터
  final Map<String, double> weeklyProgress;

  /// 최고 스트릭 습관
  final Habit? topHabit;

  /// 이전 날로 이동하는 콜백
  final VoidCallback onPreviousDay;

  /// 다음 날로 이동하는 콜백
  final VoidCallback onNextDay;

  /// 날짜 선택 콜백
  final VoidCallback onSelectDate;

  /// 오늘 날짜로 이동하는 콜백
  final VoidCallback onGoToToday;

  /// 생성자
  const HomeHeader({
    Key? key,
    required this.selectedDate,
    required this.habits,
    required this.weeklyProgress,
    this.topHabit,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onSelectDate,
    required this.onGoToToday,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // 날짜 변경 애니메이션을 위한 변수
  DateTime? _previousDate;
  bool _isAnimatingDateForward = true;
  bool _isChangingDate = false;

  @override
  void initState() {
    super.initState();
    logger.debug('HomeHeader initState');

    _previousDate = widget.selectedDate;

    // 애니메이션 컨트롤러 초기화 (1.2초 지속)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 완료율 애니메이션
    _updateProgressAnimation();

    // 애니메이션 시작
    _progressController.forward();
  }

  @override
  void didUpdateWidget(HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    logger.debug('HomeHeader didUpdateWidget');

    // 날짜가 변경되었을 때
    if (widget.selectedDate != oldWidget.selectedDate) {
      logger.debug(
        '날짜 변경됨: ${oldWidget.selectedDate} -> ${widget.selectedDate}',
      );

      setState(() {
        _previousDate = oldWidget.selectedDate;
        _isAnimatingDateForward = widget.selectedDate.isAfter(
          oldWidget.selectedDate,
        );
        _isChangingDate = true;
      });

      // 날짜 변경 후 0.3초 뒤에 애니메이션 상태 초기화
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isChangingDate = false;
          });
        }
      });
    }

    // 습관 완료 상태나 완료율이 변경되었을 때
    if (oldWidget.habits.where((h) => h.isCompleted).length !=
        widget.habits.where((h) => h.isCompleted).length) {
      logger.debug('완료 상태 변경됨');

      _updateProgressAnimation();
      _progressController.forward(from: 0);
    }
  }

  /// 진행률 애니메이션 업데이트
  void _updateProgressAnimation() {
    double completionRate = _calculateCompletionRate();
    logger.debug('진행률 애니메이션 업데이트: $completionRate');

    _progressAnimation = Tween<double>(begin: 0.0, end: completionRate).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    logger.debug('HomeHeader dispose');
    _progressController.dispose();
    super.dispose();
  }

  /// 오늘 날짜인지 확인
  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('HomeHeader build');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // 날짜 선택기
          DateSelector(
            selectedDate: widget.selectedDate,
            previousDate: _previousDate,
            isAnimatingDateForward: _isAnimatingDateForward,
            isChangingDate: _isChangingDate,
            onPreviousDay: widget.onPreviousDay,
            onNextDay: widget.onNextDay,
            onSelectDate: widget.onSelectDate,
            onTodayPressed: widget.onGoToToday,
            isToday: _isToday,
          ),

          const SizedBox(height: 20),

          // 원형 프로그레스와 주간 진행률
          Row(
            children: [
              // 원형 프로그레스
              ProgressCircle(
                progressAnimation: _progressAnimation,
                completedHabits:
                    widget.habits.where((h) => h.isCompleted).length,
                totalHabits: widget.habits.length,
              ),

              const SizedBox(width: 20),

              // 오른쪽: 텍스트 정보 및 주간 프로그레스
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 오늘 진행률
                    Row(
                      children: [
                        Text(
                          _isToday ? '오늘 진행률' : '진행률',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        // 진행률 수치 (애니메이션)
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Text(
                              '${(_progressAnimation.value * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 주간 평균
                    Row(
                      children: [
                        Text(
                          '이번 주 평균',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_calculateWeeklyAverage() * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 주간 프로그레스 바
                    WeeklyProgressBar(
                      weeklyProgress: widget.weeklyProgress,
                      selectedDate: widget.selectedDate,
                      progressController: _progressController,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 최고 스트릭 습관 카드
          if (widget.topHabit != null) TopHabitCard(habit: widget.topHabit!),
        ],
      ),
    );
  }

  /// 오늘의 완료율 계산
  double _calculateCompletionRate() {
    if (widget.habits.isEmpty) return 0.0;
    return widget.habits.where((h) => h.isCompleted).length /
        widget.habits.length;
  }

  /// 주간 평균 완료율 계산
  double _calculateWeeklyAverage() {
    if (widget.weeklyProgress.isEmpty) return 0.0;
    final total = widget.weeklyProgress.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    return total / widget.weeklyProgress.length;
  }
}
