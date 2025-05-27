import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/photo_model.dart';

/// 데이터베이스 헬퍼 클래스
class DBHelper {
  /// 싱글톤 인스턴스
  static final DBHelper instance = DBHelper._internal();

  /// 내부 생성자
  DBHelper._internal();

  /// 데이터베이스 인스턴스
  Database? _database;

  /// 데이터베이스 가져오기 (필요시 초기화)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'snaporia.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  /// 데이터베이스 테이블 생성
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL,
        date_taken TEXT,
        location TEXT,
        color_hex TEXT,
        metadata TEXT
      )
    ''');
  }

  /// 데이터베이스에 사진이 있는지 확인
  Future<bool> hasPhotos() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// 사진 목록 가져오기
  Future<List<PhotoModel>> getPhotos({
    int offset = 0,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    String? locationKeyword,
    String? colorKeyword,
  }) async {
    final db = await database;

    String query = 'SELECT * FROM photos WHERE 1=1';
    final List<dynamic> args = [];

    // 날짜 필터 적용
    if (startDate != null && endDate != null) {
      query += ' AND date_taken BETWEEN ? AND ?';
      args.add(startDate.toIso8601String());
      args.add(endDate.toIso8601String());
    }

    // 위치 필터 적용
    if (locationKeyword != null && locationKeyword.isNotEmpty) {
      query += ' AND location LIKE ?';
      args.add('%$locationKeyword%');
    }

    // 색상 필터 적용
    if (colorKeyword != null && colorKeyword.isNotEmpty) {
      query += ' AND color_hex LIKE ?';
      args.add('%$colorKeyword%');
    }

    // 날짜 순으로 정렬하고 페이징 적용
    query += ' ORDER BY date_taken DESC LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(offset);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return maps.map((map) => PhotoModel.fromMap(map)).toList();
  }

  /// 사진 추가
  Future<int> insertPhoto(PhotoModel photo) async {
    final db = await database;
    return await db.insert('photos', photo.toMap());
  }

  /// 사진 업데이트
  Future<int> updatePhoto(PhotoModel photo) async {
    final db = await database;
    return await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  /// 사진 삭제
  Future<int> deletePhoto(int id) async {
    final db = await database;
    return await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
