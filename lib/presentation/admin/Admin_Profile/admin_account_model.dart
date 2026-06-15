// lib/presentation/admin/Admin_Profile/admin_account_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// [AccountCategoryItem] merepresentasikan kategori menu pada halaman profil admin.
/// 
/// Digunakan untuk menampilkan item daftar seperti "Manajemen Akun", "Daftar Desa", dll.
/// pada menu pengaturan admin.
class AccountCategoryItem {
  /// ID kategori yang unik.
  final String id;
  /// Judul kategori yang ditampilkan ke pengguna.
  final String title;
  /// Nama ikon (seperti 'person', 'settings') untuk dipetakan ke IconData.
  final String iconName;
  /// Deskripsi singkat mengenai kategori (opsional).
  final String? description;

  AccountCategoryItem({
    required this.id,
    required this.title,
    required this.iconName,
    this.description,
  });

  /// Membuat instance [AccountCategoryItem] dari dokumen Firestore.
  factory AccountCategoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountCategoryItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      iconName: data['iconName'] as String? ?? 'default_icon', // Beri ikon default jika tidak ada
      description: data['description'] as String?,
    );
  }

  /// Mengonversi objek ke Map untuk disimpan di Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'iconName': iconName,
      'description': description,
    };
  }
}

/// [AdminAccountModel] adalah representasi data akun pengguna untuk keperluan administrasi.
/// 
/// Digunakan oleh Admin untuk melihat dan mengelola detail akun pengguna lain,
/// termasuk informasi wilayah tugas (Desa, RW, RT) dan hak akses (role).
class AdminAccountModel {
  /// Unique ID pengguna dari Firebase Auth.
  final String uid;
  /// Nama pengguna.
  final String username;
  /// Alamat email pengguna.
  final String email;
  /// Peran pengguna (misal: user, admin_desa, admin_rt, admin_rw).
  final String role;
  /// ID Desa tempat pengguna bertugas.
  final String? villageId;
  /// Nama Desa tempat pengguna bertugas.
  final String? villageName;
  /// URL foto profil pengguna.
  final String? photoURL;
  /// Nomor RT wilayah tugas.
  final String? rt;
  /// Nomor RW wilayah tugas.
  final String? rw;

  AdminAccountModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.villageId,
    this.villageName,
    this.photoURL,
    this.rt,
    this.rw,
  });

  /// Membuat instance [AdminAccountModel] dari Map data Firestore.
  factory AdminAccountModel.fromMap(String uid, Map<String, dynamic> data) {
    return AdminAccountModel(
      uid: uid,
      username: data['username'] as String? ?? 'N/A',
      email: data['email'] as String? ?? 'N/A',
      role: data['role'] as String? ?? 'N/A',
      villageId: data['villageId'] as String?,
      villageName: data['villageName'] as String?,
      photoURL: data['photoURL'] as String?,
      rt: data['rt']?.toString(),
      rw: data['rw']?.toString(),
    );
  }

  /// Mengonversi data akun ke Map untuk keperluan penyimpanan atau update di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'villageId': villageId,
      'villageName': villageName,
      'photoURL': photoURL,
      'rt': rt,
      'rw': rw,
    };
  }
}