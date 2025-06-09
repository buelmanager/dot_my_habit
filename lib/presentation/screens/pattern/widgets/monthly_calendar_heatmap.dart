// lib/presentation/screens/pattern/widgets/monthly_calendar_heatmap.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/logger.dart';

/// 월간 캘린더 히트맵 위젯
class MonthlyCalendarHeatmap extends ConsumerWidget {
  const MonthlyCalendarHeatmap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final selectedDate = viewModel.state.selectedDate;
    final repository = ref.read(habitRepositoryProvider);

    // 선택된 월의 일수 계산
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // 상태 변수 생성
    final monthlyRatesFuture = Future.wait(
        List.generate(daysInMonth, (index) async {
          final day = index + 1;
          final date = DateTime(selectedDate.year, selectedDate.month, day);
          final habits = await repository.getHabitsForDate(date);

          // 해당 날짜의 습관이 없으면 0 반환
          if (habits.isEmpty) return MapEntry(day, 0.0);

          // 완료된 습관 수 계산
          final completedCount = habits.where((h) => h.isCompleted).length;
          // 완료율 계산
          final completionRate = completedCount / habits.length;

          return MapEntry(day, completionRate);
        })
    ).then((entries) {
      final result = <int, double>{};
      for (var entry in entries) {
        result[entry.key] = entry.value;
      }
      return result;
    });

    // 요일명 헤더
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];

    // 첫 날 요일 계산 (0: 일요일, 6: 토요일)
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstDayOffset = firstDayOfMonth.weekday % 7;

    // 현재 날짜
    final today = DateTime.now();
    final isCurrentMonth = today.year == selectedDate.year && today.month == selectedDate.month;

    // 히트맵 색상 계산 함수
    Color getHeatmapColor(double value) {
      if (value <= 0) return Colors.transparent;
      if (value < 0.3) return Colors.black.withOpacity(0.1);
      if (value < 0.6) return Colors.black.withOpacity(0.3);
      if (value < 0.9) return Colors.black.withOpacity(0.6);
      return Colors.black.withOpacity(0.9);
    }

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
          Text(
            '${selectedDate.year}년 ${selectedDate.month}월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 15),

          // 요일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayNames.map((day) => SizedBox(
              width: 32,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 8),

          // 캘린더 그리드
          FutureBuilder<Map<int, double>>(
              future: monthlyRatesFuture,
              builder: (context, snapshot) {
                // 로딩 중이면 로딩 인디케이터 표시
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

                // 데이터 가져오기
                final monthlyRates = snapshot.data!;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: firstDayOffset + daysInMonth,
                  itemBuilder: (context, index) {
                    // 첫번째 주에서 이번 달 시작 전 빈 셀
                    if (index < firstDayOffset) {
                      return const SizedBox.shrink();
                    }

                    final day = index - firstDayOffset + 1;
                    final completionRate = monthlyRates[day] ?? 0.0;
                    final isToday = isCurrentMonth && day == today.day;

                    return Container(
                      decoration: BoxDecoration(
                        color: getHeatmapColor(completionRate),
                        borderRadius: BorderRadius.circular(4),
                        border: isToday
                            ? Border.all(color: Colors.black, width: 1.5)
                            : Border.all(color: Colors.black.withOpacity(0.1), width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: completionRate > 0.5
                                ? Colors.white
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
          ),

          const SizedBox(height: 15),

          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('0%', Colors.transparent),
              _buildLegendItem('25%', Colors.black.withOpacity(0.1)),
              _buildLegendItem('50%', Colors.black.withOpacity(0.3)),
              _buildLegendItem('75%', Colors.black.withOpacity(0.6)),
              _buildLegendItem('100%', Colors.black.withOpacity(0.9)),
            ],
          ),
        ],
      ),
    );
  }

  // 범례 아이템
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: color == Colors.transparent
                  ? Border.all(color: Colors.black26, width: 1)
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}