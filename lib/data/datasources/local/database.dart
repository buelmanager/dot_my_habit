import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../../core/logger.dart';

/// 데이터베이스 테이블 및 컬럼 상수
class DatabaseConstants {
  // 프라이빗 생성자 - 인스턴스화 방지
  DatabaseConstants._();

  // 데이터베이스 파일 이름
  static const String databaseName = 'dot_habit.db';

  // 데이터베이스 버전
  static const int databaseVersion = 1;

  // 습관 테이블
  static const String habitsTable = 'habits';

  // 습관 로그 테이블 (특정 날짜의 습관 완료 내역)
  static const String habitLogsTable = 'habit_logs';

  // 설정 테이블
  static const String settingsTable = 'settings';
}

/// 앱 데이터베이스 클래스
class AppDatabase {
  // 프라이빗 생성자 - 인스턴스화 방지
  AppDatabase._();

  static Database? _database;

  /// 데이터베이스 인스턴스 가져오기
  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initialize();
    return _database!;
  }

  /// 데이터베이스 초기화
  static Future<Database> initialize() async {
    logger.info('데이터베이스 초기화 시작');

    // 데이터베이스 경로 가져오기
    String path = join(await getDatabasesPath(), DatabaseConstants.databaseName);
    logger.error('데이터베이스 경로: $path');

    // 데이터베이스 열기
    var db = await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    logger.info('데이터베이스 초기화 완료');
    return db;
  }

  /// 데이터베이스 생성
  static Future<void> _createDatabase(Database db, int version) async {
    logger.info('새 데이터베이스 생성 (버전: $version)');

    // 습관 테이블 생성
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.habitsTable} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      isEmphasized INTEGER NOT NULL DEFAULT 0,
      streak INTEGER NOT NULL DEFAULT 0,
      completedAt TEXT,
      reminderTime TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
    ''');

    // 습관 로그 테이블 생성
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.habitLogsTable} (
      id TEXT PRIMARY KEY,
      habitId TEXT NOT NULL,
      date TEXT NOT NULL,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      completedAt TEXT,
      FOREIGN KEY (habitId) REFERENCES ${DatabaseConstants.habitsTable}(id)
    )
    ''');

    // 설정 테이블 생성
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.settingsTable} (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
    ''');

    // 인덱스 생성
    await db.execute(
      'CREATE INDEX habit_logs_habit_id_idx ON ${DatabaseConstants.habitLogsTable}(habitId)',
    );
    await db.execute(
      'CREATE INDEX habit_logs_date_idx ON ${DatabaseConstants.habitLogsTable}(date)',
    );

    logger.info('데이터베이스 테이블 생성 완료');
  }

  /// 데이터베이스 업그레이드
  static Future<void> _upgradeDatabase(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    logger.info('데이터베이스 업그레이드: $oldVersion -> $newVersion');

    // 버전 별 마이그레이션 코드
    if (oldVersion < 2) {
      // 버전 2에 추가된 컬럼이나 테이블 변경사항
      // 예: await db.execute('ALTER TABLE ${DatabaseConstants.habitsTable} ADD COLUMN newColumn TEXT');
    }

    // 다른 버전 업그레이드에 대한 처리 추가 가능
  }

  /// 데이터베이스 초기화 (테스트용)
  static Future<void> deleteDatabase() async {
    final dbPath = join(await getDatabasesPath(), DatabaseConstants.databaseName);
    logger.warning('데이터베이스 삭제: $dbPath');
    await databaseFactory.deleteDatabase(dbPath);
    _database = null;
  }
}