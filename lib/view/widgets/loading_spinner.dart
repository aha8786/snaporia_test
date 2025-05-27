import 'package:flutter/material.dart';
import 'dart:math';

class LoadingSpinner extends StatefulWidget {
  const LoadingSpinner({super.key});

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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  '사진 분석중',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'paperlogy',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '잠시만 기다려주세요...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'paperlogy',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final double size =
                    min(constraints.maxWidth, constraints.maxHeight) * 0.7;
                return SizedBox(
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
                );
              },
            ),
          ],
        ),
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
