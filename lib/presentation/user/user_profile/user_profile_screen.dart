// lib/presentation/user/user_profile/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_controller.dart';

class UserProfileScreen extends GetView<UserProfileController> {
  const UserProfileScreen({Key? key}) : super(key: key);

  // Warna-warna dari AdminProfilPage untuk konsistensi UI InfoCard
  static const Color pageBackgroundColor = Color(0xFFEBF4F8); // Latar belakang Admin
  static const Color headerBackgroundColorForCard = Color(0xFFFFD180); // Oranye muda header Admin (dipakai di card icon bg)
  static const Color iconColorForCard = Color(0xFFF57C00); // Ikon utama Admin (dipakai di card icon)
  static const Color cardBackgroundColor = Colors.white;
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color labelTextColor = Color(0xFF616161);
  static const Color editIconColor = Colors.black54;

  // Warna header asli user profile
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);


  @override
  Widget build(BuildContext context) {
    Get.put(UserProfileController());

    return Scaffold(
      backgroundColor: pageBackgroundColor, // Ganti dengan warna background admin
      body: Obx(() { // Tambahkan Obx untuk handle loading state global
        if (controller.isLoading.value && controller.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
        }
        // Anda bisa tambahkan kondisi error di sini jika diperlukan

        // Jika tidak loading atau sudah ada data, tampilkan CustomScrollView
        return CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent, // Tetap transparan untuk gradien
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container( // Header tetap menggunakan gaya UserProfile
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentHeaderColor.withOpacity(0.8),
                        primaryHeaderColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(100),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0, left: 24.0, right: 24.0, bottom: 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Profile.png', // Pastikan path asset ini benar
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final username = controller.userProfile.value?.username ?? 'Pengguna';
                          return Text(
                            'Hello, $username',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Informasi Akun',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor, // Gunakan primaryTextColor
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final userProfile = controller.userProfile.value;
                  if (userProfile == null) {
                    // Sebenarnya sudah ditangani oleh Obx di atas,
                    // tapi bisa sebagai fallback jika hanya bagian ini yang null
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Memuat data pengguna..."),
                    ));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding untuk kartu
                    child: Column(
                      children: [
                        // Menggunakan _buildInfoCard_AdminStyle yang dimodifikasi
                        _buildInfoCard_AdminStyle(
                          icon: Icons.person_outline, // Ikon dari admin
                          label: 'Username',
                          value: userProfile.username,
                          // Panggil dialog edit dari controller
                          onEdit: () => controller.promptEditUsernameDialog(),
                        ),
                        const SizedBox(height: 16),
                        // Kartu untuk Peran (tidak bisa diedit)
                        _buildInfoCard_AdminStyle(
                          icon: Icons.article_outlined, // Ikon dari admin
                          label: 'Peran',
                          value: userProfile.role,
                          onEdit: null, // Tidak ada fungsi edit
                        ),
                        // Anda bisa menambahkan info lain di sini jika ada
                        // misalnya program ID jika relevan untuk ditampilkan
                        if (userProfile.programId != null && userProfile.programId != '000' && userProfile.programId!.isNotEmpty)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildInfoCard_AdminStyle(
                                icon: Icons.code, // Ganti ikon sesuai
                                label: 'ID Program Terkait',
                                value: userProfile.programId!,
                                onEdit: null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentHeaderColor, // Tombol Logout tetap dengan style UserProfile
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'LOG OUT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        );
      }),
    );
  }

  // Widget ini adalah adaptasi dari _buildInfoCard di AdminProfilPage
  Widget _buildInfoCard_AdminStyle({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headerBackgroundColorForCard.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColorForCard, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: labelTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis, // Tambahkan jika value bisa panjang
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: editIconColor, size: 22),
              onPressed: onEdit,
              tooltip: 'Edit $label',
              splashRadius: 20,
            )
        ],
      ),
    );
  }

// HAPUS Widget _buildInfoCard LAMA dari UserProfileScreen (jika ada yang berbeda dari _buildInfoCard_AdminStyle)
// HAPUS Widget _buildEditableInfoCard LAMA dari UserProfileScreen
}