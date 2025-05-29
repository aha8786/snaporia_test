import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../model/color_model.dart';

/// 날짜 필터 버튼 위젯
class FilterButtons extends StatelessWidget {
  /// 날짜 범위 선택 콜백
  final void Function(DateTimeRange?)? onDateRangeSelected;

  /// 현재 선택된 날짜 범위
  final DateTimeRange? selectedDateRange;

  /// 위치 선택 콜백
  final void Function(String?)? onLocationSelected;

  /// 현재 선택된 위치
  final String? selectedLocation;

  /// 색상 선택 콜백
  final void Function(Color?)? onColorSelected;

  /// 현재 선택된 색상
  final Color? selectedColor;

  /// 검색 키워드 콜백
  final void Function(String?)? onKeywordRemoved;

  /// 현재 선택된 검색 키워드
  final String? searchKeyword;

  const FilterButtons({
    Key? key,
    this.onDateRangeSelected,
    this.selectedDateRange,
    this.onLocationSelected,
    this.selectedLocation,
    this.onColorSelected,
    this.selectedColor,
    this.onKeywordRemoved,
    this.searchKeyword,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: [
          // 키워드 필터 버튼 (있을 경우에만 표시)
          if (searchKeyword != null && searchKeyword!.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      searchKeyword!,
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        onKeywordRemoved?.call(null);
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 날짜 선택 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectCustomRange(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedDateRange != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: selectedDateRange != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: selectedDateRange != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedDateRange != null
                          ? '${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}'
                          : '날짜 선택',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        color: selectedDateRange != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        fontWeight: selectedDateRange != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (selectedDateRange != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          onDateRangeSelected?.call(null);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 위치 선택 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLocationMapDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedLocation != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: selectedLocation != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: selectedLocation != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedLocation ?? '위치',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        color: selectedLocation != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        fontWeight: selectedLocation != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (selectedLocation != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          onLocationSelected?.call(null);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 색상 선택 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showColorPicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedColor != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: selectedColor != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedColor != null)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      )
                    else
                      Icon(
                        Icons.palette,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      selectedColor != null ? '색상 선택됨' : '색상',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        color: selectedColor != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        fontWeight: selectedColor != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (selectedColor != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          onColorSelected?.call(null);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 색상 선택 다이얼로그 표시
  Future<void> _showColorPicker(BuildContext context) async {
    // 대표 색상 목록
    final representativeColors = ColorModel.representativeColors;

    final selectedValue = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('색상 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: representativeColors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, representativeColors[index].color);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: representativeColors[index].color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (selectedValue != null && onColorSelected != null) {
      onColorSelected!(selectedValue);
    }
  }

  // 사용자 정의 날짜 범위 선택
  Future<void> _selectCustomRange(BuildContext context) async {
    await _showDateRangePicker(context);
  }

  // 날짜 선택 다이얼로그 표시
  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2000); // 시작 날짜를 2000년으로 설정

    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      currentDate: now,
      saveText: '선택',
      cancelText: '취소',
      confirmText: '확인',
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
              // 테마 설정
              ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: child!,
          ),
        );
      },
    );

    if (result != null) {
      // 1년 이상의 기간을 선택한 경우
      final daysDifference = result.end.difference(result.start).inDays;
      if (daysDifference > 365) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('최대 1년까지의 기간만 선택할 수 있습니다.'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 100,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
        return;
      }

      onDateRangeSelected?.call(result);
    }
  }

  // 날짜 포맷 메서드
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 지도/주소/반경 설정 다이얼로그 (실제 구현)
  Future<void> _showLocationMapDialog(BuildContext context) async {
    // 기본 위치: 서울
    LatLng selectedLatLng = LatLng(37.5665, 126.9780);
    double selectedRadius = 1.0; // km (기본값 1km)
    TextEditingController addressController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    double mapZoom = 13.0;
    final mapController = MapController();
    String? searchErrorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        void updateZoomFromController(StateSetter setState) {
          final newZoom = mapController.camera.zoom;
          if (newZoom != mapZoom) {
            setState(() {
              mapZoom = newZoom;
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('위치로 사진 필터링'),
              content: SizedBox(
                width: 370,
                height: 540,
                child: Column(
                  children: [
                    // 주소 검색
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              hintText: '주소 검색 (예: 서울, New York, Paris)',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                            ),
                            onSubmitted: (value) async {
                              if (value.trim().length < 2) {
                                setState(() {
                                  searchErrorMsg = '2글자 이상 입력해 주세요.';
                                  searchResults = [];
                                });
                                return;
                              }
                              setState(() {
                                isSearching = true;
                                searchErrorMsg = null;
                              });
                              try {
                                final url = Uri.parse(
                                    'https://photon.komoot.io/api/?q=${Uri.encodeComponent(value)}');
                                final res = await http.get(url);
                                debugPrint(
                                    'Photon 응답: status=${res.statusCode}, body=${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
                                if (res.statusCode == 200) {
                                  final data = json.decode(res.body);
                                  final features =
                                      data['features'] as List<dynamic>;
                                  if (features.isEmpty) {
                                    setState(() {
                                      searchErrorMsg = '검색 결과가 없습니다.';
                                      searchResults = [];
                                    });
                                  } else {
                                    searchResults = features.map((f) {
                                      final props = f['properties'];
                                      final coords =
                                          f['geometry']['coordinates'];
                                      return {
                                        'name': props['name'] ?? '',
                                        'address': props['street'] ??
                                            props['city'] ??
                                            props['country'] ??
                                            '',
                                        'lat': coords[1],
                                        'lng': coords[0],
                                      };
                                    }).toList();
                                    setState(() {
                                      searchErrorMsg = null;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    searchErrorMsg = '서버 오류: ${res.statusCode}';
                                    searchResults = [];
                                  });
                                }
                              } catch (e) {
                                debugPrint('Photon 검색 에러: $e');
                                setState(() {
                                  searchErrorMsg = '네트워크 오류 또는 서버 응답 실패';
                                  searchResults = [];
                                });
                              }
                              setState(() {
                                isSearching = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final value = addressController.text;
                            if (value.trim().length < 2) {
                              setState(() {
                                searchErrorMsg = '2글자 이상 입력해 주세요.';
                                searchResults = [];
                              });
                              return;
                            }
                            setState(() {
                              isSearching = true;
                              searchErrorMsg = null;
                            });
                            try {
                              final url = Uri.parse(
                                  'https://photon.komoot.io/api/?q=${Uri.encodeComponent(value)}');
                              final res = await http.get(url);
                              debugPrint(
                                  'Photon 응답: status=${res.statusCode}, body=${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
                              if (res.statusCode == 200) {
                                final data = json.decode(res.body);
                                final features =
                                    data['features'] as List<dynamic>;
                                if (features.isEmpty) {
                                  setState(() {
                                    searchErrorMsg = '검색 결과가 없습니다.';
                                    searchResults = [];
                                  });
                                } else {
                                  searchResults = features.map((f) {
                                    final props = f['properties'];
                                    final coords = f['geometry']['coordinates'];
                                    return {
                                      'name': props['name'] ?? '',
                                      'address': props['street'] ??
                                          props['city'] ??
                                          props['country'] ??
                                          '',
                                      'lat': coords[1],
                                      'lng': coords[0],
                                    };
                                  }).toList();
                                  setState(() {
                                    searchErrorMsg = null;
                                  });
                                }
                              } else {
                                setState(() {
                                  searchErrorMsg = '서버 오류: ${res.statusCode}';
                                  searchResults = [];
                                });
                              }
                            } catch (e) {
                              debugPrint('Photon 검색 에러: $e');
                              setState(() {
                                searchErrorMsg = '네트워크 오류 또는 서버 응답 실패';
                                searchResults = [];
                              });
                            }
                            setState(() {
                              isSearching = false;
                            });
                          },
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (searchErrorMsg != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(searchErrorMsg!,
                            style: TextStyle(
                                fontFamily: 'Paperlogy',
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w400)),
                      ),
                    if (searchResults.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, idx) {
                              final r = searchResults[idx];
                              return ListTile(
                                leading: const Icon(Icons.place,
                                    color: Colors.blueAccent),
                                title: Text(r['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(r['address'] ?? '',
                                    style: const TextStyle(fontSize: 12)),
                                onTap: () {
                                  setState(() {
                                    selectedLatLng = LatLng(r['lat'], r['lng']);
                                    mapZoom = 13.0;
                                    mapController.move(selectedLatLng, mapZoom);
                                    searchResults = [];
                                    addressController.text = r['name'] ?? '';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // 지도
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border:
                              Border.all(color: Colors.blue.shade100, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: selectedRadius, end: selectedRadius),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              builder: (context, animatedRadius, child) {
                                return FlutterMap(
                                  mapController: mapController,
                                  options: MapOptions(
                                    center: selectedLatLng,
                                    zoom: mapZoom,
                                    onTap: (tapPos, latlng) {
                                      setState(() {
                                        selectedLatLng = latlng;
                                      });
                                      mapController.move(latlng, mapZoom);
                                    },
                                    onPositionChanged: (pos, hasGesture) {
                                      updateZoomFromController(setState);
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                                      subdomains: const ['a', 'b', 'c'],
                                      userAgentPackageName: 'com.snaporia.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          width: 36,
                                          height: 36,
                                          point: selectedLatLng,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              border: Border.all(
                                                color: Colors.blueAccent,
                                                width: 2.2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.place,
                                                color: Colors.blueAccent,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: selectedLatLng,
                                          color: Colors.blue.withOpacity(0.18),
                                          borderStrokeWidth: 2,
                                          borderColor: Colors.blue,
                                          radius: animatedRadius * 1000,
                                          useRadiusInMeter: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            // 확대/축소 버튼
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Column(
                                children: [
                                  FloatingActionButton(
                                    heroTag: 'zoom_in',
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    elevation: 2,
                                    onPressed: () {
                                      final newZoom =
                                          (mapZoom + 1).clamp(2.0, 18.0);
                                      mapController.move(
                                          selectedLatLng, newZoom);
                                      setState(() {
                                        mapZoom = newZoom;
                                      });
                                    },
                                    child: const Icon(Icons.add,
                                        color: Colors.black),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton(
                                    heroTag: 'zoom_out',
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    elevation: 2,
                                    onPressed: () {
                                      final newZoom =
                                          (mapZoom - 1).clamp(2.0, 18.0);
                                      mapController.move(
                                          selectedLatLng, newZoom);
                                      setState(() {
                                        mapZoom = newZoom;
                                      });
                                    },
                                    child: const Icon(Icons.remove,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 반경 슬라이더
                    Row(
                      children: [
                        const Text('반경:'),
                        Expanded(
                          child: Slider(
                            value: selectedRadius,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '${selectedRadius.toStringAsFixed(1)}km',
                            onChanged: (v) {
                              setState(() {
                                selectedRadius = v;
                              });
                            },
                            activeColor: Colors.blueAccent,
                            thumbColor: Colors.white,
                          ),
                        ),
                        Text('${selectedRadius.toStringAsFixed(1)}km',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    // lat,lng,radius 형태로 전달
                    final locationString =
                        '${selectedLatLng.latitude},${selectedLatLng.longitude},${selectedRadius.toStringAsFixed(1)}';
                    print('[DEBUG] setLocation에 전달: ' + locationString);
                    final lat = selectedLatLng.latitude;
                    final lng = selectedLatLng.longitude;
                    final radius = selectedRadius;
                    print('[DEBUG] 파싱될 값: lat=$lat, lng=$lng, radius=$radius');
                    final viewModel = context.read<HomeViewModel>();
                    viewModel.setLocation(locationString);
                    print('[DEBUG] Navigator.pop 호출 직전');
                    Navigator.pop(context, locationString);
                    print('[DEBUG] Navigator.pop 호출 직후');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
