import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/wave_indicator_widget.dart';
import 'package:one_bullet/services/score_service.dart';

class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PauseButton(onTap: game.pauseGame),
                const Spacer(),
                _TimerAndWave(game: game),
                const Spacer(),
                const SizedBox(width: 24), // visual balance
              ],
            ),
            const SizedBox(height: 8),
            _HighScoreRow(),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.pause, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerAndWave extends StatelessWidget {
  const _TimerAndWave({required this.game});
  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: game.survivalTime,
      builder: (context, duration, _) {
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassTimerDisplay(time: '$minutes:$seconds'),
            const SizedBox(width: 12),
            ValueListenableBuilder<({int waveNumber, bool isFlashing})>(
              valueListenable: game.waveState,
              builder: (context, state, _) {
                return WaveIndicatorWidget(
                  waveNumber: state.waveNumber,
                  isFlashing: state.isFlashing,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _GlassTimerDisplay extends StatelessWidget {
  const _GlassTimerDisplay({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _HighScoreRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: ScoreService.highScore,
      builder: (context, highScore, _) {
        if (highScore <= Duration.zero) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Best ${ScoreService.formatDuration(highScore)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.amberAccent,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
