import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../model/color_model.dart';

/// 색상 관련 유틸리티 클래스
class ColorUtils {
  /// 무채색 판단 기준 채도 값
  static const double saturationThreshold = 0.1;

  /// 무채색 분류 기준 Value 값
  static const double blackValueThreshold = 0.3;
  static const double whiteValueThreshold = 0.7;

  /// Hex 색상 코드에서 Color 객체 생성
  static Color hexToColor(String hex) {
    // '#' 기호가 있으면 제거
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    // 알파 값 처리 (앞 2자리가 'ff'이면 제거하여 RGB만 추출)
    if (hex.length == 8) {
      final String alpha = hex.substring(0, 2).toLowerCase();
      if (alpha == 'ff') {
        hex = hex.substring(2);
      }
    }

    // 3자리 hex 코드를 6자리로 변환 (예: "F00" -> "FF0000")
    if (hex.length == 3) {
      hex = hex.split('').map((char) => char + char).join('');
    }

    // 불완전한 Hex 코드 처리
    if (hex.length != 6) {
      return Colors.white; // 기본값 반환
    }

    // 16진수 Hex를 10진수 정수로 변환하고 alpha 채널(FF) 추가
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// RGB에서 HSV로 변환
  static HSVColor rgbToHSV(int r, int g, int b) {
    // 1. RGB를 0-1 범위로 정규화
    final double normalizedR = r / 255.0;
    final double normalizedG = g / 255.0;
    final double normalizedB = b / 255.0;

    // 2. 최대값, 최소값, delta 계산
    final double max =
        math.max(normalizedR, math.max(normalizedG, normalizedB));
    final double min =
        math.min(normalizedR, math.min(normalizedG, normalizedB));
    final double delta = max - min;

    // 3. Value = max
    final double value = max;

    // 4. Saturation 계산
    final double saturation = (max == 0) ? 0 : delta / max;

    // 5. Hue 계산 (R, G, B 중 max에 따라 다르게)
    double hue = 0;

    if (delta == 0) {
      hue = 0; // 무채색 (흰색, 회색, 검은색)
    } else if (max == normalizedR) {
      // 빨간색 계열
      hue = ((normalizedG - normalizedB) / delta) % 6;
    } else if (max == normalizedG) {
      // 초록색 계열
      hue = (normalizedB - normalizedR) / delta + 2;
    } else {
      // 파란색 계열
      hue = (normalizedR - normalizedG) / delta + 4;
    }

    hue *= 60; // 0-360 범위로 변환

    // 6. 음수 Hue 처리
    if (hue < 0) {
      hue += 360;
    }

    return HSVColor.fromAHSV(1.0, hue, saturation, value);
  }

  /// Hex 색상 코드에서 Hue 값 계산 (0-360)
  static double hexToHue(String hex) {
    // Hex를 Color 객체로 변환
    final Color color = hexToColor(hex);

    // RGB에서 HSV로 변환 후 Hue 값만 반환
    final hsv = rgbToHSV(color.red, color.green, color.blue);

    // 채도가 매우 낮은 경우 (무채색)
    if (hsv.saturation <= 0.1) {
      // 명도에 따라 무채색 분류
      if (hsv.value < 0.3) {
        return 0; // Black
      } else if (hsv.value > 0.7) {
        return 0; // White
      } else {
        return 0; // Gray
      }
    }

    return hsv.hue;
  }

  /// Hex 색상 코드에서 HSV 값 계산
  static HSVColor hexToHSV(String hex) {
    // Hex를 Color 객체로 변환
    final Color color = hexToColor(hex);

    // RGB에서 HSV로 변환
    return rgbToHSV(color.red, color.green, color.blue);
  }

  /// Hue 값에 해당하는 색상 이름 반환
  static String getColorNameFromHue(double hue) {
    // ColorModel을 활용하여 Hue 값에 해당하는 색상 반환
    final colorModel = ColorModel.fromHue(hue);
    return colorModel.englishName;
  }

  /// Hue 값이 경계에 있는지 확인 (경계는 ±2도로 정의)
  static bool isHueAtBoundary(double hue, {double threshold = 2.0}) {
    final List<double> boundaries = [
      20, // Red-Orange
      45, // Orange-Yellow
      70, // Yellow-Lime
      90, // Lime-Green
      160, // Green-Cyan
      200, // Cyan-Blue
      250, // Blue-Indigo
      290, // Indigo-Purple
      320, // Purple-Pink
      340, // Pink-Red
      0, // Red-Pink (360도 경계)
    ];

    for (final boundary in boundaries) {
      if ((hue >= boundary - threshold) && (hue <= boundary + threshold)) {
        return true;
      }
    }

    // 0도와 360도 경계 처리 (색상환의 양 끝)
    if (hue <= threshold || hue >= 360 - threshold) {
      return true;
    }

    return false;
  }

  /// Hue 값으로부터 경계인 경우 인접한 두 색상의 영문 이름 목록 반환
  static List<String> getColorNamesAtBoundary(double hue,
      {double threshold = 2.0}) {
    List<String> colorNames = [];

    // 0도/360도 경계 (Red-Pink)
    if (hue <= threshold || hue >= 360 - threshold) {
      colorNames.add('Red');
      colorNames.add('Pink');
      return colorNames;
    }

    // 각 경계값 체크
    if ((hue >= 20 - threshold) && (hue <= 20 + threshold)) {
      colorNames.add('Red');
      colorNames.add('Orange');
    } else if ((hue >= 45 - threshold) && (hue <= 45 + threshold)) {
      colorNames.add('Orange');
      colorNames.add('Yellow');
    } else if ((hue >= 70 - threshold) && (hue <= 70 + threshold)) {
      colorNames.add('Yellow');
      colorNames.add('Lime');
    } else if ((hue >= 90 - threshold) && (hue <= 90 + threshold)) {
      colorNames.add('Lime');
      colorNames.add('Green');
    } else if ((hue >= 160 - threshold) && (hue <= 160 + threshold)) {
      colorNames.add('Green');
      colorNames.add('Cyan');
    } else if ((hue >= 200 - threshold) && (hue <= 200 + threshold)) {
      colorNames.add('Cyan');
      colorNames.add('Blue');
    } else if ((hue >= 250 - threshold) && (hue <= 250 + threshold)) {
      colorNames.add('Blue');
      colorNames.add('Indigo');
    } else if ((hue >= 290 - threshold) && (hue <= 290 + threshold)) {
      colorNames.add('Indigo');
      colorNames.add('Purple');
    } else if ((hue >= 320 - threshold) && (hue <= 320 + threshold)) {
      colorNames.add('Purple');
      colorNames.add('Pink');
    } else if ((hue >= 340 - threshold) && (hue <= 340 + threshold)) {
      colorNames.add('Pink');
      colorNames.add('Red');
    }

    return colorNames;
  }

  /// 헥스 색상 코드를 대표 색상 이름으로 변환
  static List<String> getRepresentativeColors(String hexColor) {
    // 헥스 색상 코드에서 RGB 값 추출
    final color = Color(int.parse('FF$hexColor', radix: 16));

    // RGB를 HSV로 변환
    final HSVColor hsv = HSVColor.fromColor(color);
    final double hue = hsv.hue;
    final double saturation = hsv.saturation;
    final double value = hsv.value;

    debugPrint('색상 분석: $hexColor -> HSV($hue, $saturation, $value)');

    // 채도가 낮은 경우 (무채색)
    if (saturation <= 0.1) {
      if (value < 0.3) {
        debugPrint('무채색 분류: Black (Value: $value)');
        return ['Black'];
      } else if (value > 0.7) {
        debugPrint('무채색 분류: White (Value: $value)');
        return ['White'];
      } else {
        debugPrint('무채색 분류: Gray (Value: $value)');
        return ['Gray'];
      }
    }

    // 채도가 있는 경우 (유채색)
    final List<String> colors = [];

    // Hue 범위에 따른 색상 분류
    if (hue >= 0 && hue < 20 || hue >= 340 && hue <= 360) {
      colors.add('Red');
    } else if (hue >= 20 && hue < 45) {
      colors.add('Orange');
    } else if (hue >= 45 && hue < 70) {
      colors.add('Yellow');
    } else if (hue >= 70 && hue < 90) {
      colors.add('Lime');
    } else if (hue >= 90 && hue < 160) {
      colors.add('Green');
    } else if (hue >= 160 && hue < 200) {
      colors.add('Cyan');
    } else if (hue >= 200 && hue < 250) {
      colors.add('Blue');
    } else if (hue >= 250 && hue < 290) {
      colors.add('Indigo');
    } else if (hue >= 290 && hue < 320) {
      colors.add('Purple');
    } else if (hue >= 320 && hue < 340) {
      colors.add('Pink');
    }

    debugPrint('유채색 분류: ${colors.join(', ')} (Hue: $hue)');
    return colors;
  }

  /// 색상 객체로부터 대표 색상 목록 반환
  static List<String> getRepresentativeColorsFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);

