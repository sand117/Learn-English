import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    try {
      await _auth.signInWithPopup(provider);
    } catch (_) {
      await _auth.signInWithRedirect(provider);
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
