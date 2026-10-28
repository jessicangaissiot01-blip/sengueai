import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../strings.dart';

/*
 * Connexion des utilisateurs avec Firebase Authentication.
 *
 * Deux façons de se connecter :
 *  - email et mot de passe ;
 *  - compte Google. Firebase utilise le protocole OAuth 2.0 / OpenID Connect :
 *    Google vérifie l'identité de la personne et renvoie un jeton à Firebase.
 *
 * Une fois connecté, Firebase fournit un jeton d'identité (un JWT).
 * L'application l'envoie à notre API pour prouver qui fait la demande.
 *
 * En cas d'erreur, les méthodes laissent passer l'exception
 * FirebaseAuthException. L'écran l'attrape et affiche errorMessage(code).
 */
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Flux qui émet l'utilisateur à chaque connexion ou déconnexion.
  Stream<User?> authChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await _saveProfile(credential.user!, name: name.trim());
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> loginWithGoogle() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});

    // Sur le web, Google s'ouvre dans une fenêtre popup.
    // Sur Android, Firebase ouvre la page de connexion Google.
    final UserCredential credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(provider);
    } else {
      credential = await _auth.signInWithProvider(provider);
    }

    await _saveProfile(credential.user!, name: credential.user!.displayName ?? '');
  }

  Future<void> logout() => _auth.signOut();

  /*
   * Enregistre le profil dans la collection users.
   * merge: true met à jour le document sans effacer les autres champs.
   */
  Future<void> _saveProfile(User user, {required String name}) {
    return _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email ?? '',
      'language': appLanguage.value,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /*
   * Traduit un code d'erreur Firebase en message compréhensible.
   */
  static String errorMessage(String code) {
    final english = appLanguage.value == 'en';
    switch (code) {
      case 'invalid-email':
        return english ? 'Invalid email address.' : 'Adresse email invalide.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return english ? 'Wrong email or password.' : 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return english ? 'This email is already used.' : 'Cet email est déjà utilisé.';
      case 'weak-password':
        return english
            ? 'Password too short (6 characters minimum).'
            : 'Mot de passe trop court (6 caractères minimum).';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
        return english ? 'Google sign-in cancelled.' : 'Connexion Google annulée.';
      case 'network-request-failed':
        return tr('errorNetwork');
      case 'too-many-requests':
        return english ? 'Too many attempts. Wait a moment.' : 'Trop de tentatives. Attends un moment.';
      default:
        return tr('errorUnknown');
    }
  }
}
