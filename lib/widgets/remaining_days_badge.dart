import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 남은 기한 뱃지 위젯
/// 
/// 남은 일수에 따라 색상과 텍스트가 변경됩니다.
/// - 3일 이상: 초록색
/// - 1~2일: 노란색/주황색
/// - 0일(오늘): 주황색
/// - 만료: 빨간색
class RemainingDaysBadge extends StatelessWidget {
  final int remainingDays;
  final bool showIcon;

  const RemainingDaysBadge({
    super.key,
    required this.remainingDays,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getRemainingDaysColor(remainingDays);
    final text = AppConstants.getRemainingDaysText(remainingDays);
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 남은 일수에 따른 아이콘
  IconData? _getIcon() {
    if (remainingDays < 0) return Icons.error_outline;
    if (remainingDays == 0) return Icons.warning_amber;
    if (remainingDays <= 2) return Icons.timer;
    return Icons.check_circle_outline;
  }
}

/// 큰 사이즈 남은 기한 뱃지 (상세 화면용)
class LargeRemainingDaysBadge extends StatelessWidget {
  final int remainingDays;

  const LargeRemainingDaysBadge({
    super.key,
    required this.remainingDays,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getRemainingDaysColor(remainingDays);
    final text = AppConstants.getRemainingDaysText(remainingDays);
    final message = _getMessage();

    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 남은 일수
          Text(
            text,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // 메시지
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMessage() {
    if (remainingDays < 0) {
      return '유통기한이 ${-remainingDays}일 지났어요';
    } else if (remainingDays == 0) {
      return '오늘이 유통기한이에요!';
    } else if (remainingDays == 1) {
      return '내일이 유통기한이에요';
    } else if (remainingDays <= 3) {
      return '곧 유통기한이에요';
    } else if (remainingDays <= 7) {
      return '신선하게 보관중이에요';
    } else {
      return '충분한 시간이 남았어요';
    }
  }
}

