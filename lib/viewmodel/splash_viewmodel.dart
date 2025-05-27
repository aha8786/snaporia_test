import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import '../model/permission_status.dart';
import '../view/main/main_screen.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  PermissionStatus _permissionStatus = PermissionStatus.checking;
  PermissionStatus get permissionStatus => _permissionStatus;

  // 초기화 관련 플래그
  bool _isDelayCompleted = false;
  bool _isPermissionChecked = false;

  // 디바이스 정보 유틸리티
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // 권한 가이드 다이얼로그 상태 관리
  bool _shouldShowPermissionGuide = false;
  bool get shouldShowPermissionGuide => _shouldShowPermissionGuide;

  bool _isPermanentlyDenied = false;
  bool get isPermanentlyDenied => _isPermanentlyDenied;

  // 권한 상태 업데이트
  void updatePermissionStatus(PermissionStatus status) {
    _permissionStatus = status;
    notifyListeners();
  }

  // 로딩 상태 업데이트
  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  Future<void> initializeApp(BuildContext context) async {
    _permissionStatus = PermissionStatus.checking; // 상태를 '확인 중'으로 변경
    notifyListeners(); // UI 업데이트

    try {
      // 3초 대기와 권한 체크를 동시에 실행
      await Future.wait([
        _waitSplashDelay(),
        _checkPermissions(context),
      ]);

      // 모든 조건이 만족된 경우에만 메인 화면으로 이동
      if (_isDelayCompleted &&
          _isPermissionChecked &&
          _permissionStatus == PermissionStatus.granted &&
          context.mounted) {
        _navigateToHome(context);
      }
    } catch (e) {
      // _errorMessage = e.toString();
      debugPrint('초기화 중 오류 발생: $e');
      notifyListeners();
    }
  }

  // 스플래시 화면에 표시할 최소 지연 시간
  Future<void> _waitSplashDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    _isDelayCompleted = true;
  }

  // 권한 확인
  Future<void> _checkPermissions(BuildContext context) async {
    final hasPermission = await _checkAndRequestPermission(context);
    _isPermissionChecked = true;
    if (hasPermission) {
      _permissionStatus = PermissionStatus.granted;
    }
    notifyListeners();
  }

  // 권한 확인 및 요청 로직
  Future<bool> _checkAndRequestPermission(BuildContext context) async {
    await _monitorPermissionChanges(); // 현재 권한 상태 로깅

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // Android 13 이상인 경우 (API 레벨 33 이상)
        if (androidInfo.version.sdkInt >= 33) {
          final photosStatus = await ph.Permission.photos.status; // 사진 권한 상태 확인
          final videosStatus =
              await ph.Permission.videos.status; // 비디오 권한 상태 확인

          // 1. 권한이 영구적으로 거부된 경우
          if (photosStatus.isPermanentlyDenied ||
              videosStatus.isPermanentlyDenied) {
            debugPrint('❌ 권한 영구 거부됨');
            _permissionStatus = PermissionStatus.permanentlyDenied; // 상태 업데이트
            _showPermissionGuide(true);
            return false;
          }

          // 2. 권한이 거부된 경우 (아직 요청되지 않은 경우 포함)
          if (photosStatus.isDenied || videosStatus.isDenied) {
            debugPrint('⚠️ 권한 요청 시작');

            // 사진 및 비디오 권한 요청
            final photos = await ph.Permission.photos.request();
            final videos = await ph.Permission.videos.request();

            debugPrint('📱 권한 요청 결과 - 사진: $photos, 비디오: $videos');

            // 요청 후에도 권한이 허용되지 않은 경우
            if (!photos.isGranted || !videos.isGranted) {
              _permissionStatus = PermissionStatus.denied; // 상태 업데이트
              _showPermissionGuide(false);
              return false;
            }
          }
        }

        // Android 12 이하인 경우 (저장소 권한으로 처리)
        else {
          final storageStatus = await ph.Permission.storage.status;
          // Android 13과 유사한 로직 구현
          if (storageStatus.isPermanentlyDenied) {
            debugPrint('❌ 저장소 권한 영구 거부됨');
            _permissionStatus = PermissionStatus.permanentlyDenied;
            _showPermissionGuide(true);
            return false;
          }

          if (storageStatus.isDenied) {
            debugPrint('⚠️ 저장소 권한 요청 시작');

            final storage = await ph.Permission.storage.request();

            debugPrint('📱 저장소 권한 요청 결과: $storage');

            if (!storage.isGranted) {
              _permissionStatus = PermissionStatus.denied;
              _showPermissionGuide(false);
              return false;
            }
          }
        }
      }
      // iOS인 경우
      else if (Platform.isIOS) {
        final photosStatus = await ph.Permission.photos.status;

        if (photosStatus.isPermanentlyDenied) {
          debugPrint('❌ iOS 사진 권한 영구 거부됨');
          _permissionStatus = PermissionStatus.permanentlyDenied;
          _showPermissionGuide(true);
          return false;
        }

        if (photosStatus.isDenied) {
          debugPrint('⚠️ iOS 사진 권한 요청 시작');

          final photos = await ph.Permission.photos.request();

          debugPrint('📱 iOS 사진 권한 요청 결과: $photos');

          if (!photos.isGranted) {
            _permissionStatus = PermissionStatus.denied;
            _showPermissionGuide(false);
            return false;
          }
        }
      }

      // 모든 권한이 정상적으로 허용된 경우
      debugPrint('✅ 모든 권한 허용됨');
      return true;
    } catch (e) {
      debugPrint('❌ 권한 확인 중 오류 발생: $e');
      return false;
    }
  }

  // 현재 권한 상태 모니터링 (디버깅용)
  Future<void> _monitorPermissionChanges() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        debugPrint(
            '📊 현재 권한 상태 - 사진: ${await ph.Permission.photos.status}, 비디오: ${await ph.Permission.videos.status}');
      } else {
        debugPrint('📊 현재 권한 상태 - 저장소: ${await ph.Permission.storage.status}');
      }
    } else if (Platform.isIOS) {
      debugPrint('📊 현재 권한 상태 - 사진: ${await ph.Permission.photos.status}');
    }
  }

  // 권한 가이드 다이얼로그 표시
  void _showPermissionGuide(bool isPermanentlyDenied) {
    // MVVM 패턴에 맞게 ViewModel은 상태만 업데이트하고 View에서 이 상태를 관찰하여 다이얼로그를 표시
    _shouldShowPermissionGuide = true;
    _isPermanentlyDenied = isPermanentlyDenied;
    _permissionStatus = isPermanentlyDenied
        ? PermissionStatus.permanentlyDenied
        : PermissionStatus.denied;
    notifyListeners();
  }

  // 권한 가이드 다이얼로그 닫기
  void dismissPermissionGuide() {
    _shouldShowPermissionGuide = false;
    notifyListeners();
  }

  // 메인 화면으로 이동
  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
    debugPrint('메인 화면으로 이동 완료');
  }

  // 권한 요청 재시도
  Future<void> retryPermissionRequest(BuildContext context) async {
    _permissionStatus = PermissionStatus.checking; // 상태를 다시 '확인 중'으로 변경
    _isPermissionChecked = false;
    _shouldShowPermissionGuide = false; // 가이드 다이얼로그 상태 초기화
    notifyListeners(); // UI 업데이트

    await _checkPermissions(context); // 권한 체크 다시 시도

    // 권한이 허용되고 3초가 지났다면 메인 화면으로 이동
    if (_isDelayCompleted &&
        _isPermissionChecked &&
        _permissionStatus == PermissionStatus.granted &&
        context.mounted) {
      _navigateToHome(context);
    }
  }

  // 설정 앱 열기
  Future<void> openSettings() async {
    await ph.openAppSettings();
    debugPrint('앱 설정 열기');
  }
}
