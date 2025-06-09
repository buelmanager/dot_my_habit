// lib/presentation/common_widgets/view_selector.dart
import 'package:flutter/material.dart';

class ViewSelector extends StatelessWidget {
  final List<String> titles;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const ViewSelector({
    Key? key,
    required this.titles,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: List.generate(titles.length, (index) {
          return Row(
            children: [
              _buildTabItem(context, titles[index], index),
              // 마지막 아이템이 아니면 여백 추가
              if (index < titles.length - 1) const SizedBox(width: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : Colors.black45,
              ),
            ),
          ),
          // 선택된 탭 밑에 밑줄 표시
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: 30,
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }
}