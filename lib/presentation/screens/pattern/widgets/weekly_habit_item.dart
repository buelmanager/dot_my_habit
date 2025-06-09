// lib/presentation/screens/pattern/widgets/weekly_habit_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/habit.dart';

/// 주간 습관 아이템 위젯
class WeeklyHabitItem extends StatelessWidget {
  /// 습관 정보
  final Habit habit;

  /// 요일별 완료 데이터 맵 - 날짜(yyyy-MM-dd)별 완료 여부
  final Map<String, bool> completionData;

  /// 표시할 주의 시작일(월요일)
  final DateTime weekStart;

  /// 생성자
  const WeeklyHabitItem({
    Key? key,
    required this.habit,
    required this.completionData,
    required this.weekStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 표시할 7일간의 날짜 생성 (월~일)
    final weekDates = List.generate(
        7,
            (index) => weekStart.add(Duration(days: index))
    );

    // 완료율 계산
    int completedCount = 0;
    final dateFormat = DateFormat('yyyy-MM-dd');

    List<bool> completedDays = weekDates.map((date) {
      // 날짜 형식 변환
      final dateStr = dateFormat.format(date);
      // 해당 날짜에 완료 데이터가 있으면 그 값 사용, 없으면 false
      final isCompleted = completionData[dateStr] ?? false;
      if (isCompleted) completedCount++;
      return isCompleted;
    }).toList();

    // 완료율 계산
    final completionRate = weekDates.length > 0 ? completedCount / weekDates.length : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // 습관 이름
          Row(
            children: [
              Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // 완료율
              Text(
                '${(completionRate * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: completionRate > 0.7
                      ? Colors.black
                      : Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 요일별 완료 점
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekDates[index];
              final isCompleted = completedDays[index];

              // 오늘인지 확인
              final isToday = _isSameDay(date, DateTime.now());

              return Column(
                children: [
                  // 완료 표시 점
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.black : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? (isCompleted ? Colors.black : Colors.black54)
                            : (isCompleted ? Colors.black : Colors.black26),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                        : null,
                  ),

                  const SizedBox(height: 5),

                  // 요일
                  Text(
                    _getDayName(index),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? Colors.black
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // 요일 이름 반환
  String _getDayName(int index) {
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    if (index >= 0 && index < dayNames.length) {
      return dayNames[index];
    }
    return '';
  }

  // 같은 날짜인지 확인
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}