import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/workouts/workouts_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/quest/quest_screen.dart';
import 'services/storage_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageService.initialize();

  runApp(const FitQuestApp());
}

class FitQuestApp extends StatelessWidget {
  const FitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WorkoutsScreen(),
    NutritionScreen(),
    AchievementsScreen(),
    QuestScreen(),
    SettingsScreen(),
  ];

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
