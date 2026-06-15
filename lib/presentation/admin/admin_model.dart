// Path: lib/presentation/admin/admin_model.dart

/// [DashboardItem] merepresentasikan satu item atau ringkasan data yang ditampilkan 
/// pada dashboard utama Admin.
/// 
/// Model ini digunakan untuk menampilkan statistik atau navigasi cepat berdasarkan 
/// kategori program pendataan tertentu.
class DashboardItem {
  /// Judul tampilan pada item dashboard (misal: "Pendataan Penduduk").
  final String title;
  /// Kategori dari program (misal: "Kependudukan", "Kesehatan").
  final String category;
  /// Wilayah cakupan data (misal: nama desa atau RT/RW).
  final String location;
  /// ID Unik formulir atau program yang terkait.
  final String programId; 

  DashboardItem({
    required this.title,
    required this.category,
    required this.location,
    required this.programId,
  });

  /// Membuat instance [DashboardItem] dari format Map.
  /// 
  /// Berguna jika data konfigurasi dashboard diambil secara dinamis dari database 
  /// seperti Cloud Firestore.
  factory DashboardItem.fromMap(Map<String, dynamic> data) {
    return DashboardItem(
      title: data['title'] as String? ?? 'Judul Tidak Diketahui',
      category: data['category'] as String? ?? 'Kategori Umum',
      location: data['location'] as String? ?? 'Lokasi Tidak Diketahui',
      programId: data['programId'] as String? ?? 'N/A', 
    );
  }

  /// Mengonversi objek [DashboardItem] ke dalam format Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'location': location,
      'programId': programId,
    };
  }

  @override
  String toString() {
    return 'DashboardItem(title: $title, category: $category, location: $location, programId: $programId)';
  }
}