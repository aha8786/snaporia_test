import 'package:flutter/material.dart';

class MainViewModel extends ChangeNotifier {
  /// 현재 선택된 날짜 범위
  DateTimeRange? _dateRange;
  DateTimeRange? get dateRange => _dateRange;

  /// 날짜 범위 설정
  Future<void> setDateRange(DateTimeRange? range) async {
    _dateRange = range;
    notifyListeners();
  }

  /// 필터 초기화 및 데이터 다시 로드
  Future<void> resetAndReload() async {
    // 데이터 로드 로직 구현
    notifyListeners();
  }
}
