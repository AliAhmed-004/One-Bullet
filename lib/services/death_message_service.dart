import 'dart:math';

import 'package:one_bullet/services/achievement_service.dart';

/// Categories for death messages based on proximity to next achievement.
enum DeathMessageType {
  /// Player was very close to achievement (0-10 seconds away)
  nearMiss,

  /// Player was somewhat close (10-20 seconds away)
  almostThere,

  /// Player was far from achievement (20+ seconds away)
  sarcastic,

  /// Player already has all achievements
  champion,
}

/// Result containing the death message and metadata.
class DeathMessageResult {
  const DeathMessageResult({
    required this.message,
    required this.type,
    required this.secondsToNextAchievement,
    this.nextAchievementTitle,
  });

  /// The message to display.
  final String message;

  /// The type/category of message.
  final DeathMessageType type;

  /// Seconds remaining to next achievement (null if all achieved).
  final int? secondsToNextAchievement;

  /// Title of the next achievement (null if all achieved).
  final String? nextAchievementTitle;
}

/// Service for generating contextual death messages.
///
/// Messages vary based on how close the player was to their next achievement,
/// creating psychological hooks for retention:
/// - Near-miss: Infuriating messages that trigger loss aversion
/// - Far away: Sarcastic/funny messages that keep it light
class DeathMessageService {
  DeathMessageService._internal();
  static final DeathMessageService instance = DeathMessageService._internal();
  factory DeathMessageService() => instance;

  final _random = Random();

  // ============================================
  // NEAR MISS MESSAGES (0-10 seconds away)
  // Infuriating - trigger loss aversion
  // ============================================
  static const List<String> _nearMissMessages = [
    "You were THIS close. Literally.",
    "The achievement was RIGHT there...",
    "Pain. Pure pain.",
    "Your timing is impeccable. Impeccably bad.",
    "So close you could taste it.",
    "The bullet had other plans.",
    "Almost legendary. Almost.",
    "That's gonna haunt you.",
    "One more dodge... just ONE.",
    "The universe said 'not today'.",
    "Oof. That one stings.",
    "Achievement: Almost Unlocked™",
    "You were seconds away from glory.",
    "The cruelest death is the almost-death.",
  ];

  // ============================================
  // ALMOST THERE MESSAGES (10-20 seconds away)
  // Encouraging but teasing
  // ============================================
  static const List<String> _almostThereMessages = [
    "Getting warmer...",
    "Not bad! But not great either.",
    "You can smell the achievement from here.",
    "Closer than last time? Maybe?",
    "The achievement is watching. Judging.",
    "Progress! Sort of.",
    "You're on the right track. Kinda.",
    "Keep this up and you'll get there. Eventually.",
    "The bullet is learning your moves.",
    "Halfway to greatness. Or halfway to nowhere.",
    "Your persistence is... noted.",
    "Achievement proximity: Close-ish.",
  ];

  // ============================================
  // SARCASTIC MESSAGES (20+ seconds away)
  // Funny and light-hearted
  // ============================================
  static const List<String> _sarcasticMessages = [
    "Well, that happened.",
    "Bold strategy. Didn't work.",
    "The bullet sends its regards.",
    "You zigged when you should've zagged.",
    "Have you tried... not dying?",
    "Gravity works. So does the bullet.",
    "Pro tip: Avoid the glowing orange thing.",
    "Your bullet misses you already.",
    "Skill issue? Maybe. Bad luck? Also maybe.",
    "The arena claims another victim.",
    "That was certainly... an attempt.",
    "Physics: 1, You: 0",
    "The deflector was not your friend.",
    "At least you looked cool. Briefly.",
    "Did you forget you fired that?",
    "Plot twist: The bullet always wins.",
    "Nice reflexes! (Not really)",
    "Achievement unlocked: Died Creatively",
    "The bullet appreciates your sacrifice.",
    "Maybe survival isn't your thing.",
  ];

  // ============================================
  // CHAMPION MESSAGES (all achievements unlocked)
  // Respectful but still playful
  // ============================================
  static const List<String> _championMessages = [
    "Even legends fall sometimes.",
    "The champion takes a break.",
    "You've conquered everything. This is just practice.",
    "All achievements unlocked. Now you're just showing off.",
    "Back for more? Respect.",
    "The master returns to the arena.",
    "Nothing left to prove. Everything left to enjoy.",
    "You've seen it all. Yet here you are.",
  ];

  /// Gets a contextual death message based on survival time.
  ///
  /// Uses [AchievementService] to determine proximity to next achievement.
  DeathMessageResult getDeathMessage(int survivalSeconds) {
    final achievementService = AchievementService.instance;
    final nextTarget = achievementService.getNextTarget(survivalSeconds);

    // Player has all achievements
    if (nextTarget == null) {
      return DeathMessageResult(
        message: _getRandomMessage(_championMessages),
        type: DeathMessageType.champion,
        secondsToNextAchievement: null,
        nextAchievementTitle: null,
      );
    }

    final secondsRemaining = nextTarget.requiredSeconds - survivalSeconds;

    // Determine message type based on proximity
    final DeathMessageType type;
    final List<String> messagePool;

    if (secondsRemaining <= 10) {
      type = DeathMessageType.nearMiss;
      messagePool = _nearMissMessages;
    } else if (secondsRemaining <= 20) {
      type = DeathMessageType.almostThere;
      messagePool = _almostThereMessages;
    } else {
      type = DeathMessageType.sarcastic;
      messagePool = _sarcasticMessages;
    }

    return DeathMessageResult(
      message: _getRandomMessage(messagePool),
      type: type,
      secondsToNextAchievement: secondsRemaining,
      nextAchievementTitle: nextTarget.title,
    );
  }

  /// Selects a random message from the given pool.
  String _getRandomMessage(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }
}
