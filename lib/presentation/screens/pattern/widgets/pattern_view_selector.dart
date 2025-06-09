// lib/presentation/screens/pattern/widgets/pattern_view_selector.dart
import 'package:flutter/material.dart';

/// 패턴 분석 화면의 뷰 선택 위젯 (요약/주간/월간/분석)
class PatternViewSelector extends StatelessWidget {
  /// 탭 타이틀 목록
  final List<String> titles;

  /// 현재 선택된 인덱스
  final int selectedIndex;

  /// 탭 선택 콜백
  final Function(int) onTabSelected;

  /// 생성자
  const PatternViewSelector({
    Key? key,
    required this.titles,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(
          titles.length,
              (index) => Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selectedIndex == index
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                      : [],
                ),
                child: Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selectedIndex == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: selectedIndex == index
                        ? Colors.black
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}