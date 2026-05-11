import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';

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

  Future<void> _checkConnectivityAndLoad() async {
    final result = await _connectivity.checkConnectivity();
    final isConnected =
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile);

    if (isConnected) {
      _loadLeaderboards();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "No connection to the arena network";
      });
    }
  }

  Future<void> _loadLeaderboards() async {
    try {
      final data = await PlayGamesService.instance.loadLeaderboardScores();

      setState(() {
        _scores
          ..clear()
          ..addAll(data);
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Failed to reach scoreboard";
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
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: const Color(0xFF0B0F14),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF1A0F0F), Color(0xFF070A0D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: _buildCard(colors)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(22),
      width: 380,
      constraints: const BoxConstraints(maxHeight: 560),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12161C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB24A).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B2F).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _title(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
          const SizedBox(height: 14),
          _closeButton(),
        ],
      ),
    );
  }

  Widget _title() {
    return const Text(
      "LEADERBOARD",
      style: TextStyle(
        color: Color(0xFFFFC46B),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A3C)),
      );
    }

    if (_hasError) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_scores.isEmpty) {
      return const Center(
        child: Text(
          "No survivors yet",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _scores.length,
      itemBuilder: (context, i) {
        final s = _scores[i];
        final holder = s.scoreHolder;
        final name = holder.displayName;
        final score = s.displayScore;
        final rank = s.rank;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F27).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFF7A3C).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Text(
                "$rank",
                style: const TextStyle(
                  color: Color(0xFFFFB24A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                score,
                style: const TextStyle(
                  color: Color(0xFFFF6A3D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: _close,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF7A3C)),
        ),
        child: const Text(
          "CLOSE",
          style: TextStyle(
            color: Color(0xFFFFB24A),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
