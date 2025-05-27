import 'package:flutter/material.dart';

class BottomFrame47 extends StatelessWidget {
  final VoidCallback onDateTap;
  final VoidCallback onLocationTap;
  final VoidCallback onColorTap;
  final VoidCallback onSearchTap;
  final int selectedIndex;

  const BottomFrame47({
    super.key,
    required this.onDateTap,
    required this.onLocationTap,
    required this.onColorTap,
    required this.onSearchTap,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 경계선
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),
          Container(
            width: double.infinity,
            height: 58,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BottomIconButton(
                  icon: Icons.schedule,
                  label: '날 짜',
                  onTap: onDateTap,
                  selected: selectedIndex == 0,
                ),
                const SizedBox(width: 53),
                _BottomIconButton(
                  icon: Icons.location_on,
                  label: '위 치',
                  onTap: onLocationTap,
                  selected: selectedIndex == 1,
                ),
                const SizedBox(width: 53),
                _BottomIconButton(
                  icon: Icons.palette,
                  label: '색 상',
                  onTap: onColorTap,
                  selected: selectedIndex == 2,
                ),
                const SizedBox(width: 53),
                _BottomIconButton(
                  icon: Icons.search,
                  label: '검 색',
                  onTap: onSearchTap,
                  selected: selectedIndex == 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  const _BottomIconButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.selected});

  @override
  State<_BottomIconButton> createState() => _BottomIconButtonState();
}

class _BottomIconButtonState extends State<_BottomIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _controller.reverse();
    await _controller.forward();
    widget.onTap();
  }

  @override
  void didUpdateWidget(covariant _BottomIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selected && oldWidget.selected) {
      // 선택 해제 시 애니메이션 리셋
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF3578FF);
    final Color inactiveColor = Colors.black;
    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: 45,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.selected ? _scaleAnim.value : 1.0,
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: widget.selected ? activeColor : inactiveColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.0,
                color: widget.selected ? activeColor : inactiveColor,
              ),
              textAlign: TextAlign.center,
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
