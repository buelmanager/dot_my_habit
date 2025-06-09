import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/logger.dart';

/// 원형 진행률 위젯
class ProgressCircle extends StatelessWidget {
  /// 진행률 애니메이션
  final Animation<double> progressAnimation;

  /// 완료된 습관 수
  final int completedHabits;

  /// 전체 습관 수
  final int totalHabits;

  /// 생성자
  const ProgressCircle({
    Key? key,
    required this.progressAnimation,
    required this.completedHabits,
    required this.totalHabits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.debug('ProgressCircle build, 완료: $completedHabits/$totalHabits');

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // 애니메이션 적용된 원형 프로그레스
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              final currentProgress = progressAnimation.value;
              //logger.debug('ProgressCircle 애니메이션 값: $currentProgress');

              return SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: ProgressCirclePainter(
                    progress: currentProgress,
                    progressColor: Colors.black,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    strokeWidth: 2.0,
                  ),
                ),
              );
            },
          ),

          // 중앙 텍스트 (애니메이션 적용)
          Center(
            child: AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                // 애니메이션을 위한 숫자 계산 (완료 개수 증가하는 효과)
                final animatedCompleted =
                    (completedHabits * progressAnimation.value).round();
                // logger.debug(
                //   'ProgressCircle 표시 완료 수: $animatedCompleted/$totalHabits',
                // );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$animatedCompleted/$totalHabits',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 원형 프로그레스 바 그리기 위한 CustomPainter
class ProgressCirclePainter extends CustomPainter {
  /// 진행률 (0.0 ~ 1.0)
  final double progress;

  /// 진행 색상
  final Color progressColor;

  /// 배경 색상
  final Color backgroundColor;

  /// 선 두께
  final double strokeWidth;

  /// 생성자
  ProgressCirclePainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // 배경 원 그리기
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행률 원호 그리기
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 12시 방향에서 시작
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
