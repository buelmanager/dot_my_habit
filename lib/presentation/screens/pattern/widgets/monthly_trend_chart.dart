// lib/presentation/screens/pattern/widgets/monthly_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';

/// 월간 추세 차트 위젯
class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final selectedDate = viewModel.state.selectedDate;
    final repository = ref.read(habitRepositoryProvider);

    // 선택된 월의 일수 계산
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '월간 완료율 추이',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '7일 이동평균',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 차트
          FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMonthlyData(selectedDate, daysInMonth, repository),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                final monthlyData = snapshot.data!;

                // 이동 평균선 계산
                final List<Map<String, dynamic>> movingAverageData = [];
                for (int i = 0; i < monthlyData.length; i++) {
                  if (i < 6) continue; // 7일 이동 평균이므로 7일 이후부터 계산

                  double sum = 0;
                  for (int j = i - 6; j <= i; j++) {
                    sum += monthlyData[j]['value'];
                  }

                  movingAverageData.add({
                    'day': monthlyData[i]['day'],
                    'value': sum / 7,
                  });
                }

                return SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: MonthlyTrendPainter(
                      dailyData: monthlyData,
                      movingAverageData: movingAverageData,
                      daysInMonth: daysInMonth,
                    ),
                  ),
                );
              }
          ),

          // 트렌드 설명
          FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMonthlyData(selectedDate, daysInMonth, repository),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 10);
                }

                final monthlyData = snapshot.data!;

                // 이동 평균선 계산
                final List<Map<String, dynamic>> movingAverageData = [];
                for (int i = 0; i < monthlyData.length; i++) {
                  if (i < 6) continue; // 7일 이동 평균이므로 7일 이후부터 계산

                  double sum = 0;
                  for (int j = i - 6; j <= i; j++) {
                    sum += monthlyData[j]['value'];
                  }

                  movingAverageData.add({
                    'day': monthlyData[i]['day'],
                    'value': sum / 7,
                  });
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _getTrendDescription(movingAverageData),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                );
              }
          ),
        ],
      ),
    );
  }

  // 월간 데이터 가져오기
  Future<List<Map<String, dynamic>>> _fetchMonthlyData(
      DateTime selectedDate,
      int daysInMonth,
      dynamic repository
      ) async {
    final result = <Map<String, dynamic>>[];

    for (int day = 1; day <= daysInMonth; day++) {
      // 해당 날짜 생성
      final date = DateTime(selectedDate.year, selectedDate.month, day);

      // 현재 날짜 이후면 중단
      final now = DateTime.now();
      if (date.isAfter(now)) {
        break;
      }

      // 해당 날짜의 습관 목록 조회
      final habits = await repository.getHabitsForDate(date);

      // 완료율 계산
      final double completionRate = habits.isEmpty
          ? 0.0
          : habits.where((h) => h.isCompleted).length / habits.length;

      result.add({
        'day': day,
        'value': completionRate
      });
    }

    return result;
  }

  // 트렌드 설명 생성
  String _getTrendDescription(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '데이터가 충분하지 않습니다.';

    // 첫 주와 마지막 주 비교
    final firstWeekAvgPoints = data.take(7).length;
    final lastWeekAvgPoints = data.skip(data.length - 7).take(7).length;

    if (firstWeekAvgPoints < 3 || lastWeekAvgPoints < 3) {
      return '월간 추세를 확인하기에 데이터가 충분하지 않습니다.';
    }

    final firstWeekAvg = data.take(7).map((d) => d['value'] as double).reduce((a, b) => a + b) / firstWeekAvgPoints;
    final lastWeekAvg = data.skip(data.length - 7).take(7).map((d) => d['value'] as double).reduce((a, b) => a + b) / lastWeekAvgPoints;

    final difference = lastWeekAvg - firstWeekAvg;

    if (difference > 0.1) {
      return '이번 달은 꾸준히 향상되는 추세를 보이고 있습니다.';
    } else if (difference < -0.1) {
      return '이번 달 후반부에 습관 유지가 다소 어려웠던 것 같습니다.';
    } else {
      return '이번 달은 전반적으로 일정한 패턴을 유지하고 있습니다.';
    }
  }
}

/// 월간 추세 차트 페인터
class MonthlyTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> dailyData;
  final List<Map<String, dynamic>> movingAverageData;
  final int daysInMonth;

  MonthlyTrendPainter({
    required this.dailyData,
    required this.movingAverageData,
    required this.daysInMonth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 격자 그리기
    _drawGrid(canvas, size);

    // Y축 레이블 그리기
    _drawYLabels(canvas, size);

    // X축 레이블 그리기
    _drawXLabels(canvas, size);

    // 일별 데이터 선 그리기 (옅은 선)
    _drawDailyLine(canvas, size);

    // 이동 평균선 그리기 (강조 선)
    _drawMovingAverageLine(canvas, size);
  }

  // 격자 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    // 수평선 (Y축 격자)
    for (int i = 0; i <= 5; i++) {
      final y = height - (height * i / 5);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
  }

  // Y축 레이블 그리기
  void _drawYLabels(Canvas canvas, Size size) {
    final height = size.height;
    final textStyle = TextStyle(
      color: Colors.black.withOpacity(0.6),
      fontSize: 10,
    );
    final textPainter = TextPainter(
      //textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 5; i++) {
      final value = 20 * i;
      final y = height - (height * i / 5);

      textPainter.text = TextSpan(
        text: '$value%',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width - 5, y - textPainter.height / 2));
    }
  }

  // X축 레이블 그리기
  void _drawXLabels(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final textStyle = TextStyle(
      color: Colors.black.withOpacity(0.6),
      fontSize: 10,
    );
    final textPainter = TextPainter(
      //textDirection: TextDirection.ltr,
    );

    // 5일 간격으로 X축 레이블 표시
    for (int day = 5; day <= daysInMonth; day += 5) {
      final x = (day - 1) * width / (daysInMonth - 1);

      textPainter.text = TextSpan(
        text: day.toString(),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, height + 5));
    }
  }

  // 일별 데이터 선 그리기
  void _drawDailyLine(Canvas canvas, Size size) {
    if (dailyData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirst = true;

    for (final point in dailyData) {
      final x = (point['day'] - 1) * width / (daysInMonth - 1);
      final y = height - (point['value'] * height);

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  // 이동 평균선 그리기
  void _drawMovingAverageLine(Canvas canvas, Size size) {
    if (movingAverageData.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // 선 색상 및 설정
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 영역 채우기 색상
    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // 선 그리기 위한 경로
    final path = Path();

    // 영역 채우기 위한 경로
    final fillPath = Path();

    // 첫 점 이동
    final firstPoint = movingAverageData.first;
    final firstX = (firstPoint['day'] - 1) * width / (daysInMonth - 1);
    final firstY = height - (firstPoint['value'] * height);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, height);
    fillPath.lineTo(firstX, firstY);

    // 나머지 점들 연결
    for (final point in movingAverageData.skip(1)) {
      final x = (point['day'] - 1) * width / (daysInMonth - 1);
      final y = height - (point['value'] * height);

      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // 채우기 경로 닫기
    final lastPoint = movingAverageData.last;
    final lastX = (lastPoint['day'] - 1) * width / (daysInMonth - 1);

    fillPath.lineTo(lastX, height);
    fillPath.close();

    // 그리기
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // 데이터 포인트에 작은 점 그리기
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final point in movingAverageData) {
      final x = (point['day'] - 1) * width / (daysInMonth - 1);
      final y = height - (point['value'] * height);

      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}