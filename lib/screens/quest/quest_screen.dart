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

class _RoadRow extends StatelessWidget {
  final QuestWorld world;
  final int index;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final bool topFilled;
  final bool bottomFilled;
  final double? progressRing;
  final double cardWidth;

  const _RoadRow({
    required this.world,
    required this.index,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.topFilled,
    required this.bottomFilled,
    required this.progressRing,
    required this.cardWidth,
  });

  static const _filledColor = Color(0xFF00C853);
  static const _emptyColor = Color(0xFF1E3A7A);
  static const _lineW = 5.0;
  static const _nodeSize = 48.0;
  static const _halfLine = 41.0;

  @override
  Widget build(BuildContext context) {
    final pathColumn = SizedBox(
      width: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _lineW,
            height: _halfLine,
            decoration: BoxDecoration(
              color: isFirst
                  ? Colors.transparent
                  : topFilled ? _filledColor : _emptyColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: _nodeSize,
            height: _nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? world.gradient.first : const Color(0xFF1A3A6B),
              border: Border.all(
                color: isCurrent ? Colors.amber : Colors.white24,
                width: isCurrent ? 2.5 : 1.5,
              ),
            ),
            child: Icon(
              isUnlocked ? world.icon : Icons.lock_outline,
              color: isUnlocked ? Colors.white : Colors.white38,
              size: 22,
            ),
          ),
          Container(
            width: _lineW,
            height: _halfLine,
            decoration: BoxDecoration(
              color: isLast
                  ? Colors.transparent
                  : bottomFilled ? _filledColor : _emptyColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );

    final card = Container(
      height: 88,
      decoration: BoxDecoration(
        color: isUnlocked ? world.gradient.first : const Color(0xFF1A3A6B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.amber : Colors.white24,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          world.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final leftSlot = SizedBox(
      width: cardWidth,
      child: index.isOdd
          ? Padding(padding: const EdgeInsets.only(right: 6), child: card)
          : null,
    );

    final rightSlot = SizedBox(
      width: cardWidth,
      child: index.isEven
          ? Padding(padding: const EdgeInsets.only(left: 6), child: card)
          : null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '${world.requiredPoints}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: isUnlocked ? 13 : 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        leftSlot,
        pathColumn,
        rightSlot,
        const SizedBox(width: 8),
      ],
    );
  }
}
