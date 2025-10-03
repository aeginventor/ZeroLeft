import 'package:intl/intl.dart';

/// 날짜 관련 유틸리티 함수
class DateUtils {
  /// 한국어 날짜 포맷터 (2025년 10월 3일)
  static final DateFormat koreanDateFormat = DateFormat('yyyy년 M월 d일', 'ko_KR');
  
  /// 짧은 날짜 포맷터 (10/03)
  static final DateFormat shortDateFormat = DateFormat('MM/dd');
  
  /// 요일 포함 포맷터 (10/03 (금))
  static final DateFormat dateWithDayFormat = DateFormat('MM/dd (E)', 'ko_KR');
  
  /// ISO 8601 포맷터 (2025-10-03)
  static final DateFormat isoDateFormat = DateFormat('yyyy-MM-dd');
  
  /// 시간 포함 포맷터 (2025년 10월 3일 오후 3:30)
  static final DateFormat dateTimeFormat = DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR');
  
  /// 날짜를 한국어 형식으로 포맷팅
  /// 
  /// 예: 2025년 10월 3일
  static String formatKorean(DateTime date) {
    return koreanDateFormat.format(date);
  }
  
  /// 날짜를 짧은 형식으로 포맷팅
  /// 
  /// 예: 10/03
  static String formatShort(DateTime date) {
    return shortDateFormat.format(date);
  }
  
  /// 날짜를 요일 포함 형식으로 포맷팅
  /// 
  /// 예: 10/03 (금)
  static String formatWithDay(DateTime date) {
    return dateWithDayFormat.format(date);
  }
  
  /// 날짜를 ISO 형식으로 포맷팅
  /// 
  /// 예: 2025-10-03
  static String formatISO(DateTime date) {
    return isoDateFormat.format(date);
  }
  
  /// 날짜와 시간을 포맷팅
  /// 
  /// 예: 2025년 10월 3일 오후 3:30
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }
  
  /// 상대적 날짜 표시 (오늘, 어제, 내일 등)
  /// 
  /// 예: "오늘", "내일", "어제", "3일 전", "5일 후"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) return '오늘';
    if (difference == 1) return '내일';
    if (difference == -1) return '어제';
    if (difference == 2) return '모레';
    if (difference > 0) return '$difference일 후';
    return '${-difference}일 전';
  }
  
  /// 두 날짜 사이의 일수 계산
  /// 
  /// 시간을 제외하고 순수 날짜만 비교
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    
    return toDate.difference(fromDate).inDays;
  }
  
  /// 유통기한까지 남은 일수 계산
  /// 
  /// 음수: 만료됨
  /// 0: 오늘까지
  /// 양수: N일 남음
  static int calculateRemainingDays(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    
    return expiry.difference(today).inDays;
  }
  
  /// 알림 발송 날짜 계산
  /// 
  /// 유통기한 - notificationDays
  static DateTime calculateNotificationDate(
    DateTime expiryDate,
    int notificationDays,
  ) {
    return expiryDate.subtract(Duration(days: notificationDays));
  }
  
  /// 날짜가 오늘인지 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  
  /// 날짜가 과거인지 확인
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return targetDate.isBefore(today);
  }
  
  /// 날짜가 미래인지 확인
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return targetDate.isAfter(today);
  }
  
  /// 같은 날짜인지 확인
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  /// 오늘 날짜의 시작 시간 (00:00:00)
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// 오늘 날짜의 끝 시간 (23:59:59)
  static DateTime get todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }
  
  /// N일 후 날짜 계산
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }
  
  /// N일 전 날짜 계산
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }
  
  /// 이번 주의 시작일 (월요일)
  static DateTime getWeekStart([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final weekday = targetDate.weekday;
    return subtractDays(targetDate, weekday - 1);
  }
  
  /// 이번 주의 마지막일 (일요일)
  static DateTime getWeekEnd([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final weekday = targetDate.weekday;
    return addDays(targetDate, 7 - weekday);
  }
  
  /// 이번 달의 시작일
  static DateTime getMonthStart([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return DateTime(targetDate.year, targetDate.month, 1);
  }
  
  /// 이번 달의 마지막일
  static DateTime getMonthEnd([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return DateTime(targetDate.year, targetDate.month + 1, 0);
  }
  
  /// 날짜 범위 생성 (시작일부터 종료일까지)
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = addDays(current, 1);
    }
    
    return dates;
  }
  
  /// 유통기한 임박도 계산 (0.0 ~ 1.0)
  /// 
  /// 0.0: 구매일
  /// 1.0: 유통기한
  /// >1.0: 만료
  static double calculateUrgency(
    DateTime purchaseDate,
    DateTime expiryDate,
  ) {
    final now = DateTime.now();
    final totalDays = daysBetween(purchaseDate, expiryDate);
    final elapsedDays = daysBetween(purchaseDate, now);
    
    if (totalDays == 0) return 1.0;
    
    final urgency = elapsedDays / totalDays;
    return urgency.clamp(0.0, 2.0); // 최대 2.0 (만료 후도 표시)
  }
  
  /// 날짜 문자열 파싱 (안전)
  /// 
  /// 실패 시 null 반환
  static DateTime? tryParse(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// 사용자 입력 날짜 파싱 (여러 형식 지원)
  /// 
  /// 예: "2025-10-03", "20251003", "2025/10/03"
  static DateTime? parseUserInput(String input) {
    // 공백 제거
    final cleaned = input.trim().replaceAll(' ', '');
    
    // 다양한 구분자 제거 후 숫자만 추출
    final numbersOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    
    // YYYYMMDD 형식 (8자리)
    if (numbersOnly.length == 8) {
      try {
        final year = int.parse(numbersOnly.substring(0, 4));
        final month = int.parse(numbersOnly.substring(4, 6));
        final day = int.parse(numbersOnly.substring(6, 8));
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    
    // 표준 형식 파싱 시도
    return tryParse(cleaned);
  }
  
  /// 날짜 검증 (유효한 날짜인지 확인)
  static bool isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;
    
    // 월별 최대 일수
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return day <= daysInMonth;
  }
  
  /// 유통기한이 구매일보다 이후인지 검증
  static bool isValidExpiryDate(DateTime purchaseDate, DateTime expiryDate) {
    final purchase = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    
    return expiry.isAfter(purchase) || expiry.isAtSameMomentAs(purchase);
  }
  
  /// 기간 표시 (N일, N주, N개월)
  /// 
  /// 예: "3일", "2주", "1개월"
  static String formatDuration(int days) {
    if (days == 0) return '오늘';
    if (days == 1) return '1일';
    if (days < 7) return '$days일';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '$weeks주';
    }
    if (days < 365) {
      final months = (days / 30).round();
      return '$months개월';
    }
    final years = (days / 365).round();
    return '$years년';
  }
  
  /// 시간 경과 표시 (방금, N분 전, N시간 전)
  /// 
  /// 예: "방금", "3분 전", "2시간 전", "어제"
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) return '방금';
    if (difference.inMinutes < 60) return '${difference.inMinutes}분 전';
    if (difference.inHours < 24) return '${difference.inHours}시간 전';
    if (difference.inDays == 1) return '어제';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    if (difference.inDays < 30) return '${(difference.inDays / 7).round()}주 전';
    if (difference.inDays < 365) return '${(difference.inDays / 30).round()}개월 전';
    return '${(difference.inDays / 365).round()}년 전';
  }
}

