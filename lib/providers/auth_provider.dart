import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// StreamProvider to monitor authentication state
final authProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async* {
  final authStream = FirebaseAuth.instance.authStateChanges().asyncMap((
    user,
  ) async {
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('user_profiles')
              .doc(user.uid)
              .get();
      final profileId =
          doc.exists && doc.data() != null
              ? doc.data()!['profileId'] as String?
              : null;

      if (profileId == null || profileId.isEmpty) {
      }

      return {
        'user': AppUser(uid: user.uid, email: user.email!),
        'profileId':
            profileId?.isNotEmpty == true
                ? profileId
                : null, // Ensure profileId is valid
      };
    }
    return null;
  });
  await for (final data in authStream) {
    yield data;
  }
});

final boundProfileProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc =
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .get();

  return doc.exists && doc.data() != null
      ? doc.data()!['profileId'] as String?
      : null;
});
