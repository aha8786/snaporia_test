// (package:flutter/material.dart import 삭제)
import 'color_utils.dart';

/// 색상 변환 테스트 유틸리티
class TestColorConversion {
  /// 색상 코드들을 테스트하고 결과를 출력
  static void testColorCodes() {
    List<String> colorCodes = [
      'ff692944',
      'ff595656',
      'ff7e7c75',
      'ff767364',
      'ff7a7b68',
      'ff737a3c'
    ];

    print('\n===== 색상 변환 테스트 =====');
    for (String hex in colorCodes) {
      // 'ff' 접두사 제거 (알파값)
      if (hex.length == 8) {
        hex = hex.substring(2);
      }

      // 16진수에서 RGB로 직접 파싱
      int r = int.parse(hex.substring(0, 2), radix: 16);
      int g = int.parse(hex.substring(2, 4), radix: 16);
      int b = int.parse(hex.substring(4, 6), radix: 16);

      print('\n[$hex] RGB: ($r, $g, $b)');

      // 정규화된 RGB 값 계산
      double normalizedR = r / 255.0;
      double normalizedG = g / 255.0;
      double normalizedB = b / 255.0;

      // 중간 계산 과정 출력
      double max = [normalizedR, normalizedG, normalizedB]
          .reduce((a, b) => a > b ? a : b);
      double min = [normalizedR, normalizedG, normalizedB]
          .reduce((a, b) => a < b ? a : b);
      double delta = max - min;

      print(
          '정규화 RGB: (${normalizedR.toStringAsFixed(3)}, ${normalizedG.toStringAsFixed(3)}, ${normalizedB.toStringAsFixed(3)})');
      print(
          'Max: ${max.toStringAsFixed(3)}, Min: ${min.toStringAsFixed(3)}, Delta: ${delta.toStringAsFixed(3)}');

      // Hue 계산 과정 보기
      String maxChannel = '';
      if (max == normalizedR)
        maxChannel = 'R';
      else if (max == normalizedG)
        maxChannel = 'G';
      else
        maxChannel = 'B';

      print('최대값 채널: $maxChannel');

      // Hue 수동 계산
      double hue = 0;
      if (delta != 0) {
        if (max == normalizedR) {
          hue = ((normalizedG - normalizedB) / delta) % 6;
        } else if (max == normalizedG) {
          hue = (normalizedB - normalizedR) / delta + 2;
        } else {
          hue = (normalizedR - normalizedG) / delta + 4;
        }
      }
      hue *= 60;
      if (hue < 0) hue += 360;

      print('수동 계산 Hue: ${hue.toStringAsFixed(1)}');

      // ColorUtils를 사용하여 검증
      String originalHex = hex;
      if (!originalHex.startsWith('ff')) {
        originalHex = 'ff$originalHex';
      }
      double utilsHue = ColorUtils.hexToHue(originalHex);
      List<String> colorNames = ColorUtils.getRepresentativeColors(originalHex);
      print(
          'ColorUtils Hue: ${utilsHue.toStringAsFixed(1)}, 색상명: ${colorNames.join(', ')}');
    }
    print('\n===== 테스트 종료 =====');
  }
}
