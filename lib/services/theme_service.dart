import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'dark_mode';

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDark => themeNotifier.value == ThemeMode.dark;

  static Future<void> setDark(bool dark) async {
    themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dark);
  }
}
