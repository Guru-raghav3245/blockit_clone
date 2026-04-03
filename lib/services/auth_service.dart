import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Google Sign-In Logic
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Mandatory initialization for v7+ passing your specific serverClientId
      await GoogleSignIn.instance.initialize(
        serverClientId: '285912336612-lgjrceu8qmb96b5ak0jo006e3pbs61pk.apps.googleusercontent.com',
      );

      // 2. Authentication (Identity) - Replaces the old .signIn()
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      // If the user cancels the login dialog, stop here
      if (googleUser == null) return null;

      // 3. Authorization (Permissions) - Fetch the accessToken separately
      final List<String> scopes = ['email'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

      // 4. Get the idToken
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 5. Create a new credential for Firebase using both tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 6. Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}