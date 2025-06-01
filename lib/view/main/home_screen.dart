import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/photo_grid_view.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../model/photo_model.dart';
import '../../model/color_model.dart';
import '../../utils/color_utils.dart';
import '../widgets/bottom_frame47.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/loading_spinner.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  int _bottomSelectedIndex = -1; // -1: 아무것도 선택 안함
  bool _isLoadingSpinnerVisible = false;

  @override
  void initState() {
    super.initState();

    // 화면 로드 시 데이터 로드 및 자동 스캔 시작
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<HomeViewModel>();
      // 이전 스캔 상태 확인 및 초기화
      await viewModel.initialize();

      // 갤러리에 새로운 사진이 있는지 확인하고 필요시 스캔
      await viewModel.checkAndScanNewPhotos();
    });

    // 스크롤 이벤트 리스너 등록
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 핸들러
  void _onScroll() {
    // 스크롤이 끝에 도달했는지 확인
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 추가 데이터 로드
      final viewModel = context.read<HomeViewModel>();
      if (!viewModel.isLoading && viewModel.hasMorePhotos) {
        viewModel.loadPhotos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // 라벨링 진행률 구하기
        final double labelingProgress = viewModel.labelingProgress.value;
        final bool isLabelingDone = labelingProgress >= 1.0;
        // 로딩 스피너 100% 완료 시 검색 다이얼로그 띄우기
        if (_isLoadingSpinnerVisible && viewModel.isReadyToSearch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLoadingSpinnerVisible) {
              setState(() => _isLoadingSpinnerVisible = false);
              _showSearchDialog();
            }
          });
        }
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: viewModel.isSelectionMode
                ? const SizedBox.shrink()
                : const Text(
                    'Snaporia',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
            actions: viewModel.isSelectionMode
                ? <Widget>[
                    // 전체선택 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 2.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            viewModel.toggleSelectAll();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  viewModel.isAllSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  viewModel.isAllSelected ? '전체해제' : '전체선택',
                                  style: TextStyle(
                                    fontFamily: 'Paperlogy',
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 공유 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 2.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (viewModel.selectedPhotos.isEmpty) {
                              _showNoSelectedPhotosDialog(context);
                            } else {
                              _shareSelectedPhotos(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.ios_share,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '공유',
                                  style: TextStyle(
                                    fontFamily: 'Paperlogy',
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 취소 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 2.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            viewModel.handleCancelSelectionMode();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '취소',
                                  style: TextStyle(
                                    fontFamily: 'Paperlogy',
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                : <Widget>[
                    // 선택 버튼만 남김 (검색 아이콘 삭제)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            context
                                .read<HomeViewModel>()
                                .handleSelectButtonTap();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '선택',
                                  style: TextStyle(
                                    fontFamily: 'Paperlogy',
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildProgressIndicator(),
                  if (!viewModel.isSelectionMode)
                    Consumer<HomeViewModel>(
                      builder: (context, vm, child) => _FilterTagBar(
                        viewModel: vm,
                        onReset: () async {
                          await vm.resetAllFilters();
                        },
                      ),
                    ),
                  Expanded(
                    child: _buildBody(),
                  ),
                ],
              ),
              ValueListenableBuilder<double>(
                valueListenable: viewModel.labelingProgress,
                builder: (context, progress, child) {
                  if (_isLoadingSpinnerVisible) {
                    return LoadingSpinner(progressPercent: progress * 100);
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
          bottomNavigationBar: viewModel.isSelectionMode
              ? null
              : BottomFrame47(
                  onDateTap: () async {
                    setState(() => _bottomSelectedIndex = 0);
                    final picked = await _selectDateRange(context);
                    if (picked != null) {
                      context.read<HomeViewModel>().setDateRange(picked);
                    }
                    setState(() => _bottomSelectedIndex = -1);
                  },
                  onLocationTap: () async {
                    setState(() => _bottomSelectedIndex = 1);
                    final selectedLocation =
                        await _showLocationMapDialog(context);
                    if (selectedLocation != null) {
                      await context
                          .read<HomeViewModel>()
                          .setLocation(selectedLocation);
                    }
                    setState(() => _bottomSelectedIndex = -1);
                  },
                  onColorTap: () async {
                    setState(() => _bottomSelectedIndex = 2);
                    final color = await _selectColor(context);
                    if (color != null) {
                      context.read<HomeViewModel>().setColor(color);
                    }
                    setState(() => _bottomSelectedIndex = -1);
                  },
                  onSearchTap: () async {
                    setState(() => _bottomSelectedIndex = 3);
                    if (viewModel.isReadyToSearch) {
                      _showSearchDialog();
                      setState(() => _bottomSelectedIndex = -1);
                      return;
                    }
                    // 라벨링 필요: 바텀시트 → (로딩스피너 or 키워드)
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CustomBottomSheet(
                        onStart: () async {
                          Navigator.of(context).pop();
                          if (context.read<HomeViewModel>().isReadyToSearch) {
                            _showSearchDialog();
                          } else {
                            setState(() => _isLoadingSpinnerVisible = true);
                            // 라벨링은 이미 백그라운드에서 진행 중이므로 여기서 startLabeling() 호출 X
                          }
                        },
                        onClose: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                    await Future.delayed(const Duration(milliseconds: 300));
                    setState(() => _bottomSelectedIndex = -1);
                  },
                  selectedIndex: _bottomSelectedIndex,
                ),
        );
      },
    );
  }

  /// 진행 상황 인디케이터
  Widget _buildProgressIndicator() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return ValueListenableBuilder<double>(
          valueListenable: viewModel.scanProgress,
          builder: (context, progress, child) {
            if (viewModel.isScanning || progress > 0.0 && progress < 1.0) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '사진 스캔 중...',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.shade100,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// 검색 다이얼로그 표시
  void _showSearchDialog() {
    final viewModel = context.read<HomeViewModel>();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        content: SizedBox(
          width: 320,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '키워드 검색',
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w400,
                  fontSize: 22,
                  height: 1.1,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search,
                          color: Color(0xFF2F3036), size: 18),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          height: 1.4,
                          color: Color(0xFF8F9098),
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: '키워드를 입력하세요.',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF8F9098),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '1.) 키워드로만 입력해주세요 (예: 시계, 오토바이)\n2.) 영어로 입력할 경우 소문자로만 입력해주세요 (예 : car, dog)',
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w300,
                  fontSize: 10.5,
                  height: 1.7,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      side: const BorderSide(
                          color: Color(0xFF006FFD), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: Color(0xFF006FFD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text;
                      if (text.isNotEmpty) {
                        viewModel.setSearchKeyword(text);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      backgroundColor: const Color(0xFF006FFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '검색',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜 범위 선택
  Future<DateTimeRange?> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2000);

    return await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: context.read<HomeViewModel>().dateRange,
      saveText: '선택',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
  }

  /// flutter_map 기반 위치 선택 다이얼로그 (상단 필터와 동일)
  Future<String?> _showLocationMapDialog(BuildContext context) async {
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
                                    'https://photon.komoot.io/api/?q=${Uri.encodeComponent(value)}');
                                final res = await http.get(url);
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
                                    searchErrorMsg =
                                        '서버 오류: ${res.statusCode}';
                                    searchResults = [];
                                  });
                                }
                              } catch (e) {
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
                                  'https://photon.komoot.io/api/?q=${Uri.encodeComponent(value)}');
                              final res = await http.get(url);
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
                                  searchErrorMsg = '서버 오류: ${res.statusCode}';
                                  searchResults = [];
                                });
                              }
                            } catch (e) {
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
                    Navigator.pop(context, locationString);
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

  /// 색상 선택
  Future<Color?> _selectColor(BuildContext context) async {
    // 대표 색상 목록 사용
    final colors = ColorModel.representativeColors.map((c) => c.color).toList();

    return await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색상 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context, colors[index]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
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
      ),
    );
  }

  /// 본문 영역 구성
  Widget _buildBody() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // 중단된 스캔이 있는지 확인
        if (viewModel.isScanning &&
            viewModel.scanProgress.value > 0.0 &&
            viewModel.scanProgress.value < 1.0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  '중단된 스캔이 있습니다',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '진행률: ${(viewModel.scanProgress.value * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => viewModel.resumeScan(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('스캔 재개'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => viewModel.startScan(),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('처음부터 다시 시작'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (viewModel.photos.isEmpty) {
          // 스캔 중인 경우와 필터링 결과가 없는 경우를 구분
          if (viewModel.isScanning) {
            // 스캔 중인 경우
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '사진을 스캔하는 중입니다...',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // 검색 또는 필터링 결과가 없는 경우
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '조건에 맞는 사진이 없습니다',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  if (viewModel.dateRange != null ||
                      viewModel.selectedLat != null &&
                          viewModel.selectedLng != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: () => viewModel.resetAllFilters(),
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('필터 초기화'),
                      ),
                    ),
                ],
              ),
            );
          }
        }

        // 사진 그리드 뷰 표시
        return Stack(
          children: [
            PhotoGridView(
              controller: _scrollController,
              photos: viewModel.photos,
              onPhotoTap: (photo) => viewModel.isSelectionMode
                  ? viewModel.togglePhotoSelection(photo.id)
                  : _showPhotoDetail(context, photo),
            ),

            // 로딩 인디케이터
            if (viewModel.isLoading)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 사진 상세보기 다이얼로그
  void _showPhotoDetail(BuildContext context, PhotoModel photo) {
    // 선택된 사진의 color 값과 라벨 데이터 출력
    debugPrint(
        '선택된 사진 ID: ${photo.id}, 저장된 색상 값: ${photo.color ?? "없음"}, 사진 라벨: ${photo.labels ?? "없음"}');

    // 현재 표시 중인 사진의 인덱스 찾기
    final viewModel = context.read<HomeViewModel>();
    int currentIndex = viewModel.photos.indexWhere((p) => p.id == photo.id);
    if (currentIndex == -1) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 사진 영역 (스와이프 가능)
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        // 왼쪽으로 스와이프: 다음 사진
                        if (details.primaryVelocity! < 0) {
                          if (currentIndex < viewModel.photos.length - 1) {
                            setState(() {
                              currentIndex++;
                            });
                          }
                        }
                        // 오른쪽으로 스와이프: 이전 사진
                        else if (details.primaryVelocity! > 0) {
                          if (currentIndex > 0) {
                            setState(() {
                              currentIndex--;
                            });
                          }
                        }
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Hero(
                          tag: 'photo_${viewModel.photos[currentIndex].id}',
                          child: Image.file(
                            File(viewModel.photos[currentIndex].path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // 좌우 버튼 오버레이
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 이전 사진 버튼
                        if (currentIndex > 0)
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color: Colors.white.withOpacity(0.8),
                                size: 42,
                              ),
                              onPressed: () {
                                setState(() {
                                  currentIndex--;
                                });
                              },
                            ),
                          )
                        else
                          const SizedBox(width: 48),

                        // 다음 사진 버튼
                        if (currentIndex < viewModel.photos.length - 1)
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: Colors.white.withOpacity(0.8),
                                size: 42,
                              ),
                              onPressed: () {
                                setState(() {
                                  currentIndex++;
                                });
                              },
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),

                // 하단 정보 표시 영역
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 색상 정보 표시
                      if (viewModel.photos[currentIndex].color != null)
                        _buildColorInfo(viewModel.photos[currentIndex].color!),

                      const SizedBox(height: 8),

                      // 인덱스 및 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 현재 사진 인덱스 표시
                          Text(
                            '${currentIndex + 1} / ${viewModel.photos.length}',
                            style: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // 닫기 버튼
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 색상 정보를 표시하는 위젯
  Widget _buildColorInfo(String colorHex) {
    try {
      // 색상 코드에서 Hue 값 계산
      final double hue = ColorUtils.hexToHue(colorHex);
      final Color color = ColorUtils.hexToColor(colorHex);
      final String colorName = ColorUtils.getColorNameFromHue(hue);

      return Row(
        children: [
          // 색상 샘플
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 색상 정보 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color: #$colorHex',
                  style: const TextStyle(fontFamily: 'Paperlogy', fontSize: 12),
                ),
                Text(
                  'Hue: ${hue.toStringAsFixed(1)}° - $colorName',
                  style: const TextStyle(fontFamily: 'Paperlogy', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return const Text('색상 정보를 처리할 수 없습니다');
    }
  }

  /// 선택된 사진이 없을 경우 다이얼로그 표시
  void _showNoSelectedPhotosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택된 사진이 없습니다'),
        content: const Text('선택된 사진이 없습니다. 사진을 선택한 후 공유를 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 선택된 사진이 있으면 공유 실행
  void _shareSelectedPhotos(BuildContext context) {
    try {
      final viewModel = context.read<HomeViewModel>();
      viewModel.shareSelectedPhotos(context).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 중 오류가 발생했습니다: $error')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유 기능을 사용할 수 없습니다: $e')),
      );
    }
  }
}

class _FilterTagBar extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onReset;
  const _FilterTagBar({required this.viewModel, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final List<Widget> tags = [];
    // 날짜 태그
    if (viewModel.dateRange != null) {
      tags.add(_Tag(
        label:
            '${viewModel.dateRange!.start.year}.${viewModel.dateRange!.start.month.toString().padLeft(2, '0')}.${viewModel.dateRange!.start.day.toString().padLeft(2, '0')} ~ '
            '${viewModel.dateRange!.end.year}.${viewModel.dateRange!.end.month.toString().padLeft(2, '0')}.${viewModel.dateRange!.end.day.toString().padLeft(2, '0')}',
        onRemove: () => viewModel.setDateRange(null),
      ));
    }
    // 위치 태그
    if (viewModel.selectedLat != null && viewModel.selectedLng != null) {
      tags.add(_Tag(
        label:
            '위치: ${viewModel.selectedLat!.toStringAsFixed(4)}, ${viewModel.selectedLng!.toStringAsFixed(4)} (${viewModel.selectedRadiusKm?.toStringAsFixed(1)}km)',
        onRemove: () => viewModel.setLocation(null),
      ));
    }
    // 색상 태그
    if (viewModel.selectedColor != null) {
      tags.add(_Tag(
        label: '색상',
        color: viewModel.selectedColor,
        onRemove: () => viewModel.setColor(null),
      ));
    }
    // 검색어 태그
    if (viewModel.searchKeyword != null &&
        viewModel.searchKeyword!.isNotEmpty) {
      tags.add(_Tag(
        label: '검색: ${viewModel.searchKeyword}',
        onRemove: () => viewModel.setSearchKeyword(null),
      ));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 태그들 (좌측부터)
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags,
            ),
          ),
          // 초기화 버튼 (우측 끝 고정, 태그가 있을 때만)
          IconButton.filledTonal(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '필터 초기화',
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onRemove;
  const _Tag({required this.label, this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.18) ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color ?? Colors.blue.shade200,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Paperlogy',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
