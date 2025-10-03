import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

/// 설정 관리 서비스
/// 
/// SharedPreferences를 사용하여 앱 설정을 영구 저장합니다.
class SettingsService {
  // SharedPreferences 키 상수
  static const String _keyDefaultNotificationDays = 'default_notification_days';
  static const String _keyNotificationRepeat = 'notification_repeat';
  static const String _keyRecentItemsRetentionDays = 'recent_items_retention_days';
  static const String _keyShowConsumedItems = 'show_consumed_items';
  static const String _keySortBy = 'sort_by';
  static const String _keyFirstLaunch = 'first_launch';
  
  /// 앱 설정 불러오기
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return AppSettings(
      defaultNotificationDays: prefs.getInt(_keyDefaultNotificationDays) ?? 
          AppConstants.defaultNotificationDays,
      notificationRepeat: prefs.getBool(_keyNotificationRepeat) ?? 
          AppConstants.defaultNotificationRepeat,
      recentItemsRetentionDays: prefs.getInt(_keyRecentItemsRetentionDays) ?? 
          AppConstants.defaultRecentItemsRetentionDays,
      showConsumedItems: prefs.getBool(_keyShowConsumedItems) ?? true,
      sortBy: prefs.getString(_keySortBy) ?? 'expiry',
    );
  }
  
  /// 앱 설정 저장
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_keyDefaultNotificationDays, settings.defaultNotificationDays);
    await prefs.setBool(_keyNotificationRepeat, settings.notificationRepeat);
    await prefs.setInt(_keyRecentItemsRetentionDays, settings.recentItemsRetentionDays);
    await prefs.setBool(_keyShowConsumedItems, settings.showConsumedItems);
    await prefs.setString(_keySortBy, settings.sortBy);
  }
  
  // ==================== 개별 설정 저장 메서드 ====================
  
  /// 기본 알림 시점 저장
  Future<void> saveDefaultNotificationDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultNotificationDays, days);
  }
  
  /// 기본 알림 시점 불러오기
  Future<int> getDefaultNotificationDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultNotificationDays) ?? 
        AppConstants.defaultNotificationDays;
  }
  
  /// 알림 반복 설정 저장
  Future<void> saveNotificationRepeat(bool repeat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationRepeat, repeat);
  }
  
  /// 알림 반복 설정 불러오기
  Future<bool> getNotificationRepeat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationRepeat) ?? 
        AppConstants.defaultNotificationRepeat;
  }
  
  /// 최근 항목 보관 기간 저장
  Future<void> saveRecentItemsRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRecentItemsRetentionDays, days);
  }
  
  /// 최근 항목 보관 기간 불러오기
  Future<int> getRecentItemsRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRecentItemsRetentionDays) ?? 
        AppConstants.defaultRecentItemsRetentionDays;
  }
  
  /// 정렬 기준 저장
  Future<void> saveSortBy(String sortBy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySortBy, sortBy);
  }
  
  /// 정렬 기준 불러오기
  Future<String> getSortBy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySortBy) ?? 'expiry';
  }
  
  /// 소비 완료 항목 표시 여부 저장
  Future<void> saveShowConsumedItems(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowConsumedItems, show);
  }
  
  /// 소비 완료 항목 표시 여부 불러오기
  Future<bool> getShowConsumedItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowConsumedItems) ?? true;
  }
  
  // ==================== 앱 초기 실행 체크 ====================
  
  /// 앱이 처음 실행되는지 확인
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }
  
  /// 첫 실행 완료 표시
  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }
  
  // ==================== 설정 초기화 ====================
  
  /// 모든 설정 초기화 (기본값으로 복원)
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_keyDefaultNotificationDays);
    await prefs.remove(_keyNotificationRepeat);
    await prefs.remove(_keyRecentItemsRetentionDays);
    await prefs.remove(_keyShowConsumedItems);
    await prefs.remove(_keySortBy);
    // _keyFirstLaunch는 유지
  }
  
  /// 모든 데이터 삭제 (첫 실행 상태 포함)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

