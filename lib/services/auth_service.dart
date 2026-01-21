import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // dopo login: assicura i doc e i campi richiesti
    await ensureUserDocForCurrentUser();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> registerWithCompany({
    required String email,
    required String password,
    required String companyName,
    required String ownerFullName,
    required String addressStreet,
    required String addressCap,
    required String addressCity,
    required String ownerPhone,
  }) async {
    final e = email.trim();
    final p = password.trim();
    final c = companyName.trim();

  final o = ownerFullName.trim();
  final street = addressStreet.trim();
  final cap = addressCap.trim();
  final city = addressCity.trim();
  final phone = ownerPhone.trim();

if (e.isEmpty || p.isEmpty || c.isEmpty || o.isEmpty || street.isEmpty || cap.isEmpty || city.isEmpty || phone.isEmpty) {
  throw Exception('Dati registrazione mancanti');
}


    final cred = await _auth.createUserWithEmailAndPassword(email: e, password: p);
    final user = cred.user;
    if (user == null) throw Exception('Registrazione fallita (user null)');

    final uid = user.uid;

    // scelta stabile: companyId = uid
    final companyId = uid;

    // users/{uid} COMPLETO come i vecchi
    await _db.collection('users').doc(uid).set({
      'email': e,
      'emailLowerCase': e.toLowerCase(),

      'companyId': companyId,
      'companyName': c,
      'companyNameLowerCase': c.toLowerCase(),

      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('companies').doc(companyId).set({
      'companyName': c,
      'companyNameLowerCase': c.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      // nuovi campi
      'ownerFullName': o,
      'addressStreet': street,
      'addressCap': cap,
      'addressCity': city,
      'ownerPhone': phone,
    }, SetOptions(merge: true));


    // non blocca se fallisce
    try {
      await user.updateDisplayName(c);
    } catch (_) {}

    await ensureUserDocForCurrentUser();
  }

  Future<String> getCompanyIdForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) throw Exception('Profilo utente non trovato');

    final data = snap.data();
    final companyId = data?['companyId'];
    if (companyId == null || companyId is! String || companyId.trim().isEmpty) {
      throw Exception('companyId mancante');
    }
    return companyId;
  }

  Future<void> ensureUserDocForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = _db.collection('users').doc(uid);

    final email = (user.email ?? '').trim();
    final emailLc = email.toLowerCase();

    final snap = await userRef.get();
 
    if (!snap.exists) {
      final fallbackCompanyName = (user.displayName ?? 'Azienda').trim();

      await userRef.set({
        'email': email,
        'emailLowerCase': emailLc,

        'companyId': uid,
        'companyName': fallbackCompanyName,
        'companyNameLowerCase': fallbackCompanyName.toLowerCase(),

        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('companies').doc(uid).set({
        'companyName': fallbackCompanyName,
        'companyNameLowerCase': fallbackCompanyName.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return;
    }

    // patch solo campi mancanti per vecchi utenti incompleti
    final data = snap.data() ?? {};
    final Map<String, dynamic> patch = {};

    if (!data.containsKey('email')) patch['email'] = email;
    if (!data.containsKey('emailLowerCase')) patch['emailLowerCase'] = emailLc;

    if (!data.containsKey('companyId')) patch['companyId'] = uid;

    // se mancano companyName / role, li mettiamo senza distruggere nulla
    final fallbackCompanyName = (data['companyName'] ?? user.displayName ?? 'Azienda').toString().trim();

    if (!data.containsKey('companyName')) patch['companyName'] = fallbackCompanyName;
    if (!data.containsKey('companyNameLowerCase')) {
      patch['companyNameLowerCase'] = fallbackCompanyName.toLowerCase();
    }

    if (!data.containsKey('role')) patch['role'] = 'admin';

    if (patch.isNotEmpty) {
      await userRef.set(patch, SetOptions(merge: true));
    }

    // assicura companies/{uid} con chiavi giuste
    await _db.collection('companies').doc(uid).set({
      'companyName': fallbackCompanyName,
      'companyNameLowerCase': fallbackCompanyName.toLowerCase(),
      'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
