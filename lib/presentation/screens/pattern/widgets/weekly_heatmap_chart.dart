// lib/presentation/screens/pattern/widgets/weekly_heatmap_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';

/// 주간 히트맵 차트 위젯
class WeeklyHeatmapChart extends ConsumerWidget {
  const WeeklyHeatmapChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final habits = viewModel.state.habits;
    final weeklyProgress = viewModel.state.weeklyProgress;

    // 요일별 완료율 계산
    List<double> dailyCompletionRates = List.filled(7, 0.0);

    // weeklyProgress 데이터에서 완료율 계산
    if (weeklyProgress.isNotEmpty) {
      final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
      for (int i = 0; i < dayNames.length; i++) {
        if (weeklyProgress.containsKey(dayNames[i])) {
          dailyCompletionRates[i] = weeklyProgress[dayNames[i]]!;
        }
      }
    }

    // 히트맵 색상 계산 함수
    Color getHeatmapColor(double value) {
      if (value <= 0) return Colors.black.withOpacity(0.03);
      if (value < 0.3) return Colors.black.withOpacity(0.1);
      if (value < 0.6) return Colors.black.withOpacity(0.3);
      if (value < 0.9) return Colors.black.withOpacity(0.6);
      return Colors.black.withOpacity(0.9);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            '주간 완료 패턴',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 15),

          // 히트맵
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final rate = dailyCompletionRates[index];
                final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

                return Column(
                  children: [
                    // 히트맵 셀
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: getHeatmapColor(rate),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${(rate * 100).toInt()}',
                          style: TextStyle(
                            color: rate > 0.5 ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 요일
                    Text(
                      dayNames[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // 완료율 그래프
          SizedBox(
            height: 70,
            child: CustomPaint(
              size: const Size.fromHeight(70),
              painter: LinechartPainter(dailyCompletionRates),
            ),
          ),

          // 패턴 설명
          if (dailyCompletionRates.any((rate) => rate > 0))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getPatternDescription(dailyCompletionRates),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 패턴 설명 생성
  String _getPatternDescription(List<double> rates) {
    // 평일 평균
    final weekdayAvg = (rates[0] + rates[1] + rates[2] + rates[3] + rates[4]) / 5;
    // 주말 평균
    final weekendAvg = (rates[5] + rates[6]) / 2;

    // 패턴 분석
    if (weekdayAvg > weekendAvg + 0.2) {
      return '평일에 습관을 더 잘 지키고 있습니다.';
    } else if (weekendAvg > weekdayAvg + 0.2) {
      return '주말에 습관을 더 잘 지키고 있습니다.';
    } else {
      return '요일에 관계없이 꾸준히 습관을 지키고 있습니다.';
    }
  }
}

/// 선 그래프 CustomPainter
class LinechartPainter extends CustomPainter {
  final List<double> dataPoints;

  LinechartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 라인 그리기 설정
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 채우기 설정
    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 점 설정
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 경로 생성
    final path = Path();
    final fillPath = Path();

    // 균등 간격 계산
    final segmentWidth = width / (dataPoints.length - 1);

    // 첫 지점 시작
    path.moveTo(0, height - (dataPoints[0] * height));
    fillPath.moveTo(0, height);
    fillPath.lineTo(0, height - (dataPoints[0] * height));

    // 데이터 포인트 연결
    for (int i = 1; i < dataPoints.length; i++) {
      final x = segmentWidth * i;
      final y = height - (dataPoints[i] * height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // 채우기 경로 닫기
    fillPath.lineTo(width, height);
    fillPath.close();

    // 그리기
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // 데이터 포인트에 점 그리기
    for (int i = 0; i < dataPoints.length; i++) {
      final x = segmentWidth * i;
      final y = height - (dataPoints[i] * height);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}