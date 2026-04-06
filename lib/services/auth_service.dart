import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local authentication using SHA-256 hashed passwords stored in
/// SharedPreferences. All data stays on-device.
class AuthService {
  static const _usersKey = 'auth_users';
  static const _currentUserKey = 'auth_current_user';

  /// In-memory cache so callers can read the current user synchronously.
  static String? _currentUser;

  /// Call once during app startup (before runApp).
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = prefs.getString(_currentUserKey);
  }

  /// The currently logged-in email, or null if no one is logged in.
  static String? getCurrentUser() => _currentUser;

  static bool isLoggedIn() => _currentUser != null;

  /// Returns null on success, or an error message on failure.
  static Future<String?> signUp(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
      return 'Please enter a valid email address';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    if (users.containsKey(normalizedEmail)) {
      return 'An account with this email already exists';
    }

    users[normalizedEmail] = _hash(password);
    await _saveUsers(prefs, users);
    await _persistCurrentUser(prefs, normalizedEmail);
    return null;
  }

  /// Returns null on success, or an error message on failure.
  static Future<String?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    if (users[normalizedEmail] != _hash(password)) {
      return 'Invalid email or password';
    }

    await _persistCurrentUser(prefs, normalizedEmail);
    await prefs.setBool('pending_welcome_back', true);
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = null;
    await prefs.remove(_currentUserKey);
  }

  // ── helpers ────────────────────────────────────────────────

  static Map<String, String> _loadUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey) ?? '{}';
    return Map<String, String>.from(json.decode(raw) as Map);
  }

  static Future<void> _saveUsers(
    SharedPreferences prefs,
    Map<String, String> users,
  ) async {
    await prefs.setString(_usersKey, json.encode(users));
  }

  static Future<void> _persistCurrentUser(
    SharedPreferences prefs,
    String email,
  ) async {
    _currentUser = email;
    await prefs.setString(_currentUserKey, email);
  }

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
