import 'package:flutter/material.dart';
import '../models/food_item.dart';

/// 검색 및 필터 상태 관리 Provider
class FilterProvider with ChangeNotifier {
  String _searchQuery = '';
  String? _selectedCategory;
  SortOption _sortOption = SortOption.expiryDate;
  
  // Getters
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  SortOption get sortOption => _sortOption;
  
  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty || _selectedCategory != null;
  
  /// 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// 카테고리 필터 설정
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  /// 정렬 옵션 설정
  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }
  
  /// 모든 필터 초기화
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortOption = SortOption.expiryDate;
    notifyListeners();
  }
  
  /// 식품 리스트 필터링 및 정렬
  List<FoodItem> applyFilters(List<FoodItem> foods) {
    var filtered = foods;
    
    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((food) {
        return food.name.toLowerCase().contains(queryLower);
      }).toList();
    }
    
    // 카테고리 필터
    if (_selectedCategory != null) {
      filtered = filtered.where((food) {
        return food.category == _selectedCategory;
      }).toList();
    }
    
    // 정렬
    filtered = _sortFoods(filtered, _sortOption);
    
    return filtered;
  }
  
  /// 식품 리스트 정렬
  List<FoodItem> _sortFoods(List<FoodItem> foods, SortOption option) {
    final sorted = List<FoodItem>.from(foods);
    
    switch (option) {
      case SortOption.expiryDate:
        // 유통기한 오름차순 (급한 순)
        sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
        
      case SortOption.name:
        // 이름 오름차순 (가나다 순)
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
        
      case SortOption.purchaseDate:
        // 구매일 내림차순 (최근 순)
        sorted.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
        
      case SortOption.category:
        // 카테고리 순 → 유통기한 순
        sorted.sort((a, b) {
          final categoryCompare = (a.category ?? '').compareTo(b.category ?? '');
          if (categoryCompare != 0) return categoryCompare;
          return a.expiryDate.compareTo(b.expiryDate);
        });
        break;
    }
    
    return sorted;
  }
}

/// 정렬 옵션
enum SortOption {
  expiryDate,    // 유통기한 순
  name,          // 이름 순
  purchaseDate,  // 구매일 순
  category,      // 카테고리 순
}

/// 정렬 옵션 확장 (레이블)
extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.expiryDate:
        return '유통기한 순';
      case SortOption.name:
        return '이름 순';
      case SortOption.purchaseDate:
        return '구매일 순';
      case SortOption.category:
        return '카테고리 순';
    }
  }
  
  IconData get icon {
    switch (this) {
      case SortOption.expiryDate:
        return Icons.event_available;
      case SortOption.name:
        return Icons.sort_by_alpha;
      case SortOption.purchaseDate:
        return Icons.shopping_cart;
      case SortOption.category:
        return Icons.category;
    }
  }
}

