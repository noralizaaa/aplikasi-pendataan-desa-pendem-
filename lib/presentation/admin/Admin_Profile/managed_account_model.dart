// lib/presentation/admin/Admin_Profile/managed_account_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// [ManagedAccount] merepresentasikan data otoritas akun pada sebuah formulir.
/// 
/// Model ini disimpan dalam subkoleksi `managedAccounts` di bawah setiap dokumen 
/// formulir untuk menentukan siapa saja yang memiliki akses pengisian/pengelolaan data.
class ManagedAccount {
  /// ID dokumen unik di dalam subkoleksi `managedAccounts`.
  final String id; 
  /// Alamat email pengguna yang diberi otoritas.
  final String email;
  /// Peran pengguna khusus untuk formulir ini (misal: "user").
  final String role; 
  /// UID pengguna yang merujuk pada koleksi utama `/users`.
  final String? userId; 
  /// Waktu pembuatan atau pemberian otoritas.
  final Timestamp createdAt;

  ManagedAccount({
    required this.id,
    required this.email,
    required this.role,
    this.userId,
    required this.createdAt,
  });

  /// Membuat instance [ManagedAccount] dari dokumen [DocumentSnapshot] Firestore.
  factory ManagedAccount.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ManagedAccount(
      id: doc.id,
      email: data['email'] as String? ?? 'N/A',
      role: data['role'] as String? ?? 'user', // Default ke 'user' jika tidak ada
      userId: data['userId'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Mengonversi objek [ManagedAccount] ke dalam format Map untuk disimpan di Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'userId': userId,
      'createdAt': createdAt, // Untuk entri baru, gunakan FieldValue.serverTimestamp() di controller
    };
  }
}