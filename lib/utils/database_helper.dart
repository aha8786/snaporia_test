import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/color_utils.dart';
// import '../model/color_model.dart';  // 사용하지 않는 import 주석 처리
import '../model/photo_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
// import 'dart:math';

/// 데이터베이스 헬퍼 클래스
class DatabaseHelper {
  /// 싱글톤 인스턴스
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  /// 내부 생성자
  DatabaseHelper._internal();

  /// 스캔 진행률
  final ValueNotifier<double> scanProgress = ValueNotifier<double>(0.0);

  /// 현재 스캔 중인지 여부
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 처리된 사진 수
  int processedCount = 0;

  /// 전체 사진 수
  int totalCount = 0;

  /// 배치 크기
  final int _batchSize = 150; // 메모리와 성능 사이 최적 밸런스

  /// 소배치 크기 (병렬처리용)
  // final int _smallBatchSize = 50;  // 사용하지 않는 필드 주석 처리

  /// 최대 재시도 횟수
  // final int _maxRetries = 3;  // 사용하지 않는 필드 주석 처리

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
    final String path = join(await getDatabasesPath(), 'snaporia.db');

    return await openDatabase(
      path,
      version: 5, // 버전 3에서 4로 업데이트
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            taken_at INTEGER,
            date_taken TEXT,
            location TEXT,
            device TEXT,
            color TEXT,
            hue TEXT, -- 대표 색상 이름들을 저장하는 TEXT 타입
            latitude REAL,
            longitude REAL,
            device_model TEXT,
            file_size INTEGER,
            mime_type TEXT,
            width INTEGER,
            height INTEGER, 
            labels TEXT,
            analyzed INTEGER DEFAULT 0
          )
        ''');

        // taken_at 컬럼에 인덱스 생성
        await db.execute(
          'CREATE INDEX idx_taken_at ON photos(taken_at)',
        );

        // hue 컬럼에 인덱스 생성
        await db.execute(
          'CREATE INDEX idx_hue ON photos(hue)',
        );

        // labels 컬럼에 인덱스 생성
        await db.execute(
          'CREATE INDEX idx_labels ON photos(labels)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // version 1에서 2로 업그레이드: hue 컬럼 추가
          await db.execute('ALTER TABLE photos ADD COLUMN hue TEXT');

          // 기존 데이터의 색상 코드에서 hue 값 계산하여 업데이트
          final List<Map<String, dynamic>> photos = await db.query('photos');

          for (final photo in photos) {
            if (photo['color'] != null) {
              try {
                final String colorHex = photo['color'] as String;
                final List<String> colorNames =
                    ColorUtils.getRepresentativeColors(colorHex);
                final String hueNames = colorNames.join(',');

                await db.update(
                  'photos',
                  {'hue': hueNames},
                  where: 'id = ?',
                  whereArgs: [photo['id']],
                );
              } catch (e) {
                debugPrint('Hue 업데이트 실패 (ID: ${photo['id']}): $e');
              }
            }
          }

          // hue 컬럼에 인덱스 생성
          await db.execute(
            'CREATE INDEX idx_hue ON photos(hue)',
          );
        }

        if (oldVersion < 3) {
          try {
            // 기존 데이터를 백업 테이블에 저장
            await db
                .execute('CREATE TABLE photos_backup AS SELECT * FROM photos');
            debugPrint('테이블 백업 완료: photos -> photos_backup');

            // version 2에서 3으로 업그레이드: hue 컬럼 데이터 재계산
            final List<Map<String, dynamic>> photos = await db.query('photos');
            int updatedCount = 0;
            int errorCount = 0;

            for (final photo in photos) {
              if (photo['color'] != null) {
                try {
                  final String colorHex = photo['color'] as String;
                  final List<String> colorNames =
                      ColorUtils.getRepresentativeColors(colorHex);

                  // 색상 이름들을 쉼표로 구분해서 저장
                  final String hueNames = colorNames.join(',');

                  await db.update(
                    'photos',
                    {'hue': hueNames},
                    where: 'id = ?',
                    whereArgs: [photo['id']],
                  );
                  updatedCount++;
                } catch (e) {
                  errorCount++;
                  debugPrint('Hue 업데이트 실패 (ID: ${photo['id']}): $e');
                }
              }
            }

            debugPrint(
                'Hue 값 업데이트 완료: 총 ${photos.length}개 중 $updatedCount개 성공, $errorCount개 실패');

            // 만약 모든 업데이트가 실패한 경우, 백업에서 복원
            if (updatedCount == 0 && photos.isNotEmpty) {
              debugPrint('경고: 모든 업데이트가 실패했습니다. 백업에서 복원합니다.');
              await db.execute('DROP TABLE photos');
              await db.execute(
                  'CREATE TABLE photos AS SELECT * FROM photos_backup');

              // 마이그레이션 취소 (버전 2로 유지)
              // 이 경우 앱 재시작 시 다시 마이그레이션 시도
              throw Exception('Hue 값 업데이트 실패로 백업에서 복원');
            }

            // 백업 테이블 삭제 (성공 시에만)
            if (errorCount == 0) {
              await db.execute('DROP TABLE IF EXISTS photos_backup');
              debugPrint('백업 테이블 삭제 완료');
            }
          } catch (e) {
            debugPrint('버전 업그레이드 오류: $e');
            // 백업 테이블이 있으면 복원 시도
            try {
              final List<Map<String, dynamic>> checkBackup = await db.rawQuery(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name='photos_backup'");

              if (checkBackup.isNotEmpty) {
                await db.execute('DROP TABLE IF EXISTS photos');
                await db.execute(
                    'CREATE TABLE photos AS SELECT * FROM photos_backup');
                debugPrint('DB 복원 완료');
              }
            } catch (restoreError) {
              debugPrint('DB 복원 실패: $restoreError');
            }
            rethrow;
          }
        }

        if (oldVersion < 4) {
          // version 3에서 4로 업그레이드: labels 컬럼 추가
          await db.execute('ALTER TABLE photos ADD COLUMN labels TEXT');

          // labels 컬럼에 인덱스 생성
          await db.execute(
            'CREATE INDEX idx_labels ON photos(labels)',
          );
        }

        if (oldVersion < 5) {
          // version 4에서 5로 업그레이드: analyzed 컬럼 추가
          await db.execute(
              'ALTER TABLE photos ADD COLUMN analyzed INTEGER DEFAULT 0');
          // 기존 데이터에도 기본값 0이 들어가도록 업데이트
          await db
              .execute('UPDATE photos SET analyzed = 0 WHERE analyzed IS NULL');
        }
      },
    );
  }

  /// 스캔 중 여부 확인
  Future<bool> getIsScanning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_scanning') ?? false;
  }

  /// 마지막으로 스캔한 페이지 가져오기
  Future<int> getLastScannedPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_processed_page') ?? 0;
  }

  /// 총 사진 수 가져오기
  Future<int> getTotalPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_count') ?? 0;
  }

  /// 총 사진 수 저장
  Future<void> saveTotalPhotos(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_count', count);
    totalCount = count;
  }

  /// 마지막 스캔 페이지 저장
  Future<void> saveLastScannedPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_processed_page', page);
    // _lastProcessedPage = page;  // 사용하지 않는 필드 주석 처리
  }

  /// 스캔 상태 설정
  Future<void> setIsScanning(bool value) async {
    _isScanning = value;
    // 상태 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_scanning', value);
  }

  /// 스캔 상태 초기화
  Future<void> resetScanState() async {
    _isScanning = false;
    processedCount = 0;
    totalCount = 0;
    // _lastProcessedPage = 0;  // 사용하지 않는 필드 주석 처리

    // 상태 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_scanning', false);
    await prefs.setInt('last_processed_page', 0);
    await prefs.setInt('processed_count', 0);
    await prefs.setInt('total_count', 0);
  }

  /// 이전 스캔 상태 복원
  Future<bool> restoreScanState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isScanning = prefs.getBool('is_scanning') ?? false;

      if (isScanning) {
        // _lastProcessedPage = prefs.getInt('last_processed_page') ?? 0;  // 사용하지 않는 필드 주석 처리
        processedCount = prefs.getInt('processed_count') ?? 0;
        totalCount = prefs.getInt('total_count') ?? 0;

        // 진행률 복원
        if (totalCount > 0) {
          scanProgress.value = processedCount / totalCount;
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('스캔 상태 복원 실패: $e');
      return false;
    }
  }

  /// 사진 DB 초기화
  Future<void> clearPhotos() async {
    final db = await database;
    await db.delete('photos');
  }

  /// 모든 사진을 스캔하고 메타데이터를 저장합니다.
  Future<void> scanPhotosAndSaveMeta() async {
    try {
      // 이전 스캔이 중단된 경우 확인
      final isScanning = await getIsScanning();
      final lastScannedPage = await getLastScannedPage();
      int totalCount;

      // 권한 요청
      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        throw Exception('갤러리 접근 권한이 없습니다.');
      }

      // 전체 사진 수 조회 또는 복구
      if (!isScanning) {
        totalCount = await PhotoManager.getAssetCount();
        if (totalCount == 0) return;
        await saveTotalPhotos(totalCount);
      } else {
        totalCount = await getTotalPhotos();
        if (totalCount == 0) {
          // 저장된 정보가 없으면 초기화
          await resetScanState();
          totalCount = await PhotoManager.getAssetCount();
          if (totalCount == 0) return;
          await saveTotalPhotos(totalCount);
        }
      }

      // 스캔 시작 상태 저장
      await setIsScanning(true);
      scanProgress.value = 0.0;

      int processedCount = lastScannedPage * _batchSize;
      final db = await database;

      // 1. DB에 이미 저장된 (path, date_taken) 조합을 모두 가져와 Set으로 만듦
      final List<Map<String, dynamic>> existRows =
          await db.rawQuery('SELECT path, date_taken FROM photos');
      final Set<String> existKeySet =
          existRows.map((row) => '${row['path']}|${row['date_taken']}').toSet();

      // _batchSize 단위로 사진을 가져와서 처리
      for (int offset = lastScannedPage * _batchSize;
          offset < totalCount;
          offset += _batchSize) {
        // 현재 배치의 사진 목록 가져오기
        final currentPage = offset ~/ _batchSize;
        final assets = await PhotoManager.getAssetListPaged(
          page: currentPage,
          pageCount: _batchSize,
        );

        // 진행률 업데이트 (배치 시작)
        scanProgress.value = processedCount / totalCount;

        // 대표 색상 병렬 추출 (최대 4개씩 compute로)
        final colorFutures = <Future<String>>[];
        for (final asset in assets) {
          final thumbnail = await asset.thumbnailData;
          if (thumbnail == null) {
            colorFutures.add(Future.value('FFFFFF'));
          } else {
            colorFutures.add(compute(extractDominantColor, thumbnail));
          }
        }
        // 최대 4개씩 병렬로 실행
        final colors = <String>[];
        for (var i = 0; i < colorFutures.length; i += 4) {
          final batch = colorFutures.skip(i).take(4);
          final results = await Future.wait(batch);
          colors.addAll(results);
          // 4개 단위 처리마다 진행률 업데이트
          final subBatchProgress = (processedCount + i + 4) / totalCount;
          scanProgress.value = subBatchProgress > 1.0 ? 1.0 : subBatchProgress;
        }

        // 트랜잭션으로 배치 처리
        await db.transaction((txn) async {
          for (int i = 0; i < assets.length; i++) {
            final asset = assets[i];
            final file = await asset.file;
            if (file == null) continue;

            final String key =
                '${file.path}|${asset.createDateTime.toIso8601String()}';
            if (existKeySet.contains(key)) {
              // 이미 분석된 사진은 건너뜀
              continue;
            }

            // 색상 코드에서 Hue 값 계산
            final String colorHex = colors[i];
            String hueNames = '';
            try {
              // 헥스 색상 코드에서 Hue 값 계산
              final List<String> colorNames =
                  ColorUtils.getRepresentativeColors(colorHex);
              // 색상 이름들을 쉼표로 구분해서 저장 (경계에 있으면 여러 색상명 저장)
              hueNames = colorNames.join(',');
              debugPrint('색상 추출: $colorHex -> Hue: $hueNames');
            } catch (e) {
              debugPrint('Hue 계산 실패: $e');
            }

            // 디버깅: analyzed 값 출력
            print(
                '[DEBUG] insert photo: path=${file.path}, date_taken=${asset.createDateTime.toIso8601String()}, analyzed=0');
            await txn.insert(
              'photos',
              {
                'path': file.path,
                'taken_at': asset.createDateTime.millisecondsSinceEpoch,
                'date_taken': asset.createDateTime.toIso8601String(),
                'location': asset.latitude != null && asset.longitude != null
                    ? '${asset.latitude},${asset.longitude}'
                    : null,
                'latitude': asset.latitude,
                'longitude': asset.longitude,
                'device_model': null,
                'file_size': null,
                'mime_type': null,
                'width': null,
                'height': null,
                'color': colorHex,
                'hue': hueNames,
                'analyzed': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });

        // 진행률 업데이트 및 현재 페이지 저장
        processedCount += assets.length;
        scanProgress.value = processedCount / totalCount;
        await saveLastScannedPage(currentPage + 1);
      }

      // 스캔 완료
      scanProgress.value = 1.0;
      await resetScanState();

      // 디버깅: 모든 사진의 color, labels, analyzed 값을 출력
      final allPhotos = await db.query('photos');
      for (final photo in allPhotos) {
        print(
            '[DEBUG] DB 상태: id=${photo['id']}, color=${photo['color']}, labels=${photo['labels']}, analyzed=${photo['analyzed']}');
      }
    } catch (e) {
      debugPrint('사진 스캔 실패: $e');
      // 진행률은 유지하고 에러만 전파
      rethrow;
    }
  }

  /// 사진 메타데이터 일괄 저장
  Future<void> savePhotoMetadataBatch(List<Map<String, dynamic>> photos) async {
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (var photo in photos) {
        // analyzed 필드가 없으면 0으로 추가
        if (!photo.containsKey('analyzed')) {
          photo['analyzed'] = 0;
        }
        batch.insert(
          'photos',
          photo,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  /// 사진 존재 여부 확인
  Future<bool> hasPhotos() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// 사진 목록 가져오기
  Future<List<PhotoModel>> getPhotos({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? colorName,
    String? searchKeyword,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    debugPrint(
        '📂 getPhotos 호출: latitude=$latitude, longitude=$longitude, radiusKm=$radiusKm, location=$location, startDate=$startDate, endDate=$endDate, colorName=$colorName, searchKeyword=$searchKeyword, limit=$limit, offset=$offset');

    final db = await database;

    final List<String> whereConditions = [];
    final List<dynamic> whereArgs = [];

    // 위치 필터 (위경도+반경)
    if (latitude != null && longitude != null && radiusKm != null) {
      // 위경도 1도는 약 111km (단순 근사)
      final double delta = radiusKm / 111.0;
      final double minLat = latitude - delta;
      final double maxLat = latitude + delta;
      final double minLng = longitude - delta;
      final double maxLng = longitude + delta;
      whereConditions.add('latitude BETWEEN ? AND ?');
      whereArgs.add(minLat);
      whereArgs.add(maxLat);
      whereConditions.add('longitude BETWEEN ? AND ?');
      whereArgs.add(minLng);
      whereArgs.add(maxLng);
    } else if (location != null && location.isNotEmpty) {
      whereConditions.add('location = ?');
      whereArgs.add(location);
    }

    // 날짜 범위 필터 (taken_at 기준)
    if (startDate != null) {
      whereConditions.add('taken_at >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereConditions.add('taken_at <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    // 색상 필터 (새로운 hue 컬럼 활용)
    if (colorName != null && colorName.isNotEmpty) {
      debugPrint('🎨 색상으로 필터링: $colorName');
      whereConditions.add('hue LIKE ?');
      whereArgs.add('%$colorName%');
    }

    // 키워드 검색 필터
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      debugPrint('🔍 키워드 검색 시작: $searchKeyword');

      // 쉼표로 구분된 라벨들을 분리
      final labels = searchKeyword.split(',');
      debugPrint('📝 검색할 라벨 목록: $labels');

      // 각 라벨에 대해 정확한 매칭을 위한 조건 생성
      final labelConditions = List.generate(
        labels.length,
        (index) => "labels LIKE ?",
      );

      // OR 조건으로 라벨 검색
      whereConditions.add('(${labelConditions.join(' OR ')})');
      whereArgs.addAll(labels.map((label) => '%$label%'));

      debugPrint('🔎 생성된 라벨 검색 조건: ${whereConditions.last}');
      debugPrint(
          '📌 검색 파라미터: ${whereArgs.sublist(whereArgs.length - labels.length)}');
    }

    String whereClause = '';
    if (whereConditions.isNotEmpty) {
      whereClause = 'WHERE ${whereConditions.join(' AND ')}';
    }

    // 정렬 기준 설정
    final String orderByClause = orderBy ?? 'taken_at DESC';

    // 페이지네이션 설정
    final int realLimit = limit ?? 100;
    String limitOffsetClause = 'LIMIT $realLimit';
    if (offset != null) {
      limitOffsetClause += ' OFFSET $offset';
    }

    final String query =
        'SELECT * FROM photos $whereClause ORDER BY $orderByClause $limitOffsetClause';
    debugPrint('📊 실행될 쿼리: $query');
    debugPrint('🔢 쿼리 파라미터: $whereArgs');

    try {
      final List<Map<String, dynamic>> maps =
          await db.rawQuery(query, whereArgs);
      debugPrint('✅ 검색 결과: ${maps.length}개 사진 발견');

      final results = maps.map((map) => PhotoModel.fromMap(map)).toList();

      // 결과에 대한 추가 정보 로깅
      if (results.isNotEmpty) {
        debugPrint('📸 첫 번째 사진 정보:');
        debugPrint('- ID: ${results.first.id}');
        debugPrint('- 경로: ${results.first.path}');
        debugPrint('- 라벨: ${results.first.labels}');
      }

      return results;
    } catch (e) {
      debugPrint('❌ 사진 쿼리 오류: $e');
      return [];
    }
  }

  /// 라벨링이 필요한 사진 목록 가져오기
  Future<List<PhotoModel>> getPhotosNeedingLabeling({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM photos 
      WHERE labels IS NULL AND analyzed = 0
      ORDER BY taken_at DESC 
      LIMIT ?
    ''', [limit]);

    return maps.map((map) => PhotoModel.fromMap(map)).toList();
  }

  /// 사진의 라벨 업데이트
  Future<void> updatePhotoLabels(int id, String labels) async {
    final db = await database;
    await db.update(
      'photos',
      {'labels': labels},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 라벨링이 완료된 사진 수 가져오기
  Future<int> getLabeledPhotosCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM photos 
      WHERE labels IS NOT NULL
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 전체 사진 수 가져오기
  Future<int> getTotalPhotosCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 사진의 색상 정보 업데이트
  Future<void> updatePhotoColor(String path, String colorHex) async {
    final db = await database;
    final List<String> colorNames =
        ColorUtils.getRepresentativeColors(colorHex);
    final String hueNames = colorNames.join(',');

    debugPrint('색상 업데이트: $path -> $colorHex (대표 색상: $hueNames)');

    await db.update(
      'photos',
      {
        'color': colorHex,
        'hue': hueNames,
      },
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  /// 사진의 분석 상태 업데이트
  Future<void> updatePhotoAnalyzed(int id, {int analyzed = 1}) async {
    final db = await database;
    await db.update(
      'photos',
      {'analyzed': analyzed},
      where: 'id = ?',
      whereArgs: [id],
    );
    // 디버깅: analyzed 값이 1로 업데이트됨을 출력
    print('[DEBUG] update analyzed: photoId=$id, analyzed=$analyzed');
  }

  /// DB의 모든 사진 상태(color, labels, analyzed) 출력 (디버깅용)
  Future<void> printAllPhotoStatus() async {
    final db = await database;
    final allPhotos = await db.query('photos');
    for (final photo in allPhotos) {
      print(
          '[DEBUG] DB 상태: id=${photo['id']}, color=${photo['color']}, labels=${photo['labels']}, analyzed=${photo['analyzed']}');
    }
  }
}

String extractDominantColor(Uint8List imageBytes) {
  final img.Image? image = img.decodeImage(imageBytes);
  if (image == null) return 'FFFFFF';

  // 군집 수 1개(K=1)로 전체 픽셀의 평균색을 대표색으로 사용 (PaletteGenerator.maximumColorCount: 1과 동일)
  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      rSum += p.r.toInt();
      gSum += p.g.toInt();
      bSum += p.b.toInt();
      count++;
    }
  }
  if (count == 0) return 'FFFFFF';
  final r = (rSum ~/ count).clamp(0, 255);
  final g = (gSum ~/ count).clamp(0, 255);
  final b = (bSum ~/ count).clamp(0, 255);
  final color = Color.fromARGB(255, r, g, b);
  final hex =
      color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  return hex;
}
