// lib/presentation/admin/profil/admin_profil_model.dart
class AdminProfilModel {
  final String uid;
  final String username;
  final String email; // Anda bisa tambahkan atau kurangi field sesuai kebutuhan
  final String role;
  final String? photoURL;

  AdminProfilModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.photoURL,
  });

  // Factory constructor untuk membuat instance dari Map (misalnya, data Firestore)
  factory AdminProfilModel.fromMap(String uid, Map<String, dynamic> data) {
    return AdminProfilModel(
      uid: uid,
      username: data['username'] as String? ?? 'N/A',
      email: data['email'] as String? ?? 'N/A',
      role: data['role'] as String? ?? 'N/A',
      photoURL: data['photoURL'] as String?,
    );
  }

  // Method untuk konversi ke Map (berguna jika Anda ingin update data ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'photoURL': photoURL,
    };
  }
}