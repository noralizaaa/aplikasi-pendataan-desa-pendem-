// lib/presentation/user/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// [FormDataModel] merepresentasikan metadata ringkas dari sebuah formulir pendataan.
/// 
/// Model ini digunakan pada halaman utama level Pengguna (Petugas) untuk menampilkan
/// daftar formulir yang tersedia untuk diisi atau dikelola.
class FormDataModel {
  /// ID unik formulir yang diambil dari ID dokumen koleksi `adminForms`.
  final String idForm;          
  /// Nama atau judul formulir (dipetakan dari field `title`).
  final String nama;            
  /// Deskripsi singkat mengenai isi atau tujuan formulir (dipetakan dari field `description`).
  final String deskripsi;       
  /// Informasi wilayah cakupan formulir.
  final String lokasi;          
  /// Kategori program pendataan (misal: 'Kesehatan', 'Ekonomi', 'Umum').
  final String category;        
  /// Waktu pembuatan formulir.
  final Timestamp? createdAt;   
  /// Struktur seksi pertanyaan di dalam formulir (opsional pada level daftar).
  final List<dynamic>? sections; 

  FormDataModel({
    required this.idForm,
    required this.nama,
    required this.deskripsi,
    this.lokasi = 'Lokasi Tidak Ditentukan', 
    this.category = 'Umum',                 
    this.createdAt,
    this.sections,
  });

  /// Factory constructor untuk membuat instance [FormDataModel] dari data Firestore.
  /// 
  /// [data] adalah Map berisi field dokumen, dan [documentId] adalah ID dokumen tersebut.
  factory FormDataModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FormDataModel(
      idForm: documentId, 
      nama: data['title'] as String? ?? 'Tanpa Judul', 
      deskripsi: data['description'] as String? ?? '', 
      lokasi: data['lokasi'] as String? ?? 'Lokasi Tidak Ditentukan', 
      category: data['category'] as String? ?? 'Umum',         
      createdAt: data['createdAt'] as Timestamp?,       
      sections: data['sections'] as List<dynamic>?,      
    );
  }

  /// Mengonversi objek [FormDataModel] ke dalam format Map.
  /// 
  /// Berguna untuk keperluan serialisasi data atau pemetaan lokal.
  Map<String, dynamic> toMap() {
    return {
      'title': nama,
      'description': deskripsi,
      'lokasi': lokasi,
      'category': category,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'sections': sections,
    };
  }
}