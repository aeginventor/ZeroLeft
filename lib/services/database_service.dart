import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/app_settings.dart';

/// 데이터베이스 서비스 (싱글톤 패턴)
/// 
/// SQLite 데이터베이스를 관리하고 CRUD 작업을 제공합니다.
/// 앱 전체에서 하나의 인스턴스만 사용됩니다.
class DatabaseService {
  // 싱글톤 인스턴스
  static final DatabaseService instance = DatabaseService._internal();
  
  // 데이터베이스 인스턴스
  static Database? _database;
  
  // private 생성자
  DatabaseService._internal();
  
  // 데이터베이스 버전
  static const int _databaseVersion = 1;
  static const String _databaseName = 'zeroleft.db';
  
  /// 데이터베이스 인스턴스 가져오기 (없으면 초기화)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    // 데이터베이스 경로 설정
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    
    // 데이터베이스 열기 (없으면 생성)
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// 데이터베이스 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    // 1. foods 테이블 생성 (식품 정보)
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        notification_days INTEGER DEFAULT 3,
        is_consumed INTEGER DEFAULT 0,
        consumed_date TEXT,
        is_favorite INTEGER DEFAULT 0,
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    // 2. recent_items 테이블 생성 (최근 입력 항목)
    await db.execute('''
      CREATE TABLE recent_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        default_shelf_life INTEGER,
        usage_count INTEGER DEFAULT 1,
        last_used TEXT NOT NULL
      )
    ''');
    
    // 3. favorites 테이블 생성 (즐겨찾기)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        default_shelf_life INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    
    // 인덱스 생성 (성능 최적화)
    await db.execute('CREATE INDEX idx_foods_expiry ON foods(expiry_date)');
    await db.execute('CREATE INDEX idx_foods_consumed ON foods(is_consumed)');
    await db.execute('CREATE INDEX idx_recent_last_used ON recent_items(last_used DESC)');
  }
  
  /// 데이터베이스 업그레이드 (버전 변경 시)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 추후 스키마 변경 시 마이그레이션 로직 추가
  }
  
  // ==================== foods 테이블 CRUD ====================
  
  /// 식품 추가
  Future<void> insertFood(FoodItem food) async {
    final db = await database;
    await db.insert(
      'foods',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 모든 식품 조회 (소비 여부 구분)
  Future<List<FoodItem>> getAllFoods({bool? isConsumed}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps;
    
    if (isConsumed != null) {
      // 소비 여부로 필터링
      maps = await db.query(
        'foods',
        where: 'is_consumed = ?',
        whereArgs: [isConsumed ? 1 : 0],
        orderBy: 'expiry_date ASC', // 유통기한 오름차순 (급한 순)
      );
    } else {
      // 전체 조회
      maps = await db.query(
        'foods',
        orderBy: 'expiry_date ASC',
      );
    }
    
    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }
  
  /// 남은 음식만 조회 (보관 중)
  Future<List<FoodItem>> getRemainingFoods() async {
    return await getAllFoods(isConsumed: false);
  }
  
  /// 먹은 음식만 조회 (소비 완료)
  Future<List<FoodItem>> getConsumedFoods() async {
    return await getAllFoods(isConsumed: true);
  }
  
  /// ID로 식품 조회
  Future<FoodItem?> getFoodById(String id) async {
    final db = await database;
    final maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FoodItem.fromMap(maps.first);
  }
  
  /// 식품 정보 수정
  Future<void> updateFood(FoodItem food) async {
    final db = await database;
    await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }
  
  /// 식품 삭제
  Future<void> deleteFood(String id) async {
    final db = await database;
    await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 식품을 소비 완료로 표시
  Future<void> markAsConsumed(String id) async {
    final db = await database;
    await db.update(
      'foods',
      {
        'is_consumed': 1,
        'consumed_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 식품을 다시 보관 중으로 변경 (실수로 체크한 경우)
  Future<void> markAsUnconsumed(String id) async {
    final db = await database;
    await db.update(
      'foods',
      {
        'is_consumed': 0,
        'consumed_date': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String id) async {
    final food = await getFoodById(id);
    if (food == null) return;
    
    final db = await database;
    await db.update(
      'foods',
      {'is_favorite': food.isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 만료된 식품 조회
  Future<List<FoodItem>> getExpiredFoods() async {
    final allFoods = await getRemainingFoods();
    return allFoods.where((food) => food.isExpired).toList();
  }
  
  /// 임박한 식품 조회 (2일 이내)
  Future<List<FoodItem>> getExpiringSoonFoods() async {
    final allFoods = await getRemainingFoods();
    return allFoods.where((food) => food.isExpiringSoon).toList();
  }
  
  // ==================== recent_items 테이블 ====================
  
  /// 최근 입력 항목 추가 또는 업데이트
  Future<void> addOrUpdateRecentItem(RecentItem item) async {
    final db = await database;
    
    // 기존 항목 확인
    final existing = await db.query(
      'recent_items',
      where: 'name = ?',
      whereArgs: [item.name],
    );
    
    if (existing.isNotEmpty) {
      // 기존 항목 → usage_count 증가
      final existingItem = RecentItem.fromMap(existing.first);
      final updated = existingItem.incrementUsage();
      await db.update(
        'recent_items',
        updated.toMap(),
        where: 'name = ?',
        whereArgs: [item.name],
      );
    } else {
      // 신규 항목 → 삽입
      await db.insert('recent_items', item.toMap());
    }
  }
  
  /// 최근 입력 항목 조회 (사용 빈도순)
  Future<List<RecentItem>> getRecentItems({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'recent_items',
      orderBy: 'usage_count DESC, last_used DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => RecentItem.fromMap(maps[i]));
  }
  
  /// 검색어로 최근 항목 검색
  Future<List<RecentItem>> searchRecentItems(String query) async {
    final db = await database;
    final maps = await db.query(
      'recent_items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'usage_count DESC',
      limit: 10,
    );
    
    return List.generate(maps.length, (i) => RecentItem.fromMap(maps[i]));
  }
  
  /// 오래된 최근 항목 삭제
  Future<void> cleanOldRecentItems(int retentionDays) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    await db.delete(
      'recent_items',
      where: 'last_used < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  // ==================== favorites 테이블 ====================
  
  /// 즐겨찾기 추가
  Future<void> addFavorite(FavoriteItem item) async {
    final db = await database;
    await db.insert(
      'favorites',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // 중복 시 무시
    );
  }
  
  /// 즐겨찾기 제거
  Future<void> removeFavorite(String name) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'name = ?',
      whereArgs: [name],
    );
  }
  
  /// 모든 즐겨찾기 조회
  Future<List<FavoriteItem>> getAllFavorites() async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) => FavoriteItem.fromMap(maps[i]));
  }
  
  /// 즐겨찾기 여부 확인
  Future<bool> isFavorite(String name) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    return result.isNotEmpty;
  }
  
  // ==================== 유틸리티 ====================
  
  /// 모든 데이터 삭제 (데이터 초기화)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('foods');
    await db.delete('recent_items');
    await db.delete('favorites');
  }
  
  /// 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
  
  /// 통계 정보 조회
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalFoods = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM foods WHERE is_consumed = 0'),
    ) ?? 0;
    
    final consumedFoods = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM foods WHERE is_consumed = 1'),
    ) ?? 0;
    
    final expiredFoods = (await getExpiredFoods()).length;
    
    final favoritesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM favorites'),
    ) ?? 0;
    
    return {
      'total': totalFoods,
      'consumed': consumedFoods,
      'expired': expiredFoods,
      'favorites': favoritesCount,
    };
  }
}

