// lib/domain/auth/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
/// Representasi model data untuk pengguna aplikasi.
/// Menyimpan informasi dasar pengguna beserta perannya.
class UserModel {
  final String uid;        // ID unik pengguna dari Firebase Authentication
  final String? email;     // Email pengguna, bisa null (opsional)
  final String role;       // Peran pengguna, contoh: 'admin' atau 'user'

  /// Konstruktor untuk membuat instance [UserModel].
  UserModel({
    required this.uid,
    this.email,
    required this.role,
  });

  /// Factory constructor untuk membuat instance [UserModel] dari
  /// objek [DocumentSnapshot] yang diterima dari Firestore.
  ///
  /// [doc] adalah snapshot dokumen pengguna dari Firestore.
  /// Data di dalamnya diharapkan berupa Map<String, dynamic>.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();

    // Mengembalikan instance UserModel dengan data dari Firestore.
    // uid diambil dari ID dokumen itu sendiri.
    // email diambil dari field 'email', bisa null.
    // role diambil dari field 'role', default ke 'user' jika tidak ada atau null.
    return UserModel(
      uid: doc.id, // UID diambil dari ID dokumen itu sendiri
      email: data?['email'] as String?,
      role: data?['role'] as String? ?? 'user', // Default ke 'user' jika field 'role' tidak ada atau null
    );
  }

  /// Mengubah instance [UserModel] menjadi [Map<String, dynamic>].
  /// Ini digunakan untuk menulis data objek [UserModel] ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      // UID biasanya tidak disimpan sebagai field terpisah di dalam dokumen karena
      // sudah berfungsi sebagai ID dokumen di Firestore. Namun, bisa ditambahkan jika perlu.
      // 'uid': uid,
      if (email != null) 'email': email, // Hanya sertakan email jika tidak null
      'role': role,
    };
  }
}
