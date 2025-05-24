// Path: lib/presentation/admin/admin_model.dart

// This file should ONLY contain the DashboardItem class.
// It should NOT contain any other model definitions like UserModel.

class DashboardItem {
  final String title;
  final String category;
  final String location;
  final String programId; // Unique ID for the dashboard item, e.g., '001', '002'

  DashboardItem({
    required this.title,
    required this.category,
    required this.location,
    required this.programId,
  });

  // Factory constructor to create a DashboardItem object from a Map.
  // This is useful if you later decide to fetch these dashboard configurations
  // dynamically from a database like Firestore.
  factory DashboardItem.fromMap(Map<String, dynamic> data) {
    return DashboardItem(
      title: data['title'] as String? ?? 'Judul Tidak Diketahui',
      category: data['category'] as String? ?? 'Kategori Umum',
      location: data['location'] as String? ?? 'Lokasi Tidak Diketahui',
      programId: data['programId'] as String? ?? 'N/A', // Assuming programId comes from data
    );
  }

  // Optional: Method to convert DashboardItem to a Map, if you need to save it.
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