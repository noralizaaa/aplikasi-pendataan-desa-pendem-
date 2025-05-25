// lib/presentation/admin/Admin_Profile/admin_account_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_account_controller.dart'; // Menggunakan controller yang sudah dirombak
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk FormItem
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk warna konsisten
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Untuk navigasi


class AdminAccountPage extends GetView<AdminAccountController> {
  const AdminAccountPage({Key? key}) : super(key: key);

  static const Color pageBackgroundColor = Color(0xFFEBF4F8);
  static const Color titlePageColor = Colors.black87;
  static const Color cardBgColor = AdminScreen.cardBackgroundColor;
  static const Color titleColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;
  static const Color dateColor = Colors.grey;
  static const Color iconDetailColor = AdminScreen.iconColor; // Dari AdminScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul halaman, bisa "Daftar Form Saya" atau "Manajemen Form"
            // Sesuai gambar terakhir Anda, ini lebih seperti "Kategori Manajemen Akun"
            // Namun Anda klarifikasi bahwa "DC-Penduduk" adalah NAMA FORM.
            // Jadi, judulnya bisa "Form Tersedia" atau "Pilih Form"
            const Text(
              'Pilih Form untuk Dikelola', // Atau 'Daftar Form Saya'
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titlePageColor,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.listedForms.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
                }
                if (controller.listedForms.isEmpty) {
                  return _buildNoFormsMessage(); // Pesan jika tidak ada form
                }
                return RefreshIndicator(
                  onRefresh: () => controller.refreshListedForms(),
                  color: AdminScreen.accentHeaderColor,
                  child: ListView.builder(
                    itemCount: controller.listedForms.length,
                    itemBuilder: (context, index) {
                      final formItem = controller.listedForms[index];
                      // Menggunakan widget kartu yang sama dengan di Dashboard atau AdminFormPage
                      // jika tampilannya serupa
                      return _buildFormItemCardForAccountTab(formItem, context);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      // Tombol "Buat Form Baru" bisa ditambahkan di sini jika tab "Account" juga berfungsi untuk membuat form
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => Get.toNamed(AppRoutes.adminFormBuilder),
      //   label: Text('Buat Form Baru'),
      //   icon: Icon(Icons.add),
      //   backgroundColor: AdminScreen.accentHeaderColor,
      // ),
    );
  }

  // Kartu ini akan menampilkan FormItem, mirip dengan yang ada di AdminFormPage atau Dashboard
  Widget _buildFormItemCardForAccountTab(FormItem item, BuildContext context) {
    int totalQuestions = item.sections.fold(0, (sum, section) => sum + section.questions.length);
    String formattedDate = "${item.createdAt.toLocal().day.toString().padLeft(2,'0')}/"
        "${item.createdAt.toLocal().month.toString().padLeft(2,'0')}/"
        "${item.createdAt.toLocal().year}";

    // Ambil ikon berdasarkan judul atau properti lain jika ada.
    // Ini adalah bagian yang sebelumnya menggunakan _getIconFromString untuk AccountCategoryItem.
    // Untuk FormItem, Anda bisa menggunakan ikon generik atau logika lain.
    IconData formIcon = Icons.description_outlined; // Ikon default untuk form
    // Contoh logika ikon berdasarkan judul (jika judulnya unik dan bisa dipetakan)
    if (item.title.toLowerCase().contains("penduduk")) {
      formIcon = Icons.people_alt_outlined;
    } else if (item.title.toLowerCase().contains("tps3r")) {
      formIcon = Icons.recycling_outlined;
    } else if (item.title.toLowerCase().contains("bank sampah")) {
      formIcon = Icons.savings_outlined;
    } else if (item.title.toLowerCase().contains("desa")) {
      formIcon = Icons.holiday_village_outlined;
    }


    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: InkWell(
        onTap: () {
          // Aksi ketika form diklik: navigasi ke halaman edit form (form builder)
          controller.navigateToFormDetail(item);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Agar ikon dan teks sejajar tengah
            children: [
              Container( // Latar belakang ikon
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminScreen.primaryHeaderColor.withOpacity(0.25), // Warna oranye muda
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(formIcon, color: AdminScreen.iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title, // Ini adalah "DC-Penduduk", dll.
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: titleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Dibuat: $formattedDate | Pertanyaan: $totalQuestions',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Tombol aksi seperti hapus bisa menggunakan PopupMenuButton jika diperlukan di sini juga
              // Icon(Icons.arrow_forward_ios_rounded, size: 18, color: iconDetailColor.withOpacity(0.7)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'delete') {
                    controller.deleteForm(item.id, item.title);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Hapus'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFormsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ballot_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Form yang Dibuat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Semua form yang Anda buat akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}