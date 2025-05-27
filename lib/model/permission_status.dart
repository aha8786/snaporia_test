/// 앱 권한 상태를 정의하는 enum
enum PermissionStatus {
  /// 권한 확인 중
  checking,

  /// 권한 승인됨
  granted,

  /// 권한 거부됨
  denied,

  /// 권한 영구 거부됨
  permanentlyDenied,
}
