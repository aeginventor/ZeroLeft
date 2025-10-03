import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/food_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/remaining_days_badge.dart';
import 'add_food_screen.dart';

/// 식품 상세 화면
class FoodDetailScreen extends StatelessWidget {
  final FoodItem food;

  const FoodDetailScreen({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(food.name),
        actions: [
          // 수정 버튼
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFoodScreen(foodToEdit: food),
                ),
              );
              
              if (result == true && context.mounted) {
                // 수정 후 상세 화면 닫기
                Navigator.pop(context, true);
              }
            },
            tooltip: '수정',
          ),
          
          // 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
            tooltip: '삭제',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 남은 기한 대형 뱃지
            if (!food.isConsumed) ...[
              LargeRemainingDaysBadge(remainingDays: food.remainingDays),
              const SizedBox(height: 24),
            ],
            
            // 카테고리 아이콘 (큰 크기)
            if (food.category != null) ...[
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppConstants.freshGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      FoodCategories.icons[food.category] ?? '📦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  food.category!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppConstants.freshGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // 정보 카드
            _buildInfoCard(
              context,
              title: '식품 정보',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.label,
                  label: '이름',
                  value: food.name,
                ),
                if (food.category != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.category,
                    label: '카테고리',
                    value: food.category!,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 날짜 정보 카드
            _buildInfoCard(
              context,
              title: '날짜 정보',
              icon: Icons.calendar_today,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.shopping_cart,
                  label: '구매일',
                  value: app_date_utils.DateUtils.formatKorean(food.purchaseDate),
                  subtitle: app_date_utils.DateUtils.formatRelative(food.purchaseDate),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.event_available,
                  label: '유통기한',
                  value: app_date_utils.DateUtils.formatKorean(food.expiryDate),
                  subtitle: app_date_utils.DateUtils.formatRelative(food.expiryDate),
                ),
                if (food.isConsumed && food.consumedDate != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.check_circle,
                    label: '소비일',
                    value: app_date_utils.DateUtils.formatKorean(food.consumedDate!),
                    subtitle: app_date_utils.DateUtils.formatTimeAgo(food.consumedDate!),
                  ),
                _buildInfoRow(
                  context,
                  icon: Icons.timer,
                  label: '보관 기간',
                  value: '${app_date_utils.DateUtils.daysBetween(food.purchaseDate, food.expiryDate)}일',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 알림 정보 카드
            if (!food.isConsumed) ...[
              _buildInfoCard(
                context,
                title: '알림 정보',
                icon: Icons.notifications_active,
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.alarm,
                    label: '알림 시점',
                    value: AppConstants.notificationLabels[food.notificationDays] ??
                        'D-${food.notificationDays}',
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.schedule,
                    label: '알림 발송일',
                    value: app_date_utils.DateUtils.formatKorean(food.notificationDate),
                    subtitle: app_date_utils.DateUtils.formatRelative(food.notificationDate),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // 등록 정보
            _buildInfoCard(
              context,
              title: '등록 정보',
              icon: Icons.info,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.add_circle,
                  label: '등록일시',
                  value: app_date_utils.DateUtils.formatDateTime(food.createdAt),
                  subtitle: app_date_utils.DateUtils.formatTimeAgo(food.createdAt),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.fingerprint,
                  label: 'ID',
                  value: food.id.substring(0, 8),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 액션 버튼
            if (!food.isConsumed) ...[
              ElevatedButton.icon(
                onPressed: () => _markAsConsumed(context),
                icon: const Icon(Icons.check),
                label: const Text('소비 완료로 표시'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppConstants.freshGreen,
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => _markAsUnconsumed(context),
                icon: const Icon(Icons.undo),
                label: const Text('다시 보관 중으로 변경'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 삭제 버튼
            OutlinedButton.icon(
              onPressed: () => _showDeleteDialog(context),
              icon: const Icon(Icons.delete, color: AppConstants.dangerRed),
              label: const Text(
                '삭제',
                style: TextStyle(color: AppConstants.dangerRed),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppConstants.dangerRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.freshGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.freshGreen,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 소비 완료로 표시
  Future<void> _markAsConsumed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('소비 완료'),
        content: Text('${food.name}을(를) 소비 완료로 표시하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<FoodProvider>().markAsConsumed(food.id);
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('소비 완료로 표시되었습니다'),
            backgroundColor: AppConstants.freshGreen,
          ),
        );
      }
    }
  }

  /// 다시 보관 중으로 변경
  Future<void> _markAsUnconsumed(BuildContext context) async {
    await context.read<FoodProvider>().markAsUnconsumed(food.id);
    if (context.mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다시 보관 중으로 변경되었습니다'),
          backgroundColor: AppConstants.freshGreen,
        ),
      );
    }
  }

  /// 삭제 확인 다이얼로그
  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.deleteConfirmTitle),
        content: Text('${food.name}을(를) ${AppConstants.deleteConfirmMessage}'),
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
      await context.read<FoodProvider>().deleteFood(food.id);
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.deleteSuccess),
          ),
        );
      }
    }
  }
}

