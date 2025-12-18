import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

/// A provider class that manages authentication state and interacts with Appwrite Account service.
///
/// Uses static members to maintain state across instance creation, effectively acting as a Singleton.
class AuthProvider extends ChangeNotifier {
  static late Account _account;
  static Future<User?>? _user;

  // Status is instance specific in original code, but methods modify static _user.
  // Ideally this should all be instance based or all static.
  // For now, keeping consistent with original design but cleaning syntax.
  AuthStatus _status = AuthStatus.uninitialized;

  Account get account => _account;
  Future<User?>? get user => _user;
  AuthStatus get status => _status;

  // Logic to determine if a user is likely logged in based on _user future presence
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider._();

  /// Initialize the user future from the account service.
  static Future<void> initUser() async {
    _user = _account.get();
    try {
      await _user;
    } catch (_) {
      // Ignore errors during initial check (e.g. not logged in)
    }
  }

  /// Factory constructor initializes the Appwrite account and user state.
  factory AuthProvider() {
    _account = Config().getAccount();
    initUser();
    Config.userUpdateCallback = AuthProvider.reInit;
    return AuthProvider._();
  }

  static void reInit() {
    _account = Config().getAccount();
    initUser();
  }

  /// Logs in a user with email and password.
  Future<void> login(
      String email, String password, BuildContext context) async {
    try {
      await account.createEmailPasswordSession(
          email: email, password: password);
      // Refresh user after login
      _user = account.get();
      await _user;

      // Simulate delay if needed or wait for UI
      await Future.delayed(const Duration(seconds: 1));

      _status = AuthStatus.authenticated;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.message ?? "Login failed");
    }
  }

  /// Registers a new user and automatically logs them in.
  Future<void> register(
      String name, String email, String password, BuildContext context) async {
    try {
      await account.create(
          userId: ID.unique(), name: name, email: email, password: password);

      // Small delay to ensure creation propagation if needed
      await Future.delayed(const Duration(seconds: 1));

      await account.createEmailPasswordSession(
          email: email, password: password);
      _user = account.get();
      await _user;

      _status = AuthStatus.authenticated;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.message ?? "Registration failed");
    }
  }

  /// Logs out the current user.
  Future<void> logout(BuildContext context) async {
    try {
      await account.deleteSession(sessionId: "current");
      _user = null;
      _status = AuthStatus.unauthenticated;
      if (!context.mounted) return;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.message ?? "Logout failed");
    }
  }

  /// Updates the provider with a new account instance and refreshes status.
  void update(Account account) async {
    _account = account;
    _user = _account.get();

    try {
      await _user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  /// Helper to show error SnackBars.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
