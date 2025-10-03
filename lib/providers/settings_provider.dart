import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// 설정 관리 Provider
/// 
/// 앱 설정을 관리하고 변경사항을 SharedPreferences에 저장합니다.
class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  
  AppSettings _settings = AppSettings();
  bool _isLoading = false;
  
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  
  /// 설정 로드
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _settings = await _settingsService.loadSettings();
    } catch (e) {
      // 로드 실패 시 기본값 사용
      _settings = AppSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 기본 알림 시점 변경
  Future<void> updateDefaultNotificationDays(int days) async {
    _settings = _settings.copyWith(defaultNotificationDays: days);
    await _settingsService.saveDefaultNotificationDays(days);
    notifyListeners();
  }
  
  /// 알림 반복 설정 변경
  Future<void> updateNotificationRepeat(bool repeat) async {
    _settings = _settings.copyWith(notificationRepeat: repeat);
    await _settingsService.saveNotificationRepeat(repeat);
    notifyListeners();
  }
  
  /// 최근 항목 보관 기간 변경
  Future<void> updateRecentItemsRetentionDays(int days) async {
    _settings = _settings.copyWith(recentItemsRetentionDays: days);
    await _settingsService.saveRecentItemsRetentionDays(days);
    notifyListeners();
  }
  
  /// 정렬 기준 변경
  Future<void> updateSortBy(String sortBy) async {
    _settings = _settings.copyWith(sortBy: sortBy);
    await _settingsService.saveSortBy(sortBy);
    notifyListeners();
  }
  
  /// 소비 완료 항목 표시 여부 변경
  Future<void> updateShowConsumedItems(bool show) async {
    _settings = _settings.copyWith(showConsumedItems: show);
    await _settingsService.saveShowConsumedItems(show);
    notifyListeners();
  }
  
  /// 설정 초기화
  Future<void> resetSettings() async {
    await _settingsService.resetSettings();
    _settings = AppSettings();
    notifyListeners();
  }
}

