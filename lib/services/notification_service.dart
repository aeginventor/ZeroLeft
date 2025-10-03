import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../models/food_item.dart';
import '../utils/constants.dart';

/// 로컬 알림 서비스
/// 
/// 유통기한 임박 시 푸시 알림을 발송합니다.
/// flutter_local_notifications 패키지 사용
class NotificationService {
  // 싱글톤 인스턴스
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();
  
  // 알림 플러그인 인스턴스
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  // 초기화 완료 여부
  bool _isInitialized = false;
  
  // 알림 클릭 콜백 (앱에서 설정)
  Function(String?)? onNotificationTapped;
  
  /// 알림 서비스 초기화
  /// 
  /// 앱 시작 시 main()에서 호출
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 1. timezone 초기화 (알림 스케줄링에 필수)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // 한국 시간대
    
    // 2. Android 알림 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 3. iOS 알림 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // 4. 초기화 설정 통합
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // 5. 플러그인 초기화
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // 6. Android 알림 채널 생성 (중요도 높음)
    await _createAndroidNotificationChannel();
    
    // 7. 권한 요청
    await requestPermissions();
    
    _isInitialized = true;
  }
  
  /// Android 알림 채널 생성
  /// 
  /// Android 8.0 이상에서 필수
  Future<void> _createAndroidNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'zeroleft_channel', // 채널 ID
      '유통기한 알림', // 채널 이름
      description: '식품 유통기한 임박 알림', // 채널 설명
      importance: Importance.high, // 중요도 높음 (헤드업 알림)
      playSound: true,
      enableVibration: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  /// 알림 권한 요청
  /// 
  /// Android 13+ 에서 런타임 권한 필요
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13 이상 알림 권한
      final notificationStatus = await Permission.notification.request();
      
      // Android 12+ 정확한 알림 권한
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      
      return notificationStatus.isGranted && exactAlarmStatus.isGranted;
    } else if (Platform.isIOS) {
      // iOS 알림 권한
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }
  
  /// 알림 클릭 시 호출되는 콜백
  void _onNotificationResponse(NotificationResponse response) {
    // 페이로드에서 식품 ID 추출
    final payload = response.payload;
    
    // 외부에서 설정한 콜백 호출 (식품 상세 화면으로 이동)
    if (onNotificationTapped != null && payload != null) {
      onNotificationTapped!(payload);
    }
  }
  
  /// 식품 알림 스케줄링
  /// 
  /// 유통기한 - notificationDays 날짜에 알림 발송
  Future<void> scheduleNotification(FoodItem food) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // 알림 발송 날짜 계산
    final notificationDate = food.notificationDate;
    final now = DateTime.now();
    
    // 이미 지난 날짜면 알림 스케줄링하지 않음
    if (notificationDate.isBefore(now)) {
      return;
    }
    
    // 알림 ID (식품 ID의 해시코드 사용)
    final notificationId = food.id.hashCode;
    
    // 알림 제목 및 내용
    final title = AppConstants.getNotificationTitle(
      food.name,
      food.remainingDays,
    );
    const body = AppConstants.notificationBody;
    
    // Android 알림 설정
    const androidDetails = AndroidNotificationDetails(
      'zeroleft_channel',
      '유통기한 알림',
      channelDescription: '식품 유통기한 임박 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    // iOS 알림 설정
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // 플랫폼별 알림 설정 통합
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // timezone 변환 (로컬 시간대)
    final scheduledDate = tz.TZDateTime.from(notificationDate, tz.local);
    
    // 알림 스케줄링
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 정확한 시간 보장
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: food.id, // 알림 클릭 시 전달될 데이터
    );
  }
  
  /// 여러 식품 알림 일괄 스케줄링
  Future<void> scheduleMultipleNotifications(List<FoodItem> foods) async {
    for (final food in foods) {
      await scheduleNotification(food);
    }
  }
  
  /// 특정 식품 알림 취소
  /// 
  /// 식품을 소비하거나 삭제할 때 호출
  Future<void> cancelNotification(String foodId) async {
    final notificationId = foodId.hashCode;
    await _notifications.cancel(notificationId);
  }
  
  /// 여러 식품 알림 일괄 취소
  Future<void> cancelMultipleNotifications(List<String> foodIds) async {
    for (final foodId in foodIds) {
      await cancelNotification(foodId);
    }
  }
  
  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  /// 즉시 알림 발송 (테스트용)
  /// 
  /// 설정 화면에서 "알림 테스트" 버튼에 사용
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    const androidDetails = AndroidNotificationDetails(
      'zeroleft_channel',
      '유통기한 알림',
      channelDescription: '식품 유통기한 임박 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0, // 테스트 알림 ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  /// 예약된 모든 알림 조회
  /// 
  /// 디버깅 또는 설정 화면에서 사용
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
  
  /// 예약된 알림 개수 조회
  Future<int> getPendingNotificationCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }
  
  /// 특정 식품의 알림이 예약되어 있는지 확인
  Future<bool> isNotificationScheduled(String foodId) async {
    final notificationId = foodId.hashCode;
    final pending = await getPendingNotifications();
    return pending.any((req) => req.id == notificationId);
  }
  
  /// 알림 업데이트 (식품 정보 변경 시)
  /// 
  /// 기존 알림 취소 후 새로 스케줄링
  Future<void> updateNotification(FoodItem food) async {
    await cancelNotification(food.id);
    await scheduleNotification(food);
  }
  
  /// 반복 알림 스케줄링 (옵션 기능)
  /// 
  /// 설정에서 "알림 반복" 활성화 시 사용
  /// 유통기한 당일까지 매일 알림
  Future<void> scheduleRepeatingNotifications(FoodItem food) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final notificationDate = food.notificationDate;
    final expiryDate = food.expiryDate;
    final now = DateTime.now();
    
    // 시작일부터 유통기한까지 날짜 목록 생성
    final dates = <DateTime>[];
    var currentDate = notificationDate;
    
    while (currentDate.isBefore(expiryDate) || 
           currentDate.isAtSameMomentAs(expiryDate)) {
      if (currentDate.isAfter(now)) {
        dates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // 각 날짜마다 알림 스케줄링
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final remainingDays = expiryDate.difference(date).inDays;
      
      final title = AppConstants.getNotificationTitle(
        food.name,
        remainingDays,
      );
      
      const androidDetails = AndroidNotificationDetails(
        'zeroleft_channel',
        '유통기한 알림',
        channelDescription: '식품 유통기한 임박 알림',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final scheduledDate = tz.TZDateTime.from(date, tz.local);
      
      // 고유 ID: 원본 ID + 인덱스
      final notificationId = food.id.hashCode + i;
      
      await _notifications.zonedSchedule(
        notificationId,
        title,
        AppConstants.notificationBody,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: food.id,
      );
    }
  }
}

