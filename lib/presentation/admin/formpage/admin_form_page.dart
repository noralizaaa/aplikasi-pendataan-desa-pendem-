// lib/presentation/admin/formpage/admin_form_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk penggunaan warna konsisten
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import '../../../infrastructure/navigation/routes.dart'; // Untuk AppRoutes (navigasi)

class AdminFormPage extends GetView<AdminFormController> {
  const AdminFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get.put(AdminFormController()); // DIHAPUS - Controller sekarang di-inject oleh AdminBinding

    return Scaffold(
      backgroundColor: AdminScreen.pageBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigasi ke halaman pembuatan form baru menggunakan rute bernama
          Get.toNamed(AppRoutes.adminFormBuilder);
        },
        label: const Text('Buat Form Baru', style: TextStyle(fontWeight: FontWeight.w500)),
        icon: const Icon(Icons.add_circle_outline_rounded),
        backgroundColor: AdminScreen.accentHeaderColor, // Warna tombol dari AdminScreen
        foregroundColor: Colors.white, // Warna teks & ikon pada FAB
        elevation: 4.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Padding(
        // Padding untuk seluruh konten halaman, beri ruang untuk FAB
        padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0, bottom: 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anda bisa menambahkan judul halaman di sini jika diinginkan,
            // misalnya:
            // const Padding(
            //   padding: EdgeInsets.only(bottom: 16.0),
            //   child: Text(
            //     'Manajemen Form Survei',
            //     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            //   ),
            // ),

            // Daftar Forms
            // ... (import dan kode lain di AdminFormPage)

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.forms.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
                }
                if (controller.forms.isEmpty) {
                  return _buildNoFormsMessage(context);
                }
                return RefreshIndicator(
                  onRefresh: () => controller.refreshFormsData(), // <-- PANGGIL METODE BARU
                  color: AdminScreen.accentHeaderColor,
                  child: ListView.builder(
                    itemCount: controller.forms.length,
                    itemBuilder: (context, index) {
                      final form = controller.forms[index];
                      return _buildFormCard(form);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk membangun satu kartu item form
  Widget _buildFormCard(FormItem form) {
    int totalQuestions = form.sections.fold(0, (sum, section) => sum + section.questions.length);
    // Contoh format tanggal sederhana, Anda bisa menggunakan package 'intl' untuk format yang lebih kaya
    String formattedDate = "${form.createdAt.toLocal().day.toString().padLeft(2, '0')}/"
        "${form.createdAt.toLocal().month.toString().padLeft(2, '0')}/"
        "${form.createdAt.toLocal().year}";

    return Card(
      elevation: 2.5, // Shadow yang lebih halus
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut lebih membulat
      color: AdminScreen.cardBackgroundColor,
      child: InkWell(
        onTap: () {
          // Ketika form yang sudah ada diklik, navigasi ke builder untuk mengeditnya
          Get.toNamed(AppRoutes.adminFormBuilder, arguments: form.id);
        },
        borderRadius: BorderRadius.circular(12), // Sesuaikan dengan shape Card
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Sejajarkan item dari atas
            children: [
              // Ikon untuk form
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 2.0),
                child: Icon(Icons.assignment_turned_in_outlined, color: AdminScreen.accentHeaderColor, size: 38),
              ),
              // Konten teks form
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (form.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        form.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10), // Jarak lebih
                    Text(
                      'Dibuat: $formattedDate',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    // Tampilkan createdByUserId jika relevan, atau bisa disembunyikan
                    // Text(
                    //   'Oleh: ${form.createdByUserId.length > 10 ? form.createdByUserId.substring(0,10)+'...' : form.createdByUserId}',
                    //   style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    // ),
                    Text(
                      'Bagian: ${form.sections.length}, Pertanyaan: $totalQuestions',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Tombol aksi (misalnya hapus) menggunakan PopupMenuButton
              SizedBox( // Memberi sedikit ruang agar PopupMenuButton tidak terlalu mepet
                width: 40,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                  tooltip: "Opsi Lainnya",
                  onSelected: (value) {
                    if (value == 'delete') {
                      // Langsung panggil metode deleteForm dari controller
                      // Controller akan menampilkan dialog konfirmasi
                      controller.deleteForm(form.id, form.title);
                    }
                    // Tambahkan case lain jika ada aksi lain, misal 'lihat_respon'
                    // else if (value == 'view_responses') {
                    //   Get.toNamed(AppRoutes.adminViewFormResponses, arguments: form.id);
                    // }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Hapus Form'),
                        ],
                      ),
                    ),
                    // Contoh item menu lain:
                    // const PopupMenuItem<String>(
                    //   value: 'view_responses',
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.visibility_outlined, color: Colors.blueAccent, size: 20),
                    //       SizedBox(width: 10),
                    //       Text('Lihat Respon'),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk ditampilkan jika tidak ada form yang tersedia
  Widget _buildNoFormsMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Belum ada form yang dibuat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Tekan tombol "Buat Form Baru" di bawah untuk menambahkan form pertama Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}