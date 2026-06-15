// Path: lib/presentation/user_profile/user_profile_model.dart

/// [UserProfile] merepresentasikan struktur data profil untuk pengguna level User/Petugas.
/// 
/// Digunakan untuk menyimpan informasi identitas pengguna yang sedang aktif, 
/// termasuk username, peran (role), dan kaitannya dengan program pendataan tertentu.
class UserProfile {
  /// Nama tampilan pengguna yang dapat diperbarui.
  String username;
  /// Peran pengguna dalam sistem (misal: 'user', 'admin_desa', dll).
  final String role;
  /// ID program atau formulir yang dikaitkan dengan otoritas user (opsional).
  final String? programId; 

  UserProfile({
    required this.username,
    required this.role,
    this.programId, 
  });

  /// Membuat instance [UserProfile] dari format Map (biasanya dari Firestore atau argumen navigasi).
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      username: data['username'] as String? ?? 'N/A', 
      role: data['role'] as String? ?? 'user', 
      programId: data['programId'] as String?, 
    );
  }

  /// Mengonversi objek [UserProfile] ke format Map.
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