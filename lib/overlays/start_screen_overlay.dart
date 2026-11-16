import 'package:flutter/material.dart';
import 'package:one_bullet/debug/mock_leaderboard.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/theme/west.dart';
import 'package:one_bullet/theme/west_widgets.dart';

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

    return Material(
      color: West.dustDeep,
      child: WestBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // ===== SYSTEM MENU BUTTON (TOP RIGHT) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: West.gold),
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

              const Spacer(flex: 2),

              // ===== TITLE =====
              const WestLogo(),

              const Spacer(flex: 3),

              // ===== START BUTTON =====
              WestButton(
                label: 'START',
                icon: Icons.play_arrow_rounded,
                primary: true,
                color: West.gold,
                onTap: () => widget.game.startGame(),
              ),

              const SizedBox(height: 14),

              // ===== HIGH SCORE =====
              ValueListenableBuilder<Duration>(
                valueListenable: ScoreService.highScore,
                builder: (context, score, _) {
                  if (score == Duration.zero) {
                    return Text(
                      'NO SURVIVAL RECORD YET',
                      style: westText(
                        size: 11,
                        color: West.textMuted,
                        weight: FontWeight.w500,
                        spacing: 2,
                      ),
                    );
                  }

                  return Text(
                    'BEST  ${ScoreService.formatDuration(score)}',
                    style: westText(
                      size: 14,
                      color: West.gold,
                      weight: FontWeight.w700,
                      spacing: 2,
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

                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        WestButton(
                          label: _isSigningIn
                              ? 'CONNECTING...'
                              : 'CONNECT PLAY GAMES',
                          icon: _isSigningIn ? null : Icons.emoji_events,
                          color: West.sandLight,
                          width: 280,
                          onTap: _isSigningIn ? null : _signInToPlayGames,
                        ),
                        Text(
                          'Save achievements and join global leaderboards',
                          style: TextStyle(
                            color: West.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              // ===== MINIMAL FOOTER =====
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  'fire a bullet, survive as long as you can',
                  style: TextStyle(
                    color: West.textPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
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
    if (mockLeaderboard) {
      onAuthorized();
      return;
    }

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
    return PlankPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SystemButton(
            icon: Icons.leaderboard,
            label: "LEADERBOARD",
            color: West.gold,
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
          _SystemButton(
            icon: Icons.emoji_events,
            label: "ACHIEVEMENTS",
            color: West.gold,
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
          _SystemButton(
            icon: Icons.settings,
            label: "SETTINGS",
            color: West.blood,
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WestButton(
      label: label,
      icon: icon,
      color: color,
      width: double.infinity,
      onTap: onTap,
    );
  }
}
