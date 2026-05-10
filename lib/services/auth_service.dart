import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signInWithGoogle() async {
    try {
      // On iOS Safari (PWA), redirect flow is more reliable than popup
      await _auth.signInWithRedirect(GoogleAuthProvider());
    } catch (_) {
      // Fallback to popup on desktop browsers
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    }
  }

  static Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
