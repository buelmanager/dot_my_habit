import 'package:flutter/material.dart';

import '../../../core/logger.dart';
import '../../../data/models/habit.dart';

/// 가장 높은 스트릭을 가진 습관 카드 위젯
class TopHabitCard extends StatelessWidget {
  /// 습관 정보
  final Habit habit;

  /// 생성자
  const TopHabitCard({Key? key, required this.habit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.debug('TopHabitCard build, 습관: ${habit.name}, 스트릭: ${habit.streak}');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 아이콘 (펄스 애니메이션 추가)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 14),
              ),
            ),

            const SizedBox(width: 12),

            // 습관 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 주 가장 잘 지킨 습관',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 스트릭 표시 (숫자 카운팅 애니메이션)
            if (habit.streak > 0)
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: habit.streak),
                duration: const Duration(milliseconds: 1200),
                builder: (context, value, child) {
                  //logger.debug('TopHabitCard 스트릭 애니메이션 값: $value');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${value}일',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
