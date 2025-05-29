import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../viewmodel/splash_viewmodel.dart';
import '../../model/permission_status.dart';
import '../../constants/permission_constants.dart';
import '../widgets/permission_guide_dialog.dart';
import 'dart:io' show Platform;

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
      body: Stack(
        children: [
          Container(
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
          // 권한 안내 다이얼로그 감지 및 표시
          Consumer<SplashViewModel>(
            builder: (context, vm, child) {
              if (vm.shouldShowPermissionGuide) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ModalRoute.of(context)?.isCurrent ?? true) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Platform.isAndroid
                          ? PermissionGuideDialogAndroid(
                              isPermanentlyDenied: vm.isPermanentlyDenied,
                              onOpenSettings: vm.openSettings,
                              onRetry: () => vm.retryPermissionRequest(context),
                              onPermanentDeny: () {
                                vm.showPermissionGuidePermanent();
                              },
                            )
                          : PermissionGuideDialog(
                              isPermanentlyDenied: vm.isPermanentlyDenied,
                              onOpenSettings: vm.openSettings,
                              onRetry: () => vm.retryPermissionRequest(context),
                              onClose: vm.dismissPermissionGuide,
                            ),
                    );
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
