import 'package:flutter/material.dart';

/// Flutter widget version of the wave indicator for the HUD.
/// Displays the current wave number with flash animation on warnings.
class WaveIndicatorWidget extends StatefulWidget {
  const WaveIndicatorWidget({
    required this.waveNumber,
    required this.isFlashing,
    super.key,
  });

  /// Current wave number to display.
  final int waveNumber;

  /// Whether the indicator should flash (warning state).
  final bool isFlashing;

  @override
  State<WaveIndicatorWidget> createState() => _WaveIndicatorWidgetState();
}

class _WaveIndicatorWidgetState extends State<WaveIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _scaleController;
  late Animation<double> _flashAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Flash animation - loops continuously when flashing
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    // Scale animation - one-time pop when wave changes
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start scale animation on initial load
    _scaleController.forward();

    if (widget.isFlashing) {
      _flashController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle wave number change
    if (oldWidget.waveNumber != widget.waveNumber) {
      _scaleController.reset();
      _scaleController.forward();
    }

    // Handle flash state change
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _flashAnimation,
        builder: (context, child) {
          // Calculate flash color transition
          final flashColor = widget.isFlashing
              ? Color.lerp(
                  Colors.orange,
                  Colors.red,
                  _flashAnimation.value,
                )!
              : Colors.cyan;

          return Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color: flashColor.withValues(
                alpha: widget.isFlashing
                    ? 0.3 + _flashAnimation.value * 0.2
                    : 0.15,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: flashColor.withValues(
                  alpha:
                      widget.isFlashing ? 0.8 + _flashAnimation.value * 0.2 : 0.5,
                ),
                width: widget.isFlashing ? 2 + _flashAnimation.value : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "WAVE" label
                Text(
                  'WAVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
                // Wave number
                Text(
                  '${widget.waveNumber}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isFlashing
                        ? Color.lerp(
                            Colors.orange,
                            Colors.red,
                            _flashAnimation.value,
                          )
                        : Colors.white,
                    letterSpacing: 2,
                    height: 1,
                    shadows: widget.isFlashing
                        ? [
                            Shadow(
                              color: Colors.orange.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 10 + _flashAnimation.value * 10,
                            ),
                          ]
                        : null,
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
