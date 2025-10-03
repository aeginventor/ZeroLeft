import '../utils/constants.dart';

/// 앱 설정 데이터 모델
/// 
/// SharedPreferences에 저장되는 사용자 설정값을 관리
class AppSettings {
  final int defaultNotificationDays; // 기본 알림 시점 (D-N일)
  final bool notificationRepeat; // 알림 반복 여부
  final int recentItemsRetentionDays; // 최근 항목 보관 기간 (일)
  final bool showConsumedItems; // 소비 완료 항목 표시 여부
  final String sortBy; // 정렬 기준 ('expiry', 'name', 'created')

  AppSettings({
    this.defaultNotificationDays = AppConstants.defaultNotificationDays,
    this.notificationRepeat = AppConstants.defaultNotificationRepeat,
    this.recentItemsRetentionDays = AppConstants.defaultRecentItemsRetentionDays,
    this.showConsumedItems = true,
    this.sortBy = 'expiry', // 기본: 유통기한 순
  });

  /// SharedPreferences 저장용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'defaultNotificationDays': defaultNotificationDays,
      'notificationRepeat': notificationRepeat,
      'recentItemsRetentionDays': recentItemsRetentionDays,
      'showConsumedItems': showConsumedItems,
      'sortBy': sortBy,
    };
  }

  /// Map에서 AppSettings 객체 생성
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      defaultNotificationDays: map['defaultNotificationDays'] as int? ?? 
          AppConstants.defaultNotificationDays,
      notificationRepeat: map['notificationRepeat'] as bool? ?? 
          AppConstants.defaultNotificationRepeat,
      recentItemsRetentionDays: map['recentItemsRetentionDays'] as int? ?? 
          AppConstants.defaultRecentItemsRetentionDays,
      showConsumedItems: map['showConsumedItems'] as bool? ?? true,
      sortBy: map['sortBy'] as String? ?? 'expiry',
    );
  }

  /// 일부 설정만 변경한 새 객체 생성
  AppSettings copyWith({
    int? defaultNotificationDays,
    bool? notificationRepeat,
    int? recentItemsRetentionDays,
    bool? showConsumedItems,
    String? sortBy,
  }) {
    return AppSettings(
      defaultNotificationDays: defaultNotificationDays ?? this.defaultNotificationDays,
      notificationRepeat: notificationRepeat ?? this.notificationRepeat,
      recentItemsRetentionDays: recentItemsRetentionDays ?? this.recentItemsRetentionDays,
      showConsumedItems: showConsumedItems ?? this.showConsumedItems,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'AppSettings{defaultNotificationDays: $defaultNotificationDays, '
        'notificationRepeat: $notificationRepeat, '
        'recentItemsRetentionDays: $recentItemsRetentionDays}';
  }
}

/// 최근 입력 항목 모델
class RecentItem {
  final String name; // 식품명
  final String? category; // 카테고리
  final int? defaultShelfLife; // 기본 유통기한 (일)
  final int usageCount; // 사용 횟수
  final DateTime lastUsed; // 마지막 사용 일시

  RecentItem({
    required this.name,
    this.category,
    this.defaultShelfLife,
    this.usageCount = 1,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  /// 데이터베이스 저장용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'default_shelf_life': defaultShelfLife,
      'usage_count': usageCount,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  /// Map에서 RecentItem 객체 생성
  factory RecentItem.fromMap(Map<String, dynamic> map) {
    return RecentItem(
      name: map['name'] as String,
      category: map['category'] as String?,
      defaultShelfLife: map['default_shelf_life'] as int?,
      usageCount: map['usage_count'] as int? ?? 1,
      lastUsed: DateTime.parse(map['last_used'] as String),
    );
  }

  /// 사용 횟수 증가
  RecentItem incrementUsage() {
    return RecentItem(
      name: name,
      category: category,
      defaultShelfLife: defaultShelfLife,
      usageCount: usageCount + 1,
      lastUsed: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RecentItem{name: $name, usageCount: $usageCount}';
  }
}

/// 즐겨찾기 항목 모델
class FavoriteItem {
  final String name; // 식품명
  final String? category; // 카테고리
  final int? defaultShelfLife; // 기본 유통기한 (일)
  final DateTime createdAt; // 등록 일시

  FavoriteItem({
    required this.name,
    this.category,
    this.defaultShelfLife,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 데이터베이스 저장용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'default_shelf_life': defaultShelfLife,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Map에서 FavoriteItem 객체 생성
  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      name: map['name'] as String,
      category: map['category'] as String?,
      defaultShelfLife: map['default_shelf_life'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'FavoriteItem{name: $name, category: $category}';
  }
}

