// lib/presentation/screens/pattern/widgets/monthly_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

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
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              // 에러 로깅 추가
              if (snapshot.hasError) {
                developer.log(
                  'Monthly trend data error: ${snapshot.error}',
                  name: 'MonthlyTrendChart',
                );
                print('Monthly trend data error: ${snapshot.error}');
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error loading data: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                developer.log(
                  'Monthly trend data loading...',
                  name: 'MonthlyTrendChart',
                );
                print('Monthly trend data loading...');
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
              developer.log(
                'Monthly data loaded: ${monthlyData.length} points',
                name: 'MonthlyTrendChart',
              );
              print('Monthly data loaded: ${monthlyData.length} points');

              if (monthlyData.isEmpty) {
                developer.log(
                  'No monthly data available',
                  name: 'MonthlyTrendChart',
                );
                print('No monthly data available');
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      '이번 달에는 아직 데이터가 없습니다',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                );
              }

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

              developer.log(
                'Moving average data calculated: ${movingAverageData.length} points',
                name: 'MonthlyTrendChart',
              );
              print(
                'Moving average data calculated: ${movingAverageData.length} points',
              );

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
            },
          ),

          // 트렌드 설명
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchMonthlyData(selectedDate, daysInMonth, repository),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _getTrendDescription(movingAverageData),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 월간 데이터 가져오기
  Future<List<Map<String, dynamic>>> _fetchMonthlyData(
    DateTime selectedDate,
    int daysInMonth,
    dynamic repository,
  ) async {
    try {
      developer.log(
        'Fetching monthly data for ${selectedDate.year}-${selectedDate.month}',
        name: 'MonthlyTrendChart',
      );
      print(
        'Fetching monthly data for ${selectedDate.year}-${selectedDate.month}',
      );

      final result = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int day = 1; day <= daysInMonth; day++) {
        // 해당 날짜 생성
        final date = DateTime(selectedDate.year, selectedDate.month, day);

        // 현재 날짜 이후면 중단
        if (date.isAfter(now)) {
          developer.log(
            'Breaking at day $day (future date)',
            name: 'MonthlyTrendChart',
          );
          print('Breaking at day $day (future date)');
          break;
        }

        try {
          // 해당 날짜의 습관 목록 조회
          final habits = await repository.getHabitsForDate(date);

          developer.log(
            'Day $day: ${habits.length} habits found',
            name: 'MonthlyTrendChart',
          );

          // 완료율 계산
          double completionRate = 0.0;
          int completedCount = 0;

          if (habits.isNotEmpty) {
            // 타입 안전성을 위해 명시적으로 필터링
            for (final habit in habits) {
              if (habit.isCompleted) {
                completedCount++;
              }
            }
            completionRate = completedCount / habits.length;

            developer.log(
              'Day $day: $completedCount/${habits.length} completed (${(completionRate * 100).toInt()}%)',
              name: 'MonthlyTrendChart',
            );
            print(
              'Day $day: $completedCount/${habits.length} completed (${(completionRate * 100).toInt()}%)',
            );
          } else {
            developer.log(
              'Day $day: No habits found, rate = 0%',
              name: 'MonthlyTrendChart',
            );
          }

          result.add({
            'day': day,
            'value': completionRate,
            'date': DateFormat('yyyy-MM-dd').format(date),
            'totalHabits': habits.length,
            'completedHabits': completedCount,
          });
        } catch (e) {
          developer.log(
            'Error fetching data for day $day: $e',
            name: 'MonthlyTrendChart',
          );
          print('Error fetching data for day $day: $e');

          // 에러가 발생해도 0값으로 추가
          result.add({
            'day': day,
            'value': 0.0,
            'date': DateFormat('yyyy-MM-dd').format(date),
            'totalHabits': 0,
            'completedHabits': 0,
          });
        }
      }

      developer.log(
        'Monthly data fetch completed: ${result.length} days processed',
        name: 'MonthlyTrendChart',
      );
      print('Monthly data fetch completed: ${result.length} days processed');

      // 각 날짜별 상세 정보 로깅
      for (final item in result) {
        developer.log(
          'Day ${item['day']}: ${item['completedHabits']}/${item['totalHabits']} = ${(item['value'] * 100).toInt()}%',
          name: 'MonthlyTrendChart',
        );
      }

      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Error in _fetchMonthlyData: $e',
        name: 'MonthlyTrendChart',
      );
      print('Error in _fetchMonthlyData: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // 트렌드 설명 생성
  String _getTrendDescription(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '데이터가 충분하지 않습니다.';

    developer.log(
      'Generating trend description for ${data.length} data points',
      name: 'MonthlyTrendChart',
    );
    print('Generating trend description for ${data.length} data points');

    // 데이터 수가 적으면 간단한 설명 반환
    if (data.length < 7) {
      return ' * 추세 분석을 위해 더 많은 데이터가 필요합니다.';
    }

    // 첫 주와 마지막 주 비교 (안전한 인덱스 사용)
    final firstWeekSize = data.length >= 7 ? 7 : data.length;
    final lastWeekSize = data.length >= 7 ? 7 : data.length;
    final lastWeekStartIndex = data.length - lastWeekSize;

    if (lastWeekStartIndex < 0) {
      return ' * 추세 분석을 위해 더 많은 데이터가 필요합니다.';
    }

    final firstWeekData = data.take(firstWeekSize).toList();
    final lastWeekData =
        data.skip(lastWeekStartIndex).take(lastWeekSize).toList();

    if (firstWeekData.length < 3 || lastWeekData.length < 3) {
      developer.log(
        'Insufficient data for trend analysis: first week ${firstWeekData.length}, last week ${lastWeekData.length}',
        name: 'MonthlyTrendChart',
      );
      return '월간 추세를 확인하기에 데이터가 충분하지 않습니다.';
    }

    final firstWeekAvg =
        firstWeekData.map((d) => d['value'] as double).reduce((a, b) => a + b) /
        firstWeekData.length;
    final lastWeekAvg =
        lastWeekData.map((d) => d['value'] as double).reduce((a, b) => a + b) /
        lastWeekData.length;

    final difference = lastWeekAvg - firstWeekAvg;

    developer.log(
      'Trend analysis: first week avg ${(firstWeekAvg * 100).toInt()}%, last week avg ${(lastWeekAvg * 100).toInt()}%, difference ${(difference * 100).toInt()}%',
      name: 'MonthlyTrendChart',
    );
    print(
      'Trend analysis: first week avg ${(firstWeekAvg * 100).toInt()}%, last week avg ${(lastWeekAvg * 100).toInt()}%, difference ${(difference * 100).toInt()}%',
    );

    if (difference > 0.1) {
      return '이번 달은 꾸준히 향상되는 추세를 보이고 있습니다. (${(difference * 100).toInt()}%p 상승)';
    } else if (difference < -0.1) {
      return '이번 달 후반부에 습관 유지가 다소 어려웠던 것 같습니다. (${(difference * 100).abs().toInt()}%p 하락)';
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
    developer.log(
      'Painting monthly trend chart: ${dailyData.length} daily points, ${movingAverageData.length} moving avg points',
      name: 'MonthlyTrendPainter',
    );
    print(
      'Painting monthly trend chart: ${dailyData.length} daily points, ${movingAverageData.length} moving avg points',
    );

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
    final gridPaint =
        Paint()
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
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= 5; i++) {
      final value = 20 * i;
      final y = height - (height * i / 5);

      textPainter.text = TextSpan(text: '$value%', style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 5, y - textPainter.height / 2),
      );
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
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // 5일 간격으로 X축 레이블 표시
    for (int day = 5; day <= daysInMonth; day += 5) {
      final x = (day - 1) * width / (daysInMonth - 1);

      textPainter.text = TextSpan(text: day.toString(), style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, height + 5));
    }
  }

  // 일별 데이터 선 그리기
  void _drawDailyLine(Canvas canvas, Size size) {
    if (dailyData.isEmpty) {
      developer.log('No daily data to draw', name: 'MonthlyTrendPainter');
      return;
    }

    final width = size.width;
    final height = size.height;
    final linePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirst = true;

    for (final point in dailyData) {
      final day = point['day'] as int;
      final value = point['value'] as double;

      final x = (day - 1) * width / (daysInMonth - 1);
      final y = height - (value * height);

      // developer.log(
      //   'Daily point day $day: value $value, x $x, y $y',
      //   name: 'MonthlyTrendPainter',
      // );

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
    developer.log(
      'Daily line drawn with ${dailyData.length} points',
      name: 'MonthlyTrendPainter',
    );
  }

  // 이동 평균선 그리기
  void _drawMovingAverageLine(Canvas canvas, Size size) {
    if (movingAverageData.isEmpty) {
      developer.log(
        'No moving average data to draw',
        name: 'MonthlyTrendPainter',
      );
      return;
    }

    final width = size.width;
    final height = size.height;

    // 선 색상 및 설정
    final linePaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    // 영역 채우기 색상
    final fillPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..style = PaintingStyle.fill;

    // 선 그리기 위한 경로
    final path = Path();

    // 영역 채우기 위한 경로
    final fillPath = Path();

    // 첫 점 이동
    final firstPoint = movingAverageData.first;
    final firstDay = firstPoint['day'] as int;
    final firstValue = firstPoint['value'] as double;
    final firstX = (firstDay - 1) * width / (daysInMonth - 1);
    final firstY = height - (firstValue * height);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, height);
    fillPath.lineTo(firstX, firstY);

    developer.log(
      'Moving average first point day $firstDay: value $firstValue, x $firstX, y $firstY',
      name: 'MonthlyTrendPainter',
    );

    // 나머지 점들 연결
    for (final point in movingAverageData.skip(1)) {
      final day = point['day'] as int;
      final value = point['value'] as double;
      final x = (day - 1) * width / (daysInMonth - 1);
      final y = height - (value * height);

      path.lineTo(x, y);
      fillPath.lineTo(x, y);

      developer.log(
        'Moving average point day $day: value $value, x $x, y $y',
        name: 'MonthlyTrendPainter',
      );
    }

    // 채우기 경로 닫기
    final lastPoint = movingAverageData.last;
    final lastDay = lastPoint['day'] as int;
    final lastX = (lastDay - 1) * width / (daysInMonth - 1);

    fillPath.lineTo(lastX, height);
    fillPath.close();

    // 그리기
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // 데이터 포인트에 작은 점 그리기
    final dotPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    for (final point in movingAverageData) {
      final day = point['day'] as int;
      final value = point['value'] as double;
      final x = (day - 1) * width / (daysInMonth - 1);
      final y = height - (value * height);

      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }

    developer.log(
      'Moving average line drawn with ${movingAverageData.length} points',
      name: 'MonthlyTrendPainter',
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
