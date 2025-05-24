// Path: lib/presentation/user_profile/user_profile_model.dart

class UserProfile {
  // CHANGE: Make username non-final so it can be updated
  String username;
  final String role;
  final String? programId; // This is correctly defined as nullable

  UserProfile({
    required this.username,
    required this.role,
    this.programId, // This is correctly defined as an optional named parameter
  });

  // FIX: Removed the extra 'Map<' from the type argument of the 'data' parameter
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      username: data['username'] as String? ?? 'N/A', // Safer cast with `as String?`
      role: data['role'] as String? ?? 'Peran Tidak Diketahui', // Safer cast
      programId: data['programId'] as String?, // Null-safe cast
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
      'programId': programId,
    };
  }

  @override
  String toString() {
    return 'UserProfile(username: $username, role: $role, programId: $programId)';
  }
}