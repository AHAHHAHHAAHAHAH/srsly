import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// LOGIN
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return cred.user!;
  }

  /// REGISTRAZIONE + CREAZIONE USER DOC
  Future<User> registerWithCompany({
    required String email,
    required String password,
    required String companyName,
  }) async {
    // 1️⃣ Crea utente Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    final uid = user.uid;

    // 2️⃣ Crea companyId (semplice, deterministico)
    final companyId = _db.collection('companies').doc().id;

    // 3️⃣ Scrive users/{uid}
    await _db.collection('users').doc(uid).set({
      'email': email,
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// STREAM AUTH
  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
