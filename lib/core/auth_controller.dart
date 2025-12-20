import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _initialized = false;
  bool get initialized => _initialized;

  String? get companyId => _authService.companyId;

  StreamSubscription<User?>? _sub;

  /// Avvia una sola volta il listener globale.
  /// onChange viene chiamato quando cambia lo stato (login/logout/init).
  void start(Function onChange) {
    _sub ??= _auth.authStateChanges().listen((user) async {
      _initialized = false;
      _currentUser = user;

      // Se logout -> UI deve tornare al login
      if (user == null) {
        onChange();
        return;
      }

      try {
        // Carica profilo Firestore (users/{uid}) e companyId
        await _authService.loadUserProfile();
        _initialized = true;
      } catch (_) {
        // Account senza profilo => lo sloggiamo (coerenza data model)
        await _auth.signOut();
        _currentUser = null;
        _initialized = false;
      }

      onChange();
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    _initialized = false;
    _currentUser = null;
    await _authService.logout();
  }
}
