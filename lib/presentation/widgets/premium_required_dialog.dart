// lib/presentation/widgets/premium_required_dialog.dart
import 'package:flutter/material.dart';
import '../screens/subscription/subscription_screen.dart';

/// 프리미엄 전용 기능에 대한 다이얼로그를 표시하는 공용 위젯
class PremiumRequiredDialog {
  /// 프리미엄 필수 다이얼로그 표시
  ///
  /// [context] - BuildContext
  /// [featureName] - 사용하려는 기능 이름 (예: '데이터 내보내기')
  static void show(BuildContext context, String featureName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 32),
                ),

                const SizedBox(height: 20),

                // 제목
                const Text(
                  '프리미엄 전용 기능',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // 설명
                Text(
                  '$featureName은 프리미엄 구독자만 사용할 수 있는 기능입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // 혜택 목록
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.purple,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '프리미엄으로 이용 가능:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem('데이터 백업 및 복원'),
                      _buildBenefitItem('AI 인사이트 & 예측'),
                      _buildBenefitItem('상세 리포트 & 통계'),
                      _buildBenefitItem('무제한 습관 추가'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 버튼들
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 프리미엄 업그레이드 버튼
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          _navigateToSubscription(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '프리미엄 업그레이드',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 혜택 아이템 위젯
  static Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  /// 구독 화면으로 이동
  static void _navigateToSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }
}

/// 확장 메서드로 더 간편하게 사용할 수 있도록 추가
extension PremiumRequiredDialogExtension on BuildContext {
  /// 프리미엄 필수 다이얼로그 표시
  void showPremiumRequiredDialog(String featureName) {
    PremiumRequiredDialog.show(this, featureName);
  }
}
