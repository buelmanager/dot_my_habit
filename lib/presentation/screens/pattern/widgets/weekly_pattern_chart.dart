// lib/presentation/screens/pattern/widgets/weekly_pattern_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';

/// 주간 패턴 차트 위젯
class WeeklyPatternChart extends ConsumerWidget {
  const WeeklyPatternChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final weeklyProgress = viewModel.state.weeklyProgress;

    // 요일별 더미 데이터
    final List<double> weekdayValues = []; // 월, 화, 수, 목, 금, 토, 일

    // 실제 데이터 매핑 (weeklyProgress가 있을 경우)
    if (weeklyProgress.isNotEmpty) {
      // 요일 이름을 기준으로 정렬된 값 추출
      final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
      for (int i = 0; i < dayNames.length; i++) {
        if (weeklyProgress.containsKey(dayNames[i])) {
          weekdayValues[i] = weeklyProgress[dayNames[i]]!;
        }
      }
    }

    return Container(
      height: 220,
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
          // 차트 설명
          Text(
            '요일별 완료율',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 20),

          // 차트
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final barWidth =
                    (availableWidth - 20) / weekdayValues.length - 8;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(weekdayValues.length, (index) {
                    return _buildBar(
                      index: index,
                      value: weekdayValues[index],
                      barWidth: barWidth,
                      maxHeight: constraints.maxHeight - 45,
                    );
                  }),
                );
              },
            ),
          ),

          // 차트 설명
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getPatternMessage(weekdayValues),
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

  // 막대 위젯 빌드
  Widget _buildBar({
    required int index,
    required double value,
    required double barWidth,
    required double maxHeight,
  }) {
    final barHeight = maxHeight * value;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 값 표시
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        // 막대
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color:
                value > 0.7
                    ? Colors.black
                    : Colors.black.withOpacity(0.3 + value * 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 요일 레이블
        Text(
          dayNames[index],
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  //
  // // 막대 위젯 빌드
  // Widget _buildBar({
  //   required int index,
  //   required double value,
  //   required double barWidth,
  //   required double maxHeight,
  // }) {
  //   final barHeight = maxHeight * value;
  //   final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
  //
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       // 값 표시
  //       Text(
  //         '${(value * 100).toInt()}%',
  //         style: TextStyle(
  //           fontSize: 10,
  //           color: Colors.black.withOpacity(0.6),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //
  //       const SizedBox(height: 4),
  //
  //       // 막대
  //       Container(
  //         width: barWidth,
  //         height: barHeight,
  //         decoration: BoxDecoration(
  //           color: Colors.black,
  //           borderRadius: const BorderRadius.only(
  //             topLeft: Radius.circular(4),
  //             topRight: Radius.circular(4),
  //           ),
  //         ),
  //       ),
  //
  //       const SizedBox(height: 8),
  //
  //       // 요일 레이블
  //       Text(
  //         dayNames[index],
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: Colors.black.withOpacity(0.7),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // 패턴 분석 메시지 생성
  String _getPatternMessage(List<double> values) {
    // 평일 평균 (월~금)
    final weekdayAvg =
        (values[0] + values[1] + values[2] + values[3] + values[4]) / 5;

    // 주말 평균 (토~일)
    final weekendAvg = (values[5] + values[6]) / 2;

    if (weekdayAvg > weekendAvg + 0.2) {
      return '평일에 더 높은 완료율을 보이고 있습니다.';
    } else if (weekendAvg > weekdayAvg + 0.2) {
      return '주말에 더 높은 완료율을 보이고 있습니다.';
    } else {
      return '요일에 관계없이 일정한 완료율을 유지하고 있습니다.';
    }
  }
}
