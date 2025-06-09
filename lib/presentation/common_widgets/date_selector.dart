import 'package:flutter/material.dart';

import '../../../core/logger.dart';

/// 날짜 선택 위젯
class DateSelector extends StatelessWidget {
  /// 선택된 날짜
  final DateTime selectedDate;

  /// 이전 날짜 (애니메이션용)
  final DateTime? previousDate;

  /// 날짜를 앞으로 진행중인지 (애니메이션용)
  final bool isAnimatingDateForward;

  /// 날짜 변경 중인지 (애니메이션용)
  final bool isChangingDate;

  /// 이전 날로 이동하는 콜백
  final VoidCallback onPreviousDay;

  /// 다음 날로 이동하는 콜백
  final VoidCallback onNextDay;

  /// 날짜 선택 콜백
  final VoidCallback onSelectDate;

  /// 오늘로 이동하는 콜백
  final VoidCallback onTodayPressed;

  /// 오늘 날짜인지 여부
  final bool isToday;

  /// 생성자
  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.previousDate,
    required this.isAnimatingDateForward,
    required this.isChangingDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onSelectDate,
    required this.onTodayPressed,
    required this.isToday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.debug('DateSelector build, 선택된 날짜: $selectedDate');

    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = selectedDate.weekday;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 날짜 표시 (슬라이드 애니메이션)
            if (isChangingDate)
              // 날짜 전환 애니메이션
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  logger.debug(
                    '날짜 전환 애니메이션: ${isAnimatingDateForward ? '앞으로' : '뒤로'}',
                  );
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(isAnimatingDateForward ? 1.0 : -1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 (${dayNames[weekday - 1]})',
                  key: ValueKey<DateTime>(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  logger.debug('날짜 선택 탭');
                  onSelectDate();
                },
                child: Text(
                  '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 (${dayNames[weekday - 1]})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // 이전/다음 버튼
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    logger.debug('이전 날짜 버튼 클릭');
                    onPreviousDay();
                  },
                ),
                const SizedBox(width: 5),
                // 오늘로 이동하는 버튼
                //if (!isToday)
                Opacity(
                  opacity: isToday ? 0 : 1,
                  child: GestureDetector(
                    onTap: !isToday ? onTodayPressed : null,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '오늘',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    logger.debug('다음 날짜 버튼 클릭');
                    onNextDay();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
