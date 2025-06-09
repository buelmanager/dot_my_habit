// lib/presentation/screens/pattern/widgets/longest_streak_card.dart
import 'package:flutter/material.dart';
import '../../../../data/models/habit.dart';

/// 최장 스트릭 카드 위젯
class LongestStreakCard extends StatelessWidget {
  /// 습관 정보
  final Habit habit;

  /// 생성자
  const LongestStreakCard({
    Key? key,
    required this.habit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            '최장 연속 달성',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 15),

          // 습관 이름
          Text(
            habit.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          // 스트릭 값
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 24,
                color: Colors.orange.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                '${habit.streak}일 연속',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 칭찬 메시지
          const Text(
            '정말 대단해요! 계속 유지해보세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}