import '../models/app_settings.dart';
import '../models/food_item.dart';
import 'database_service.dart';
import '../utils/constants.dart';

/// 자동완성 서비스
/// 
/// 식품 입력 시 최근 항목 및 즐겨찾기 기반 자동완성 제안
class AutocompleteService {
  final DatabaseService _db = DatabaseService.instance;
  
  /// 검색어 기반 자동완성 제안
  /// 
  /// 1순위: 즐겨찾기 매칭
  /// 2순위: 최근 입력 항목 매칭
  /// 3순위: 카테고리 기본 항목
  Future<List<AutocompleteSuggestion>> getSuggestions(String query) async {
    final suggestions = <AutocompleteSuggestion>[];
    
    // 빈 검색어면 최근 항목만 반환
    if (query.isEmpty) {
      final recentItems = await _db.getRecentItems(limit: AppConstants.maxRecentItems);
      for (final item in recentItems) {
        suggestions.add(AutocompleteSuggestion(
          name: item.name,
          category: item.category,
          defaultShelfLife: item.defaultShelfLife,
          source: SuggestionSource.recent,
          usageCount: item.usageCount,
        ));
      }
      return suggestions;
    }
    
    // 검색어가 있으면 즐겨찾기와 최근 항목 검색
    final queryLower = query.toLowerCase();
    
    // 1. 즐겨찾기 검색
    final favorites = await _db.getAllFavorites();
    for (final favorite in favorites) {
      if (favorite.name.toLowerCase().contains(queryLower)) {
        suggestions.add(AutocompleteSuggestion(
          name: favorite.name,
          category: favorite.category,
          defaultShelfLife: favorite.defaultShelfLife,
          source: SuggestionSource.favorite,
        ));
      }
    }
    
    // 2. 최근 항목 검색
    final recentItems = await _db.searchRecentItems(query);
    for (final item in recentItems) {
      // 중복 방지 (즐겨찾기에 이미 있는 항목 제외)
      if (!suggestions.any((s) => s.name == item.name)) {
        suggestions.add(AutocompleteSuggestion(
          name: item.name,
          category: item.category,
          defaultShelfLife: item.defaultShelfLife,
          source: SuggestionSource.recent,
          usageCount: item.usageCount,
        ));
      }
    }
    
    // 3. 정렬 (즐겨찾기 우선, 그 다음 사용 빈도순)
    suggestions.sort((a, b) {
      if (a.source == SuggestionSource.favorite && 
          b.source != SuggestionSource.favorite) {
        return -1;
      }
      if (a.source != SuggestionSource.favorite && 
          b.source == SuggestionSource.favorite) {
        return 1;
      }
      return (b.usageCount ?? 0).compareTo(a.usageCount ?? 0);
    });
    
    return suggestions.take(10).toList(); // 최대 10개만 반환
  }
  
  /// 식품 등록 후 최근 항목 업데이트
  /// 
  /// 등록된 식품을 최근 항목에 추가하거나 사용 횟수 증가
  Future<void> recordFoodInput(FoodItem food) async {
    // 카테고리별 기본 유통기한 추론
    final defaultShelfLife = food.category != null
        ? FoodCategories.defaultShelfLife[food.category]
        : null;
    
    final recentItem = RecentItem(
      name: food.name,
      category: food.category,
      defaultShelfLife: defaultShelfLife,
    );
    
    await _db.addOrUpdateRecentItem(recentItem);
  }
  
  /// 오래된 최근 항목 자동 정리
  /// 
  /// 설정된 보관 기간이 지난 항목 삭제
  /// 앱 시작 시 또는 주기적으로 호출
  Future<void> cleanupOldItems(int retentionDays) async {
    await _db.cleanOldRecentItems(retentionDays);
  }
  
  /// 카테고리별 추천 식품 가져오기
  /// 
  /// 사용자가 카테고리를 선택했을 때 일반적인 식품 제안
  List<String> getCommonFoodsByCategory(String category) {
    switch (category) {
      case '유제품':
        return ['우유', '요거트', '치즈', '버터', '생크림'];
      case '과일':
        return ['사과', '바나나', '딸기', '포도', '오렌지', '수박', '귤'];
      case '채소':
        return ['배추', '양파', '당근', '감자', '상추', '오이', '토마토'];
      case '육류':
        return ['돼지고기', '소고기', '닭고기', '삼겹살', '목살'];
      case '해산물':
        return ['고등어', '갈치', '오징어', '새우', '조개'];
      case '곡물':
        return ['쌀', '현미', '보리', '귀리'];
      case '음료':
        return ['주스', '탄산음료', '커피', '차'];
      default:
        return [];
    }
  }
  
