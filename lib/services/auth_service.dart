import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _companyId;
  String? get companyId => _companyId;

  User? get currentUser => _auth.currentUser;

  Future<void> registerWithCompany({
    required String email,
    required String password,
    required String companyName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final companyRef = await _db.collection('companies').add({
      'name': companyName,
      'createdAt': Timestamp.now(),
    });

    await _db.collection('users').doc(uid).set({
      'companyId': companyRef.id,
      'role': 'admin',
    });

    _companyId = companyRef.id;
  }

  Future<void> loadUserProfile() async {
    final user = currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      throw Exception('Profilo utente non trovato');
    }

    final data = snap.data()!;
    _companyId = data['companyId'];
  }

  Future<void> logout() async {
    _companyId = null;
    await _auth.signOut();
  }
}
