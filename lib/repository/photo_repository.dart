import 'package:photo_manager/photo_manager.dart';

class PhotoRepository {
  Future<List<AssetEntity>> getPhotos() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isEmpty) return [];

    final List<AssetEntity> photos = await albums[0].getAssetListPaged(
      page: 0,
      size: 80,
    );

    return photos;
  }
}
