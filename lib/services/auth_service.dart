import 'package:firebase_auth/firebase_auth.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  String? get uid => currentUser?.uid;
  String? get email => currentUser?.email;
  bool get isSignedIn => currentUser != null;

  Future<String?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.setString('anon_uid', user.uid);
      }
      notifyListeners();
      return user?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return false;
      final auth = await user.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCred = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      await _auth.signInWithCredential(oauthCred);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          notifyListeners();
          return true;
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    notifyListeners();
  }
}
