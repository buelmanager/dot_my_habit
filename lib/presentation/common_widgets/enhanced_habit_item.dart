import 'package:flutter/material.dart';

import '../../../core/logger.dart';
import '../../../data/models/habit.dart';

/// 향상된 습관 아이템 위젯 (삭제/편집 기능 포함)
class EnhancedHabitItem extends StatefulWidget {
  /// 습관 정보
  final Habit habit;

  /// 습관 토글 콜백
  final Function(Habit) onToggle;

  /// 습관 삭제 콜백
  final Function(Habit)? onDelete;

  /// 습관 편집 콜백
  final Function(Habit)? onEdit;

  /// 애니메이션 지연 시간 (초)
  final double animationDelay;

  /// 생성자
  const EnhancedHabitItem({
    Key? key,
    required this.habit,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
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
        child: Row(
          children: [
            // 메인 터치 영역 (토글 기능)
            Expanded(
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
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
                      if (widget.habit.completedAt != null)
                        _buildTimeIndicator(),
                    ],
                  ),
                ),
              ),
            ),

            // 메뉴 버튼 (삭제/편집 기능이 있을 때만 표시)
            if (widget.onDelete != null || widget.onEdit != null)
              _buildMenuButton(),
          ],
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

  /// 메뉴 버튼
  Widget _buildMenuButton() {
    return Container(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showOptionsMenu,
          child: Icon(
            Icons.more_vert,
            size: 20,
            color: Colors.black.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  /// 옵션 메뉴 표시
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildOptionsMenu(),
    );
  }

  /// 옵션 메뉴 위젯
  Widget _buildOptionsMenu() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        widget.habit.isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.habit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 옵션들
          if (widget.onEdit != null)
            _buildMenuOption(
              icon: Icons.edit_outlined,
              title: '편집',
              onTap: () {
                Navigator.pop(context);
                widget.onEdit!(widget.habit);
              },
            ),

          if (widget.onDelete != null)
            _buildMenuOption(
              icon: Icons.delete_outline,
              title: '삭제',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),

          // 취소 버튼
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 메뉴 옵션 아이템
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : Colors.black.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 삭제 확인 대화상자
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '습관 삭제',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            content: Text(
              '"${widget.habit.name}" 습관을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 기록이 함께 삭제됩니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete!(widget.habit);
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
