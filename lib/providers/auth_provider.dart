import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  static late Account _account;
  static late bool _isLoggedIn;
  static late Future<User?>? _user;
  AuthStatus _status = AuthStatus.uninitialized;

  Account get account => _account;
  Future<User?>? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  AuthStatus get status => _status;

  AuthProvider._();

  factory AuthProvider() {
    _account = Config().getAccount();
    _user = _account.get();
    return AuthProvider._();
  }

  Future<void> login(
      String email, String password, BuildContext context) async {
    try {
      await account.createEmailPasswordSession(
          email: email, password: password);
      _user = account.get();
      await _user;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> register(
      String name, String email, String password, BuildContext context) async {
    try {
      await account.create(
          userId: ID.unique(), name: name, email: email, password: password);
      await account.createEmailPasswordSession(
          email: email, password: password);
      _user = account.get();
      await _user;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await account.deleteSession(sessionId: "current");
      _user = account.get();
      //print(_user);
      if (!context.mounted) return;
      notifyListeners();
    } on AppwriteException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void update(Account account) async {
    _account = account;
    _user = _account.get();
    try {
      await _user;
      _status = AuthStatus.authenticated;
    } on AppwriteException catch (e) {
      _status = AuthStatus.unauthenticated;
      print(e);
      print("in auth");
      print(_user);
      _user = null;
      print("in auth");
      print(_user);
    }
    notifyListeners();
  }
}
