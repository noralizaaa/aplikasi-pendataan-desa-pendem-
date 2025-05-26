// lib/presentation/admin/Admin_Profile/admin_account_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// This class is for the "Kategori Manajemen Akun" display (FormItem is used for actual forms)
class AccountCategoryItem {
  final String id;
  final String title;
  final String iconName; // e.g., 'person', 'recycling' - untuk memetakan ke IconData
  final String? description; // Opsional

  AccountCategoryItem({
    required this.id,
    required this.title,
    required this.iconName,
    this.description,
  });

  factory AccountCategoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountCategoryItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      iconName: data['iconName'] as String? ?? 'default_icon', // Beri ikon default jika tidak ada
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'iconName': iconName,
      'description': description,
    };
  }
}

// lib/presentation/admin/Admin_Profile/admin_account_model.dart
// This class will be used for displaying individual user accounts in AllAccountPage
class AdminAccountModel {
  final String uid;
  final String username;
  final String email;
  final String role;
  final String? photoURL;

  AdminAccountModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.photoURL,
  });

  factory AdminAccountModel.fromMap(String uid, Map<String, dynamic> data) {
    return AdminAccountModel(
      uid: uid,
      username: data['username'] as String? ?? 'N/A',
      email: data['email'] as String? ?? 'N/A',
      role: data['role'] as String? ?? 'N/A',
      photoURL: data['photoURL'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email, // Keep email in map for potential updates, though it's not directly editable in UI
      'role': role,
      'photoURL': photoURL, // Include photoURL if you manage it
    };
  }
}