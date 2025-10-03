import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/food_provider.dart';
import '../utils/constants.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.settings),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            children: [
              // 알림 설정 섹션
              _buildSectionHeader(context, '알림 설정', Icons.notifications),
              
              // 기본 알림 시점
              ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('기본 알림 시점'),
                subtitle: Text(
                  AppConstants.notificationLabels[settings.defaultNotificationDays] ??
                      'D-${settings.defaultNotificationDays}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNotificationDaysDialog(context, settingsProvider),
              ),
              
              // 알림 반복
              SwitchListTile(
                secondary: const Icon(Icons.repeat),
                title: const Text('알림 반복'),
                subtitle: const Text('알림일부터 유통기한까지 매일 알림'),
                value: settings.notificationRepeat,
                onChanged: (value) {
                  settingsProvider.updateNotificationRepeat(value);
                },
              ),
              
              const Divider(),
              
              // 데이터 관리 섹션
              _buildSectionHeader(context, '데이터 관리', Icons.storage),
              
              // 최근 항목 보관 기간
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('최근 항목 보관 기간'),
                subtitle: Text('${settings.recentItemsRetentionDays}일'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRetentionDaysDialog(context, settingsProvider),
              ),
              
              // 데이터 초기화
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppConstants.dangerRed),
                title: const Text(
                  '모든 데이터 삭제',
                  style: TextStyle(color: AppConstants.dangerRed),
                ),
                subtitle: const Text('모든 식품 데이터가 삭제됩니다'),
                onTap: () => _showClearDataDialog(context),
              ),
              
              const Divider(),
              
              // 앱 정보 섹션
              _buildSectionHeader(context, '앱 정보', Icons.info),
              
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('앱 이름'),
                subtitle: Text('${AppConstants.appNameKorean} (${AppConstants.appName})'),
              ),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('버전'),
                subtitle: const Text('1.0.0'),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.largePadding,
        AppConstants.defaultPadding,
        AppConstants.smallPadding,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.freshGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.freshGreen,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 기본 알림 시점 선택 다이얼로그
  Future<void> _showNotificationDaysDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기본 알림 시점'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.notificationOptions.map((days) {
            final isSelected = days == settingsProvider.settings.defaultNotificationDays;
            return ListTile(
              title: Text(AppConstants.notificationLabels[days] ?? 'D-$days'),
              leading: Radio<int>(
                value: days,
                // ignore: deprecated_member_use
                groupValue: settingsProvider.settings.defaultNotificationDays,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              selected: isSelected,
              onTap: () {
                Navigator.pop(context, days);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      await settingsProvider.updateDefaultNotificationDays(selected);
    }
  }

  /// 최근 항목 보관 기간 선택 다이얼로그
  Future<void> _showRetentionDaysDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final controller = TextEditingController(
      text: settingsProvider.settings.recentItemsRetentionDays.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최근 항목 보관 기간'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '일수',
            suffixText: '일',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0 && days <= 365) {
                Navigator.pop(context, days);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null) {
      await settingsProvider.updateRecentItemsRetentionDays(result);
    }
  }

  /// 모든 데이터 삭제 확인 다이얼로그
  Future<void> _showClearDataDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '정말로 모든 식품 데이터를 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.dangerRed,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<FoodProvider>().clearAllData();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 삭제되었습니다'),
          ),
        );
      }
    }
  }
}

