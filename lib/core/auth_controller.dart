import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  String? _companyId;
  bool _initialized = false;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  /// ========================
  /// GETTERS PUBBLICI (SERVONO A TUTTA L’APP)
  /// ========================
  User? get currentUser => _currentUser;
  String? get companyId => _companyId;
  bool get initialized => _initialized;
  Stream<User?> get authState => _authStateController.stream;

  /// ========================
  /// START → chiamato da AuthGate
  /// ========================
  Future<void> start() async {
    _auth.authStateChanges().listen((user) async {
      _currentUser = user;

      if (user == null) {
        _companyId = null;
        _initialized = true;
        _authStateController.add(null);
        return;
      }

      // carica profilo user
      final snap = await _db.collection('users').doc(user.uid).get();
      if (snap.exists) {
        _companyId = snap.data()?['companyId'];
      } else {
        _companyId = null;
      }

      _initialized = true;
      _authStateController.add(user);
    });
  }

  /// ========================
  /// LOGIN
  /// ========================
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // il resto lo fa authStateChanges()
  }

  /// ========================
  /// LOGOUT
  /// ========================
  Future<void> logout() async {
    await _auth.signOut();
  }
}
