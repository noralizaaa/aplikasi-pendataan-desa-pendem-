import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/navigation/routes.dart';
import './list_submission_form_controller.dart';
// FormSubmission tidak perlu diimport di sini jika kita pakai DisplayableSubmission
// import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart';

/// [ListSubmissionFormScreen] adalah antarmuka untuk menampilkan daftar riwayat pendataan 
/// yang dilakukan oleh Petugas pada satu formulir tertentu.
/// 
/// Halaman ini menyediakan fitur:
/// 1. Bar pencarian identitas (Nama/NIK) yang modern dalam header gradasi.
/// 2. Kontrol pengurutan data (sorting).
/// 3. Kartu informasi ringkas per isian dengan status badge.
/// 4. Tombol aksi cepat untuk mengedit atau menghapus isian.
class ListSubmissionFormScreen extends GetView<ListSubmissionFormController> {
  const ListSubmissionFormScreen({super.key});

  /// Skema warna standar halaman riwayat pendataan.
  static const Color pageBackgroundColor = Color(0xFFF0F4F8);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);

  static const Color cardBackgroundColor = Colors.white;
  static const Color searchFieldColor = Colors.white;
  static const Color searchButtonBackgroundColor = Color(0xFFFFD600);
  static const Color searchIconItselfColor = Color(0xFF424242);

  static const Color deleteButtonColor = Color(0xFFEF5350);
  static const Color editButtonColor = Color(0xFF66BB6A);
  static const Color textColorPrimary = Color(0xFF37474F);
  static const Color textColorSecondary = Color(0xFF546E7A);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yy, HH:mm', 'id_ID'); // Format diperpendek

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, controller.searchController),
          _buildControlsAndTitle(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingStructure.value && controller.formStructure.value == null) {
                return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
              }
              if (controller.errorMessage.value.isNotEmpty && controller.formStructure.value == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
                );
              }
              if (controller.formStructure.value == null && !controller.isLoadingStructure.value) { // Tambahan kondisi
                return const Center(child: Text("Detail form tidak dapat dimuat."));
              }

              return RefreshIndicator(
                onRefresh: () => controller.refreshData(),
                color: accentHeaderColor,
                child: Obx(() {
                  if (controller.isLoadingSubmissions.value && controller.displayedSubmissions.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
                  }
                  if (controller.displayedSubmissions.isEmpty && !controller.isLoadingSubmissions.value) {
                    return _buildNoSubmissionsMessage();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: controller.displayedSubmissions.length,
                    itemBuilder: (context, index) {
                      final displayableSubmission = controller.displayedSubmissions[index];
                      return _buildSubmissionCard(displayableSubmission, dateFormat, context);
                    },
                  );
                }),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  /// Membangun bagian header yang mencakup AppBar dan bar pencarian identitas.
  /// 
  /// Menggunakan dekorasi gradasi oranye dan lengkungan pada sisi bawah untuk 
  /// konsistensi desain modern aplikasi.
  Widget _buildHeader(BuildContext context, TextEditingController searchController) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryHeaderColor, accentHeaderColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ]
      ),
      child: Column(
        children: [
          AppBar(
            // AWAL PENAMBAHAN UNTUK Get.back()
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              tooltip: 'Kembali',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // AKHIR PENAMBAHAN

            title: Obx(() => Text(
              controller.formStructure.value?.title ?? 'Daftar Isian',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            )),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white), // Ini akan berlaku untuk ikon di `actions` juga
            centerTitle: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Padding disesuaikan
            child: Material(
              elevation: 4.0, // Shadow lebih terlihat
              borderRadius: BorderRadius.circular(30.0), // Lebih bulat
              shadowColor: Colors.black45,
              child: TextField(
                controller: searchController,
                onChanged: (value) => controller.changeSearchQuery(value),
                style: const TextStyle(color: textColorPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama/NIK/No.KK...', // Hint lebih spesifik
                  hintStyle: TextStyle(color: textColorSecondary.withValues(alpha: 0.7), fontSize: 14.5),
                  filled: true,
                  fillColor: searchFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding vertikal disesuaikan
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6), // Margin agar tidak terlalu mepet
                    decoration: const BoxDecoration(
                      color: searchButtonBackgroundColor,
                      shape: BoxShape.circle, // Tombol search bulat
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: searchIconItselfColor, size: 22), // Warna ikon search
                      onPressed: () {
                        controller.changeSearchQuery(searchController.text);
                      },
                      splashRadius: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun barisan judul section dan dropdown untuk pengurutan data.
  Widget _buildControlsAndTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0), // Padding disesuaikan
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Riwayat Pendataan', // Judul diganti
            style: TextStyle(
              fontSize: 19, // Ukuran font disesuaikan
              fontWeight: FontWeight.bold,
              color: textColorPrimary,
            ),
          ),
          Container(
            height: 36, // Tinggi dropdown
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Padding internal
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18), // Lebih bulat
                border: Border.all(color: Colors.grey.shade300, width: 1), // Border lebih halus
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.currentSortOrder.value,
                icon: const Icon(Icons.sort_rounded, color: accentHeaderColor, size: 20), // Ikon sort
                style: const TextStyle(color: textColorSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
                items: controller.sortOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  controller.changeSortOrder(newValue);
                },
                dropdownColor: Colors.white,
              ),
            )),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu item individu untuk setiap data isian (submission).
  /// 
  /// Menampilkan judul (Nama KRT), NIK, status badge, periode, dan waktu pengiriman.
  /// Dilengkapi dengan tombol aksi edit dan hapus.
  Widget _buildSubmissionCard(DisplayableSubmission displayableSubmission, DateFormat dateFormat, BuildContext context) {
    final submission = displayableSubmission.originalSubmission; // Ambil original submission
    return Card(
      elevation: 2.0, // Shadow lebih subtle
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut lebih membulat
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // Padding disesuaikan
        child: Row(
          children: [
            // Tambahkan ikon di kiri jika diinginkan, misal ikon orang
            // CircleAvatar(
            //   backgroundColor: accentHeaderColor.withOpacity(0.15),
            //   child: Icon(Icons.person_pin_circle_outlined, color: accentHeaderColor, size: 24),
            //   radius: 22,
            // ),
            // const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayableSubmission.displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColorPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(displayableSubmission.status),
                    ],
                  ),
                  if (displayableSubmission.displayDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        displayableSubmission.displayDescription,
                        style: TextStyle(fontSize: 13, color: textColorSecondary.withValues(alpha: 0.9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (displayableSubmission.nikKepalaKeluarga.isNotEmpty && 
                      displayableSubmission.displayTitle != displayableSubmission.nikKepalaKeluarga &&
                      displayableSubmission.displayDescription != displayableSubmission.nikKepalaKeluarga)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        "NIK: ${displayableSubmission.nikKepalaKeluarga}",
                        style: TextStyle(fontSize: 12, color: textColorSecondary.withValues(alpha: 0.7), letterSpacing: 0.5),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentHeaderColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayableSubmission.period,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentHeaderColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dikirim: ${dateFormat.format(submission.submittedAt.toDate())}',
                        style: TextStyle(fontSize: 11, color: textColorSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min, // Ensures the Row takes minimum space
              children: [
                IconButton(
                  tooltip: 'Edit Pengajuan', // Tooltip for edit
                  icon: const Icon(Icons.edit_outlined, color: editButtonColor),
                  onPressed: () => controller.editSubmission(submission),
                ),
                const SizedBox(width: 4), // Consistent spacing with all_account_page
                IconButton(
                  tooltip: 'Hapus Pengajuan', // Tooltip for delete
                  icon: const Icon(Icons.delete_outline_rounded, color: deleteButtonColor),
                  onPressed: () => controller.deleteSubmission(submission, displayableSubmission.displayTitle),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Menampilkan pesan placeholder saat petugas belum pernah mengisi formulir tersebut.
  Widget _buildNoSubmissionsMessage() {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum Ada Data Isian',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda belum pernah mengisi form ini.\nTekan tombol di bawah untuk memulai pendataan baru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: textColorSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  /// Membangun label (badge) berwarna untuk menunjukkan status isian (Draft, Submitted, Locked).
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft': color = Colors.grey; break;
      case 'submitted': color = Colors.green; break;
      case 'locked': color = Colors.red; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Membangun tombol utama di bagian bawah layar untuk membuat pendataan baru.
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), // Padding bawah lebih besar untuk home indicator
      decoration: BoxDecoration(
        color: pageBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
        label: const Text('Buat Pendataan Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => controller.goToAddSubmission(),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentHeaderColor,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut lebih membulat
          elevation: 2.5,
        ),
      ),
    );
  }
}