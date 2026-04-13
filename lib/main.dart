import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/workouts/workouts_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/quest/quest_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage, auth, and theme
  await StorageService.initialize();
  await AuthService.initialize();
  await ThemeService.initialize();

  runApp(const FitQuestApp());
}

class FitQuestApp extends StatefulWidget {
  const FitQuestApp({super.key});

  @override
  State<FitQuestApp> createState() => _FitQuestAppState();
}

class _FitQuestAppState extends State<FitQuestApp> {
  bool _isLoggedIn = AuthService.isLoggedIn();
  bool _needsOnboarding = StorageService.hasPendingOnboardingFlow();

  void _onLogin() => setState(() {
    _isLoggedIn = true;
    _needsOnboarding = StorageService.hasPendingOnboardingFlow();
  });
  void _onLogout() => setState(() => _isLoggedIn = false);
  void _onOnboardingFinished() => setState(() => _needsOnboarding = false);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final font = Platform.isAndroid ? 'Inter' : null;
    return ThemeData(
      useMaterial3: false,
      primarySwatch: Colors.indigo,
      fontFamily: font,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: const Color(0xFF1A237E).withValues(alpha: 0.6),
        elevation: 8,
      ),
      dividerColor: isDark ? Colors.white24 : Colors.black12,
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'FitQuest',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeMode,
          home: !_isLoggedIn
              ? LoginScreen(onLogin: _onLogin)
              : _needsOnboarding
              ? OnboardingFlowScreen(onFinished: _onOnboardingFinished)
              : HomeScreen(onLogout: _onLogout),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pipColors = [
    Color(0xFF1A237E), // Dashboard
    Color(0xFF1A237E), // Workouts
    Color(0xFF1B5E20), // Nutrition
    Color(0xFF4A148C), // Achievements
    Colors.amber,     // Quest
    Color(0xFF212121), // Settings
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const WorkoutsScreen(),
      const NutritionScreen(),
      const AchievementsScreen(),
      const QuestScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];
  }

  Widget _navIcon(IconData icon, int tabIndex) {
    final isActive = _currentIndex == tabIndex;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 20 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? _pipColors[tabIndex] : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 3),
        Icon(icon),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Making sure the body doesn't resize to avoid hiding the bottom
      // navigation when the keyboard appears (keeps it always visible)
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],

      bottomNavigationBar: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final borderColor = isDark ? Colors.white12 : const Color(0xFFE8E8E8);
          return Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                backgroundColor: navBg,
                elevation: 0,
                showUnselectedLabels: true,
                showSelectedLabels: true,
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (i) => setState(() => _currentIndex = i),
                items: [
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.home, 0),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.fitness_center, 1),
                    label: 'Workouts',
                  ),
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.restaurant_menu, 2),
                    label: 'Nutrition',
                  ),
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.emoji_events, 3),
                    label: 'Achieve',
                  ),
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.explore, 4),
                    label: 'Quest',
                  ),
                  BottomNavigationBarItem(
                    icon: _navIcon(Icons.settings, 5),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
