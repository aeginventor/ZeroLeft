import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'remaining_days_badge.dart';

/// 식품 리스트 아이템 위젯
/// 
/// 체크박스, 식품 정보, 남은 기한 뱃지, 스와이프 액션 포함
class FoodListItem extends StatelessWidget {
  final FoodItem food;
  final bool isConsumed;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckChanged;
  final VoidCallback? onDelete;

  const FoodListItem({
    super.key,
    required this.food,
    this.isConsumed = false,
    this.onTap,
    this.onCheckChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(food.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // 삭제 액션
          SlidableAction(
            onPressed: (context) {
              if (onDelete != null) onDelete!();
            },
            backgroundColor: AppConstants.dangerRed,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                // 체크박스
                Checkbox(
                  value: food.isConsumed,
                  onChanged: onCheckChanged,
                ),
                const SizedBox(width: 12),
                
                // 카테고리 아이콘
                if (food.category != null) ...[
                  Text(
                    FoodCategories.icons[food.category] ?? '📦',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // 식품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 식품명
                      Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: food.isConsumed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: food.isConsumed
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      
                      // 날짜 정보
                      if (food.isConsumed && food.consumedDate != null) ...[
                        // 소비 완료일
                        Text(
                          '소비일: ${app_date_utils.DateUtils.formatWithDay(food.consumedDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ] else ...[
                        // 구매일 & 유통기한
                        Text(
                          '구매일: ${app_date_utils.DateUtils.formatShort(food.purchaseDate)} • '
                          '유통기한: ${app_date_utils.DateUtils.formatWithDay(food.expiryDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                      
                      // 카테고리 표시 (텍스트)
                      if (food.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          food.category!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConstants.freshGreen,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 남은 기한 뱃지 (보관 중인 경우만)
                if (!food.isConsumed) ...[
                  const SizedBox(width: 12),
                  RemainingDaysBadge(remainingDays: food.remainingDays),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

