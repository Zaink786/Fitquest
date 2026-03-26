import 'package:flutter/material.dart';
import '../../models/quest_model.dart';
import '../../services/storage_service.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  int _questPoints = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _questPoints = StorageService.getQuestPoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWorld = getCurrentWorld(_questPoints);
    final nextWorld = getNextWorld(_questPoints);
    final progress = getWorldProgress(_questPoints);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CurrentWorldCard(
              world: currentWorld,
              questPoints: _questPoints,
              progress: progress,
              nextWorld: nextWorld,
            ),
            const SizedBox(height: 20),
            _StatsRow(questPoints: _questPoints),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'World Map',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...questWorlds.reversed.map(
              (world) => _WorldMapTile(
                world: world,
                questPoints: _questPoints,
                isCurrent: world.id == currentWorld.id,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CurrentWorldCard extends StatelessWidget {
  final QuestWorld world;
  final int questPoints;
  final double progress;
  final QuestWorld? nextWorld;

  const _CurrentWorldCard({
    required this.world,
    required this.questPoints,
    required this.progress,
    required this.nextWorld,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: world.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: world.gradient.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(world.icon, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'World ${world.id}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      world.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            world.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          if (nextWorld != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$questPoints Quest Points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${nextWorld!.requiredPoints} to ${nextWorld!.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ] else
            Text(
              'Max world reached — you are a legend!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int questPoints;

  const _StatsRow({required this.questPoints});

  @override
  Widget build(BuildContext context) {
    final currentWorld = getCurrentWorld(questPoints);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            label: 'Quest Points',
            value: '$questPoints',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.public,
            label: 'Worlds Reached',
            value: '${currentWorld.id} / ${questWorlds.length}',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldMapTile extends StatelessWidget {
  final QuestWorld world;
  final int questPoints;
  final bool isCurrent;

  const _WorldMapTile({
    required this.world,
    required this.questPoints,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = questPoints >= world.requiredPoints;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? world.gradient.first.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: world.gradient.first, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(colors: world.gradient)
                : null,
            color: isUnlocked ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUnlocked ? world.icon : Icons.lock,
            color: isUnlocked ? Colors.white : Colors.grey[500],
            size: 22,
          ),
        ),
        title: Text(
          world.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? Colors.black87 : Colors.grey[400],
          ),
        ),
        subtitle: Text(
          isUnlocked
              ? world.description
              : '${world.requiredPoints} Quest Points to unlock',
          style: TextStyle(
            fontSize: 12,
            color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: world.gradient.first,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : isUnlocked
            ? Icon(Icons.check_circle, color: Colors.green[400], size: 24)
            : Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
      ),
    );
  }
}
