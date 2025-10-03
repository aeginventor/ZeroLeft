import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 상수 정의
class AppConstants {
  // 앱 정보
  static const String appName = 'FreshMate';
  static const String appNameKorean = '남김없이';
  
  // 색상 정의 (Material 3 기반)
  static const Color freshGreen = Color(0xFF4CAF50); // 신선한 초록 (남은 음식)
  static const Color warningYellow = Color(0xFFFFA726); // 경고 노랑 (임박)
  static const Color dangerRed = Color(0xFFE53935); // 위험 빨강 (만료)
  static const Color consumedGray = Color(0xFF9E9E9E); // 먹은 음식 회색
  static const Color softOrange = Color(0xFFFF7043); // 부드러운 주황
  static const Color softBlue = Color(0xFF42A5F5); // 부드러운 파랑
  
  // 기본값 설정
  static const int defaultNotificationDays = 3; // 기본 알림 시점: D-3
  static const int defaultRecentItemsRetentionDays = 30; // 최근 항목 보관 기간
  static const bool defaultNotificationRepeat = false; // 기본 알림 반복 여부
  
  // 문자열 상수
  static const String tabRemainingFood = '신선하게 보관중';
  static const String tabConsumedFood = '소비 완료!';
  static const String addFoodButton = '식품 추가';
  static const String settings = '설정';
  
  // 입력 필드 라벨
  static const String labelFoodName = '식품 이름';
  static const String labelPurchaseDate = '구매 날짜';
  static const String labelExpiryDate = '유통기한';
  static const String labelNotificationDays = '알림 시점';
  static const String labelCategory = '카테고리';
  
  // 힌트 텍스트
  static const String hintFoodName = '예: 우유, 계란, 사과';
  static const String hintSelectDate = '날짜를 선택해주세요';
  
  // 알림 옵션
  static const List<int> notificationOptions = [1, 2, 3, 5, 7];
  static const Map<int, String> notificationLabels = {
    1: 'D-1 (하루 전)',
    2: 'D-2 (이틀 전)',
    3: 'D-3 (3일 전)',
    5: 'D-5 (5일 전)',
    7: 'D-7 (일주일 전)',
  };
  
  // 메시지
  static const String emptyRemainingFood = '등록된 식품이 없어요.\n+ 버튼을 눌러 추가해보세요!';
  static const String emptyConsumedFood = '아직 소비한 식품이 없어요.';
  static const String deleteConfirmTitle = '삭제 확인';
  static const String deleteConfirmMessage = '정말 삭제하시겠습니까?';
  static const String saveSuccess = '저장되었습니다';
  static const String deleteSuccess = '삭제되었습니다';
  static const String errorOccurred = '오류가 발생했습니다';
  
  // 알림 메시지 템플릿
  static String getNotificationTitle(String foodName, int remainingDays) {
    if (remainingDays == 0) {
      return '🔔 $foodName의 유통기한이 오늘까지예요!';
    } else if (remainingDays == 1) {
      return '🔔 $foodName의 유통기한이 내일까지예요!';
    } else {
      return '🔔 $foodName가 $remainingDays일 남았어요!';
    }
  }
  
  static const String notificationBody = '오늘은 꼭 확인해 주세요.';
  
  // 남은 기한 표시
  static String getRemainingDaysText(int days) {
    if (days < 0) return '만료됨';
    if (days == 0) return '오늘';
    return 'D-$days';
  }
  
  // 남은 기한에 따른 색상
  static Color getRemainingDaysColor(int days) {
    if (days < 0) return dangerRed;
    if (days == 0) return warningYellow;
    if (days <= 2) return softOrange;
    return freshGreen;
  }
  
  // 애니메이션 시간
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // 레이아웃
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // 리스트
  static const int maxRecentItems = 10; // 자동완성에 표시할 최대 최근 항목 수
  static const int staggerAnimationLimit = 100; // 이 개수 이상이면 애니메이션 비활성화
}

/// 식품 카테고리 (확장 예정)
class FoodCategories {
  static const String dairy = '유제품';
  static const String fruit = '과일';
  static const String vegetable = '채소';
  static const String meat = '육류';
  static const String seafood = '해산물';
  static const String grain = '곡물';
  static const String beverage = '음료';
  static const String etc = '기타';
  
  static const List<String> all = [
    dairy,
    fruit,
    vegetable,
    meat,
    seafood,
    grain,
    beverage,
    etc,
  ];
  
  // 카테고리별 기본 유통기한 (일)
  static const Map<String, int> defaultShelfLife = {
    dairy: 7,
    fruit: 5,
    vegetable: 7,
    meat: 3,
    seafood: 2,
    grain: 30,
    beverage: 14,
    etc: 7,
  };
  
  // 카테고리별 아이콘 (이모지)
  static const Map<String, String> icons = {
    dairy: '🥛',
    fruit: '🍎',
    vegetable: '🥬',
    meat: '🥩',
    seafood: '🐟',
    grain: '🌾',
    beverage: '🥤',
    etc: '📦',
  };
}

