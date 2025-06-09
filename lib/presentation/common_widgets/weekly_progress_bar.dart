import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../constants/app_colors.dart';
import '../../../core/logger.dart';

/// 주간 진행률 바 위젯
class WeeklyProgressBar extends StatelessWidget {
  /// 주간 진행률 데이터 (요일 -> 완료율)
  final Map<String, double> weeklyProgress;

  /// 선택된 날짜
  final DateTime selectedDate;

  /// 애니메이션 컨트롤러
  final AnimationController progressController;

  /// 생성자
  const WeeklyProgressBar({
    Key? key,
    required this.weeklyProgress,
    required this.selectedDate,
    required this.progressController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.debug('WeeklyProgressBar build, 데이터: $weeklyProgress');

    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(7, (index) {
          final day = dayNames[index];
          final progress = weeklyProgress[day] ?? 0.0;

          // 각 요일별 애니메이션 지연 시간 설정 (순차적 애니메이션)
          final delayFactor = index * 0.1;

          //logger.debug('$day 진행률: $progress');

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                children: [
                  // 요일
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          selectedDate.weekday == index + 1
                              ? Colors.black
                              : Colors.black.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 애니메이션 적용된 프로그레스 바
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barHeight = constraints.maxHeight;

                        return AnimatedBuilder(
                          animation: progressController,
                          builder: (context, child) {
                            // 애니메이션 딜레이를 위한 계산
                            final animationValue = progressController.value;
                            //progressController.value - delayFactor;
                            final currentProgress =
                                math.max(0.0, math.min(1.0, animationValue)) *
                                progress;

                            // logger.debug(
                            //   'day $day animationValue: $animationValue',
                            // );
                            // logger.debug(
                            //   'day $day currentProgress: $currentProgress',
                            // );

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: barHeight * currentProgress,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _getProgressColor(progress),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 완료율에 따른 색상 결정
  Color _getProgressColor(double progress) {
    return AppColors.getCompletionRateColor(progress);
  }
}
