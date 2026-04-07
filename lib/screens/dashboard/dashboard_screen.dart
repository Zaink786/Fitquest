import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';
import '../../models/level_model.dart';
import '../../models/quest_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExerciseService _exerciseService = ExerciseService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _showOnboarding = false;
  String? _welcomeBackMessage;

  int _points = 0;
  int _streakDays = 0;
  late LevelInfo _levelInfo;

  // Exercise database stats
  int _totalExercises = 0;
  int _totalCategories = 0;

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
    _loadExerciseStats();
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
      final seenOnboarding = StorageService.hasSeenOnboarding();

      setState(() {
        _points = points;
        _streakDays = streak;
        _levelInfo = levelInfo;
        _showOnboarding = !seenOnboarding;
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

  Future<void> _loadExerciseStats() async {
    try {
      final stats = await _exerciseService.getDatabaseStats();
      setState(() {
        _totalExercises = stats['totalExercises'] ?? 0;
        _totalCategories = stats['categories'] ?? 0;
      });
    } catch (e) {
      print('Error loading exercise stats: $e');
    }
  }

  void _showProgressSummary() {
    final name = _username();
    final level = _levelInfo.level;
    final totalXp = _levelInfo.currentXp;
    final streak = _streakDays;
    final questPoints = StorageService.getQuestPoints();
    final nextWorld = getNextWorld(questPoints);
    final ptsToNext =
        nextWorld != null ? nextWorld.requiredPoints - questPoints : 0;

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
              _SummaryRow(
                icon: Icons.star,
                color: Colors.amber,
                label: 'Level $level',
                detail: '$totalXp XP total',
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                label: streak > 0 ? '$streak-day streak' : 'No active streak',
                detail: streak > 0 ? 'Keep it going!' : 'Start one today',
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                icon: Icons.fitness_center,
                color: Colors.blue,
                label: '$questPoints Quest Points',
                detail: nextWorld != null
                    ? '$ptsToNext pts to ${nextWorld.name}'
                    : 'All worlds unlocked!',
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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + date
              Text(
                'Hi ${_username()} ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(now),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

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
                    onDismiss: () => setState(() => _welcomeBackMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // Onboarding card (shown only on first launch)
                if (_showOnboarding) ...[
                  _OnboardingCard(
                    onDismiss: () async {
                      await StorageService.setHasSeenOnboarding();
                      setState(() => _showOnboarding = false);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Level card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${_levelInfo.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
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
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _levelInfo.progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_levelInfo.xpIntoLevel} / ${_levelInfo.xpForNextLevel} XP to next level',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Two small stat cards: Daily XP + Streak
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(height: 8),
                              const Text(
                                'Today\'s XP',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${StorageService.getDailyPoints()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Streak',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_streakDays days',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Exercise Database Stats Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Exercise Database',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_totalExercises exercises',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalCategories categories available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.purple[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ready to track your workouts',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // How to earn XP
                const Text(
                  'How to earn XP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: Icon(Icons.fitness_center, color: Colors.blue),
                        title: Text('Log a workout'),
                        trailing: Text(
                          '+20 XP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.restaurant_menu,
                          color: Colors.green,
                        ),
                        title: Text('Log a meal'),
                        trailing: Text(
                          '+5 XP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                        title: Text('Maintain streak'),
                        trailing: Text(
                          '+10 XP/day',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(Icons.emoji_events, color: Colors.amber),
                        title: Text('Hit calorie goal'),
                        trailing: Text(
                          '+20 XP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.military_tech,
                          color: Colors.purple,
                        ),
                        title: Text('Unlock achievement'),
                        trailing: Text(
                          '+30 XP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: Colors.blue[700]!, width: 4)),
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
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _OnboardingCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: Colors.blue[700]!, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to FitQuest',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'XP levels you up from any activity — workouts, meals, streaks, and goals. '
            'Quest Points come exclusively from personal records and unlock new worlds on the Quest map.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onDismiss,
            child: Text(
              'Got it, dismiss ×',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String detail;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                detail,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
