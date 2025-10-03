/// 식품(Food Item) 데이터 모델
/// 
/// 앱의 핵심 데이터 구조로, 사용자가 등록한 식품 정보를 담습니다.
class FoodItem {
  final String id; // 고유 식별자 (UUID)
  final String name; // 식품 이름
  final DateTime purchaseDate; // 구매 날짜
  final DateTime expiryDate; // 유통기한
  final int notificationDays; // 알림 시점 (D-N일)
  final bool isConsumed; // 소비 여부
  final DateTime? consumedDate; // 소비 완료 날짜
  final bool isFavorite; // 즐겨찾기 여부
  final String? category; // 카테고리 (유제품, 과일 등)
  final DateTime createdAt; // 등록 일시

  FoodItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    required this.notificationDays,
    this.isConsumed = false,
    this.consumedDate,
    this.isFavorite = false,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 유통기한까지 남은 일수 계산
  /// 
  /// 음수: 만료됨
  /// 0: 오늘까지
  /// 양수: N일 남음
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    
    return expiry.difference(today).inDays;
  }

  /// 알림 발송 날짜 계산
  DateTime get notificationDate {
    return expiryDate.subtract(Duration(days: notificationDays));
  }

  /// 유통기한이 지났는지 확인
  bool get isExpired => remainingDays < 0;

  /// 오늘이 유통기한인지 확인
  bool get isExpiringToday => remainingDays == 0;

  /// 유통기한이 임박했는지 확인 (2일 이내)
  bool get isExpiringSoon => remainingDays > 0 && remainingDays <= 2;

  /// 데이터베이스 저장용 Map으로 변환
  /// 
  /// SQLite에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'notification_days': notificationDays,
      'is_consumed': isConsumed ? 1 : 0,
      'consumed_date': consumedDate?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Map에서 FoodItem 객체 생성
  /// 
  /// 데이터베이스에서 조회할 때 사용
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      notificationDays: map['notification_days'] as int,
      isConsumed: (map['is_consumed'] as int) == 1,
      consumedDate: map['consumed_date'] != null
          ? DateTime.parse(map['consumed_date'] as String)
          : null,
      isFavorite: (map['is_favorite'] as int) == 1,
      category: map['category'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 일부 필드만 수정한 새 객체 생성 (불변성 유지)
  /// 
  /// 예: food.copyWith(isConsumed: true) → 소비 완료 표시
  FoodItem copyWith({
    String? id,
    String? name,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    int? notificationDays,
    bool? isConsumed,
    DateTime? consumedDate,
    bool? isFavorite,
    String? category,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notificationDays: notificationDays ?? this.notificationDays,
      isConsumed: isConsumed ?? this.isConsumed,
      consumedDate: consumedDate ?? this.consumedDate,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'FoodItem{id: $id, name: $name, expiryDate: $expiryDate, '
        'remainingDays: $remainingDays, isConsumed: $isConsumed}';
  }

  /// 객체 동등성 비교 (id 기준)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

