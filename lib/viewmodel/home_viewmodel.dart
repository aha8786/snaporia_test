import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../model/photo_model.dart';
import '../model/color_model.dart';
import '../utils/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// 홈 화면 ViewModel
class HomeViewModel extends ChangeNotifier {
  /// DB 헬퍼 인스턴스
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DatabaseHelper get dbHelper => _dbHelper;

  /// 현재 선택된 날짜 범위
  DateTimeRange? _dateRange;
  DateTimeRange? get dateRange => _dateRange;

  /// 현재 선택된 위치
  double? _selectedLat;
  double? get selectedLat => _selectedLat;
  double? _selectedLng;
  double? get selectedLng => _selectedLng;
  double? _selectedRadiusKm;
  double? get selectedRadiusKm => _selectedRadiusKm;

  /// 현재 선택된 색상
  Color? _selectedColor;
  Color? get selectedColor => _selectedColor;

  /// 현재 선택된 검색 키워드
  String? _searchKeyword;
  String? get searchKeyword => _searchKeyword;

  /// 현재 선택된 Hue 범위
  double? _minHue;
  double? get minHue => _minHue;

  double? _maxHue;
  double? get maxHue => _maxHue;

  /// 선택 모드 활성화 여부
  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  /// 선택된 사진 목록
  final Set<int> _selectedPhotos = {};
  Set<int> get selectedPhotos => _selectedPhotos;

  /// 모든 사진이 선택되었는지 확인
  bool get isAllSelected {
    // 사진이 없으면 전체 선택 상태가 아님
    if (photos.isEmpty) return false;
    // 현재 표시된 모든 사진 ID가 선택된 상태인지 확인
    return photos.every((photo) => _selectedPhotos.contains(photo.id));
  }

  /// 사진 목록
  List<PhotoModel> _photos = [];
  List<PhotoModel> get photos => _photos;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 추가 사진 존재 여부
  bool _hasMorePhotos = true;
  bool get hasMorePhotos => _hasMorePhotos;

  /// 현재 사용 중인 정렬 기준
  String _sortBy = 'taken_at DESC';
  String get sortBy => _sortBy;

  /// 초기화 완료 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 스캔 진행률
  ValueNotifier<double> get scanProgress => _dbHelper.scanProgress;

  /// 스캔 중 여부
  bool get isScanning => _dbHelper.isScanning;

  /// 현재 페이지

  /// 페이지당 항목 수

  /// 현재 스캔 배치

  /// 라벨링 작업 진행률
  final ValueNotifier<double> labelingProgress = ValueNotifier<double>(0.0);

  /// 라벨링 작업 중 여부
  bool _isLabeling = false;
  bool get isLabeling => _isLabeling;

  /// 라벨링 작업 취소 토큰
  bool _shouldStopLabeling = false;

  /// 라벨링 검색 중 여부
  bool _isLabelingSearch = false;
  bool get isLabelingSearch => _isLabelingSearch;

