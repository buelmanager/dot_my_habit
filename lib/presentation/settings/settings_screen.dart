// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/logger.dart';
import '../../app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 헤더 부분
            _buildHeader(context),

            // 설정 그룹: 앱 설정
            _buildSectionHeader(context, '앱 설정'),
            _buildSettingItem(
              context,
              icon: Icons.palette_outlined,
              title: '테마',
              subtitle: '기본 (흑백)',
              onTap: () {
                logger.debug('테마 설정 탭');
                // TODO: 테마 설정 화면으로 이동
                _showFeatureNotImplementedSnackBar();
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.notifications_none_outlined,
              title: '알림',
              subtitle: '사용',
              onTap: () {
                logger.debug('알림 설정 탭');
                // TODO: 알림 설정 화면으로 이동
                _showFeatureNotImplementedSnackBar();
              },
            ),

            // 설정 그룹: 데이터
            _buildSectionHeader(context, '데이터'),
            _buildSettingItem(
              context,
              icon: Icons.file_download_outlined,
              title: '데이터 내보내기',
              subtitle: '모든 습관 데이터 백업',
              isLoading: _isProcessing,
              onTap: _isProcessing ? null : _backupData,
            ),
            _buildSettingItem(
              context,
              icon: Icons.file_upload_outlined,
              title: '데이터 가져오기',
              subtitle: '백업 데이터 복원',
              isLoading: _isProcessing,
              onTap: _isProcessing ? null : _importData,
            ),

            // 설정 그룹: 계정
            _buildSectionHeader(context, '계정'),
            _buildSettingItem(
              context,
              icon: Icons.star_border_outlined,
              title: '프리미엄 업그레이드',
              subtitle: '더 많은 기능 사용하기',
              onTap: () {
                logger.debug('프리미엄 업그레이드 탭');
                // TODO: 프리미엄 업그레이드 화면으로 이동
                _showFeatureNotImplementedSnackBar();
              },
              showBadge: true,
            ),

            // 설정 그룹: 앱 정보
            _buildSectionHeader(context, '앱 정보'),
            _buildSettingItem(
              context,
              icon: Icons.info_outline,
              title: '버전 정보',
              subtitle: '1.0.0', // AppConstants.appVersion
              onTap: () {
                logger.debug('버전 정보 탭');
                _showAboutDialog(context);
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.help_outline,
              title: '도움말',
              subtitle: '앱 사용 가이드',
              onTap: () {
                logger.debug('도움말 탭');
                // TODO: 도움말 화면으로 이동
                _showFeatureNotImplementedSnackBar();
              },
            ),

            // 개발자용 섹션 (빠른 데이터 관리)
            // _buildSectionHeader(context, '개발자 옵션'),
            // _buildSettingItem(
            //   context,
            //   icon: Icons.delete_outline,
            //   title: '더미 데이터 초기화',
            //   subtitle: '테스트용 데이터 다시 로드',
            //   onTap: () {
            //     logger.debug('더미 데이터 초기화 탭');
            //     _resetDummyData(context);
            //   },
            //   showDivider: false,
            // ),
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
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.black, size: 22),
                ),

                const SizedBox(width: 12),

                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // 로딩 인디케이터 또는 뱃지 또는 화살표
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                else if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.black45,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),

        // 구분선
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 20),
            child: Divider(height: 1, color: Colors.black.withOpacity(0.05)),
          ),
      ],
    );
  }

  /// 데이터 백업 기능
  Future<void> _backupData() async {
    logger.debug('데이터 백업 시작');

    setState(() {
      _isProcessing = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.exportToJson();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '습관 데이터 백업 성공' : '습관 데이터 백업 실패'),
            backgroundColor: success ? Colors.black : Colors.red,
          ),
        );
      }
    } catch (e) {
      logger.error('백업 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 데이터 복원 기능
  Future<void> _importData() async {
    logger.debug('데이터 복원 시작');

    // 복원 전 경고 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 복원'),
            content: const Text(
              '백업 파일에서 데이터를 복원하면 기존 데이터와 병합됩니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('복원'),
              ),
            ],
          ),
    );

    if (confirm != true) {
      logger.debug('데이터 복원 취소됨');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.importFromJson();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '습관 데이터 복원 성공' : '습관 데이터 복원 실패'),
            backgroundColor: success ? Colors.black : Colors.red,
          ),
        );
      }
    } catch (e) {
      logger.error('복원 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 더미 데이터 초기화
  void _resetDummyData(BuildContext context) {
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('더미 데이터 초기화'),
            content: const Text('테스트용 더미 데이터를 초기화하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  // 데이터 초기화 로직
                  try {
                    final viewModel = ref.read(homeViewModelProvider);
                    viewModel.refresh();

                    // 완료 메시지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('더미 데이터가 초기화되었습니다.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    logger.error('데이터 초기화 오류: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('데이터 초기화 중 오류 발생: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('초기화'),
              ),
            ],
          ),
    );
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
