// lib/presentation/admin/profil/admin_profil_model.dart
/// [AdminProfilModel] merepresentasikan struktur data profil pengguna dengan hak akses Admin.
/// 
/// Model ini digunakan untuk menyimpan dan mentransformasi data identitas admin
/// yang diambil dari koleksi `users` di Firestore.
class AdminProfilModel {
  /// Unique ID pengguna dari Firebase Auth.
  final String uid;
  /// Nama pengguna (username) admin.
  final String username;
  /// Alamat email admin.
  final String email; 
  /// Peran pengguna dalam sistem (misal: admin_global, admin_desa, dll).
  final String role;
  /// URL foto profil pengguna (opsional).
  final String? photoURL;

  AdminProfilModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.photoURL,
  });

  /// Factory constructor untuk membuat instance [AdminProfilModel] dari Map data Firestore.
  /// 
  /// Menggunakan [uid] dari dokumen dan Map [data] yang berisi field profil.
  factory AdminProfilModel.fromMap(String uid, Map<String, dynamic> data) {
    return AdminProfilModel(
      uid: uid,
      username: data['username'] as String? ?? 'N/A',
      email: data['email'] as String? ?? 'N/A',
      role: data['role'] as String? ?? 'N/A',
      photoURL: data['photoURL'] as String?,
    );
  }

  /// Mengonversi objek [AdminProfilModel] kembali ke format Map.
  /// 
  /// Berguna untuk melakukan operasi pembaruan data (update) ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'photoURL': photoURL,
    };
  }
}