  /// 이미지 라벨링 처리 (이것만 남김)
  Future<String> _processImageLabeling(PhotoModel photo) async {
    ImageLabeler? imageLabeler;
    try {
      print('1️⃣ 이미지 디코딩 시작: \\${photo.path}');
      final file = File(photo.path);
      if (!await file.exists()) throw Exception('이미지 파일을 찾을 수 없습니다.');
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('이미지를 디코딩할 수 없습니다.');
      final resizedImage = img.copyResize(
        image,
        width: image.width > 400 ? 400 : image.width,
        height: image.width > 400
            ? (400 * image.height / image.width).round()
            : image.height,
      );
      final processedBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
      print('2️⃣ ML Kit 호출 시작');
      imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.6,
        ),
      );
      final inputImage = InputImage.fromFilePath(photo.path);
      final labels = await imageLabeler.processImage(inputImage);
      print('2️⃣ ML Kit 호출 완료: 라벨 개수 = \\${labels.length}');
      final highConfidenceLabels = labels
          .where((label) => label.confidence > 0.6)
          .map((label) =>
              '\\${label.label}(\\${label.confidence.toStringAsFixed(2)})')
          .toList();
      return highConfidenceLabels.join(', ');
    } catch (e, stack) {
      print('❌ _processImageLabeling 예외 발생: \\${e}');
      print('❌ 스택트레이스: \\${stack}');
      return '';
    } finally {
      imageLabeler?.close();
    }
  }

  /// 라벨링 작업 시작 (이것만 남김)
  Future<void> startLabeling() async {
    if (_isLabeling) {
      debugPrint('⚠️ 이미 라벨링 작업이 진행 중입니다.');
      return;
    }
    debugPrint('🚀 라벨링 작업 시작');
    _isLabeling = true;
    _shouldStopLabeling = false;
    notifyListeners();
    try {
      final totalPhotos = await _dbHelper.getTotalPhotosCount();
      int processedCount = await _dbHelper.getLabeledPhotosCount();
      debugPrint(
          '📊 전체 사진 수: \\${totalPhotos}, 이미 라벨링된 사진 수: \\${processedCount}');
      if (totalPhotos == 0) {
        debugPrint('⚠️ 라벨링할 사진이 없습니다.');
        return;
      }
      while (!_shouldStopLabeling) {
        final photos = await _dbHelper.getPhotosNeedingLabeling(limit: 10);
        if (photos.isEmpty) {
          debugPrint(
              '✅ 라벨링 작업이 완료되었습니다. 총 \\${processedCount}개의 사진이 라벨링되었습니다.');
          break;
        }
        debugPrint('📸 \\${photos.length}개의 사진에 대해 라벨링을 시작합니다.');
        for (final photo in photos) {
          if (_shouldStopLabeling) {
            debugPrint('⚠️ 라벨링 작업이 중단되었습니다.');
            break;
          }
          try {
            debugPrint('🔍 사진 ID \\${photo.id} 라벨링 시작');
            final labels = await _processImageLabeling(photo);
            print('3️⃣ 라벨 저장 시작: photoId=\\${photo.id}, labels=\\${labels}');
            await _dbHelper.updatePhotoLabels(photo.id, labels);
            print('3️⃣ 라벨 저장 완료: photoId=\\${photo.id}');
            processedCount++;
            labelingProgress.value = processedCount / totalPhotos;
            debugPrint(
                '📈 라벨링 진행률: \\${(labelingProgress.value * 100).toStringAsFixed(1)}%');
          } catch (e, stack) {
            debugPrint('❌ 사진 라벨링 실패 (ID: \\${photo.id}): \\${e}');
            print('❌ 사진 라벨링 실패 스택트레이스: \\${stack}');
          }
        }
      }
    } finally {
      _isLabeling = false;
      notifyListeners();
      debugPrint('🏁 라벨링 작업 종료');
    }
  }

  void stopLabeling() {
    _shouldStopLabeling = true;
  }

  /// 선택 모드 설정
  void setSelectionMode(bool value) {
    if (_isSelectionMode == value) return;
    _isSelectionMode = value;

    // 선택 모드가 꺼지면 선택된 사진 목록 초기화
    if (!value) {
      _selectedPhotos.clear();
    }

    notifyListeners();
  }

  /// 사진 선택 토글
  void togglePhotoSelection(int photoId) {
    if (!_isSelectionMode) return;

    if (_selectedPhotos.contains(photoId)) {
      _selectedPhotos.remove(photoId);
    } else {
      _selectedPhotos.add(photoId);
      // 선택된 사진의 라벨 데이터 출력
      final selectedPhoto = photos.firstWhere((photo) => photo.id == photoId);
      debugPrint(
          '선택된 사진 ID: $photoId, 저장된 색상 값: ${selectedPhoto.color}, 사진 라벨: ${selectedPhoto.labels}');
    }

    notifyListeners();
  }

  /// 사진이 선택되었는지 확인
  bool isPhotoSelected(int photoId) {
    return _selectedPhotos.contains(photoId);
  }

  /// 상단 선택 버튼 클릭 이벤트 처리
  void handleSelectButtonTap() {
    // 선택 모드 활성화
    setSelectionMode(true);
    debugPrint('선택 모드가 활성화되었습니다.');
  }

  /// 선택 모드 취소 이벤트 처리
  void handleCancelSelectionMode() {
    // 선택 모드 비활성화
    setSelectionMode(false);
    debugPrint('선택 모드가 비활성화되었습니다.');
  }

  /// 전체 사진 선택/해제 토글
  void toggleSelectAll() {
    if (!_isSelectionMode) return;

    if (isAllSelected) {
      // 모든 사진이 선택된 상태면 전체 해제
      _selectedPhotos.clear();
    } else {
      // 일부만 선택되었거나 아무것도 선택되지 않은 상태면 전체 선택
      _selectedPhotos.clear();
      for (var photo in photos) {
        _selectedPhotos.add(photo.id);
      }
    }

    notifyListeners();
  }

  /// 선택된 사진 공유
  Future<void> shareSelectedPhotos(BuildContext context) async {
    if (!_isSelectionMode || _selectedPhotos.isEmpty) return;

    try {
      // 선택된 사진 파일 리스트 생성
      final selectedFiles = <XFile>[];

      for (var photoId in _selectedPhotos) {
        // ID로 사진 객체 찾기
        final photo = photos.firstWhere(
          (p) => p.id == photoId,
          orElse: () => throw Exception('선택된 사진을 찾을 수 없습니다.'),
        );

        // 파일이 존재하는지 확인
        final file = File(photo.path);
        if (await file.exists()) {
          selectedFiles.add(XFile(photo.path));
        }
      }

      if (selectedFiles.isEmpty) {
        throw Exception('공유할 수 있는 사진이 없습니다.');
      }

      // Share Plus 패키지를 사용하여 파일 공유
      await Share.shareXFiles(
        selectedFiles,
        text: '${selectedFiles.length}장의 사진을 공유합니다.',
      );

      debugPrint('공유 성공: ${selectedFiles.length}장의 사진');
    } catch (e) {
      debugPrint('사진 공유 오류: $e');
      rethrow;
    }
  }

  /// 초기화 메서드
  Future<void> initialize() async {
    try {
      // 이전 스캔 상태 확인
      final prefs = await SharedPreferences.getInstance();
      final isScanning = prefs.getBool('is_scanning') ?? false;

      if (isScanning) {
        // 중단된 스캔이 있다면 자동으로 재개
        _isInitialized = true;
        notifyListeners();
        await resumeScan();
      } else {
        // 스캔 완료된 상태라면 사진 존재 여부 확인
        final bool photosExist = await _dbHelper.hasPhotos();
        _isInitialized = true;
        notifyListeners();

        if (photosExist) {
          await loadPhotos();
        }
      }
    } catch (e) {
      debugPrint('초기화 오류: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 날짜 범위 설정
  Future<void> setDateRange(DateTimeRange? range) async {
    if (_dateRange == range) return;

    _dateRange = range;
    await resetAndReload();
  }

  /// 위치 설정 (lat,lng,radius 형태의 문자열)
  Future<void> setLocation(String? location) async {
    if (location == null || location.isEmpty) {
      _selectedLat = null;
      _selectedLng = null;
      _selectedRadiusKm = null;
      await resetAndReload();
      return;
    }
    final parts = location.split(',');
    if (parts.length == 3) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      final radius = double.tryParse(parts[2]);
      if (lat != null && lng != null && radius != null) {
        _selectedLat = lat;
        _selectedLng = lng;
        _selectedRadiusKm = radius;
        await resetAndReload();
        return;
      }
    }
    // 파싱 실패 시 위치 필터 해제
    _selectedLat = null;
    _selectedLng = null;
    _selectedRadiusKm = null;
    await resetAndReload();
  }

  /// 색상 설정
  Future<void> setColor(Color? color) async {
    if (_selectedColor == color) return;

    _selectedColor = color;

    // 색상이 설정되면 해당 색상의 Hue 값을 계산하여 Hue 범위도 설정
    if (color != null) {
      // ColorModel을 사용하여 대표 색상 및 Hue 범위 구하기
      final colorModel = ColorModel.fromColor(color);
      _minHue = colorModel.minHue;
      _maxHue = colorModel.maxHue;
    } else {
      // 색상이 선택되지 않으면 Hue 범위도 초기화
      _minHue = null;
      _maxHue = null;
    }

    await resetAndReload();
  }

  /// 정렬 기준 설정
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// 필터 초기화 및 사진 목록 재로드
  Future<void> resetAndReload() async {
    _photos.clear();
    _hasMorePhotos = true;
    _isLoading = true;
    notifyListeners();

    try {
      // DB에서 사진 목록 가져오기 (필터링 적용)
      final List<PhotoModel> newPhotos = await _dbHelper.getPhotos(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        latitude: _selectedLat,
        longitude: _selectedLng,
        radiusKm: _selectedRadiusKm,
        colorName:
            _selectedColor != null ? _mapColorToKeyword(_selectedColor!) : null,
        searchKeyword: _searchKeyword, // 키워드 검색 추가
      );

      // 실제 존재하는 사진만 필터링
      final List<PhotoModel> validPhotos =
          newPhotos.where((photo) => photoExists(photo)).toList();

      if (validPhotos.isEmpty) {
        _hasMorePhotos = false;
      } else {
        _photos.addAll(validPhotos);
      }
    } catch (e) {
      debugPrint('사진 로드 오류: $e');
      _hasMorePhotos = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사진 테이블 초기화
  Future<void> resetPhotos() async {
    try {
      // 메모리상의 사진 목록 초기화
      _photos.clear();
      _hasMorePhotos = true;
      _isInitialized = false;

      // 진행 상태 초기화
      scanProgress.value = 0.0;

      // 데이터베이스의 사진 데이터 초기화
      await _dbHelper.clearPhotos();

      notifyListeners();
    } catch (e) {
      debugPrint('사진 초기화 오류: $e');
      rethrow;
    }
  }

  /// 중단된 스캔 재개
  Future<void> resumeScan() async {
    if (isScanning) return;

    try {
      notifyListeners();

      // 실제 스캔 실행
      await _dbHelper.scanPhotosAndSaveMeta();

      // 스캔 완료 후 사진 로드
      _isInitialized = true;
      await loadPhotos();
    } catch (e) {
      debugPrint('❌ 사진 스캔 중 오류 발생: $e');

      // 오류 발생해도 상태 초기화하고 사진 로드 시도
      final bool photosExist = await _dbHelper.hasPhotos();
      if (photosExist) {
        await loadPhotos();
      }
    } finally {
      notifyListeners();
    }
  }

  /// 사진 스캔 시작
  Future<void> startScan() async {
    // 이미 스캔 중이면 재개
    if (isScanning) {
      return await resumeScan();
    }

    try {
      scanProgress.value = 0.0;
      notifyListeners();

      // DB 초기화
      await resetPhotos();

      // 실제 스캔 실행
      await _dbHelper.scanPhotosAndSaveMeta();

      // 스캔 완료 후 사진 로드
      scanProgress.value = 1.0;
      _isInitialized = true;
      await loadPhotos();

      // 스캔 완료 후 자동으로 라벨링 시작
      debugPrint('📸 스캔 완료, 라벨링 작업을 시작합니다...');
      await startLabeling();
    } catch (e) {
      debugPrint('❌ 사진 스캔 중 오류 발생: $e');

      // 상태 업데이트
      final prefs = await SharedPreferences.getInstance();
      final isScanning = prefs.getBool('is_scanning') ?? false;

      if (isScanning) {
        // 오류가 났지만 스캔이 진행 중인 상태라면 재개 가능하도록 설정
        _isInitialized = true;
        await Future.delayed(const Duration(seconds: 3)); // 잠시 대기 후 재시도
        await resumeScan(); // 자동으로 재시도
      }

      // 오류가 발생해도 이미 있는 사진은 로드
      final bool photosExist = await _dbHelper.hasPhotos();
      if (photosExist) {
        await loadPhotos();
      }
    } finally {
      notifyListeners();
    }
  }

  /// 사진 데이터 로드
  Future<void> loadPhotos() async {
    if (_isLoading || !_hasMorePhotos) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 초기화가 안 된 경우는 사진이 있는지만 확인하고 종료
      if (!_isInitialized) {
        final bool photosExist = await _dbHelper.hasPhotos();
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final String? colorKeyword =
          _selectedColor != null ? _mapColorToKeyword(_selectedColor!) : null;

      // DB에서 사진 목록 가져오기 (필터링 적용)
      final List<PhotoModel> newPhotos = await _dbHelper.getPhotos(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        latitude: _selectedLat,
        longitude: _selectedLng,
        radiusKm: _selectedRadiusKm,
        colorName: colorKeyword,
      );

      // 실제 존재하는 사진만 필터링
      final List<PhotoModel> validPhotos =
          newPhotos.where((photo) => photoExists(photo)).toList();

      if (validPhotos.isEmpty) {
        _hasMorePhotos = false;
      } else {
        // 중복 제거를 위해 Set 사용
        final Set<int> existingIds = _photos.map((p) => p.id).toSet();
        final List<PhotoModel> uniqueNewPhotos = validPhotos
            .where((photo) => !existingIds.contains(photo.id))
            .toList();

        if (uniqueNewPhotos.isNotEmpty) {
          _photos.addAll(uniqueNewPhotos);
        } else {
          _hasMorePhotos = false;
        }
      }
    } catch (e) {
      debugPrint('사진 로드 오류: $e');
      _hasMorePhotos = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 색상을 키워드로 변환
  String _mapColorToKeyword(Color color) {
    // HSV 기반으로 색상 분류
    final HSVColor hsv = HSVColor.fromColor(color);

    // 채도가 매우 낮은 경우 (무채색)
    if (hsv.saturation <= 0.1) {
      if (hsv.value < 0.3) {
        return 'Black';
      } else if (hsv.value > 0.7) {
        return 'White';
      } else {
        return 'Gray';
      }
    } else {
      // 채도가 있는 경우 (유채색)
      final hue = hsv.hue;
      if (hue >= 0 && hue < 20 || hue >= 340 && hue <= 360) return 'Red';
      if (hue >= 20 && hue < 45) return 'Orange';
      if (hue >= 45 && hue < 70) return 'Yellow';
      if (hue >= 70 && hue < 90) return 'Lime';
      if (hue >= 90 && hue < 160) return 'Green';
      if (hue >= 160 && hue < 200) return 'Cyan';
      if (hue >= 200 && hue < 250) return 'Blue';
      if (hue >= 250 && hue < 290) return 'Indigo';
      if (hue >= 290 && hue < 320) return 'Purple';
      if (hue >= 320 && hue < 340) return 'Pink';
      return 'Unknown';
    }
  }

  /// 사진이 실제로 존재하는지 확인
  bool photoExists(PhotoModel photo) {
    final file = File(photo.path);
    return file.existsSync();
  }

  /// 검색 키워드 설정
  void setSearchKeyword(String? keyword) {
    if (_searchKeyword == keyword) return;

    // 키워드가 비어있지 않은 경우에만 처리
    if (keyword != null && keyword.isNotEmpty) {
      debugPrint('🔍 키워드 검색 시작: $keyword');

      // 한글 검색어를 영어 라벨로 변환
      final List<String> englishLabels = _translateKoreanToLabels(keyword);
      debugPrint('🌐 변환된 영어 라벨: $englishLabels');

      // 변환된 라벨들을 쉼표로 구분된 문자열로 저장
      _searchKeyword = englishLabels.join(',');
      debugPrint('📝 저장된 검색 키워드: $_searchKeyword');

      // 검색 실행
      resetAndReload();
    } else {
      _searchKeyword = null;
      resetAndReload();
    }
  }

  /// 모든 필터 초기화
  Future<void> resetAllFilters() async {
    _dateRange = null;
    _selectedLat = null;
    _selectedLng = null;
    _selectedRadiusKm = null;
    _selectedColor = null;
    _minHue = null;
    _maxHue = null;
    _searchKeyword = null; // 검색 키워드도 초기화
    await resetAndReload();
  }

  /// 필터링 및 검색 수행
  Future<void> searchPhotos({
    DateTimeRange? dateRange,
    String? location,
    Color? color,
    String? searchKeyword, // 키워드 검색 파라미터 추가
    double? minHue,
    double? maxHue,
  }) async {
    // 검색 조건 설정
    _dateRange = dateRange;
    // 위치 파싱 제거 (이미 setLocation에서 처리)
    _searchKeyword = searchKeyword; // 키워드 설정

    // 색상과 Hue 범위 중 하나만 설정 (충돌 방지)
    if (color != null) {
      _selectedColor = color;

      // ColorModel을 사용하여 대표 색상 및 Hue 범위 구하기
      final colorModel = ColorModel.fromColor(color);
      _minHue = colorModel.minHue;
      _maxHue = colorModel.maxHue;
    } else if (minHue != null || maxHue != null) {
      _selectedColor = null;
      _minHue = minHue;
      _maxHue = maxHue;
    } else {
      _selectedColor = null;
      _minHue = null;
      _maxHue = null;
    }

    // 검색 초기화 및 재로드
    await resetAndReload();
  }

  /// Hue 범위 설정
  Future<void> setHueRange(double? min, double? max) async {
    if (_minHue == min && _maxHue == max) return;

    _minHue = min;
    _maxHue = max;

    // Hue 범위가 설정되면 _selectedColor는 null로 설정 (충돌 방지)
    if (min != null || max != null) {
      _selectedColor = null;
    }

    await resetAndReload();
  }

  /// 한글 검색어를 영어 라벨로 변환
  List<String> _translateKoreanToLabels(String korean) {
    // 한글 검색어를 영어 라벨로 매핑
    final Map<String, List<String>> koreanToLabels = {
      '사람': ['person', 'man', 'woman', 'child'],
      '남자': ['man', 'person'],
      '여자': ['woman', 'person'],
      '아이': ['child', 'person'],
      '개': ['dog'],
      '고양이': ['cat'],
      '새': ['bird'],
      '나무': ['tree'],
      '꽃': ['flower'],
      '건물': ['building'],
      '자동차': ['car', 'vehicle'],
      '음식': ['food'],
      '음료': ['drink'],
      '하늘': ['sky'],
      '물': ['water'],
      '산': ['mountain'],
      '해변': ['beach'],
      '실내': ['indoor'],
      '실외': ['outdoor'],
      '자연': ['nature'],
      '동물': ['animal', 'dog', 'cat', 'bird'],
      '식물': ['plant', 'tree', 'flower'],
      '차량': ['vehicle', 'car'],
      '가구': ['furniture'],
      '전자제품': ['electronic'],
      '의류': ['clothing'],
      '악세서리': ['accessory'],
      '스포츠': ['sport'],
      '음악': ['music'],
      '예술': ['art'],
      '책': ['book'],
      '컴퓨터': ['computer'],
      '휴대폰': ['phone', 'cell phone'],
      '카메라': ['camera'],
      '시계': ['clock', 'watch'],
      '가방': ['bag', 'backpack', 'handbag'],
      '신발': ['shoe'],
      '모자': ['hat'],
      '안경': ['glasses'],
      '보석': ['jewelry'],
      '장난감': ['toy'],
      '게임': ['game'],
      '영화': ['movie'],
      'TV': ['TV'],
      '라디오': ['radio'],
      '신문': ['newspaper'],
      '잡지': ['magazine'],
      '문서': ['document'],
      '돈': ['money'],
      '달력': ['calendar'],
      '지도': ['map'],
      '깃발': ['flag'],
      '표지판': ['sign'],
      '신호등': ['traffic light'],
      '소화전': ['fire hydrant'],
      '정지 표지판': ['stop sign'],
      '주차 미터기': ['parking meter'],
      '벤치': ['bench'],
      '말': ['horse'],
      '양': ['sheep'],
      '소': ['cow'],
      '코끼리': ['elephant'],
      '곰': ['bear'],
      '얼룩말': ['zebra'],
      '기린': ['giraffe'],
      '배낭': ['backpack'],
      '우산': ['umbrella'],
      '핸드백': ['handbag'],
      '넥타이': ['tie'],
      '여행가방': ['suitcase'],
      '프리스비': ['frisbee'],
      '스키': ['skis'],
      '스노우보드': ['snowboard'],
      '스포츠 공': ['sports ball'],
      '연': ['kite'],
      '야구 방망이': ['baseball bat'],
      '야구 글러브': ['baseball glove'],
      '스케이트보드': ['skateboard'],
      '서핑보드': ['surfboard'],
      '테니스 라켓': ['tennis racket'],
      '병': ['bottle'],
      '와인 글라스': ['wine glass'],
      '컵': ['cup'],
      '포크': ['fork'],
      '나이프': ['knife'],
      '스푼': ['spoon'],
      '그릇': ['bowl'],
      '바나나': ['banana'],
      '사과': ['apple'],
      '샌드위치': ['sandwich'],
      '오렌지': ['orange'],
      '브로콜리': ['broccoli'],
      '당근': ['carrot'],
      '핫도그': ['hot dog'],
      '피자': ['pizza'],
      '도넛': ['donut'],
      '케이크': ['cake'],
      '의자': ['chair'],
      '소파': ['couch'],
      '화분': ['potted plant'],
      '침대': ['bed'],
      '식탁': ['dining table'],
      '화장실': ['toilet'],
      '노트북': ['laptop'],
      '마우스': ['mouse'],
      '리모컨': ['remote'],
      '키보드': ['keyboard'],
      '전자레인지': ['microwave'],
      '오븐': ['oven'],
      '토스터': ['toaster'],
      '싱크대': ['sink'],
      '냉장고': ['refrigerator'],
      '꽃병': ['vase'],
      '가위': ['scissors'],
      '테디베어': ['teddy bear'],
      '헤어드라이어': ['hair drier'],
      '칫솔': ['toothbrush'],
    };

    // 한글 검색어를 소문자로 변환하여 매핑
    final koreanLower = korean.toLowerCase();
    return koreanToLabels[koreanLower] ?? [koreanLower];
  }

  /// 사진 목록 가져오기 (라벨 필터링 추가)
  Future<List<PhotoModel>> getPhotos({
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? colorName,
    List<String>? labels, // 라벨 필터링 추가
  }) async {
    debugPrint(
        'getPhotos 호출: location=$location, startDate=$startDate, endDate=$endDate, colorName=$colorName, labels=$labels');

    // 라벨 검색이 있고 라벨링이 진행 중이면 로딩 상태 설정
    if (labels != null && labels.isNotEmpty && _isLabeling) {
      _isLabelingSearch = true;
      notifyListeners();
    }

    final db = await _dbHelper.database;
    final List<String> whereConditions = [];
    final List<dynamic> whereArgs = [];

    // 위치 필터
    if (location != null && location.isNotEmpty) {
      whereConditions.add('location = ?');
      whereArgs.add(location);
    }

    // 날짜 범위 필터
    if (startDate != null) {
      whereConditions.add('taken_at >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereConditions.add('taken_at <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    // 색상 필터
    if (colorName != null && colorName.isNotEmpty) {
      whereConditions.add('hue LIKE ?');
      whereArgs.add('%$colorName%');
    }

    // 라벨 필터 (한글 검색어를 영어 라벨로 변환)
    if (labels != null && labels.isNotEmpty) {
      final List<String> englishLabels = [];
      for (final label in labels) {
        englishLabels.addAll(_translateKoreanToLabels(label));
      }

      // OR 조건으로 라벨 검색 (정확한 매칭을 위해 쉼표로 구분된 값 검색)
      if (englishLabels.isNotEmpty) {
        final labelConditions = List.generate(
          englishLabels.length,
          (index) => "',' || labels || ',' LIKE ?",
        );
        whereConditions.add('(${labelConditions.join(' OR ')})');
        whereArgs.addAll(englishLabels.map((label) => '%,$label,%'));
      }
    }

    String whereClause = '';
    if (whereConditions.isNotEmpty) {
      whereClause = 'WHERE ${whereConditions.join(' AND ')}';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM photos $whereClause ORDER BY taken_at DESC',
      whereArgs,
    );

    // 검색 완료 후 로딩 상태 해제
    if (_isLabelingSearch) {
      _isLabelingSearch = false;
      notifyListeners();
    }

    return maps.map((map) => PhotoModel.fromMap(map)).toList();
  }
}
