String formatAchievementId(String id) {
  const mappedTitles = {
    'survive_60': 'Survived 1 Minute',
    'reach_endurance': 'Endurance Unlocked',
    'survive_150': 'Survived 2:30',
    'survive_240': 'Survived 4 Minutes',
    'survive_360': 'Survived 6 Minutes',
    'survive_480': 'Survived 8 Minutes',
  };

  final mapped = mappedTitles[id];
  if (mapped != null) {
    return mapped;
  }

  return id
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
