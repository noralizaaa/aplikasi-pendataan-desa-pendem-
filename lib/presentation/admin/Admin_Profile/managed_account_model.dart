// lib/presentation/admin/Admin_Profile/managed_account_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagedAccount {
  final String id; // ID dokumen di subkoleksi managedAccounts
  final String email;
  final String role; // Peran pengguna, e.g., "user"
  final String? userId; // UID pengguna dari koleksi /users
  final Timestamp createdAt;

  ManagedAccount({
    required this.id,
    required this.email,
    required this.role,
    this.userId,
    required this.createdAt,
  });

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

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'userId': userId,
      'createdAt': createdAt, // Untuk entri baru, gunakan FieldValue.serverTimestamp() di controller
    };
  }
}