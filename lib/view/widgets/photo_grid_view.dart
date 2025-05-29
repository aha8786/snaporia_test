import 'dart:io';
import 'package:flutter/material.dart';
import '../../model/photo_model.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'package:provider/provider.dart';

/// 사진 그리드 뷰 위젯
class PhotoGridView extends StatelessWidget {
  /// 스크롤 컨트롤러
  final ScrollController controller;

  /// 사진 목록
  final List<PhotoModel> photos;

  /// 사진 클릭 이벤트 콜백
  final Function(PhotoModel) onPhotoTap;

  /// 생성자
  const PhotoGridView({
    super.key,
    required this.controller,
    required this.photos,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    // 그리드 뷰에서 열 수 계산
    const int crossAxisCount = 5;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        controller: controller,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0, // 정사각형 아이템
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];

          // 경로가 비어있는지 확인
          if (photo.path.isEmpty) {
            return _buildErrorPlaceholder();
          }

          // 파일이 실제로 존재하는지 확인
          final file = File(photo.path);
          if (!file.existsSync()) {
            return _buildErrorPlaceholder();
          }

          // 사진 아이템 위젯 생성
          return _buildPhotoItem(photo);
        },
      ),
    );
  }

  /// 오류 플레이스홀더 위젯 생성
  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final bool isSelectionMode = viewModel.isSelectionMode;
        final bool isSelected = viewModel.isPhotoSelected(photo.id);
        return GestureDetector(
          onTap: () {
            onPhotoTap(photo);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'photo_${photo.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('이미지 로드 실패: $error');
                      return _buildErrorPlaceholder();
                    },
                  ),
                ),
              ),
              // 선택 모드에서 선택된 경우 오버레이 및 체크 아이콘 표시
              if (isSelectionMode)
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blueAccent,
                        size: 44,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
