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
  final String? villageId;
  final String? villageName;

  // --- HELPER PERAN TERPUSAT ---
  bool get isAdmin {
    final r = (roleFromFirestore ?? '').toLowerCase().trim();
    return [
      'admin', 'global_admin', 'admin_global', 'adminglobal', 
      'admin_desa', 'admindesa', 'admin desa',
      'admin_rt', 'adminrt', 'admin rt'
    ].contains(r) || r.contains('admin') || programId == 'admin';
  }

  bool get isGlobalAdmin {
    final r = (roleFromFirestore ?? '').toLowerCase().trim();
    return ['admin', 'global_admin', 'admin_global', 'adminglobal'].contains(r);
  }

  bool get isVillageAdmin {
    final r = (roleFromFirestore ?? '').toLowerCase().trim();
    return ['admin_desa', 'admindesa', 'admin desa'].contains(r);
  }

  bool get isAdminRt {
    final r = (roleFromFirestore ?? '').toLowerCase().trim();
    return ['admin_rt', 'adminrt', 'admin rt'].contains(r);
  }

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.photoURL,
    this.roleFromFirestore,
    this.programId,
    this.villageId,
    this.villageName,
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
    String? villageId,
    String? villageName,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoURL: photoURL ?? this.photoURL,
      roleFromFirestore: roleFromFirestore ?? this.roleFromFirestore,
      programId: programId ?? this.programId,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
    );
  }
}