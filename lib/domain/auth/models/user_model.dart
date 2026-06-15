// lib/domain/auth/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
/// [UserModel] adalah representasi data inti dari setiap pengguna di dalam aplikasi.
/// 
/// Model ini menyimpan identitas unik, email, peran (role), serta wilayah tugas (RT/RW) 
/// yang menjadi dasar sistem keamanan berbasis peran (Role-Based Access Control).
class UserModel {
  /// ID unik pengguna dari Firebase Authentication.
  final String uid;        
  /// Alamat email pengguna (opsional).
  final String? email;     
  /// Peran pengguna (misal: 'admin_global', 'admin_desa', 'user').
  final String role;       
  /// Nomor RT wilayah tugas (untuk Admin RT/RW dan Petugas).
  final String? rt;        
  /// Nomor RW wilayah tugas.
  final String? rw;        

  UserModel({
    required this.uid,
    this.email,
    required this.role,
    this.rt,
    this.rw,
  });

  // --- LOGIKA PERAN (ROLE) TERPUSAT ---
  
  /// Mengecek apakah pengguna memiliki otoritas administratif (Global, Desa, RW, atau RT).
  bool get isAdmin {
    final r = role.toLowerCase().trim();
    return [
      'admin', 'global_admin', 'admin_global', 'adminglobal', 
      'admin_desa', 'admindesa', 'admin desa',
      'admin_rt', 'adminrt', 'admin rt'
    ].contains(r) || r.contains('admin');
  }

  /// Mengecek apakah pengguna adalah Admin Global dengan akses tidak terbatas.
  bool get isGlobalAdmin {
    final r = role.toLowerCase().trim();
    return ['admin', 'global_admin', 'admin_global', 'adminglobal'].contains(r);
  }

  /// Mengecek apakah pengguna adalah Admin Desa.
  bool get isVillageAdmin {
    final r = role.toLowerCase().trim();
    return ['admin_desa', 'admindesa', 'admin desa'].contains(r);
  }

  /// Mengecek apakah pengguna adalah Admin RW.
  bool get isAdminRw {
    final r = role.toLowerCase().trim();
    return ['admin_rw', 'adminrw', 'admin rw'].contains(r);
  }

  /// Mengecek apakah pengguna adalah Admin RT.
  bool get isAdminRt {
    final r = role.toLowerCase().trim();
    return ['admin_rt', 'adminrt', 'admin rt'].contains(r);
  }

  /// Mengecek apakah admin memiliki akses yang dibatasi wilayah (Desa/RW/RT).
  bool get isRestrictedAdmin => isVillageAdmin || isAdminRw || isAdminRt;

  /// Factory constructor untuk memetakan dokumen Firestore ke objek [UserModel].
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();

    return UserModel(
      uid: doc.id, 
      email: data?['email'] as String?,
      role: data?['role'] as String? ?? 'user', 
      rt: data?['rt']?.toString(),
      rw: data?['rw']?.toString(),
    );
  }

  /// Mengonversi objek [UserModel] ke dalam format Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      'role': role,
      if (rt != null) 'rt': rt,
      if (rw != null) 'rw': rw,
    };
  }
}
