import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:one_bullet/debug/mock_leaderboard.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/theme/west.dart';
import 'package:one_bullet/theme/west_widgets.dart';

/// Leaderboard as a wall of wanted posters: #1 gets the full "WANTED" poster,
/// everyone else a smaller pinned notice.
class LeaderboardsOverlay extends StatefulWidget {
  const LeaderboardsOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  State<LeaderboardsOverlay> createState() => _LeaderboardsOverlayState();
}

class _LeaderboardsOverlayState extends State<LeaderboardsOverlay>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final List<LeaderboardScoreData> _scores = [];

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _connectivity = Connectivity();
    _controller.forward();

    _checkConnectivityAndLoad();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivityAndLoad() async {
    if (mockLeaderboard) {
      setState(() {
        _scores
          ..clear()
          ..addAll(mockLeaderboardScores());
        _isLoading = false;
      });
      return;
    }

    final result = await _connectivity.checkConnectivity();
    final isConnected =
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile);

    if (!mounted) return;

    if (isConnected) {
      _loadLeaderboards();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No telegraph line to town';
      });
    }
  }

  Future<void> _loadLeaderboards() async {
    try {
      final data = await PlayGamesService.instance.loadLeaderboardScores();
      if (!mounted) return;

      setState(() {
        _scores
          ..clear()
          ..addAll(data);
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to reach the sheriff\'s office';
      });
    }
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.game.overlays.remove(OneBulletGame.leaderboardsOverlayId);
    widget.game.overlays.add(OneBulletGame.startScreenOverlayId);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: West.dustDeep,
      child: WestBackdrop(
        child: ColoredBox(
          color: West.dustDeep.withValues(alpha: 0.55),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'MOST WANTED',
                      style: westTitle(
                        size: 30,
                        color: West.gold,
                        spacing: 3,
                        shadow: West.dustDeep,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _buildContent()),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 6),
                      child: WestButton(
                        label: 'CLOSE',
                        icon: Icons.close_rounded,
                        primary: true,
                        width: 200,
                        onTap: _close,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: WantedPoster(
          width: 300,
          seed: 2,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: westText(size: 15, color: West.ink),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: West.gold));
    }

    if (_hasError) return _centerMessage(_errorMessage);

    if (_scores.isEmpty) return _centerMessage('No outlaws on record yet');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: _scores.length,
      itemBuilder: (context, i) {
        final s = _scores[i];
        final name = s.scoreHolder.displayName;
        final score = s.displayScore;
        final rank = s.rank;

        // Alternate the lean so the wall of posters feels hand-pinned.
        final tilt = (i.isEven ? -1 : 1) * (0.01 + (i % 3) * 0.006);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: i == 0
                ? _topPoster(name, score, tilt)
                : _notice(rank, name, score, tilt, i),
          ),
        );
      },
    );
  }

  /// First place: full-size WANTED poster.
  Widget _topPoster(String name, String score, double tilt) {
    return WantedPoster(
      width: 340,
      tilt: tilt,
      seed: 101,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      child: Column(
        children: [
          Text(
            'WANTED',
            style: westTitle(size: 44, color: West.blood, spacing: 5),
          ),
          Text(
            'FASTEST GUN IN THE WEST',
            style: westText(size: 10, color: West.ink, spacing: 3),
          ),
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: West.ink.withValues(alpha: 0.12),
              border: Border.all(color: West.ink, width: 3),
            ),
            child: const Icon(Icons.person, size: 60, color: West.ink),
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: westTitle(size: 22, color: West.ink, spacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'SURVIVED',
            style: westText(size: 11, color: West.rust, spacing: 4),
          ),
          Text(
            score,
            style: westTitle(size: 32, color: West.ink, spacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            'RANK #1',
            style: westText(
              size: 13,
              color: West.blood,
              spacing: 3,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Everyone else: a smaller pinned notice.
  Widget _notice(int rank, String name, String score, double tilt, int i) {
    return WantedPoster(
      width: 310,
      tilt: tilt,
      seed: 200 + i,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: westTitle(size: 24, color: West.rust, spacing: 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: westText(
                size: 15,
                color: West.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Text(score, style: westText(size: 15, color: West.ink)),
        ],
      ),
    );
  }
}
