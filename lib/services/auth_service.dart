import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<AppUser?> signUp(
    String email,
    String password,
    String role,
    String name,
    String designation,
  ) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email,
          'role': role.toLowerCase(),
          'name': name,
          'designation': designation,
          'profilePictureUrl': '',
        });

        return AppUser(
          uid: credential.user!.uid,
          email: credential.user!.email!,
          role: role.toLowerCase(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'The email address is already in use by another account.',
        );
      }
      throw Exception('An error occurred: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  static Future<AppUser?> signIn(String email, String password) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('User profile not found.');
        }

        final userData = userDoc.data()!;
        final role = (userData['role'] as String? ?? 'student').toLowerCase();

        return AppUser(
          uid: credential.user!.uid,
          email: credential.user!.email!,
          role: role,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('The authentication credential is incorrect');
      }
      throw Exception('An error occurred: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  static bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }
}