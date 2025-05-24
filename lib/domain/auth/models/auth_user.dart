// lib/models/auth_user.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
  final String? photoURL;

  final String? roleFromFirestore; // This will receive the role from Firestore's UserModel.role
  final String? programId;

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.photoURL,
    this.roleFromFirestore,
    this.programId,
  });

  factory AuthUser.fromFirebaseUser(firebase_auth.User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
      photoURL: user.photoURL,
      // roleFromFirestore and programId are initially null here, fetched later
    );
  }

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    String? photoURL,
    String? roleFromFirestore,
    String? programId,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoURL: photoURL ?? this.photoURL,
      roleFromFirestore: roleFromFirestore ?? this.roleFromFirestore,
      programId: programId ?? this.programId,
    );
  }
}