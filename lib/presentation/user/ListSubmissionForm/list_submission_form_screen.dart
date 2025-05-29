import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import './list_submission_form_controller.dart';
// FormSubmission tidak perlu diimport di sini jika kita pakai DisplayableSubmission
// import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart';

class ListSubmissionFormScreen extends GetView<ListSubmissionFormController> {
  const ListSubmissionFormScreen({Key? key}) : super(key: key);

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
    final TextEditingController searchController = TextEditingController();

    // Sinkronisasi searchController dengan RxString searchQuery
    ever(controller.searchQuery, (String query) {
      if (searchController.text != query) {
        searchController.text = query;
        // Pindahkan kursor ke akhir teks jika diperlukan
        searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));
      }
    });
    // Membersihkan searchController saat widget di-dispose
    // Atau bisa dilakukan di onInit dan onClose controller jika searchController ada di controller.
    // Untuk saat ini, cukup di sini karena searchController bersifat lokal.
    // Jika ingin state search tetap ada saat kembali ke halaman ini, pindahkan searchController ke controller.

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, searchController),
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
              icon: const Icon(Icons.arrow_back), // Anda bisa mengganti ikon ini jika mau
              color: Colors.white, // Warna ikon, bisa juga diatur via iconTheme di AppBar
              tooltip: 'Kembali', // Opsional, untuk aksesibilitas
              onPressed: () {
                Get.back(); // Memanggil fungsi Get.back() saat tombol ditekan
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
                  hintStyle: TextStyle(color: textColorSecondary.withOpacity(0.7), fontSize: 14.5),
                  filled: true,
                  fillColor: searchFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding vertikal disesuaikan
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6), // Margin agar tidak terlalu mepet
                    decoration: BoxDecoration(
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
                    color: Colors.grey.withOpacity(0.1),
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
                  Text(
                    displayableSubmission.displayTitle, // Menggunakan displayTitle
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColorPrimary),
                    maxLines: 2, // Izinkan 2 baris jika panjang
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Dikirim: ${dateFormat.format(submission.submittedAt.toDate())}',
                    style: TextStyle(fontSize: 12, color: textColorSecondary.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _actionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: editButtonColor,
              textColor: Colors.white,
              onPressed: () => controller.editSubmission(submission),
            ),
            const SizedBox(width: 8),
            _actionButton(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              color: deleteButtonColor,
              textColor: Colors.white,
              onPressed: () => controller.deleteSubmission(submission, displayableSubmission.displayTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(label, style: TextStyle(fontSize: 12.5, color: textColor, fontWeight: FontWeight.w500)), // Ukuran font disesuaikan
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Padding tombol
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1.0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Mengurangi area tap
      ),
    );
  }

  Widget _buildNoSubmissionsMessage() {
    return LayoutBuilder( // Agar bisa mengambil constraint tinggi
        builder: (context, constraints) {
          return SingleChildScrollView( // Agar bisa di-scroll jika kontennya melebihi tinggi
            physics: const AlwaysScrollableScrollPhysics(), // Selalu bisa di-scroll untuk RefreshIndicator
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight), // Minimal setinggi parent
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
                      Text(
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

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), // Padding bawah lebih besar untuk home indicator
      decoration: BoxDecoration(
        color: pageBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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