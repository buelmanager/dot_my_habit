// lib/presentation/screens/pattern/widgets/time_of_day_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // 이 임포트가 있는지 확인하세요
import '../../../../app_providers.dart';

/// 시간대별 완료 패턴 차트 위젯
class TimeOfDayChart extends ConsumerWidget {
  const TimeOfDayChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(habitRepositoryProvider);
    final viewModel = ref.watch(homeViewModelProvider);
    final selectedDate = viewModel.state.selectedDate;

    // 실제 데이터를 가져오는 함수 호출
    final hourlyDataFuture = _fetchHourlyCompletionData(repository, selectedDate);

    return FutureBuilder<List<double>>(
        future: hourlyDataFuture,
        builder: (context, snapshot) {
          // 로딩 중이면 로딩 표시
          if (!snapshot.hasData) {
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
              height: 250,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            );
          }

          final hourlyData = snapshot.data!;

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
                const Text(
                  '시간대별 완료 패턴',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 15),

                // 차트
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: TimeOfDayChartPainter(hourlyData),
                  ),
                ),

                const SizedBox(height: 15),

                // 설명
                Text(
                  _getTimePatternDescription(hourlyData),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // 시간대별 완료 데이터 가져오기
  Future<List<double>> _fetchHourlyCompletionData(dynamic repository, DateTime selectedDate) async {
    // 결과 배열 (0-23시 각각의 완료율)
    List<double> hourlyData = List.filled(24, 0.0);

    // 시간대별 완료 횟수와 전체 습관 수
    List<int> completedCountByHour = List.filled(24, 0);
    List<int> totalCountByHour = List.filled(24, 0);

    // 지난 30일간의 데이터 분석
    final today = DateTime.now();
    for (int day = 0; day < 30; day++) {
      final date = today.subtract(Duration(days: day));

      // 해당 날짜의 습관 목록 조회
      final habits = await repository.getHabitsForDate(date);

      if (habits.isEmpty) continue;

      // 완료된 습관 찾기
      for (final habit in habits) {
        if (habit.completedAt != null && habit.isCompleted) {
          // 완료 시간 확인
          final hour = habit.completedAt!.hour;
          completedCountByHour[hour]++;
        }

        // 습관이 설정된 시간이 있다면 해당 시간대 카운트 증가
        if (habit.reminderTime != null) {
          final hour = habit.reminderTime!.hour;
          totalCountByHour[hour]++;
        } else {
          // 시간이 설정되지 않은 경우, 평균적으로 모든 시간대에 분배
          for (int h = 0; h < 24; h++) {
            totalCountByHour[h] += (1 / 24).toInt(); // 부분 카운트
          }
        }
      }
    }

    // 각 시간대별 완료율 계산
    for (int hour = 0; hour < 24; hour++) {
      if (totalCountByHour[hour] > 0) {
        hourlyData[hour] = completedCountByHour[hour] / totalCountByHour[hour];
        // 1.0을 넘지 않도록 제한
        hourlyData[hour] = hourlyData[hour] > 1.0 ? 1.0 : hourlyData[hour];
      }
    }

    return hourlyData;
  }

  // 시간 패턴 설명 생성
  String _getTimePatternDescription(List<double> hourlyData) {
    // 가장 활발한 시간대 찾기
    double maxRate = 0;
    int maxHour = 0;

    for (int i = 0; i < hourlyData.length; i++) {
      if (hourlyData[i] > maxRate) {
        maxRate = hourlyData[i];
        maxHour = i;
      }
    }

    // 데이터가 없는 경우
    if (maxRate == 0) {
      return '아직 충분한 완료 데이터가 수집되지 않았습니다.';
    }

    // 시간대에 따른 설명
    if (maxHour >= 5 && maxHour <= 9) {
      return '아침 시간대(${maxHour}시)에 습관을 가장 잘 완료하는 경향이 있습니다.';
    } else if (maxHour >= 10 && maxHour <= 16) {
      return '낮 시간대(${maxHour}시)에 습관을 가장 잘 완료하는 경향이 있습니다.';
    } else if (maxHour >= 17 && maxHour <= 21) {
      return '저녁 시간대(${maxHour}시)에 습관을 가장 잘 완료하는 경향이 있습니다.';
    } else {
      return '야간 시간대(${maxHour}시)에 습관을 가장 잘 완료하는 경향이 있습니다.';
    }
  }
}

/// 시간대별 차트 페인터
class TimeOfDayChartPainter extends CustomPainter {
  final List<double> hourlyData;

  TimeOfDayChartPainter(this.hourlyData);

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

    // 막대 그래프 그리기
    _drawBars(canvas, size);
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
      //textDirection: TextDirection.LTR,
    );

    for (int i = 0; i <= 5; i++) {
      final value = 20 * i;
      final y = height - (height * i / 5);

      textPainter.text = TextSpan(
        text: '$value%',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-5, y - textPainter.height / 2));
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
      //textDirection: TextDirection.LTR,
    );

    // 4시간 간격으로 레이블 표시
    for (int hour = 0; hour < 24; hour += 4) {
      final x = hour * width / 24 + (width / 48); // 중앙 정렬

      textPainter.text = TextSpan(
        text: '$hour',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, height + 5));
    }
  }

  // 막대 그래프 그리기
  void _drawBars(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final barWidth = width / hourlyData.length - 4;

    for (int i = 0; i < hourlyData.length; i++) {
      final value = hourlyData[i];
      final barHeight = value * height;
      final x = i * width / hourlyData.length + 2; // 간격 고려
      final y = height - barHeight;

      // 막대 그리기
      final barPaint = Paint()
        ..color = value > 0.5
            ? Colors.black
            : Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      // 상단 둥근 막대
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      );

      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}