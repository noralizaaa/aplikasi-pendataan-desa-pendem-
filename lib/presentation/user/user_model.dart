// lib/presentation/user/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FormDataModel {
  final String idForm;          // Akan menjadi ID dokumen dari adminForms
  final String nama;            // Akan dipetakan dari field 'title' di Firestore
  final String deskripsi;       // Akan dipetakan dari field 'description' di Firestore
  final String lokasi;          // Beri nilai default jika tidak ada
  final String category;        // Beri nilai default jika tidak ada
  final Timestamp? createdAt;   // Dari field 'createdAt' di Firestore
  final List<dynamic>? sections; // Untuk menyimpan data 'sections' jika perlu

  FormDataModel({
    required this.idForm,
    required this.nama,
    required this.deskripsi,
    this.lokasi = 'Lokasi Tidak Ditentukan', // Nilai default
    this.category = 'Umum',                 // Nilai default
    this.createdAt,
    this.sections,
  });

  // Factory constructor untuk membuat instance dari Map (data Firestore)
  // dan ID dokumen (yang akan menjadi idForm)
  factory FormDataModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FormDataModel(
      idForm: documentId, // Gunakan ID dokumen sebagai idForm
      nama: data['title'] as String? ?? 'Tanpa Judul', // Ambil dari field 'title'
      deskripsi: data['description'] as String? ?? '', // Ambil dari field 'description'
      lokasi: data['lokasi'] as String? ?? 'Lokasi Tidak Ditentukan', // Jika ada field 'lokasi' di data
      category: data['category'] as String? ?? 'Umum',         // Jika ada field 'category' di data
      createdAt: data['createdAt'] as Timestamp?,       // Ambil dari field 'createdAt'
      sections: data['sections'] as List<dynamic>?,      // Ambil dari field 'sections'
    );
  }

  // Method toMap (opsional untuk tampilan pengguna, tapi baik untuk dimiliki)
  Map<String, dynamic> toMap() {
    return {
      // idForm biasanya adalah ID dokumen, tidak disimpan sebagai field saat menulis ke Firestore
      'title': nama,
      'description': deskripsi,
      'lokasi': lokasi,
      'category': category,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'sections': sections,
    };
  }
}