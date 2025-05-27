/// 기본 모델 클래스 - 모든 모델의 기본이 되는 클래스
abstract class BaseModel {
  /// 기본 생성자
  const BaseModel();

  /// JSON 형식으로 변환하는 메서드
  Map<String, dynamic> toMap();
}
