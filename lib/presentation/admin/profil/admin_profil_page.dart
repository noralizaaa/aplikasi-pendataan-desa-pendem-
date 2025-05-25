// lib/presentation/admin/profil/admin_profil_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_profil_controller.dart'; // Pastikan controller ini sudah memiliki fungsi edit

class AdminProfilPage extends GetView<AdminProfilController> {
  const AdminProfilPage({Key? key}) : super(key: key);

  // Definisi warna
  static const Color pageBackgroundColor = Color(0xFFEBF4F8); // Latar belakang sedikit kebiruan/abu
  static const Color headerBackgroundColor = Color(0xFFFFD180); // Oranye muda untuk header (sesuai gambar)
  static const Color headerTextColor = Colors.black87; // Teks di header (Hello, Admin)
  static const Color iconColor = Color(0xFFF57C00); // Ikon utama (misal di kartu)
  static const Color cardBackgroundColor = Colors.white;
  static const Color logoutButtonTextColor = Color(0xFFF57C00);
  static const Color logoutButtonBorderColor = Color(0xFFF57C00);
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color labelTextColor = Color(0xFF616161);
  static const Color editIconColor = Colors.black54; // Warna untuk ikon edit

  @override
  Widget build(BuildContext context) {
    // Controller akan di-inject melalui binding yang sudah Anda atur di AppRoutes
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.adminProfile.value == null) {
          return const Center(child: CircularProgressIndicator(color: headerBackgroundColor));
        }
        if (!controller.isLoading.value && controller.adminProfile.value == null && controller.currentUserId.value.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.grey, size: 60),
                  const SizedBox(height: 16),
                  Text('Tidak dapat memuat data profil.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor)),
                  const SizedBox(height: 8),
                  Text('Pastikan Anda telah login.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshProfile(),
          color: headerBackgroundColor,
          child: CustomScrollView( // Menggunakan CustomScrollView untuk efek header yang lebih fleksibel
            slivers: [
              _buildCustomSliverAppBar(context), // Header kustom sebagai SliverAppBar
              SliverToBoxAdapter( // Konten lainnya
                child: _buildProfileContent(context),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCustomSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: headerBackgroundColor,
      expandedHeight: 220.0, // Tinggi header kustom
      pinned: true, // Header tetap terlihat saat scroll (hanya bagian title/leading)
      automaticallyImplyLeading: false, // Kita akan buat tombol back sendiri
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: headerBackgroundColor, // Warna solid
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40), // Lengkungan lebih besar
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Space untuk status bar dan tombol back
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.8),
                backgroundImage: (controller.displayPhotoUrl.value.isNotEmpty && Uri.tryParse(controller.displayPhotoUrl.value)?.hasAbsolutePath == true)
                    ? NetworkImage(controller.displayPhotoUrl.value)
                    : null,
                child: (controller.displayPhotoUrl.value.isEmpty || Uri.tryParse(controller.displayPhotoUrl.value)?.hasAbsolutePath != true)
                    ? Icon(Icons.person_outline, size: 60, color: iconColor.withOpacity(0.9))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                "Hello, ${controller.displayUsername.value}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: headerTextColor, // Teks di header
                ),
              ),
              const SizedBox(height: 20), // Padding bawah
            ],
          ),
        ),
      ),
      leading: IconButton( // Tombol back di AppBar
        icon: const Icon(Icons.arrow_back, color: Colors.black54), // Warna ikon back
        onPressed: () => Get.back(),
      ),
    );
  }


  Widget _buildProfileContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0), // Jarak dari header
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Informasi Akun",
              style: TextStyle(
                fontSize: 22, // Ukuran font lebih besar untuk judul section
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding untuk kartu
            child: _buildInfoCard(
              icon: Icons.person_outline, // Ikon sesuai gambar
              label: "Username",
              value: controller.displayUsername.value,
              onEdit: () => controller.promptEditUsername(), // Panggil fungsi edit username
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding untuk kartu
            child: _buildInfoCard(
              icon: Icons.article_outlined, // Ikon sesuai gambar
              label: "Peran",
              value: controller.displayRole.value,
              onEdit: null, // Tidak ada fungsi edit untuk peran, ikon edit tidak akan tampil
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Padding untuk tombol logout
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit, // Ubah menjadi VoidCallback? (nullable)
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16), // Border radius lebih besar
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
          Container( // Latar belakang ikon
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headerBackgroundColor.withOpacity(0.25), // Warna dari header tapi lebih transparan
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
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
                ),
              ],
            ),
          ),
          // Tampilkan IconButton hanya jika onEdit tidak null
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: editIconColor, size: 22), // Ikon edit
              onPressed: onEdit,
              tooltip: 'Edit $label',
              splashRadius: 20,
            )
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          controller.logout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: cardBackgroundColor,
          foregroundColor: logoutButtonTextColor,
          padding: const EdgeInsets.symmetric(vertical: 16), // Padding sedikit dikurangi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Border radius disamakan
            side: const BorderSide(color: logoutButtonBorderColor, width: 1.5),
          ),
          elevation: 2,
          shadowColor: logoutButtonBorderColor.withOpacity(0.3),
        ),
        child: const Text(
          "LOG OUT",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}