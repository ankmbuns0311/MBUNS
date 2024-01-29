import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<bool> signInWithGoogle() async {
    bool rest = false;
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    print('okeee');
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuth =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuth.idToken,
        accessToken: googleSignInAuth.accessToken,
      );

      try {
        final UserCredential authResult =
            await _auth.signInWithCredential(credential);

        final User? user = authResult.user;
        print(user!.email);
        print('oke');
        rest = true;
      } catch (e) {
        print('error $e');
        rest = false;
      }
    }
    return rest;
  }

  Future<String> getUUID() async {
    final User? user = _auth.currentUser;
    return user!.uid;
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
  }
}
