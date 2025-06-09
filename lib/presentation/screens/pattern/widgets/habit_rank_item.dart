// lib/presentation/screens/pattern/widgets/habit_rank_item.dart
import 'package:flutter/material.dart';

import '../../../../data/models/habit.dart';

/// 습관 랭킹 아이템 위젯
class HabitRankItem extends StatelessWidget {
  /// 습관 정보
  final Habit habit;

  /// 랭킹 (1위, 2위, 3위 등)
  final int rank;

  /// 완료율 (0.0 ~ 1.0)
  final double completionRate;

  /// 생성자
  const HabitRankItem({
    Key? key,
    required this.habit,
    required this.rank,
    required this.completionRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 랭크에 따른 배지 색상
    Color getBadgeColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFF353535); // 1등 - 진한 검정
        case 2:
          return const Color(0xFF545454); // 2등 - 중간 검정
        case 3:
          return const Color(0xFF757575); // 3등 - 연한 검정
        default:
          return Colors.black.withOpacity(0.5);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // 랭킹 배지
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: getBadgeColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 습관 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.orange.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streak}일 연속',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 완료율
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(completionRate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '완료율',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}