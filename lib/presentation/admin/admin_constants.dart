import 'package:flutter/material.dart';

/// [AdminTheme] mendefinisikan skema warna standar yang digunakan di seluruh 
/// antarmuka pengguna (UI) pada modul Admin.
/// 
/// Menyediakan warna latar belakang, warna utama header, dan aksen untuk 
/// memastikan konsistensi visual aplikasi.
class AdminTheme {
  /// Warna latar belakang utama halaman admin.
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  /// Warna primer untuk bagian header (biasanya oranye muda).
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  /// Warna aksen oranye untuk tombol atau elemen yang disorot.
  static const Color accentHeaderColor = Color(0xFFFF9800);
  /// Warna standar untuk ikon di halaman admin.
  static const Color iconColor = Color(0xFFF57C00);
  /// Warna latar belakang kartu (card) informasi.
  static const Color cardBackgroundColor = Colors.white;
  /// Warna ikon pada Bottom Navigation Bar.
  static const Color bottomNavIconColor = Color(0xFFF57C00);
  /// Warna teks untuk judul utama halaman.
  static const Color titlePageColor = Colors.black87;
}