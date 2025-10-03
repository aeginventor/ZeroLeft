import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';
import 'food_list_item.dart';

/// 애니메이션이 적용된 식품 리스트
class AnimatedFoodList extends StatelessWidget {
  final List<FoodItem> foods;
  final bool isConsumed;
  final Function(FoodItem)? onTap;
  final Function(FoodItem, bool?)? onCheckChanged;
  final Function(FoodItem)? onDelete;
  final String? emptyMessage;
  final IconData? emptyIcon;

  const AnimatedFoodList({
    super.key,
    required this.foods,
    this.isConsumed = false,
    this.onTap,
    this.onCheckChanged,
    this.onDelete,
    this.emptyMessage,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    // 빈 상태 처리
    if (foods.isEmpty) {
      return AnimatedEmptyState(
        icon: emptyIcon ?? (isConsumed ? Icons.check_circle_outline : Icons.shopping_basket_outlined),
        message: emptyMessage ?? (isConsumed ? '아직 소비 완료된 식품이 없습니다' : '아직 등록된 식품이 없습니다'),
      );
    }

    // 리스트가 너무 많으면 애니메이션 비활성화 (성능 최적화)
    final enableAnimation = foods.length < AppConstants.staggerAnimationLimit;

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppConstants.defaultPadding,
          bottom: 80,
        ),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];

          if (enableAnimation) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppConstants.normalAnimation,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildListItem(food),
                ),
              ),
            );
          } else {
            return _buildListItem(food);
          }
        },
      ),
    );
  }

  Widget _buildListItem(FoodItem food) {
    return FoodListItem(
      food: food,
      isConsumed: isConsumed,
      onTap: onTap != null ? () => onTap!(food) : null,
      onCheckChanged: onCheckChanged != null
          ? (value) => onCheckChanged!(food, value)
          : null,
      onDelete: onDelete != null ? () => onDelete!(food) : null,
    );
  }
}

/// 빈 상태 애니메이션
class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
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
}

/// 로딩 애니메이션
class AnimatedLoadingIndicator extends StatelessWidget {
  final String? message;

  const AnimatedLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

