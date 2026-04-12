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
      primarySwatch: Colors.blue,
      fontFamily: font,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.blue.withValues(alpha: 0.6),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Making sure the body doesn't resize to avoid hiding the bottom
      // navigation when the keyboard appears (keeps it always visible)
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          showUnselectedLabels: true,
          showSelectedLabels: true,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _currentIndex = i),

          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Nutrition',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Achievements',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Quest'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
