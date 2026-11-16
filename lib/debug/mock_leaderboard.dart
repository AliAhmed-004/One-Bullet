import 'package:games_services/games_services.dart';

/// Test the leaderboard UI without Play Games access (e.g. internal-testing
/// builds). Enable with `--dart-define=MOCK_LEADERBOARD=true`. Compile-time
/// constant, so it is dead code (tree-shaken) in normal builds.
const bool mockLeaderboard = bool.fromEnvironment('MOCK_LEADERBOARD');

List<LeaderboardScoreData> mockLeaderboardScores() {
  const names = [
    'Doc Holliday',
    'Calamity Jane',
    'Billy the Kid',
    'Annie Oakley',
    'Wild Bill Hickok-Longname-Overflow-Test',
    'Jesse James',
    'Sundance',
    'Belle Starr',
    'Pat Garrett',
    'Black Bart',
  ];
  const secs = [312, 287, 241, 205, 188, 160, 133, 97, 64, 31];

  return [
    for (var i = 0; i < names.length; i++)
      LeaderboardScoreData(
        rank: i + 1,
        displayScore:
            '${(secs[i] ~/ 60).toString().padLeft(2, '0')}:${(secs[i] % 60).toString().padLeft(2, '0')}',
        rawScore: secs[i] * 1000,
        timestampMillis: 0,
        scoreHolder: PlayerData(playerID: 'mock$i', displayName: names[i]),
      ),
  ];
}
