// lib/presentation/user/user_model.dart (Example of how it should look)
class FormDataModel { // <-- Ensure this class exists and is correctly structured
  final String idForm;
  final String nama;
  final String deskripsi;
  final String lokasi;
  final String category;
  final bool requiresAuthority;

  FormDataModel({
    required this.idForm,
    required this.nama,
    required this.deskripsi,
    required this.lokasi,
    required this.category,
    this.requiresAuthority = false,
  });

  factory FormDataModel.fromMap(Map<String, dynamic> data) {
    return FormDataModel(
      idForm: data['idForm'] ?? 'N/A',
      nama: data['nama'] ?? 'Nama Form Tidak Tersedia',
      deskripsi: data['deskripsi'] ?? 'Deskripsi Tidak Tersedia',
      lokasi: data['lokasi'] ?? 'Lokasi Tidak Tersedia',
      category: data['category'] ?? 'Umum',
      requiresAuthority: data['requiresAuthority'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idForm': idForm,
      'nama': nama,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'category': category,
      'requiresAuthority': requiresAuthority,
    };
  }
}