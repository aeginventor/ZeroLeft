import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/autocomplete_service.dart';

/// 식품 데이터 관리 Provider
/// 
/// 식품 CRUD 작업과 알림 관리를 담당합니다.
class FoodProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notification = NotificationService.instance;
  final AutocompleteService _autocomplete = AutocompleteService();
  
  List<FoodItem> _foods = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<FoodItem> get foods => _foods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  /// 남은 음식 (보관 중)
  List<FoodItem> get remainingFoods {
    return _foods
        .where((food) => !food.isConsumed)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)); // 유통기한 오름차순
  }
  
  /// 먹은 음식 (소비 완료)
  List<FoodItem> get consumedFoods {
    return _foods
        .where((food) => food.isConsumed)
        .toList()
      ..sort((a, b) {
        // 소비일 내림차순 (최근 순)
        if (a.consumedDate != null && b.consumedDate != null) {
          return b.consumedDate!.compareTo(a.consumedDate!);
        }
        return 0;
      });
  }
  
  /// 만료된 식품
  List<FoodItem> get expiredFoods {
    return remainingFoods.where((food) => food.isExpired).toList();
  }
  
  /// 임박한 식품 (2일 이내)
  List<FoodItem> get expiringSoonFoods {
    return remainingFoods.where((food) => food.isExpiringSoon).toList();
  }
  
  /// 모든 식품 로드
  Future<void> loadFoods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _foods = await _db.getAllFoods();
      _error = null;
    } catch (e) {
      _error = '데이터를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 식품 추가
  Future<void> addFood(FoodItem food) async {
    try {
      // 1. 데이터베이스에 저장
      await _db.insertFood(food);
      
      // 2. 알림 스케줄링
      await _notification.scheduleNotification(food);
      
      // 3. 최근 항목에 기록
      await _autocomplete.recordFoodInput(food);
      
      // 4. 리스트 새로고침
      await loadFoods();
      
      // 5. 추가 확인: UI 업데이트 보장
      notifyListeners();
    } catch (e) {
      _error = '식품 추가 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 식품 수정
  Future<void> updateFood(FoodItem food) async {
    try {
      // 기존 식품 정보 가져오기 (이름 변경 확인용)
      final existingFood = _foods.firstWhere(
        (f) => f.id == food.id,
        orElse: () => food,
      );
      
      // 1. 데이터베이스 업데이트
      await _db.updateFood(food);
      
      // 2. 식품명이나 카테고리가 변경된 경우 자동완성 제안 업데이트
      if (existingFood.name != food.name || existingFood.category != food.category) {
        await _db.updateFoodNameInSuggestions(
          existingFood.name,
          food.name,
          food.category,
        );
      }
      
      // 3. 알림 업데이트
      await _notification.updateNotification(food);
      
      // 4. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '식품 수정 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 식품 삭제
  Future<void> deleteFood(String foodId) async {
    try {
      // 1. 알림 취소
      await _notification.cancelNotification(foodId);
      
      // 2. 데이터베이스에서 삭제
      await _db.deleteFood(foodId);
      
      // 3. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '식품 삭제 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 여러 식품 일괄 삭제
  Future<void> deleteMultipleFoods(List<String> foodIds) async {
    try {
      // 1. 모든 알림 취소
      for (final foodId in foodIds) {
        await _notification.cancelNotification(foodId);
      }
      
      // 2. 데이터베이스에서 일괄 삭제
      await _db.deleteMultipleFoods(foodIds);
      
      // 3. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '식품 일괄 삭제 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 식품을 소비 완료로 표시
  Future<void> markAsConsumed(String foodId) async {
    try {
      // 1. 알림 취소
      await _notification.cancelNotification(foodId);
      
      // 2. 데이터베이스 업데이트
      await _db.markAsConsumed(foodId);
      
      // 3. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '상태 변경 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 식품을 다시 보관 중으로 변경
  Future<void> markAsUnconsumed(String foodId) async {
    try {
      // 1. 데이터베이스 업데이트
      await _db.markAsUnconsumed(foodId);
      
      // 2. 식품 정보 가져오기
      final food = await _db.getFoodById(foodId);
      
      // 3. 알림 재설정
      if (food != null) {
        await _notification.scheduleNotification(food);
      }
      
      // 4. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '상태 변경 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// ID로 식품 조회
  Future<FoodItem?> getFoodById(String id) async {
    try {
      return await _db.getFoodById(id);
    } catch (e) {
      _error = '식품 조회 중 오류가 발생했습니다: $e';
      notifyListeners();
      return null;
    }
  }
  
  /// 모든 데이터 삭제
  Future<void> clearAllData() async {
    try {
      // 1. 모든 알림 취소
      await _notification.cancelAllNotifications();
      
      // 2. 데이터베이스 초기화
      await _db.clearAllData();
      
      // 3. 리스트 새로고침
      await loadFoods();
    } catch (e) {
      _error = '데이터 삭제 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 통계 정보 조회
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _db.getStatistics();
    } catch (e) {
      _error = '통계 조회 중 오류가 발생했습니다: $e';
      notifyListeners();
      return {};
    }
  }
}

