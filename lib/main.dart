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

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage and auth
  await StorageService.initialize();
  await AuthService.initialize();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        fontFamily: Platform.isAndroid ? 'Inter' : null,
      ),
      home: !_isLoggedIn
          ? LoginScreen(onLogin: _onLogin)
          : _needsOnboarding
          ? OnboardingFlowScreen(onFinished: _onOnboardingFinished)
          : HomeScreen(onLogout: _onLogout),
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
          backgroundColor: Colors.white, // 👈 solid background (visible)
          selectedItemColor: Colors.blue, // 👈 active tab color
          unselectedItemColor: Colors.blue.withOpacity(
            0.75,
          ), // 👈 unselected also blue-ish
          selectedIconTheme: const IconThemeData(color: Colors.blue),
          unselectedIconTheme: IconThemeData(
            color: Colors.blue.withOpacity(0.75),
          ),
          showUnselectedLabels: true,
          showSelectedLabels: true,
          elevation: 8,
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
