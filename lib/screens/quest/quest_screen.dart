import 'package:flutter/material.dart';
import '../../models/quest_model.dart';
import '../../services/storage_service.dart';

final _displayWorlds = questWorlds.reversed.toList();

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  int _questPoints = 0;
  final _scrollController = ScrollController();
  static const double _rowHeight = 130.0;

  @override
  void initState() {
    super.initState();
    _questPoints = StorageService.getQuestPoints();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final currentWorld = getCurrentWorld(_questPoints);
    final displayIndex =
        _displayWorlds.indexWhere((w) => w.id == currentWorld.id);
    if (displayIndex < 0) return;
    final target = displayIndex * _rowHeight -
        (MediaQuery.of(context).size.height / 2) +
        _rowHeight;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWorld = getCurrentWorld(_questPoints);
    final nextWorld = getNextWorld(_questPoints);
    final progress = getWorldProgress(_questPoints);

    return Scaffold(
      backgroundColor: const Color(0xFF0D2461),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2461),
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quest',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              currentWorld.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_questPoints',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: nextWorld != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: _AppBarProgress(
                  questPoints: _questPoints,
                  nextWorld: nextWorld,
                  progress: progress,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _questPoints = StorageService.getQuestPoints());
          _scrollToCurrent();
        },
        child: const Center(
          child: Text('World map coming soon',
              style: TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}

class _AppBarProgress extends StatelessWidget {
  final int questPoints;
  final QuestWorld nextWorld;
  final double progress;

  const _AppBarProgress({
    required this.questPoints,
    required this.nextWorld,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$questPoints pts',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${nextWorld.requiredPoints - questPoints} pts to ${nextWorld.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}