    // 채도가 매우 낮은 경우 (무채색)
    if (hsv.saturation <= 0.1) {
      if (hsv.value < 0.3) {
        return ['Black'];
      } else if (hsv.value > 0.7) {
        return ['White'];
      } else {
        return ['Gray'];
      }
    }

    final double hue = hsv.hue;

    if (ColorModel.isAtBoundary(hue)) {
      return ColorModel.getColorNamesAtBoundary(hue);
    } else {
      return [getColorNameFromHue(hue)];
    }
  }

  /// 대표 색상에 해당하는 Material Color 가져오기
  static Color getColorFromName(String name) {
    switch (name) {
      case 'Red':
        return Colors.red;
      case 'Orange':
        return Colors.orange;
      case 'Yellow':
        return Colors.yellow;
      case 'Lime':
        return Colors.lime;
      case 'Green':
        return Colors.green;
      case 'Cyan':
        return Colors.cyan;
      case 'Blue':
        return Colors.blue;
      case 'Indigo':
        return Colors.indigo;
      case 'Purple':
        return Colors.purple;
      case 'Pink':
        return Colors.pink;
      default:
        return Colors.red;
    }
  }

  /// 색상 필터링을 위한 모든 대표 색상 반환
  static List<Map<String, dynamic>> getAllRepresentativeColors() {
    return [
      {'name': 'Red', 'color': Colors.red},
      {'name': 'Orange', 'color': Colors.orange},
      {'name': 'Yellow', 'color': Colors.yellow},
      {'name': 'Lime', 'color': Colors.lime},
      {'name': 'Green', 'color': Colors.green},
      {'name': 'Cyan', 'color': Colors.cyan},
      {'name': 'Blue', 'color': Colors.blue},
      {'name': 'Indigo', 'color': Colors.indigo},
      {'name': 'Purple', 'color': Colors.purple},
      {'name': 'Pink', 'color': Colors.pink},
    ];
  }
}
