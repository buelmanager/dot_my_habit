import 'package:flutter/material.dart';

import '../../../core/logger.dart';
import '../../../data/models/habit.dart';

/// 향상된 습관 아이템 위젯
class EnhancedHabitItem extends StatefulWidget {
  /// 습관 정보
  final Habit habit;

  /// 습관 토글 콜백
  final Function(Habit) onToggle;

  /// 애니메이션 지연 시간 (초)
  final double animationDelay;

  /// 생성자
  const EnhancedHabitItem({
    Key? key,
    required this.habit,
    required this.onToggle,
    this.animationDelay = 0.0,
  }) : super(key: key);

  @override
  State<EnhancedHabitItem> createState() => _EnhancedHabitItemState();
}

class _EnhancedHabitItemState extends State<EnhancedHabitItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    logger.debug('EnhancedHabitItem initState: ${widget.habit.name}');

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // 약간의 딜레이 후 시작
    Future.delayed(
      Duration(milliseconds: (widget.animationDelay * 1000).toInt()),
      () {
        if (mounted) {
          logger.debug('EnhancedHabitItem 애니메이션 시작: ${widget.habit.name}');
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    logger.debug('EnhancedHabitItem dispose: ${widget.habit.name}');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.debug(
      'EnhancedHabitItem build: ${widget.habit.name}, 완료: ${widget.habit.isCompleted}',
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: _buildHabitItem(),
    );
  }

  Widget _buildHabitItem() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          splashColor: Colors.transparent, // 스플래시 효과 제거
          highlightColor: Colors.transparent, // 하이라이트 효과 제거
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            logger.debug('EnhancedHabitItem 탭됨: ${widget.habit.name}');
            widget.onToggle(widget.habit);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // 왼쪽 영역: 점
                _buildDot(),

                const SizedBox(width: 16),

                // 중앙 영역: 습관 이름 및 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              widget.habit.isCompleted
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.7),
                        ),
                      ),
                      if (widget.habit.streak > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildStreakIndicator(),
                        ),
                    ],
                  ),
                ),

                // 오른쪽 영역: 시간 (있는 경우)
                if (widget.habit.completedAt != null) _buildTimeIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 점 위젯 - 토글 애니메이션 없이 즉시 변경
  Widget _buildDot() {
    final baseSize = widget.habit.isEmphasized ? 24.0 : 20.0;

    return Container(
      width: baseSize,
      height: baseSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.habit.isCompleted ? Colors.black : Colors.transparent,
        border: Border.all(
          color: Colors.black,
          width: widget.habit.isEmphasized ? 2.0 : 1.5,
        ),
      ),
      child:
          widget.habit.isCompleted
              ? Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: baseSize * 0.6,
                ),
              )
              : null,
    );
  }

  /// 연속 달성 표시
  Widget _buildStreakIndicator() {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          color: Colors.orange.shade300,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.habit.streak}일째',
          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
        ),
      ],
    );
  }

  /// 완료 시간 표시
  Widget _buildTimeIndicator() {
    final completedAt = widget.habit.completedAt;
    if (completedAt == null) return const SizedBox.shrink();

    final hour = completedAt.hour.toString().padLeft(2, '0');
    final minute = completedAt.minute.toString().padLeft(2, '0');

    return Text(
      '$hour:$minute',
      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
    );
  }
}
