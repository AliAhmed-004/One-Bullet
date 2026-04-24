import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/theme/heat_theme.dart';

class StartScreenOverlay extends StatefulWidget {
  const StartScreenOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  State<StartScreenOverlay> createState() => _StartScreenOverlayState();
}

class _StartScreenOverlayState extends State<StartScreenOverlay> {
  bool _isSigningIn = false;

  Future<void> _signInToPlayGames() async {
    if (_isSigningIn) {
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    final success = await PlayGamesService.instance.signIn();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Play Games connected. Achievements and leaderboards are now synced.'
              : 'Could not connect to Play Games. You can try again from Settings.',
        ),
      ),
    );

    setState(() {
      _isSigningIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final heat = 0.15; // static calm menu state

    return Material(
      color: HeatTheme.background(heat),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== SYSTEM MENU BUTTON (TOP RIGHT) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.menu, color: HeatTheme.accent(heat)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _SystemMenu(game: widget.game),
                      );
                    },
                  ),
                ),
              ),

              // ===== TITLE =====
              Text(
                'ONE BULLET',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: HeatTheme.textPrimary(heat),
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 40),

              // ===== START BUTTON =====
              GestureDetector(
                onTap: () => widget.game.startGame(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: HeatTheme.surface(heat),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HeatTheme.accent(heat),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HeatTheme.accent(heat).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'START',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HeatTheme.accent(heat),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ===== HIGH SCORE =====
              ValueListenableBuilder<Duration>(
                valueListenable: ScoreService.highScore,
                builder: (context, score, _) {
                  if (score == Duration.zero) {
                    return Text(
                      'No survival record yet',
                      style: TextStyle(color: HeatTheme.textMuted(heat)),
                    );
                  }

                  return Text(
                    'Best: ${ScoreService.formatDuration(score)}',
                    style: TextStyle(
                      color: HeatTheme.emberGold,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),

              ValueListenableBuilder(
                valueListenable: PlayGamesService.instance.signInState,
                builder: (context, isSignedIn, _) {
                  if (!PlayGamesService.isSupportedPlatform || isSignedIn) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: _isSigningIn ? null : _signInToPlayGames,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: HeatTheme.surface(heat),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HeatTheme.accent(
                                heat,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSigningIn) ...[
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: HeatTheme.accent(heat),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                Icon(
                                  Icons.emoji_events,
                                  size: 16,
                                  color: HeatTheme.accent(heat),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _isSigningIn
                                    ? 'CONNECTING...'
                                    : 'CONNECT PLAY GAMES',
                                style: TextStyle(
                                  color: HeatTheme.textPrimary(heat),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save achievements and join global leaderboards',
                        style: TextStyle(
                          color: HeatTheme.textMuted(heat),
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 60),

              // ===== MINIMAL FOOTER =====
              Text(
                'fire a bullet, survive as long as you can',
                style: TextStyle(
                  color: HeatTheme.textMuted(heat),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),

              // Text(
              //   '',
              //   style: TextStyle(
              //     color: HeatTheme.textMuted(heat),
              //     fontSize: 12,
              //     letterSpacing: 1.2,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemMenu extends StatefulWidget {
  const _SystemMenu({required this.game});

  final OneBulletGame game;

  @override
  State<_SystemMenu> createState() => _SystemMenuState();
}

class _SystemMenuState extends State<_SystemMenu> {
  Future<void> _handlePlayGamesAction({
    required String featureLabel,
    required VoidCallback onAuthorized,
  }) async {
    if (!PlayGamesService.isSupportedPlatform) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Play Games is not available on this platform.'),
        ),
      );
      return;
    }

    if (PlayGamesService.instance.isSignedIn) {
      onAuthorized();
      return;
    }

    final shouldSignIn =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Sign In Required'),
              content: Text(
                'Sign in to Play Games before accessing $featureLabel.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Not Now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Sign In'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSignIn || !mounted) {
      return;
    }

    final success = await PlayGamesService.instance.signIn();

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Play Games sign-in failed. Please try again.'),
        ),
      );
      return;
    }

    onAuthorized();
  }

  @override
  Widget build(BuildContext context) {
    final heat = 0.2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HeatTheme.surface(heat),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: HeatTheme.accent(heat).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SystemButton(
            icon: Icons.leaderboard,
            label: "Leaderboard",
            onTap: () {
              _handlePlayGamesAction(
                featureLabel: 'leaderboards',
                onAuthorized: () {
                  Navigator.pop(context);
                  widget.game.overlays.add(OneBulletGame.leaderboardsOverlayId);
                  widget.game.overlays.remove(
                    OneBulletGame.startScreenOverlayId,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),

          _SystemButton(
            icon: Icons.emoji_events,
            label: "Achievements",
            onTap: () {
              _handlePlayGamesAction(
                featureLabel: 'achievements',
                onAuthorized: () {
                  Navigator.pop(context);
                  PlayGamesService.instance.showAchievements();
                },
              );
            },
          ),
          const SizedBox(height: 12),

          _SystemButton(
            icon: Icons.settings,
            label: "Settings",
            onTap: () {
              Navigator.pop(context);
              widget.game.overlays.add(OneBulletGame.settingsOverlayId);
              widget.game.overlays.remove(OneBulletGame.startScreenOverlayId);
            },
          ),
        ],
      ),
    );
  }
}

class _SystemButton extends StatelessWidget {
  const _SystemButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final heat = 0.2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: HeatTheme.surface(heat),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: HeatTheme.accent(heat).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: HeatTheme.accent(heat)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: HeatTheme.textPrimary(heat),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
