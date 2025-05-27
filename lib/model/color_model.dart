import 'package:flutter/material.dart';

/// 대표 색상 모델
class ColorModel {
  /// 색상 이름 (한글)
  final String koreanName;

  /// 색상 이름 (영문)
  final String englishName;

  /// 색상 객체
  final Color color;

  /// Hue 범위 최소값
  final double minHue;

  /// Hue 범위 최대값
  final double maxHue;

  /// 생성자
  const ColorModel({
    required this.koreanName,
    required this.englishName,
    required this.color,
    required this.minHue,
    required this.maxHue,
  });

  /// 경계 인식을 위한 임계값
  static const double boundaryThreshold = 2.0;

  /// 대표 색상 목록
  static List<ColorModel> get representativeColors => [
        const ColorModel(
          koreanName: '검정',
          englishName: 'Black',
          color: Colors.black,
          minHue: 0,
          maxHue: 360,
        ),
        const ColorModel(
          koreanName: '회색',
          englishName: 'Gray',
          color: Colors.grey,
          minHue: 0,
          maxHue: 360,
        ),
        const ColorModel(
          koreanName: '흰색',
          englishName: 'White',
          color: Colors.white,
          minHue: 0,
          maxHue: 360,
        ),
        const ColorModel(
          koreanName: '빨강',
          englishName: 'Red',
          color: Colors.red,
          minHue: 0,
          maxHue: 20,
        ),
        const ColorModel(
          koreanName: '주황',
          englishName: 'Orange',
          color: Colors.orange,
          minHue: 20,
          maxHue: 45,
        ),
        const ColorModel(
          koreanName: '노랑',
          englishName: 'Yellow',
          color: Colors.yellow,
          minHue: 45,
          maxHue: 70,
        ),
        const ColorModel(
          koreanName: '라임',
          englishName: 'Lime',
          color: Colors.lime,
          minHue: 70,
          maxHue: 90,
        ),
        const ColorModel(
          koreanName: '초록',
          englishName: 'Green',
          color: Colors.green,
          minHue: 90,
          maxHue: 160,
        ),
        const ColorModel(
          koreanName: '청록',
          englishName: 'Cyan',
          color: Colors.cyan,
          minHue: 160,
          maxHue: 200,
        ),
        const ColorModel(
          koreanName: '파랑',
          englishName: 'Blue',
          color: Colors.blue,
          minHue: 200,
          maxHue: 250,
        ),
        const ColorModel(
          koreanName: '남보라',
          englishName: 'Indigo',
          color: Colors.indigo,
          minHue: 250,
          maxHue: 290,
        ),
        const ColorModel(
          koreanName: '보라',
          englishName: 'Purple',
          color: Colors.purple,
          minHue: 290,
          maxHue: 320,
        ),
        const ColorModel(
          koreanName: '분홍',
          englishName: 'Pink',
          color: Colors.pink,
          minHue: 320,
          maxHue: 340,
        ),
      ];

  /// 경계값 목록
  static List<double> get boundaries => [
        20.0, // Red-Orange 경계
        45.0, // Orange-Yellow 경계
        70.0, // Yellow-Lime 경계
        90.0, // Lime-Green 경계
        160.0, // Green-Cyan 경계
        200.0, // Cyan-Blue 경계
        250.0, // Blue-Indigo 경계
        290.0, // Indigo-Purple 경계
        320.0, // Purple-Pink 경계
        340.0, // Pink-Red 경계
      ];

  /// 특정 Hue 값이 경계에 있는지 확인
  static bool isAtBoundary(double hue, {double threshold = boundaryThreshold}) {
    // 0과 360도 경계 (원형 색상환에서 끝과 끝이 만나는 지점)
    if (hue <= threshold || hue >= 360.0 - threshold) {
      return true;
    }

    // 나머지 경계 확인
    for (final boundary in boundaries) {
      if ((hue >= boundary - threshold) && (hue <= boundary + threshold)) {
        return true;
      }
    }

    return false;
  }

  /// 두 경계값의 ColorModel 목록 반환
  static List<ColorModel> getModelsAtBoundary(double hue,
      {double threshold = boundaryThreshold}) {
    List<ColorModel> models = [];

    // 0과 360도 경계 (Red와 Pink 사이)
    if (hue <= threshold || hue >= 360.0 - threshold) {
      models.add(representativeColors[0]); // Red (0-20)
      models.add(representativeColors[9]); // Pink (320-340)
      return models;
    }

    // Hue 값이 특정 경계에 있는지 확인
    for (final boundary in boundaries) {
      if ((hue >= boundary - threshold) && (hue <= boundary + threshold)) {
        // 경계 전후의 색상 모델을 찾기
        ColorModel? before, after;

        for (final model in representativeColors) {
          // 경계값이 색상의 maxHue와 일치하면 이 색상과 다음 색상 사이의 경계
          if (model.maxHue == boundary) {
            before = model;
            // after는 다음 범위의 모델 (경계값이 시작점)
            for (final next in representativeColors) {
              if (next.minHue == boundary) {
                after = next;
                break;
              }
            }
            break;
          }
        }

        if (before != null) models.add(before);
        if (after != null) models.add(after);
        break;
      }
    }

    return models;
  }

  /// 경계 근처의 Hue 값에 대해 대표 색상 영문 이름 목록 반환
  static List<String> getColorNamesAtBoundary(double hue,
      {double threshold = boundaryThreshold}) {
    final models = getModelsAtBoundary(hue, threshold: threshold);
    return models.map((model) => model.englishName).toList();
  }

  /// Hue 값에 해당하는 대표 색상 반환
  static ColorModel fromHue(double hue) {
    // 340-360도 범위는 빨강으로 처리
    if (hue >= 340 && hue <= 360) {
      return representativeColors[0]; // Red
    }

    // 0-340도 범위 처리
    for (final color in representativeColors) {
      if (hue >= color.minHue && hue < color.maxHue) {
        return color;
      }
    }

    // 기본값으로 빨강 반환
    return representativeColors[0];
  }

  /// HSV 색상으로부터 대표 색상 반환
  static ColorModel fromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    return fromHue(hsv.hue);
  }

  /// 색상값으로부터 대표 색상 목록 반환 (경계에 있으면 두 가지 색상 반환)
  static List<ColorModel> getRepresentativeModels(Color color) {
    final hsv = HSVColor.fromColor(color);
    final hue = hsv.hue;

    // 경계에 있는지 확인
    if (isAtBoundary(hue)) {
      return getModelsAtBoundary(hue);
    } else {
      return [fromHue(hue)];
    }
  }

  /// 색상값으로부터 대표 색상 이름 목록 반환
  static List<String> getRepresentativeColorNames(Color color) {
    final models = getRepresentativeModels(color);
    return models.map((model) => model.englishName).toList();
  }

  @override
  String toString() {
    return '$koreanName ($englishName)';
  }
}
