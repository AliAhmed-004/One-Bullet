import 'package:flutter/material.dart';

class WaveIndicatorWidget extends StatefulWidget {
  const WaveIndicatorWidget({
    required this.waveNumber,
    required this.isFlashing,
    super.key,
  });

  final int waveNumber;
  final bool isFlashing;

  @override
  State<WaveIndicatorWidget> createState() => _WaveIndicatorWidgetState();
}

class _WaveIndicatorWidgetState extends State<WaveIndicatorWidget>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  late final AnimationController _scaleController;
  late final Animation<double> _flashAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _flashAnimation = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();

    if (widget.isFlashing) {
      _flashController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.waveNumber != widget.waveNumber) {
      _scaleController.reset();
      _scaleController.forward();
    }

    if (oldWidget.isFlashing != widget.isFlashing) {
      if (widget.isFlashing) {
        _flashController.repeat(reverse: true);
      } else {
        _flashController.stop();
      }
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseAccent = widget.isFlashing
        ? Color.lerp(
            Colors.orangeAccent,
            Colors.redAccent,
            _flashAnimation.value,
          )!
        : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _flashAnimation,
        builder: (context, _) {
          final glowStrength = widget.isFlashing
              ? 0.25 + _flashAnimation.value * 0.25
              : 0.1;

          return Container(
            width: 130,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: baseAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WAVE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.waveNumber}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    height: 1,
                    color: baseAccent,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: baseAccent.withValues(alpha: glowStrength * 2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
