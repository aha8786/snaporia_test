import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// 권한 안내 다이얼로그
class PermissionGuideDialog extends StatelessWidget {
  /// 설정 열기 콜백
  final Future<void> Function() onOpenSettings;

  /// 권한 재요청 콜백
  final Future<void> Function() onRetry;

  /// 닫기 콜백
  final VoidCallback onClose;

  /// 영구 거부 여부
  final bool isPermanentlyDenied;

  const PermissionGuideDialog({
    super.key,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onClose,
    required this.isPermanentlyDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isPermanentlyDenied ? '권한 설정 필요' : '저장소 접근 권한 필요',
        style: TextStyle(
          fontFamily: 'Paperlogy',
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        isPermanentlyDenied
            ? '설정에서 저장소 접근 권한을 허용해주세요'
            : '사진을 불러오기 위해 저장소 접근 권한이 필요합니다',
        style: TextStyle(
          fontFamily: 'Paperlogy',
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose();
          },
          child: Text(
            '취소',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isPermanentlyDenied
              ? () async => await onOpenSettings()
              : () async {
                  Navigator.of(context).pop();
                  await onRetry();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3578FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isPermanentlyDenied ? '설정으로 이동' : '다시 시도',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Android 전용 권한 안내 다이얼로그
class PermissionGuideDialogAndroid extends StatelessWidget {
  /// 설정 열기 콜백
  final Future<void> Function() onOpenSettings;

  /// 권한 재요청 콜백
  final Future<void> Function() onRetry;

  /// 영구 거부 안내 다이얼로그 표시 콜백
  final VoidCallback onPermanentDeny;

  /// 영구 거부 여부
  final bool isPermanentlyDenied;

  const PermissionGuideDialogAndroid({
    super.key,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onPermanentDeny,
    required this.isPermanentlyDenied,
  });

  @override
  Widget build(BuildContext context) {
    if (isPermanentlyDenied) {
      // 영구 거부 상태에서는 설정 안내 다이얼로그만 출력
      return AlertDialog(
        title: const Text('권한 설정 필요',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            textAlign: TextAlign.center),
        content: const Text('설정에서 저장소 접근 권한을 허용해주세요',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async => await onOpenSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3578FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '설정으로 이동',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }
    // 일반 권한 거부 상태
    return AlertDialog(
      title: const Text('저장소 접근 권한 필요',
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          textAlign: TextAlign.center),
      content: const Text('사진을 불러오기 위해 저장소 접근 권한이 필요합니다',
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          textAlign: TextAlign.center),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPermanentDeny();
          },
          child: const Text(
            '다시 묻지 않음',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await onRetry();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3578FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '다시 시도',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
