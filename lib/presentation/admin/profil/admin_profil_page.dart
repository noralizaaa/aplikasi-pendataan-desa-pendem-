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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildUserStyleHeader(context), // Header disamakan seperti UI user
                _buildProfileContent(context), // Konten lainnya
              ],
            ),
          ),
        );
      }),
    );
  }

  // Header bergaya user, tidak menggunakan SliverAppBar
  Widget _buildUserStyleHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFAB40).withOpacity(1.0), // Warna oranye lebih tua untuk gradasi
            Color(0xFFFFD180).withOpacity(0.5), // Warna oranye muda
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(100),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black54),
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: ClipOval(
              child: (controller.displayPhotoUrl.value.isNotEmpty &&
                  Uri.tryParse(controller.displayPhotoUrl.value)?.hasAbsolutePath == true)
                  ? Image.network(
                controller.displayPhotoUrl.value,
                fit: BoxFit.cover,
                width: 90,
                height: 90,
              )
                  : Image.asset(
                'assets/images/Profile.png',
                fit: BoxFit.cover,
                width: 90,
                height: 90,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Hello, ${controller.displayUsername.value}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
        ],
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
