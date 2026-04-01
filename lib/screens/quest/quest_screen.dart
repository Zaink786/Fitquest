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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 54 - 8 - 44 - 8) / 2;
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _displayWorlds.length,
              itemBuilder: (context, index) {
                final world = _displayWorlds[index];
                final isUnlocked = _questPoints >= world.requiredPoints;
                final isCurrent = world.id == currentWorld.id;
                final isFirst = index == 0;
                final isLast = index == _displayWorlds.length - 1;
                final topFilled = !isFirst &&
                    _questPoints >= _displayWorlds[index - 1].requiredPoints;
                final bottomFilled = !isLast && isUnlocked;
                return SizedBox(
                  height: _rowHeight,
                  child: _RoadRow(
                    world: world,
                    index: index,
                    isUnlocked: isUnlocked,
                    isCurrent: isCurrent,
                    isFirst: isFirst,
                    isLast: isLast,
                    topFilled: topFilled,
                    bottomFilled: bottomFilled,
                    progressRing: isCurrent ? progress : null,
                    cardWidth: cardWidth,
                  ),
                );
              },
            );
          },
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
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (progressRing != null)
                SizedBox(
                  width: _nodeSize + 14,
                  height: _nodeSize + 14,
                  child: CircularProgressIndicator(
                    value: progressRing,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              Container(
                width: _nodeSize,
                height: _nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: world.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUnlocked ? null : const Color(0xFF1A3A6B),
                  border: Border.all(
                    color: isCurrent ? Colors.amber : Colors.white24,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.55),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : isUnlocked
                          ? [
                              BoxShadow(
                                color: world.gradient.first
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                ),
                child: Icon(
                  isUnlocked ? world.icon : Icons.lock_outline,
                  color: isUnlocked ? Colors.white : Colors.white38,
                  size: 22,
                ),
              ),
            ],
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

    final card = _WorldCard(
      world: world,
      isUnlocked: isUnlocked,
      isCurrent: isCurrent,
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

class _WorldCard extends StatelessWidget {
  final QuestWorld world;
  final bool isUnlocked;
  final bool isCurrent;

  const _WorldCard({
    required this.world,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: world.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1A3A6B), Color(0xFF132D52)],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.amber : Colors.white24,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ]
            : isUnlocked
                ? [
                    BoxShadow(
                      color: world.gradient.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
      ),
      child: Stack(
        children: [
          if (isUnlocked && !isCurrent)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 13),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlocked ? world.icon : Icons.lock_outline,
                  color: isUnlocked ? Colors.white : Colors.white38,
                  size: 26,
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    world.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'YOU ARE HERE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
