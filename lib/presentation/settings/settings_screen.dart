// lib/presentation/screens/settings/settings_screen.dart (수정된 버전)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_providers.dart';
import '../../../core/logger.dart';
import '../../../data/services/subscription_service.dart';
import '../../../data/services/premium_service.dart';
import '../../../domain/models/subscription_model.dart';
import '../screens/subscription/subscription_screen.dart';
import '../widgets/premium_required_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _tag = 'SettingsScreen';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    logger.info('🏠 SettingsScreen 초기화', tag: _tag);
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('🔄 SettingsScreen build 호출', tag: _tag);

    final subscriptionAsync = ref.watch(currentSubscriptionProvider);

    // 구독 상태 로그
    subscriptionAsync.whenOrNull(
      data: (subscription) {
        logger.info(
          '📊 현재 구독 상태: ${subscription.type}, isPremium: ${subscription.isPremium}, isTrial: ${subscription.isTrial}',
          tag: _tag,
        );
      },
      error: (error, stack) {
        logger.error('❌ 구독 상태 조회 오류: $error', tag: _tag);
      },
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 헤더 부분
            _buildHeader(context),

            // 구독 상태 섹션
            subscriptionAsync.when(
              loading: () {
                logger.debug('🔄 구독 정보 로딩 중...', tag: _tag);
                return const SizedBox.shrink();
              },
              error: (error, stack) {
                logger.error('❌ 구독 정보 로딩 오류: $error', tag: _tag);
                return const SizedBox.shrink();
              },
              data: (subscription) {
                logger.debug('✅ 구독 정보 로딩 완료: ${subscription.type}', tag: _tag);
                return _buildSubscriptionSection(context, subscription);
              },
            ),

            // 개발자 테스트 섹션
            _buildDeveloperTestSection(context),

            // 설정 그룹: 앱 설정
            _buildSectionHeader(context, '앱 설정'),
            _buildSettingItem(
              context,
              icon: Icons.palette_outlined,
              title: '테마',
              subtitle: '기본 (흑백)',
              onTap: () {
                logger.debug('테마 설정 탭', tag: _tag);
                _showFeatureNotImplementedSnackBar();
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.notifications_none_outlined,
              title: '알림',
              subtitle: '사용',
              onTap: () {
                logger.debug('알림 설정 탭', tag: _tag);
                _showFeatureNotImplementedSnackBar();
              },
            ),

            // 설정 그룹: 데이터 (프리미엄 제한 적용)
            _buildSectionHeader(context, '데이터'),
            Consumer(
              builder: (context, ref, child) {
                logger.debug('🔍 데이터 백업 권한 확인 중...', tag: _tag);
                final dataBackupAsync = ref.watch(canUseDataBackupProvider);

                return dataBackupAsync.when(
                  loading: () {
                    logger.debug('⏳ 데이터 백업 권한 로딩 중...', tag: _tag);
                    return Column(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.file_download_outlined,
                          title: '데이터 내보내기',
                          subtitle: '권한 확인 중...',
                          isLoading: true,
                          onTap: null,
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.file_upload_outlined,
                          title: '데이터 가져오기',
                          subtitle: '권한 확인 중...',
                          isLoading: true,
                          onTap: null,
                        ),
                      ],
                    );
                  },
                  error: (error, stack) {
                    logger.error('❌ 데이터 백업 권한 확인 오류: $error', tag: _tag);
                    return Column(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.file_download_outlined,
                          title: '데이터 내보내기',
                          subtitle: '프리미엄 전용 기능',
                          isPremiumOnly: true,
                          onTap: () => _showPremiumRequiredDialog('데이터 내보내기'),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.file_upload_outlined,
                          title: '데이터 가져오기',
                          subtitle: '프리미엄 전용 기능',
                          isPremiumOnly: true,
                          onTap: () => _showPremiumRequiredDialog('데이터 가져오기'),
                        ),
                      ],
                    );
                  },
                  data: (canUseBackup) {
                    logger.info('✅ 데이터 백업 권한 확인 완료: $canUseBackup', tag: _tag);
                    return Column(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.file_download_outlined,
                          title: '데이터 내보내기',
                          subtitle:
                              canUseBackup ? '모든 습관 데이터 백업' : '프리미엄 전용 기능',
                          isLoading: _isProcessing,
                          isPremiumOnly: !canUseBackup,
                          onTap:
                              canUseBackup
                                  ? (_isProcessing ? null : _backupData)
                                  : () =>
                                      _showPremiumRequiredDialog('데이터 내보내기'),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.file_upload_outlined,
                          title: '데이터 가져오기',
                          subtitle: canUseBackup ? '백업 데이터 복원' : '프리미엄 전용 기능',
                          isLoading: _isProcessing,
                          isPremiumOnly: !canUseBackup,
                          onTap:
                              canUseBackup
                                  ? (_isProcessing ? null : _importData)
                                  : () =>
                                      _showPremiumRequiredDialog('데이터 가져오기'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // 설정 그룹: 앱 정보
            _buildSectionHeader(context, '앱 정보'),
            _buildSettingItem(
              context,
              icon: Icons.info_outline,
              title: '버전 정보',
              subtitle: '1.0.0',
              onTap: () {
                logger.debug('버전 정보 탭', tag: _tag);
                _showAboutDialog(context);
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.help_outline,
              title: '도움말',
              subtitle: '앱 사용 가이드',
              onTap: () {
                logger.debug('도움말 탭', tag: _tag);
                _showFeatureNotImplementedSnackBar();
              },
              showDivider: false,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 헤더 위젯
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        children: [
          Text(
            '설정',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 구독 상태 섹션
  Widget _buildSubscriptionSection(
    BuildContext context,
    SubscriptionModel subscription,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: () => _navigateToSubscription(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient:
                subscription.isPremium
                    ? const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    subscription.isPremium
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    subscription.isPremium ? Icons.star : Icons.star_border,
                    color:
                        subscription.isPremium
                            ? Colors.white
                            : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.isPremium ? '프리미엄' : '무료 플랜',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                subscription.isPremium
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subscription.isPremium
                              ? subscription.isTrial
                                  ? '체험판 ${subscription.remainingDays}일 남음'
                                  : '모든 기능 사용 가능'
                              : '기본 기능만 사용 가능',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                subscription.isPremium
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color:
                        subscription.isPremium
                            ? Colors.white
                            : Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
              if (!subscription.isPremium) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToSubscription(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '프리미엄 업그레이드',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 개발자 테스트 섹션
  Widget _buildDeveloperTestSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  '개발자 테스트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '구독 기능을 시뮬레이션으로 테스트해보세요',
              style: TextStyle(fontSize: 14, color: Colors.blue[600]),
            ),
            const SizedBox(height: 16),

            // 시뮬레이션 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _simulateFreeTrial,
                    icon:
                        _isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('무료 체험'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _simulatePremium,
                    icon:
                        _isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.star, size: 18),
                    label: const Text('프리미엄'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _simulateExpired,
                    icon:
                        _isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.timer_off, size: 18),
                    label: const Text('만료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _resetToFree,
                    icon:
                        _isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.refresh, size: 18),
                    label: const Text('초기화'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 설정 섹션 헤더
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }

  // 설정 아이템
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showDivider = true,
    bool showBadge = false,
    bool isLoading = false,
    bool isPremiumOnly = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isPremiumOnly
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color:
                  isPremiumOnly
                      ? Colors.purple.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      isPremiumOnly
                          ? Colors.purple.withOpacity(0.8)
                          : Colors.black,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (isPremiumOnly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color:
                  isPremiumOnly
                      ? Colors.purple.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
            ),
          ),
          trailing:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : isPremiumOnly
                  ? Icon(
                    Icons.lock_outline,
                    color: Colors.purple.withOpacity(0.6),
                    size: 20,
                  )
                  : Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black.withOpacity(0.3),
                    size: 16,
                  ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 80,
            endIndent: 20,
            color: Colors.black.withOpacity(0.1),
          ),
      ],
    );
  }

  // =============================================================================
  // 이벤트 핸들러들
  // =============================================================================

  void _showPremiumRequiredDialog(String featureName) {
    PremiumRequiredDialog.show(context, featureName);

    // 또는 확장 메서드 사용
    // context.showPremiumRequiredDialog(featureName);
  }

  // 구독 화면으로 이동
  void _navigateToSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }

  // 시뮬레이션: 무료 체험 시작
  Future<void> _simulateFreeTrial() async {
    logger.info('🎭 무료 체험 시뮬레이션 시작', tag: _tag);
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      logger.debug('🔄 무료 체험 provider 호출 시작', tag: _tag);
      final success = await ref.read(startFreeTrialProvider.future);
      logger.info('📋 무료 체험 provider 결과: $success', tag: _tag);

      if (mounted) {
        if (success) {
          logger.info('✅ 무료 체험 시뮬레이션 성공 - UI 새로고침', tag: _tag);
          // 수동으로 provider 새로고침
          ref.invalidate(currentSubscriptionProvider);
          ref.invalidate(isPremiumUserProvider);
          ref.invalidate(canUseDataBackupProvider);

          _showSuccessSnackBar('🎉 무료 체험이 시작되었습니다! (시뮬레이션)');
        } else {
          logger.warning('⚠️ 무료 체험 시뮬레이션 실패', tag: _tag);
          _showErrorSnackBar('무료 체험 시작에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('❌ 무료 체험 시뮬레이션 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('시뮬레이션 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 시뮬레이션: 프리미엄 구독 활성화
  Future<void> _simulatePremium() async {
    logger.info('🎭 프리미엄 구독 시뮬레이션 시작', tag: _tag);
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      logger.debug('🔄 프리미엄 구독 provider 호출 시작', tag: _tag);
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.startSubscription(
        'premium_yearly',
      );
      logger.info('📋 프리미엄 구독 provider 결과: $success', tag: _tag);

      if (mounted) {
        if (success) {
          logger.info('✅ 프리미엄 구독 시뮬레이션 성공 - UI 새로고침', tag: _tag);
          // 수동으로 provider 새로고침
          ref.invalidate(currentSubscriptionProvider);
          ref.invalidate(isPremiumUserProvider);
          ref.invalidate(canUseDataBackupProvider);

          _showSuccessSnackBar('🌟 프리미엄 구독이 활성화되었습니다! (시뮬레이션)');
        } else {
          logger.warning('⚠️ 프리미엄 구독 시뮬레이션 실패', tag: _tag);
          _showErrorSnackBar('프리미엄 구독 활성화에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('❌ 프리미엄 구독 시뮬레이션 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('시뮬레이션 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 시뮬레이션: 만료된 구독
  Future<void> _simulateExpired() async {
    logger.info('🎭 만료된 구독 시뮬레이션 시작', tag: _tag);
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      logger.debug('🔄 구독 만료 provider 호출 시작', tag: _tag);
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.cancelSubscription();
      logger.info('📋 구독 만료 provider 결과: $success', tag: _tag);

      if (mounted) {
        if (success) {
          logger.info('✅ 만료된 구독 시뮬레이션 성공 - UI 새로고침', tag: _tag);
          // 수동으로 provider 새로고침
          ref.invalidate(currentSubscriptionProvider);
          ref.invalidate(isPremiumUserProvider);
          ref.invalidate(canUseDataBackupProvider);

          _showSuccessSnackBar('⏰ 구독이 만료되었습니다 (시뮬레이션)');
        } else {
          logger.warning('⚠️ 구독 만료 시뮬레이션 실패', tag: _tag);
          _showErrorSnackBar('구독 만료 시뮬레이션에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('❌ 만료된 구독 시뮬레이션 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('시뮬레이션 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 시뮬레이션: 무료 플랜으로 초기화
  Future<void> _resetToFree() async {
    logger.info('🎭 무료 플랜 초기화 시뮬레이션 시작', tag: _tag);
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      logger.debug('🔄 구독 초기화 시작', tag: _tag);
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.saveSubscription(
        SubscriptionModel.defaultFree,
      );
      logger.info('📋 구독 초기화 결과: $success', tag: _tag);

      if (mounted) {
        if (success) {
          logger.info('✅ 무료 플랜 초기화 성공 - UI 새로고침', tag: _tag);
          // provider 새로고침
          ref.invalidate(currentSubscriptionProvider);
          ref.invalidate(isPremiumUserProvider);
          ref.invalidate(canUseDataBackupProvider);

          _showSuccessSnackBar('🔄 무료 플랜으로 초기화되었습니다 (시뮬레이션)');
        } else {
          logger.warning('⚠️ 무료 플랜 초기화 실패', tag: _tag);
          _showErrorSnackBar('초기화에 실패했습니다.');
        }
      }
    } catch (e) {
      logger.error('❌ 무료 플랜 초기화 시뮬레이션 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('시뮬레이션 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 데이터 백업
  Future<void> _backupData() async {
    setState(() => _isProcessing = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.exportToJson();

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('데이터 백업이 완료되었습니다.');
      } else {
        _showErrorSnackBar('데이터 백업에 실패했습니다.');
      }
    } catch (e) {
      logger.error('데이터 백업 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('백업 중 오류 발생: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 데이터 가져오기
  Future<void> _importData() async {
    setState(() => _isProcessing = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.importFromJson();

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('데이터 가져오기가 완료되었습니다.');
      } else {
        _showErrorSnackBar('데이터 가져오기에 실패했습니다.');
      }
    } catch (e) {
      logger.error('데이터 가져오기 오류: $e', tag: _tag);
      if (mounted) {
        _showErrorSnackBar('가져오기 중 오류 발생: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 앱 정보 대화상자
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('점(Dot)'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('버전: 1.0.0'),
                SizedBox(height: 8),
                Text('하나의 점이 모여 선이 됩니다.'),
                SizedBox(height: 16),
                Text('© 2025 점(Dot) 개발팀'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // 성공 스낵바
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 오류 스낵바
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 미구현 기능 안내
  void _showFeatureNotImplementedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('해당 기능은 아직 구현되지 않았습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
