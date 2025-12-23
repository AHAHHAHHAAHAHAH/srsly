import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stato semplice e robusto dell'inizializzazione profilo.
enum AuthInitStatus { idle, loading, ready, error }

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== API compatibilità (per i tuoi file che prima si sono rotti)
  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// True quando il profilo è pronto (companyId disponibile).
  bool get initialized => _status == AuthInitStatus.ready;

  /// Email comoda per badge/settings.
  String get email => _auth.currentUser?.email ?? '';

  /// CompanyId letto da users/{uid}
  String? get companyId => _companyId;

  AuthInitStatus get status => _status;
  String? get lastError => _lastError;

  // ===== Stato interno
  AuthInitStatus _status = AuthInitStatus.idle;
  String? _lastError;
  String? _companyId;

  String? _initUid; // uid per cui abbiamo inizializzato
  Future<void>? _initFuture; // caching per evitare doppi init

  /// Login: NON fa init qui, perché init lo gestisce AuthGate + ensureInitialized.
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    _reset();
    await _auth.signOut();
  }

  void _reset() {
    _status = AuthInitStatus.idle;
    _lastError = null;
    _companyId = null;
    _initUid = null;
    _initFuture = null;
  }

  /// Chiamata sicura da AuthGate: inizializza UNA VOLTA per UID.
  /// Non chiama setState in build, niente navigazioni, solo Future.
  Future<void> ensureInitialized() {
    final user = _auth.currentUser;
    if (user == null) {
      _reset();
      return Future.value();
    }

    // Se uid cambia, resetta cache.
    if (_initUid != user.uid) {
      _reset();
      _initUid = user.uid;
    }

    // Se già in corso/finito, riusa.
    _initFuture ??= _initializeForUid(user.uid);
    return _initFuture!;
  }

  /// Alias compatibilità: alcuni tuoi file cercavano start()
  Future<void> start() => ensureInitialized();

  Future<void> _initializeForUid(String uid) async {
    _status = AuthInitStatus.loading;
    _lastError = null;

    // Retry breve per il caso in cui token/claims non siano ancora "caldi"
    // e Firestore risponde permission-denied per qualche ms.
    const attempts = 3;
    for (int i = 0; i < attempts; i++) {
      try {
        final snap = await _db.collection('users').doc(uid).get();

        if (!snap.exists) {
          throw StateError('Profilo mancante: users/$uid');
        }

        final data = snap.data();
        final cid = data?['companyId'];

        if (cid == null || (cid is String && cid.trim().isEmpty)) {
          throw StateError('companyId mancante su users/$uid');
        }

        _companyId = cid.toString();
        _status = AuthInitStatus.ready;
        _lastError = null;
        return;
      } on FirebaseException catch (e) {
        // Se è permission-denied/unauthenticated facciamo retry breve.
        final code = e.code;
        final retryable = code == 'permission-denied' || code == 'unauthenticated';

        if (retryable && i < attempts - 1) {
          await Future.delayed(const Duration(milliseconds: 350));
          continue;
        }

        _status = AuthInitStatus.error;
        _lastError = '[${e.code}] ${e.message ?? e.toString()}';
        rethrow;
      } catch (e) {
        _status = AuthInitStatus.error;
        _lastError = e.toString();
        rethrow;
      }
    }
  }
}
