import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

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
      await StorageService.openUserBox(_currentUser!);
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
    await StorageService.openUserBox(normalizedEmail);
    await StorageService.markOnboardingTipsPending();
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
    await StorageService.openUserBox(normalizedEmail);
    await StorageService.setPendingWelcomeBack();
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await StorageService.switchToAnonymousStorage();
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

  // ── security questions ─────────────────────────────────────

  static const _sqQuestionsPrefix = 'auth_sq_questions_';
  static const _sqAnswersPrefix = 'auth_sq_answers_';

  static const List<String> allSecurityQuestions = [
    "What was the name of your first pet?",
    "What was the name of your primary school?",
    "What is your mother's maiden name?",
    "What city were you born in?",
    "What was your childhood nickname?",
    "What is the name of your oldest sibling?",
    "What street did you grow up on?",
    "What was the make of your first car?",
    "What was the name of your first best friend?",
    "What was your favourite subject in school?",
  ];

  /// Returns true if the given email has security questions set up.
  static Future<bool> hasSecurityQuestions(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sqQuestionsPrefix${email.trim().toLowerCase()}';
    return prefs.getString(key) != null;
  }

  /// Returns the list of stored question strings for [email], or null.
  static Future<List<String>?> getSecurityQuestions(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      '$_sqQuestionsPrefix${email.trim().toLowerCase()}',
    );
    if (raw == null) return null;
    return List<String>.from(json.decode(raw) as List);
  }

  /// Saves security questions + hashed answers for [email].
  /// [questionsAndAnswers] is a list of 3 (question, answer) pairs.
  static Future<void> setSecurityQuestions(
    String email,
    List<MapEntry<String, String>> questionsAndAnswers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    final questions = questionsAndAnswers.map((e) => e.key).toList();
    final answers =
        questionsAndAnswers.map((e) => _hashAnswer(e.value)).toList();
    await prefs.setString(
      '$_sqQuestionsPrefix$normalized',
      json.encode(questions),
    );
    await prefs.setString('$_sqAnswersPrefix$normalized', json.encode(answers));
  }

  /// Verifies answers against stored hashes. Returns true if all match.
  static Future<bool> verifySecurityAnswers(
    String email,
    List<String> answers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    final raw = prefs.getString('$_sqAnswersPrefix$normalized');
    if (raw == null) return false;
    final stored = List<String>.from(json.decode(raw) as List);
    if (stored.length != answers.length) return false;
    for (int i = 0; i < stored.length; i++) {
      if (stored[i] != _hashAnswer(answers[i])) return false;
    }
    return true;
  }

  /// Resets the password for [email] without verifying the old password.
  /// Only call this after [verifySecurityAnswers] returns true.
  static Future<String?> resetPassword(
    String email,
    String newPassword,
  ) async {
    if (newPassword.length < 6) {
      return 'Password must be at least 6 characters';
    }
    final normalized = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    if (!users.containsKey(normalized)) return 'No account found for that email';
    users[normalized] = _hash(newPassword);
    await _saveUsers(prefs, users);
    return null;
  }

  static String _hashAnswer(String answer) {
    final bytes = utf8.encode(answer.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
