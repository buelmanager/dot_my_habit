import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/logger.dart';
import '../../../data/models/habit.dart';
import 'enhanced_habit_item.dart';

/// 향상된 일간 보기 위젯 (삭제 기능 포함)
class EnhancedDailyView extends StatefulWidget {
  /// 습관 목록
  final List<Habit> habits;

  /// 습관 토글 콜백
  final Function(Habit) onToggle;

  /// 습관 삭제 콜백
  final Function(Habit)? onDelete;

  /// 습관 편집 콜백
  final Function(Habit)? onEdit;

  /// 선택된 날짜
  final DateTime selectedDate;

  /// 생성자
  const EnhancedDailyView({
    Key? key,
    required this.habits,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<EnhancedDailyView> createState() => _EnhancedDailyViewState();
}

class _EnhancedDailyViewState extends State<EnhancedDailyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;

  /// 오늘의 완료율
  double get completionRate {
    if (widget.habits.isEmpty) return 0.0;
    final completedCount =
        widget.habits.where((habit) => habit.isCompleted).length;
    return completedCount / widget.habits.length;
  }

  /// 완료된 습관 수
  int get completedCount =>
      widget.habits.where((habit) => habit.isCompleted).length;

  @override
  void initState() {
    super.initState();
    logger.debug('EnhancedDailyView initState');

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scrollController = ScrollController();
    _controller.forward();
  }

  @override
  void dispose() {
    logger.debug('EnhancedDailyView dispose');
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedDailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    logger.debug('EnhancedDailyView didUpdateWidget');

    if (oldWidget.selectedDate != widget.selectedDate) {
      logger.debug('날짜 변경됨, 애니메이션 재시작');
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('EnhancedDailyView build, 습관 ${widget.habits.length}개');

    if (widget.habits.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: widget.habits.length + 1, // +1 for summary at bottom
      itemBuilder: (context, index) {
        // 마지막 아이템에 요약 정보 표시
        if (index == widget.habits.length) {
          return _buildSummary();
        }

        final habit = widget.habits[index];
        return EnhancedHabitItem(
          habit: habit,
          onToggle: widget.onToggle,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
          animationDelay: index * 0.15,
        );
      },
    );
  }

  /// 빈 상태 표시
  Widget _buildEmptyState() {
    logger.debug('빈 상태 표시');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    Tween<double>(begin: 0.8, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.0,
                              0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        )
                        .value,
                child: Opacity(
                  opacity:
                      Tween<double>(begin: 0.0, end: 1.0)
                          .animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.0,
                                0.5,
                                curve: Curves.easeOut,
                              ),
                            ),
                          )
                          .value,
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity:
                    Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.3,
                              0.8,
                              curve: Curves.easeOut,
                            ),
                          ),
                        )
                        .value,
                child: child,
              );
            },
            child: Text(
              '첫 번째 습관을 추가해보세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity:
                    Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.5,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        )
                        .value,
                child: child,
              );
            },
            child: Text(
              '하나의 점이 모여 선이 됩니다',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 요약 정보 위젯
  Widget _buildSummary() {
    logger.debug('요약 정보 표시, 완료율: ${(completionRate * 100).toInt()}%');

    final completedHabits =
        widget.habits.where((habit) => habit.isCompleted).length;
    final totalHabits = widget.habits.length;

    // 모든 습관을 완료한 경우에만 표시
    if (completedHabits < totalHabits) {
      return const SizedBox(height: 60);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0)
                    .animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                      ),
                    )
                    .value,
            child: child,
          );
        },
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  '모든 습관 완료!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
