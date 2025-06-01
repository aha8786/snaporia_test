import 'package:flutter/material.dart';
import 'dart:math';

class LoadingSpinner extends StatefulWidget {
  final double? progressPercent; // 0~100, null이면 미표시
  final VoidCallback? onClose;
  final VoidCallback? onComplete;
  const LoadingSpinner(
      {super.key, this.progressPercent, this.onClose, this.onComplete});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int blobCount = 7;
  late List<_BlobCircle> circles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    final rand = Random();
    circles = List.generate(blobCount, (i) {
      final angle = 2 * pi * i / blobCount + rand.nextDouble() * pi;
      final baseRadius = 0.12 + rand.nextDouble() * 0.08;
      final animRadius = 0.05 + rand.nextDouble() * 0.04;
      final size = 0.14 + rand.nextDouble() * 0.08;
      return _BlobCircle(
        angle: angle,
        baseRadius: baseRadius,
        animRadius: animRadius,
        size: size,
        phase: rand.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void didUpdateWidget(covariant LoadingSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 진행률이 100%가 되면 onComplete 콜백 호출
    if (widget.progressPercent != null && widget.progressPercent! >= 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'AI가 열심히 사진을 분석 중이에요!\n조금만 기다려 주세요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'paperlogy',
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double size =
                        min(constraints.maxWidth, constraints.maxHeight) * 0.7;
                    return Column(
                      children: [
                        SizedBox(
                          width: size,
                          height: size,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final t = _controller.value;
                              return Stack(
                                children: [
                                  for (final c in circles)
                                    Positioned(
                                      left: size / 2 +
                                          cos(c.angle + t * 2 * pi + c.phase) *
                                              size *
                                              c.baseRadius -
                                          size * c.size / 2 +
                                          sin(t * 2 * pi + c.phase) *
                                              size *
                                              c.animRadius,
                                      top: size / 2 +
                                          sin(c.angle + t * 2 * pi + c.phase) *
                                              size *
                                              c.baseRadius -
                                          size * c.size / 2 +
                                          cos(t * 2 * pi + c.phase) *
                                              size *
                                              c.animRadius,
                                      width: size * c.size,
                                      height: size * c.size,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF21D1FF),
                                              Color(0xFF0578FF)
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        if (widget.progressPercent != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 18.0),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _controller,
                                // progressPercent는 외부에서 바뀌므로 setState로 갱신됨
                              ]),
                              builder: (context, child) {
                                return Text(
                                  '진행률 ${widget.progressPercent!.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontFamily: 'paperlogy',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // 우측 상단 X 닫기 버튼
          Positioned(
            top: 32,
            right: 24,
            child: GestureDetector(
              onTap: widget.onClose,
              child: const Icon(
                Icons.close,
                size: 32,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobCircle {
  final double angle;
  final double baseRadius;
  final double animRadius;
  final double size;
  final double phase;
  _BlobCircle({
    required this.angle,
    required this.baseRadius,
    required this.animRadius,
    required this.size,
    required this.phase,
  });
}
