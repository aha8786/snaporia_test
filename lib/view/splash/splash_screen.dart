import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../viewmodel/splash_viewmodel.dart';
import '../../model/permission_status.dart';
import '../../constants/permission_constants.dart';
import '../widgets/permission_guide_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // 애니메이션 시작
    _fadeController.forward();

    // ViewModel 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashViewModel>().initializeApp(context);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF21D1FF), // #21d1ff
              Color(0xFF0578FF), // #0578ff
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SizedBox(
              width: 235,
              height: 89,
              child: Text(
                'Snaporia',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w900, // 9 Black
                  fontSize: 44,
                  color: Colors.white,
                  height: 51.82 / 44, // Figma lineHeightPx/fontSize
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 필요한 경우 권한 가이드 다이얼로그 표시
  void _showPermissionGuideIfNeeded(
      BuildContext context, SplashViewModel viewModel) {
    if (viewModel.shouldShowPermissionGuide) {
      // 다이얼로그 표시 플래그 초기화
      viewModel.dismissPermissionGuide();

      // 실제 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false, // 사용자가 반드시 응답해야 함
          builder: (context) => PermissionGuideDialog(
            onOpenSettings: () async => await viewModel.openSettings(),
            onRetry: () {
              Navigator.of(context).pop();
              viewModel.retryPermissionRequest(context);
            },
            onClose: () {
              Navigator.of(context).pop();
            },
            isPermanentlyDenied: viewModel.isPermanentlyDenied,
          ),
        );
      });
    }
  }

  Widget _buildPermissionStatus(SplashViewModel viewModel) {
    switch (viewModel.permissionStatus) {
      case PermissionStatus.checking:
        return Column(
          children: [
            const CircularProgressIndicator(color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              '권한 확인 중...',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      case PermissionStatus.denied:
        return _buildErrorWidget(
          PermissionConstants.storagePermissionTitle,
          PermissionConstants.storagePermissionMessage,
          PermissionConstants.retryButtonText,
          () => viewModel.retryPermissionRequest(context),
        );
      case PermissionStatus.permanentlyDenied:
        return _buildErrorWidget(
          PermissionConstants.permanentlyDeniedTitle,
          PermissionConstants.permanentlyDeniedMessage,
          PermissionConstants.settingsButtonText,
          () async => await viewModel.openSettings(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorWidget(
    String title,
    String message,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Paperlogy',
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Paperlogy',
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
