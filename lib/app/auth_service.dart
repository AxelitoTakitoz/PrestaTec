// lib/app/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> isAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;

    try {
      final doc = await _db.collection('admins').doc(clean).get();
      return doc.exists;
    } catch (_) {
      // Si reglas están mal o no hay permiso, NO truenes la app.
      return false;
    }
  }

  Future<bool> currentUserIsAdmin() async {
    final u = _auth.currentUser;
    final em = u?.email;
    if (em == null) return false;
    return isAdminEmail(em);
  }
}
