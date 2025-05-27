import 'base_model.dart';
import '../utils/color_utils.dart';
import 'package:flutter/material.dart';

/// 사진 데이터 모델
class PhotoModel extends BaseModel {
  /// 사진 고유 ID
  final int id;

  /// 사진 파일 경로
  final String path;

  /// 촬영 타임스탬프 (밀리초)
  final int? takenAt;

  /// 촬영 날짜
  final DateTime? dateTaken;

  /// 위치 정보
  final String? location;

  /// 위도
  final double? latitude;

  /// 경도
  final double? longitude;

  /// 주요 색상 (16진수 색상 코드)
  final String? color;

  /// 색상의 Hue 값 또는 색상명 (hue 컬럼에 색상명 문자열이 들어있음)
  final String? hueNames;

  /// 색상의 Hue 값 (0-360)
  final double? hue;

  /// 기기 모델
  final String? deviceModel;

  /// 파일 크기
  final int? fileSize;

  /// MIME 타입
  final String? mimeType;

  /// 가로 크기
  final int? width;

  /// 세로 크기
  final int? height;

  /// 이미지 라벨 (쉼표로 구분된 문자열)
  final String? labels;

  /// 생성자
  const PhotoModel({
    required this.id,
    required this.path,
    this.takenAt,
    this.dateTaken,
    this.location,
    this.latitude,
    this.longitude,
    this.color,
    this.hueNames,
    this.hue,
    this.deviceModel,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.labels,
  });

  /// Map에서 모델 객체 생성
  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    // hue는 DB에서 String으로 저장되어 있음 (색상 이름들이 쉼표로 구분됨)
    String? hueNames = map['hue'] as String?;
    double? hueValue;

    // 색상 코드에서 Hue 값 추출 시도 (실패하면 null)
    if (map['color'] != null) {
      try {
        final String colorHex = map['color'] as String;
        // ColorUtils 사용해서 Hue 값 계산
        hueValue = ColorUtils.hexToHue(colorHex);
      } catch (e) {
        debugPrint('Hue 값 계산 실패: $e');
        hueValue = null;
      }
    }

    return PhotoModel(
      id: map['id'] as int,
      path: map['path'] as String,
      takenAt: map['taken_at'] as int?,
      dateTaken: map['date_taken'] != null
          ? DateTime.parse(map['date_taken'] as String)
          : null,
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      color: map['color'] as String?,
      hueNames: hueNames,
      hue: hueValue,
      deviceModel: map['device_model'] as String?,
      fileSize: map['file_size'] as int?,
      mimeType: map['mime_type'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      labels: map['labels'] as String?,
    );
  }

  /// 모델을 Map으로 변환
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'taken_at': takenAt,
      'date_taken': dateTaken?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'color': color,
      'hue': hueNames,
      'device_model': deviceModel,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'labels': labels,
    };
  }

  /// 검색 조건과 일치하는지 확인
  bool matchesSearchCriteria({
    DateTime? startDate,
    DateTime? endDate,
    String? locationKeyword,
    String? deviceKeyword,
    String? colorKeyword,
    double? minHue,
    double? maxHue,
  }) {
    // 날짜 범위 체크
    if (startDate != null && dateTaken != null) {
      if (dateTaken!.isBefore(startDate)) {
        return false;
      }
    }

    if (endDate != null && dateTaken != null) {
      if (dateTaken!.isAfter(endDate)) {
        return false;
      }
    }

    // 위치 키워드 체크
    if (locationKeyword != null && locationKeyword.isNotEmpty) {
      if (location == null ||
          !location!.toLowerCase().contains(locationKeyword.toLowerCase())) {
        return false;
      }
    }

    // 기기 키워드 체크
    if (deviceKeyword != null && deviceKeyword.isNotEmpty) {
      if (deviceModel == null ||
          !deviceModel!.toLowerCase().contains(deviceKeyword.toLowerCase())) {
        return false;
      }
    }

    // 색상 키워드 체크 - 이제 hueNames 사용
    if (colorKeyword != null && colorKeyword.isNotEmpty) {
      if (hueNames == null ||
          !hueNames!.toLowerCase().contains(colorKeyword.toLowerCase())) {
        return false;
      }
    }

    // Hue 범위 체크
    if (hue != null && minHue != null && maxHue != null) {
      // Hue는 색상환이므로 경계를 넘는 경우 처리 (예: 350-30도 범위)
      if (minHue > maxHue) {
        if (!(hue! >= minHue || hue! <= maxHue)) {
          return false;
        }
      } else if (!(hue! >= minHue && hue! <= maxHue)) {
        return false;
      }
    } else if (hue != null && minHue != null) {
      if (hue! < minHue) {
        return false;
      }
    } else if (hue != null && maxHue != null) {
      if (hue! > maxHue) {
        return false;
      }
    }

    return true;
  }
}
