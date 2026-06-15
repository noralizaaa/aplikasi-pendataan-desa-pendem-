// lib/presentation/admin/profil/admin_profil_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_profil_controller.dart'; // Pastikan controller ini sudah memiliki fungsi edit

/// [AdminProfilPage] adalah halaman antarmuka untuk profil pribadi pengguna Admin.
/// 
/// Halaman ini menampilkan informasi dasar admin seperti foto profil, nama, dan peran,
/// serta menyediakan akses untuk mengubah nama pengguna dan tombol keluar (logout).
class AdminProfilPage extends GetView<AdminProfilController> {
  const AdminProfilPage({super.key});

  /// Warna latar belakang halaman.
  static const Color pageBackgroundColor = Color(0xFFEBF4F8); 
  /// Warna oranye muda untuk gradasi header.
  static const Color headerBackgroundColor = Color(0xFFFFD180); 
  static const Color headerTextColor = Colors.black87; 
  /// Warna oranye utama untuk ikon.
  static const Color iconColor = Color(0xFFF57C00); 
  static const Color cardBackgroundColor = Colors.white;
  static const Color logoutButtonTextColor = Color(0xFFF57C00);
  static const Color logoutButtonBorderColor = Color(0xFFF57C00);
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color labelTextColor = Color(0xFF616161);
  static const Color editIconColor = Colors.black54; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.adminProfile.value == null) {
          return const Center(child: CircularProgressIndicator(color: headerBackgroundColor));
        }
        if (!controller.isLoading.value && controller.adminProfile.value == null && controller.currentUserId.value.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.grey, size: 60),
                  SizedBox(height: 16),
                  Text('Tidak dapat memuat data profil.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor)),
                  SizedBox(height: 8),
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
                _buildUserStyleHeader(context), 
                _buildProfileContent(context), 
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Membangun bagian header halaman dengan gaya profil user.
  /// 
  /// Mencakup gradasi warna oranye, tombol kembali, foto profil melingkar, 
  /// dan ucapan sapaan nama admin.
  Widget _buildUserStyleHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFAB40).withValues(alpha: 1.0), 
            const Color(0xFFFFD180).withValues(alpha: 0.5), 
          ],
        ),
        borderRadius: const BorderRadius.only(
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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
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

  /// Membangun isi utama profil berupa daftar kartu informasi akun.
  Widget _buildProfileContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Informasi Akun",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), 
            child: _buildInfoCard(
              icon: Icons.person_outline, 
              label: "Username",
              value: controller.displayUsername.value,
              onEdit: () => controller.promptEditUsername(), 
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), 
            child: _buildInfoCard(
              icon: Icons.article_outlined, 
              label: "Peran",
              value: controller.displayRole.value == 'admin_rt' ? 'Admin Monitoring' : (controller.displayRole.value.replaceAll('_', ' ').capitalizeFirst ?? controller.displayRole.value),
              onEdit: null, 
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), 
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu informasi yang berisi ikon, label, dan nilai data.
  /// 
  /// Dilengkapi dengan tombol edit opsional jika [onEdit] diberikan.
  Widget _buildInfoCard({
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
            color: Colors.grey.withValues(alpha: 0.15),
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
              color: headerBackgroundColor.withValues(alpha: 0.25), 
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
                  style: const TextStyle(
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
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: editIconColor, size: 22), 
              onPressed: onEdit,
              tooltip: 'Edit $label',
              splashRadius: 20,
            )
        ],
      ),
    );
  }

  /// Membangun tombol Logout yang bergaya Outline Button.
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
          padding: const EdgeInsets.symmetric(vertical: 16), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: logoutButtonBorderColor, width: 1.5),
          ),
          elevation: 2,
          shadowColor: logoutButtonBorderColor.withValues(alpha: 0.3),
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
