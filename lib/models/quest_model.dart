import 'package:flutter/material.dart';

/// Represents a single world in the Quest progression system.
class QuestWorld {
  final int id;
  final String name;
  final String description;
  final int requiredPoints;
  final IconData icon;
  final List<Color> gradient;

  const QuestWorld({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredPoints,
    required this.icon,
    required this.gradient,
  });
}

// All 10 quest worlds in order of progression.
const List<QuestWorld> questWorlds = [
  QuestWorld(
    id: 1,
    name: 'Training Grounds',
    description: 'Every legend starts somewhere. Begin your journey here.',
    requiredPoints: 0,
    icon: Icons.shield_outlined,
    gradient: [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
  ),
  QuestWorld(
    id: 2,
    name: 'Grasslands of the East',
    description: 'Open fields stretch ahead. Your strength is growing.',
    requiredPoints: 100,
    icon: Icons.grass,
    gradient: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
  ),
  QuestWorld(
    id: 3,
    name: 'Misty Forest',
    description: 'Ancient trees tower above. Only the strong find the path.',
    requiredPoints: 300,
    icon: Icons.park,
    gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
  ),
  QuestWorld(
    id: 4,
    name: 'Mountain Pass',
    description: 'The air thins. Each step demands more power.',
    requiredPoints: 600,
    icon: Icons.terrain,
    gradient: [Color(0xFF5C6BC0), Color(0xFF8896CC)],
  ),
  QuestWorld(
    id: 5,
    name: 'Volcanic Cavern',
    description: 'Heat and fire surround you. Forge yourself in the flames.',
    requiredPoints: 1000,
    icon: Icons.whatshot,
    gradient: [Color(0xFFE53935), Color(0xFFFF8A65)],
  ),
  QuestWorld(
    id: 6,
    name: 'Frozen Tundra',
    description: 'Ice and wind test your endurance. Push through the cold.',
    requiredPoints: 1500,
    icon: Icons.ac_unit,
    gradient: [Color(0xFF29B6F6), Color(0xFFB3E5FC)],
  ),
  QuestWorld(
    id: 7,
    name: 'Sky Citadel',
    description:
        'A fortress in the clouds. Only true warriors reach this high.',
    requiredPoints: 2200,
    icon: Icons.castle,
    gradient: [Color(0xFF7E57C2), Color(0xFFB39DDB)],
  ),
  QuestWorld(
    id: 8,
    name: "Dragon's Realm",
    description: 'Dragons guard this land. Your power rivals theirs.',
    requiredPoints: 3000,
    icon: Icons.local_fire_department,
    gradient: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
  ),
  QuestWorld(
    id: 9,
    name: 'The Void',
    description: 'Beyond reality itself. Few have ever stood here.',
    requiredPoints: 4000,
    icon: Icons.dark_mode,
    gradient: [Color(0xFF8896CC), Color(0xFF534BAE)],
  ),
  QuestWorld(
    id: 10,
    name: "Champion's Hall",
    description: 'The pinnacle of strength. You are a legend.',
    requiredPoints: 5000,
    icon: Icons.emoji_events,
    gradient: [Color(0xFFFFD600), Color(0xFFFFF176)],
  ),
];

/// Returns the current world based on quest points.
QuestWorld getCurrentWorld(int questPoints) {
  QuestWorld current = questWorlds.first;
  for (final world in questWorlds) {
    if (questPoints >= world.requiredPoints) {
      current = world;
    } else {
      break;
    }
  }
  return current;
}

/// Returns the next world to unlock, or null if at max.
QuestWorld? getNextWorld(int questPoints) {
  for (final world in questWorlds) {
    if (questPoints < world.requiredPoints) {
      return world;
    }
  }
  return null;
}

/// Returns progress (0.0–1.0) toward the next world.
double getWorldProgress(int questPoints) {
  final current = getCurrentWorld(questPoints);
  final next = getNextWorld(questPoints);
  if (next == null) return 1.0;
  final range = next.requiredPoints - current.requiredPoints;
  final into = questPoints - current.requiredPoints;
  return (into / range).clamp(0.0, 1.0);
}
