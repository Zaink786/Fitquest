import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local authentication using SHA-256 hashed passwords stored in
/// SharedPreferences. All data stays on-device.
class AuthService {
  static const _usersKey = 'auth_users';
  static const _currentUserKey = 'auth_current_user';
  static const _createdAtPrefix = 'auth_created_at_';
  static const _displayNamePrefix = 'auth_display_name_';

  /// In-memory cache so callers can read the current user synchronously.
  static String? _currentUser;

  /// Call once during app startup (before runApp).
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _prefsSync = prefs;
    _currentUser = prefs.getString(_currentUserKey);
    // Backfill creation timestamp for accounts that pre-date this feature.
    if (_currentUser != null) {
      final key = '$_createdAtPrefix${_currentUser!.trim().toLowerCase()}';
      if (prefs.getString(key) == null) {
        await prefs.setString(key, DateTime.now().toIso8601String());
      }
    }
  }

  /// The currently logged-in email, or null if no one is logged in.
  static String? getCurrentUser() => _currentUser;

  /// Returns the account creation date for [email], or null if not recorded.
  static Future<DateTime?> getAccountCreatedAt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      '$_createdAtPrefix${email.trim().toLowerCase()}',
    );
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static bool isLoggedIn() => _currentUser != null;

  /// Returns the stored display name for the current user, or null.
  static String? getDisplayName() {
    if (_currentUser == null) return null;
    final prefs = _prefsSync;
    if (prefs == null) return null;
    return prefs.getString('$_displayNamePrefix${_currentUser!}');
  }

  /// SharedPreferences handle cached during [initialize].
  static SharedPreferences? _prefsSync;

  /// Returns null on success, or an error message on failure.
  static Future<String?> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
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
    await prefs.setString(
      '$_createdAtPrefix$normalizedEmail',
      DateTime.now().toIso8601String(),
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await prefs.setString(
        '$_displayNamePrefix$normalizedEmail',
        displayName.trim(),
      );
    }
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
