// lib/presentation/admin/Admin_Profile/form_account_management_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'form_account_management_controller.dart';
import 'managed_account_model.dart';

class FormAccountManagementPage
    extends GetView<FormAccountManagementController> {
  const FormAccountManagementPage({Key? key}) : super(key: key);

  // Define colors based on the image or your app's theme
  static const Color pageBackgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color headerBackgroundColor = FormAccountManagementController.primaryHeaderColor; // Orange from controller
  static const Color headerTextColor = Colors.white;
  static const Color searchBarColor = Colors.white;
  static const Color searchIconColor = Color(0xFFFFCA28); // Yellowish

  // Warna Tombol Aksi
  static const Color createNewUserButtonColor = FormAccountManagementController.primaryHeaderColor; // Tombol utama untuk buat akun baru
  static const Color selectExistingUserButtonColor = Color(0xFF4CAF50); // Warna hijau untuk tombol pilih pengguna

  static const Color buttonTextColor = Colors.white;
  static const Color cardBackgroundColor = Colors.white;
  static const Color accountTextColor = Colors.black87;
  static const Color editButtonColor = FormAccountManagementController.editButtonColor; // Green
  static const Color deleteButtonColor = FormAccountManagementController.deleteButtonColor; // Red


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildActionButtonsRow(), // Widget untuk tombol-tombol aksi
          Expanded(child: _buildAccountList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: headerBackgroundColor,
      padding: EdgeInsets.only(
          top: Get.mediaQuery.padding.top + 10,
          bottom: 15,
          left: 10,
          right: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: headerTextColor),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 10),
          Obx(() => Text(
            'Management Account\n${controller.formTitle.value}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: headerTextColor),
            textAlign: TextAlign.start,
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Cari Akun (berdasarkan email)',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: searchIconColor,
                borderRadius: BorderRadius.circular(8.0)
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Aksi pencarian bisa dipicu di sini jika perlu
              },
            ),
          ),
          filled: true,
          fillColor: searchBarColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: headerBackgroundColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Widget untuk menampung semua tombol aksi
  Widget _buildActionButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Tombol PERTAMA: Diganti menjadi "Buat Akun Pengguna Baru"
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: createNewUserButtonColor, // Menggunakan warna utama
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => controller.showCreateSystemUserDialog(), // Panggil dialog buat pengguna sistem baru
            icon: const Icon(Icons.person_add_alt_1, color: buttonTextColor),
            label: const Text(
              'Buat Akun Pengguna Baru', // Label tombol diganti
              style: TextStyle(fontSize: 15, color: buttonTextColor),
            ),
          ),
          const SizedBox(height: 10),
          // Tombol KEDUA: Tetap "Pilih dari Daftar Pengguna"
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectExistingUserButtonColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => controller.showSelectUserFromListDialog(),
            icon: const Icon(Icons.person_search_outlined, color: buttonTextColor),
            label: const Text(
              'Pilih dari Daftar Pengguna',
              style: TextStyle(fontSize: 15, color: buttonTextColor),
            ),
          ),
          // Tombol "Tambah Otoritas via Email" yang asli sudah digantikan fungsinya oleh tombol pertama.
          // Tombol ketiga yang sebelumnya juga "Buat Akun Pengguna Baru" kini tidak diperlukan.
        ],
      ),
    );
  }


  Widget _buildAccountList() {
    return Obx(() {
      if (controller.isLoading.value && controller.accounts.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: headerBackgroundColor));
      }
      if (controller.filteredAccounts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              controller.searchQuery.value.isEmpty
                  ? 'Belum ada akun dengan otoritas untuk form ini.'
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

  Widget _buildAccountItem(ManagedAccount account) {
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
                    account.email,
                    style: const TextStyle(fontSize: 15, color: accountTextColor, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (account.role.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Peran: ${account.role.capitalizeFirst ?? account.role}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: editButtonColor)
                    ),
                  ),
                  onPressed: () => controller.editAccount(account),
                  child: const Text('Edit', style: TextStyle(color: editButtonColor)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: deleteButtonColor)
                      )
                  ),
                  onPressed: () => controller.deleteAccount(account),
                  child: const Text('Delete', style: TextStyle(color: deleteButtonColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