  /// 모든 일반 식품 목록 (초기 제안용)
  List<String> getAllCommonFoods() {
    final allFoods = <String>[];
    for (final category in FoodCategories.all) {
      allFoods.addAll(getCommonFoodsByCategory(category));
    }
    return allFoods;
  }
  
  /// 식품명으로 카테고리 자동 추론
  /// 
  /// 사용자가 카테고리를 입력하지 않았을 때 자동 설정
  String? inferCategory(String foodName) {
    final nameLower = foodName.toLowerCase();
    
    // 각 카테고리의 일반 식품 목록과 비교
    for (final category in FoodCategories.all) {
      final commonFoods = getCommonFoodsByCategory(category);
      for (final food in commonFoods) {
        if (nameLower.contains(food.toLowerCase()) || 
            food.toLowerCase().contains(nameLower)) {
          return category;
        }
      }
    }
    
    // 키워드 기반 추론
    if (nameLower.contains('우유') || nameLower.contains('치즈') || 
        nameLower.contains('요거트')) {
      return '유제품';
    }
    if (nameLower.contains('고기') || nameLower.contains('삼겹') || 
        nameLower.contains('목살')) {
      return '육류';
    }
    if (nameLower.contains('생선') || nameLower.contains('조개') || 
        nameLower.contains('새우')) {
      return '해산물';
    }
    
    return null; // 추론 실패
  }
  
  /// 식품명과 카테고리로 기본 유통기한 추론
  /// 
  /// 사용자가 유통기한을 빠르게 입력할 수 있도록 제안
  int? inferShelfLife(String foodName, String? category) {
    // 1. 카테고리 기본값 사용
    if (category != null && FoodCategories.defaultShelfLife.containsKey(category)) {
      return FoodCategories.defaultShelfLife[category];
    }
    
    // 2. 카테고리가 없으면 자동 추론 후 적용
    final inferredCategory = inferCategory(foodName);
    if (inferredCategory != null) {
      return FoodCategories.defaultShelfLife[inferredCategory];
    }
    
    // 3. 기본값 (일주일)
    return 7;
  }
  
  /// 최근 입력 항목 통계
  /// 
  /// 설정 화면이나 대시보드에서 표시
  Future<Map<String, dynamic>> getRecentItemsStats() async {
    final recentItems = await _db.getRecentItems(limit: 100);
    
    final totalItems = recentItems.length;
    final totalUsage = recentItems.fold<int>(
      0,
      (sum, item) => sum + item.usageCount,
    );
    
    // 가장 많이 사용한 항목 Top 5
    recentItems.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    final topItems = recentItems.take(5).map((item) => item.name).toList();
    
    return {
      'totalItems': totalItems,
      'totalUsage': totalUsage,
      'topItems': topItems,
    };
  }
  
  /// 즐겨찾기 통계
  Future<Map<String, dynamic>> getFavoriteStats() async {
    final favorites = await _db.getAllFavorites();
    
    // 카테고리별 즐겨찾기 개수
    final categoryCount = <String, int>{};
    for (final favorite in favorites) {
      final category = favorite.category ?? '기타';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    return {
      'totalFavorites': favorites.length,
      'categoryCount': categoryCount,
    };
  }
}

/// 자동완성 제안 항목
class AutocompleteSuggestion {
  final String name; // 식품명
  final String? category; // 카테고리
  final int? defaultShelfLife; // 기본 유통기한 (일)
  final SuggestionSource source; // 출처 (즐겨찾기/최근 항목)
  final int? usageCount; // 사용 횟수 (최근 항목인 경우)
  
  AutocompleteSuggestion({
    required this.name,
    this.category,
    this.defaultShelfLife,
    required this.source,
    this.usageCount,
  });
  
  /// 제안 날짜 계산 (오늘부터 N일 후)
  DateTime? getSuggestedExpiryDate() {
    if (defaultShelfLife == null) return null;
    return DateTime.now().add(Duration(days: defaultShelfLife!));
  }
  
  /// 아이콘 가져오기
  String get icon {
    if (category != null && FoodCategories.icons.containsKey(category)) {
      return FoodCategories.icons[category]!;
    }
    return FoodCategories.icons['기타']!;
  }
  
  @override
  String toString() {
    return 'AutocompleteSuggestion{name: $name, source: $source}';
  }
}

/// 자동완성 제안 출처
enum SuggestionSource {
  favorite, // 즐겨찾기
  recent,   // 최근 입력
  common,   // 일반 식품
}

