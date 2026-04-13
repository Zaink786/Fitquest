import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/level_model.dart';
import '../../models/quest_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _welcomeBackMessage;

  int _points = 0;
  int _streakDays = 0;
  late LevelInfo _levelInfo;

  String _username() {
    final displayName = AuthService.getDisplayName();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = AuthService.getCurrentUser() ?? '';
    final name = email.split('@').first;
    return name.isEmpty ? 'there' : _capitalise(name);
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday ${date.day} $month';
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Expire streak if the user missed days without logging.
      // Returns true if the streak was broken right now.
      final streakBroken = await StorageService.validateStreak();

      // Check and immediately consume the one-shot welcome-back flag.
      String? welcomeMsg;
      bool showProgressSummary = false;
      if (StorageService.hasPendingWelcomeBack()) {
        await StorageService.clearPendingWelcomeBack();
        final name = _username();
        final streak = StorageService.getCurrentStreak();
        if (streakBroken) {
          welcomeMsg =
              'Welcome back $name — your streak reset, but your XP is safe. Start a new one today.';
        } else if (streak > 0) {
          welcomeMsg =
              'Welcome back $name — you\'re on a $streak-day streak, don\'t break it! 🔥';
        }
        showProgressSummary = true;
      }

      // Load from storage
      final points = StorageService.getTotalPoints();
      final streak = StorageService.getCurrentStreak();
      final levelInfo = StorageService.getLevelInfo();

      setState(() {
        _points = points;
        _streakDays = streak;
        _levelInfo = levelInfo;
        _welcomeBackMessage = welcomeMsg;
        _isLoading = false;
      });

      if (showProgressSummary && mounted) {
        // Small delay so the dashboard paints first.
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showProgressSummary();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load activity data';
        _isLoading = false;
      });
    }
  }

  void _showProgressSummary() {
    final name = _username();
    final level = _levelInfo.level;
    final totalXp = _levelInfo.currentXp;
    final streak = _streakDays;
    final questPoints = StorageService.getQuestPoints();
    final nextWorld = getNextWorld(questPoints);
    final ptsToNext = nextWorld != null
        ? nextWorld.requiredPoints - questPoints
        : 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Auto-dismiss after 3 seconds.
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your progress, $name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _EarnRow(
                icon: Icons.star,
                color: Colors.amber,
                label: 'Level $level — $totalXp XP total',
                reward: '',
                rewardColor: Colors.transparent,
              ),
              const SizedBox(height: 10),
              _EarnRow(
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                label: streak > 0 ? '$streak-day streak' : 'No active streak',
                reward: streak > 0 ? 'Keep going!' : 'Start today',
                rewardColor: Colors.grey,
              ),
              const SizedBox(height: 10),
              _EarnRow(
                icon: Icons.fitness_center,
                color: const Color(0xFF1A237E),
                label: '$questPoints Quest Points',
                reward: nextWorld != null
                    ? '$ptsToNext to ${nextWorld.name}'
                    : 'All unlocked!',
                rewardColor: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final questPoints = StorageService.getQuestPoints();
    final dailyPoints = StorageService.getDailyPoints();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + date
                Text(
                  'Hi ${_username()} 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(now),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 14),

                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (_errorMessage != null) ...[
                  Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadDashboardData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Welcome-back banner (shown once after login)
                  if (_welcomeBackMessage != null) ...[
                    _WelcomeBackBanner(
                      message: _welcomeBackMessage!,
                      onDismiss: () =>
                          setState(() => _welcomeBackMessage = null),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Level card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFDCE3FF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${_levelInfo.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level ${_levelInfo.level}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$_points XP total',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _levelInfo.progress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_levelInfo.xpIntoLevel} / ${_levelInfo.xpForNextLevel} XP to next level',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Three stat cards ──
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.fitness_center,
                        iconColor: Colors.grey[700]!,
                        value: '$dailyPoints',
                        label: "Today's\nXP",
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.local_fire_department,
                        iconColor: Colors.red,
                        value: '$_streakDays',
                        label: 'Day streak',
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.star,
                        iconColor: const Color(0xFFF9A825),
                        value: '$questPoints',
                        label: 'Quest pts',
                        valueColor: const Color(0xFFF9A825),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── How to earn ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFDCE3FF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HOW TO EARN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EarnRow(
                          icon: Icons.fitness_center,
                          label: 'Log a workout',
                          reward: '+20 XP',
                          color: Colors.grey[700]!,
                        ),
                        const SizedBox(height: 10),
                        _EarnRow(
                          icon: Icons.restaurant,
                          label: 'Log a meal',
                          reward: '+5 XP',
                          color: Colors.grey[700]!,
                        ),
                        const SizedBox(height: 10),
                        _EarnRow(
                          icon: Icons.local_fire_department,
                          label: 'Daily streak',
                          reward: '+10 XP',
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 10),
                        _EarnRow(
                          icon: Icons.emoji_events,
                          label: 'Calorie goal',
                          reward: '+20 XP',
                          color: Colors.amber[700]!,
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFF0F2FF),
                        ),
                        const SizedBox(height: 10),
                        _EarnRow(
                          icon: Icons.star,
                          label: 'Personal record',
                          reward: '+50 Quest',
                          color: Colors.amber,
                          rewardColor: const Color(0xFFF9A825),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBackBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WelcomeBackBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2744) : const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: const Color(0xFF1A237E), width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.close,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String reward;
  final Color color;
  final Color? rewardColor;

  const _EarnRow({
    required this.icon,
    required this.label,
    required this.reward,
    required this.color,
    this.rewardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          reward,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: rewardColor ?? const Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}
