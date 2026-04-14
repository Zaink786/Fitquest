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
                iconColor: Colors.amber,
                pillLight: const Color(0xFFFFF8E1),
                pillDark: const Color(0xFF2D1F00),
                label: 'Level $level — $totalXp XP total',
                subtitle: 'Total XP earned',
                reward: '',
                rewardColor: Colors.transparent,
              ),
              const SizedBox(height: 10),
              _EarnRow(
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange,
                pillLight: const Color(0xFFFBECE8),
                pillDark: const Color(0xFF2D1206),
                label: streak > 0 ? '$streak-day streak' : 'No active streak',
                subtitle: streak > 0 ? 'Keep it up!' : 'Start today',
                reward: streak > 0 ? 'Keep going!' : 'Start today',
                rewardColor: Colors.grey,
              ),
              const SizedBox(height: 10),
              _EarnRow(
                icon: Icons.fitness_center,
                iconColor: const Color(0xFF5B4FCF),
                pillLight: const Color(0xFFEDE9FB),
                pillDark: const Color(0xFF1E1A3D),
                label: '$questPoints Quest Points',
                subtitle: nextWorld != null
                    ? '$ptsToNext pts to ${nextWorld.name}'
                    : 'All worlds unlocked!',
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

  // Accent colours mirrored from _FitQuestAppState constants.
  static const _accentLight = Color(0xFF5B4FCF);
  static const _accentDark  = Color(0xFFA695F5);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final questPoints = StorageService.getQuestPoints();
    final dailyPoints = StorageService.getDailyPoints();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? _accentDark : _accentLight;
    final subtleText = isDark ? Colors.grey[500]! : Colors.grey[500]!;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      // No AppBar — content owns the full safe area.
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date + Greeting ──
                Text(
                  _formatDate(now).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: subtleText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hi, ${_username()} 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT LEVEL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: subtleText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Level ${_levelInfo.level}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$_points XP total',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2060)
                                    : const Color(0xFF1A237E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${_levelInfo.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _levelInfo.progress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_levelInfo.xpIntoLevel} / ${_levelInfo.xpForNextLevel} XP to Level ${_levelInfo.level + 1}',
                          style: TextStyle(fontSize: 12, color: subtleText),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Three stat cards ──
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _StatCard(
                          iconText: 'XP',
                          value: '$dailyPoints',
                          label: "Today's\nXP",
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          iconText: '🔥',
                          value: '$_streakDays',
                          label: 'Day\nstreak',
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          iconText: '⭐',
                          value: '$questPoints',
                          label: 'Quest\npts',
                          valueColor: const Color(0xFFF9A825),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Quick Earn card ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK EARN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: subtleText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EarnRow(
                          icon: Icons.fitness_center,
                          label: 'Log a workout',
                          subtitle: 'Keep the streak going',
                          reward: '+20 XP',
                          pillLight: const Color(0xFFEDE9FB),
                          pillDark:  const Color(0xFF1E1A3D),
                          iconColor: const Color(0xFF5B4FCF),
                        ),
                        const SizedBox(height: 12),
                        _EarnRow(
                          icon: Icons.restaurant,
                          label: 'Log a meal',
                          subtitle: 'Track what you eat',
                          reward: '+5 XP',
                          pillLight: const Color(0xFFE8F5E9),
                          pillDark:  const Color(0xFF0D2213),
                          iconColor: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 12),
                        _EarnRow(
                          icon: Icons.local_fire_department,
                          label: 'Daily streak',
                          subtitle: 'Log in every day',
                          reward: '+10 XP',
                          pillLight: const Color(0xFFFBECE8),
                          pillDark:  const Color(0xFF2D1206),
                          iconColor: Colors.deepOrange,
                        ),
                        const SizedBox(height: 12),
                        _EarnRow(
                          icon: Icons.emoji_events,
                          label: 'Calorie goal',
                          subtitle: 'Hit your daily target',
                          reward: '+20 XP',
                          pillLight: const Color(0xFFFFF8E1),
                          pillDark:  const Color(0xFF2D1F00),
                          iconColor: const Color(0xFFF9A825),
                        ),
                        const SizedBox(height: 4),
                        Divider(
                          height: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        _EarnRow(
                          icon: Icons.star,
                          label: 'Personal record',
                          subtitle: 'Beat your best',
                          reward: '+50 QP',
                          pillLight: const Color(0xFFFFF8E1),
                          pillDark:  const Color(0xFF2D1F00),
                          iconColor: const Color(0xFFF9A825),
                          rewardColor: const Color(0xFFF9A825),
                        ),
                        const SizedBox(height: 6),
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
  final String? iconText;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    this.iconText,
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            if (iconText != null)
              Text(iconText!, style: const TextStyle(fontSize: 16)),
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
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
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
  final Color iconColor;
  final Color pillLight;
  final Color pillDark;
  final String label;
  final String subtitle;
  final String reward;
  final Color? rewardColor;

  const _EarnRow({
    required this.icon,
    required this.iconColor,
    required this.pillLight,
    required this.pillDark,
    required this.label,
    required this.subtitle,
    required this.reward,
    this.rewardColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pill = isDark ? pillDark : pillLight;
    // XP rewards use a green tint; QP rewards use amber — anything else falls
    // back to the accent colour.
    final Color defaultReward = reward.contains('QP')
        ? const Color(0xFFF9A825)
        : const Color(0xFF2E7D32);

    return Row(
      children: [
        // Icon pill
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: pill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        // Label + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        // Reward badge
        Text(
          reward,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: rewardColor ?? defaultReward,
          ),
        ),
      ],
    );
  }
}
