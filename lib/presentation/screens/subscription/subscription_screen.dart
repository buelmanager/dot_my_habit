// lib/presentation/screens/subscription/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../domain/models/subscription_model.dart';
import '../../../domain/models/subscription_plan.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'SubscriptionScreen';

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  String? _selectedPlanId;
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    // 기본 선택된 플랜 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recommendedPlan = SubscriptionPlan.popularPlan;
      if (recommendedPlan != null) {
        setState(() {
          _selectedPlanId = recommendedPlan.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RevenueCat 초기화 상태 리스닝 (build 메서드 내에서)
    ref.listen(revenueCatInitProvider, (previous, next) {
      next.when(
        data: (success) {
          if (success) {
            logger.info('RevenueCat 초기화 성공', tag: _tag);
          } else {
            logger.error('RevenueCat 초기화 실패', tag: _tag);
            _showErrorSnackBar('결제 시스템 초기화에 실패했습니다.');
          }
        },
        loading: () => logger.debug('RevenueCat 초기화 중...', tag: _tag),
        error: (error, stack) {
          logger.error('RevenueCat 초기화 오류: $error', tag: _tag);

          // API 키 오류인 경우 특별 처리
          if (error.toString().contains('Invalid API Key') ||
              error.toString().contains('INVALID_CREDENTIALS')) {
            _showErrorSnackBar('RevenueCat API 키가 설정되지 않았습니다.\n개발 모드로 전환합니다.');
            logger.warning('RevenueCat API 키 오류 - 로컬 모드로 전환', tag: _tag);
          } else {
            _showErrorSnackBar('결제 시스템 오류가 발생했습니다.');
          }
        },
      );
    });

    // 구독 정보 조회 (RevenueCat 실패 시 로컬 모드로 fallback)
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final plans = SubscriptionPlan.defaultPlans;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: subscriptionAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            ),
        error: (error, stackTrace) {
          logger.error('구독 정보 조회 오류: $error', tag: _tag);

          // API 키 오류인 경우 개발 모드로 fallback
          if (error.toString().contains('Invalid API Key') ||
              error.toString().contains('INVALID_CREDENTIALS')) {
            // 로컬 시뮬레이션 모드로 전환
            return _buildDevelopmentMode(context, plans);
          }

          return _buildErrorView(error);
        },
        data: (subscription) => _buildContent(context, subscription, plans),
      ),
    );
  }

  /// 개발 모드 화면 (RevenueCat 실패 시)
  Widget _buildDevelopmentMode(
    BuildContext context,
    List<SubscriptionPlan> plans,
  ) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // 개발 모드 안내
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '개발 모드',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RevenueCat API 키가 설정되지 않아 시뮬레이션 모드로 실행됩니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 가짜 구독 정보로 UI 표시
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeader(context, SubscriptionModel.defaultFree),
                      const SizedBox(height: 32),
                      _buildFeatureHighlights(),
                      const SizedBox(height: 32),
                      _buildSubscriptionPlans(plans),
                      const SizedBox(height: 32),
                      _buildFeatureComparison(),
                      const SizedBox(height: 32),
                      _buildDevelopmentActionButtons(),
                      const SizedBox(height: 24),
                      _buildFooterText(SubscriptionModel.defaultFree),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 개발 모드용 액션 버튼
  Widget _buildDevelopmentActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 시뮬레이션 체험 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simulateFreeTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '7일 무료 체험 시작 (시뮬레이션)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 12),

          // 시뮬레이션 구독 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isLoading || _selectedPlanId == null
                      ? null
                      : _simulatePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPlanId != null
                                ? '프리미엄 시작하기 (시뮬레이션)'
                                : '플랜을 선택해주세요',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: _restorePurchases,
            child: const Text(
              '복원',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '구독 정보를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(currentSubscriptionProvider);
                ref.invalidate(revenueCatInitProvider);
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SubscriptionModel subscription,
    List<SubscriptionPlan> plans,
  ) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(context, subscription),
                  const SizedBox(height: 32),
                  _buildFeatureHighlights(),
                  const SizedBox(height: 32),
                  _buildSubscriptionPlans(plans),
                  const SizedBox(height: 32),
                  _buildFeatureComparison(),
                  const SizedBox(height: 32),
                  _buildActionButtons(subscription),
                  const SizedBox(height: 24),
                  _buildFooterText(subscription),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, SubscriptionModel subscription) {
    final bool showTrialOffer =
        subscription.isFree && !subscription.isTrialUsed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 애니메이션 아이콘
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B46C1), // Purple-600
                        Color(0xFF8B5CF6), // Purple-500
                        Color(0xFFA855F7), // Purple-400
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 메인 타이틀
          Text(
            subscription.isPremium
                ? '프리미엄 구독 관리'
                : showTrialOffer
                ? '7일 무료로 시작하세요!'
                : '프리미엄으로 업그레이드',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // 서브타이틀
          Text(
            subscription.isPremium
                ? subscription.isTrial
                    ? '체험판 ${subscription.remainingDays}일 남음'
                    : '모든 프리미엄 기능을 사용하고 계세요'
                : showTrialOffer
                ? '모든 기능을 무료로 체험해보세요\n언제든 취소 가능합니다'
                : '더 강력한 습관 형성 도구를\n경험해보세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // 현재 구독 상태 배지
          if (subscription.isPremium) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      subscription.isTrial
                          ? [Colors.orange[400]!, Colors.orange[600]!]
                          : [Colors.green[400]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    subscription.isTrial ? Icons.schedule : Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subscription.isTrial
                        ? '체험판 ${subscription.remainingDays}일 남음'
                        : '프리미엄 활성화',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    final highlights = [
      {
        'icon': Icons.all_inclusive,
        'title': '무제한 습관',
        'description': '원하는 만큼 습관 추가',
        'color': Colors.blue,
      },
      {
        'icon': Icons.psychology,
        'title': 'AI 분석',
        'description': '개인화된 인사이트',
        'color': Colors.purple,
      },
      {
        'icon': Icons.trending_up,
        'title': '상세 리포트',
        'description': '진전 상황 추적',
        'color': Colors.green,
      },
      {
        'icon': Icons.backup,
        'title': '데이터 백업',
        'description': '안전한 데이터 보관',
        'color': Colors.orange,
      },
    ];

    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: (highlights.length / 2).ceil(),
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * 2;
          final endIndex = (startIndex + 2).clamp(0, highlights.length);
          final pageHighlights = highlights.sublist(startIndex, endIndex);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children:
                  pageHighlights.map((highlight) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (highlight['color'] as Color).withOpacity(
                                0.1,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              highlight['icon'] as IconData,
                              color: highlight['color'] as Color,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              highlight['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              highlight['description'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionPlans(List<SubscriptionPlan> plans) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '구독 플랜 선택',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPlanCard(plan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlanId == plan.id;
    final bool isRecommended = plan.isPopular || plan.isRecommended;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = plan.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            // 추천 배지
            if (isRecommended)
              Positioned(
                top: -1,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.badge ?? '인기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // 메인 콘텐츠
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecommended) const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? Colors.purple[700]
                                        : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              plan.durationText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (plan.originalPrice != null) ...[
                            Text(
                              plan.formattedOriginalPrice,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            plan.formattedPrice,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected
                                      ? Colors.purple[700]
                                      : Colors.black,
                            ),
                          ),
                          if (plan.durationMonths > 1)
                            Text(
                              plan.formattedMonthlyPrice,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.purple : Colors.grey[400]!,
                            width: 2,
                          ),
                          color:
                              isSelected ? Colors.purple : Colors.transparent,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      ),
                    ],
                  ),

                  // 할인 정보
                  if (plan.discountText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plan.discountText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (plan.formattedSavings.isNotEmpty) ...[
                            const Text(' • ', style: TextStyle(fontSize: 12)),
                            Text(
                              plan.formattedSavings,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    final comparisonData = SubscriptionPlan.getComparisonData();
    // 타입 캐스팅 수정: List<dynamic>을 안전하게 List<Map<String, dynamic>>로 변환
    final features =
        (comparisonData['features'] as List<dynamic>?)
            ?.map((item) => item as Map<String, dynamic>)
            .toList() ??
        <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    '기능 비교',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _buildComparisonHeader('무료', Colors.grey[600]!),
                  const SizedBox(width: 16),
                  _buildComparisonHeader('프리미엄', Colors.purple[700]!),
                ],
              ),
            ),
            const Divider(height: 1),
            ...features.map((feature) => _buildFeatureRow(feature)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader(String title, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatureRow(Map<String, dynamic> feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 80, child: _buildFeatureValue(feature['free'])),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: _buildFeatureValue(feature['premium'], isPremium: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureValue(dynamic value, {bool isPremium = false}) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.cancel,
        color:
            value
                ? (isPremium ? Colors.purple[600] : Colors.green[600])
                : Colors.grey[400],
        size: 20,
      );
    }

    return Text(
      value.toString(),
      style: TextStyle(
        fontSize: 12,
        color: isPremium ? Colors.purple[700] : Colors.grey[600],
        fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(SubscriptionModel subscription) {
    if (subscription.isPremium) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _showManageSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '구독 관리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!subscription.isTrialUsed) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startFreeTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '7일 무료 체험 시작',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isLoading || _selectedPlanId == null
                      ? null
                      : _purchaseSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPlanId != null
                                ? '프리미엄 시작하기'
                                : '플랜을 선택해주세요',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterText(SubscriptionModel subscription) {
    if (subscription.isPremium) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            '• 언제든지 취소 가능합니다\n• 구독은 자동으로 갱신됩니다\n• 결제는 Apple App Store를 통해 이루어집니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showTermsAndConditions(),
                child: const Text('이용약관', style: TextStyle(fontSize: 12)),
              ),
              Text(' • ', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () => _showPrivacyPolicy(),
                child: const Text('개인정보처리방침', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 이벤트 핸들러들
  // =========================================================================

  /// 무료 체험 시작
  Future<void> _startFreeTrial() async {
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(startFreeTrialProvider.future);

      if (success) {
        if (mounted) {
          _showSuccessDialog('7일 무료 체험 시작!', '모든 프리미엄 기능을 7일간 무료로 사용해보세요.');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('무료 체험 시작에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('무료 체험 시작 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 구독 구매 (RevenueCat)
  Future<void> _purchaseSubscription() async {
    if (_selectedPlanId == null) {
      _showErrorSnackBar('구독 플랜을 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(
        purchaseSubscriptionProvider(_selectedPlanId!).future,
      );

      if (success) {
        if (mounted) {
          _showSuccessDialog('구독 완료!', '프리미엄 구독이 활성화되었습니다.');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('구매에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('구독 구매 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('구매 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 시뮬레이션 무료 체험
  Future<void> _simulateFreeTrial() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog('시뮬레이션: 7일 무료 체험!', '개발 모드에서 무료 체험을 시뮬레이션했습니다.');
    }
  }

  /// 시뮬레이션 구매
  Future<void> _simulatePurchase() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog('시뮬레이션: 구독 완료!', '개발 모드에서 구독을 시뮬레이션했습니다.');
    }
  }

  /// 구매 복원
  Future<void> _restorePurchases() async {
    try {
      final success = await ref.read(restorePurchasesProvider.future);

      if (success) {
        if (mounted) {
          _showSuccessSnackBar('구독이 복원되었습니다.');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('복원할 구독이 없습니다.');
        }
      }
    } catch (e) {
      logger.error('구매 복원 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('복원에 실패했습니다.');
      }
    }
  }

  void _showManageSubscription() {
    _showErrorSnackBar('구독 관리 기능은 준비 중입니다.');
  }

  void _showTermsAndConditions() {
    _showErrorSnackBar('이용약관 화면은 준비 중입니다.');
  }

  void _showPrivacyPolicy() {
    _showErrorSnackBar('개인정보처리방침 화면은 준비 중입니다.');
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
