import '../model/photo_label.dart';

class PhotoLabelRepository {
  // 임시 메모리 저장소
  final Map<String, List<PhotoLabel>> _labelStorage = {};

  Future<void> saveLabels(String photoId, List<PhotoLabel>? labels) async {
    if (photoId.isEmpty) {
      throw ArgumentError('photoId는 비어있을 수 없습니다.');
    }

    // null인 경우 빈 리스트로 저장
    _labelStorage[photoId] = labels ?? [];
  }

  Future<List<PhotoLabel>> getLabels(String photoId) async {
    if (photoId.isEmpty) {
      throw ArgumentError('photoId는 비어있을 수 없습니다.');
    }

    try {
      // null 체크 및 안전한 반환
      return _labelStorage[photoId] ?? [];
    } catch (e) {
      print('라벨 조회 중 오류 발생: $e');
      return [];
    }
  }

  // 라벨 존재 여부 확인
  Future<bool> hasLabels(String photoId) async {
    if (photoId.isEmpty) {
      return false;
    }

    final labels = await getLabels(photoId);
    return labels.isNotEmpty;
  }

  // 라벨 삭제
  Future<void> deleteLabels(String photoId) async {
    if (photoId.isEmpty) {
      throw ArgumentError('photoId는 비어있을 수 없습니다.');
    }

    _labelStorage.remove(photoId);
  }
}
