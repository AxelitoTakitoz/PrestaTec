// lib/app/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// ✅ Devuelve true si el usuario actual es admin.
  /// 1) admins/{correoLower} existe
  /// 2) o hay algún doc en admins con campo email = correoLower
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final rawEmail = user.email?.trim();
    if (rawEmail == null || rawEmail.isEmpty) return false;

    final emailLower = rawEmail.toLowerCase();

    final admins = _db.collection('admins');

    // 1) Intentar por docId normalizado
    final doc = await admins.doc(emailLower).get();
    // DEBUG
    // ignore: avoid_print
    print("DEBUG isAdmin -> docId=$emailLower exists=${doc.exists}");
    if (doc.exists) return true;

    // 2) Intentar por campo "email"
    final q = await admins
        .where('email', isEqualTo: emailLower)
        .limit(1)
        .get();

    final ok = q.docs.isNotEmpty;
    // DEBUG
    // ignore: avoid_print
    print("DEBUG isAdmin -> query email=$emailLower -> $ok");

    return ok;
  }
}
