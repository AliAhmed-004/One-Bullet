import 'dart:convert';

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
  final List<LeaderboardScoreData> _scores = [];

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Load leaderboards data from Play Games Services.
  Future<void> _loadLeaderboards() async {
    try {
      // Fetch LeaderboardScoreData
      final fetchedScores = await PlayGamesService.instance
          .loadLeaderboardScores();

      if (mounted) {
        if (fetchedScores.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _scores.clear();
          _scores.addAll(fetchedScores);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading leaderboards: $e');
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
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          const SizedBox.expand(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(scale: _scale, child: _buildCard()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEADERBOARDS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Flexible(child: _buildContent()),
          const SizedBox(height: 20),
          _CloseButton(onTap: _close),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    if (_scores.isEmpty) {
      return const Center(
        child: Text(
          'No scores yet',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: false,
      itemCount: _scores.length,
      separatorBuilder: (context, _) =>
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 14),
      itemBuilder: (context, index) {
        final scoreData = _scores[index];
        // Platform channel models can still carry nulls at runtime.
        final dynamic holder = scoreData.scoreHolder;
        final displayName = (holder?.displayName as String?)?.trim();
        final iconUrl = (holder?.iconImage as String?)?.trim();
        final cleaned = iconUrl != null && iconUrl.contains(',')
            ? iconUrl.split(',').last
            : iconUrl;
        final rank = scoreData.rank;
        final rankLabel = rank <= 0 ? '-' : '$rank';
        final scoreLabel = scoreData.displayScore.trim().isEmpty
            ? 'Unknown score'
            : scoreData.displayScore;

        print('Score #$index: $displayName - $scoreLabel (Rank: $rankLabel)');
        print('  Icon URL: ${iconUrl ?? "None"}');

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: iconUrl != null && iconUrl.isNotEmpty
              ? CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  backgroundImage: MemoryImage(base64Decode(cleaned!)),
                )
              : const Icon(Icons.person, color: Colors.white70),

          title: Text(
            '$rankLabel. ${displayName == null || displayName.isEmpty ? 'Unknown Player' : displayName}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            "Survival Time: $scoreLabel",
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'CLOSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
