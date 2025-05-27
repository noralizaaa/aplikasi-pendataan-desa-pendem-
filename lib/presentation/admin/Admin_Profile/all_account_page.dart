// lib/presentation/admin/Admin_Profile/all_account_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'all_account_controller.dart'; // Controller baru
import 'admin_account_model.dart'; // Menggunakan AdminAccountModel
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk warna konsisten

class AllAccountPage extends GetView<AllAccountController> {
  const AllAccountPage({Key? key}) : super(key: key);

  // Define colors based on the image or your app's theme
  static const Color pageBackgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color headerBackgroundColor = AdminScreen.primaryHeaderColor; // Orange from AdminScreen
  static const Color headerTextColor = Colors.white;
  static const Color searchBarColor = Colors.white;
  static const Color searchIconColor = AdminScreen.accentHeaderColor; // Yellowish from AdminScreen

  // Warna Tombol Aksi
  static const Color createNewUserButtonColor = AdminScreen.primaryHeaderColor; // Tombol utama untuk buat akun baru
  static const Color buttonTextColor = Colors.white;
  static const Color cardBackgroundColor = Colors.white;
  static const Color accountTextColor = Colors.black87;
  static const Color editButtonColor = Color(0xFF4CAF50); // Green (slightly darker for contrast)
  static const Color deleteButtonColor = Color(0xFFF44336); // Red (slightly darker for contrast)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          _buildHeaderWithSearch(), // Gabungan header + search bar dalam satu container oranye
          _buildActionButton(), // Only one button for creating new user
          Expanded(child: _buildAccountList()),
        ],
      ),
    );
  }

  // Gabungan header + search bar, supaya search bar di dalam container oranye dengan gradasi dan lengkungan kanan bawah
  Widget _buildHeaderWithSearch() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFAB40), // Warna oranye tua
            Color(0xFFFFD180), // Warna oranye muda
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(60),
        ),
      ),
      padding: EdgeInsets.only(
        top: Get.mediaQuery.padding.top + 10,
        left: 16,
        right: 16,
        bottom: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Manajemen Semua Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar diletakkan di sini, jadi masuk dalam container oranye
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => controller.updateSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Cari Akun (berdasarkan email atau username)',
                suffixIcon: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AdminScreen.accentHeaderColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // Optional search action, sudah ada onChanged
                    },
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: searchIconColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () => controller.showCreateSystemUserDialog(),
        icon: const Icon(Icons.person_add_alt_1, color: buttonTextColor),
        label: const Text(
          'Buat Akun Pengguna Baru',
          style: TextStyle(fontSize: 15, color: buttonTextColor),
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    return Obx(() {
      if (controller.isLoading.value && controller.allAccounts.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: headerBackgroundColor));
      }
      if (controller.filteredAccounts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              controller.searchQuery.value.isEmpty
                  ? 'Tidak ada akun terdaftar.'
                  : 'Akun "${controller.searchQuery.value}" tidak ditemukan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: controller.filteredAccounts.length,
        itemBuilder: (context, index) {
          final account = controller.filteredAccounts[index];
          return _buildAccountItem(account);
        },
      );
    });
  }

  Widget _buildAccountItem(AdminAccountModel account) {
    return Card(
      color: cardBackgroundColor,
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.username,
                    style: const TextStyle(
                        fontSize: 15,
                        color: accountTextColor,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      account.email,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (account.role.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Peran: ${account.role.capitalizeFirst ?? account.role}',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Edit Akun',
                  icon: Icon(Icons.edit, color: editButtonColor),
                  onPressed: () => controller.editAccount(account),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Hapus Akun',
                  icon: Icon(Icons.delete, color: deleteButtonColor),
                  onPressed: () => controller.deleteAccount(account),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
