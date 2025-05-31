// lib/presentation/admin/submissions_form/submissions_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import './submissions_form_controller.dart'; // Pastikan path ini benar

class SubmissionsFormScreen extends GetView<SubmissionsFormController> {
  const SubmissionsFormScreen({Key? key}) : super(key: key);

  // --- Konstanta Warna dari User Screen (bisa disesuaikan jika perlu tema admin berbeda) ---
  static const Color pageBackgroundColor = Color(0xFFF0F4F8); // Atau warna tema Admin
  static const Color primaryHeaderColor = Color(0xFFFFB74D); // Orange lebih muda untuk admin
  static const Color accentHeaderColor = Color(0xFFFB8C00); // Orange lebih tua untuk admin

  static const Color cardBackgroundColor = Colors.white;
  static const Color searchFieldColor = Colors.white;
  static const Color searchButtonBackgroundColor = Color(0xFFFFCA28); // Kuning untuk admin
  static const Color searchIconItselfColor = Color(0xFF424242);

  static const Color deleteButtonColor = Color(0xFFE53935); // Merah lebih gelap
  static const Color editButtonColor = Color(0xFF43A047); // Hijau lebih gelap
  static const Color textColorPrimary = Color(0xFF263238); // Biru tua keabu-abuan
  static const Color textColorSecondary = Color(0xFF455A64); // Sedikit lebih muda
  // --- Akhir Konstanta Warna ---

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yy, HH:mm', 'id_ID');
    final TextEditingController searchController = TextEditingController();

    ever(controller.searchQuery, (String query) {
      if (searchController.text != query) {
        searchController.text = query;
        searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));
      }
    });

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, searchController),
          _buildControlsAndTitle(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingStructure.value && controller.formStructure.value == null && controller.initialFormTitle.value.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
              }
              if (controller.errorMessage.value.isNotEmpty && controller.displayedSubmissions.isEmpty) { // Tampilkan error jika ada dan list kosong
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
                );
              }
              // Jika struktur form belum ada tapi initial title ada, setidaknya tampilkan loading submissions
              if (controller.isLoadingSubmissions.value && controller.displayedSubmissions.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
              }


              return RefreshIndicator(
                onRefresh: () => controller.refreshData(),
                color: accentHeaderColor,
                child: Obx(() {
                  if (controller.isLoadingSubmissions.value && controller.displayedSubmissions.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
                  }
                  if (controller.displayedSubmissions.isEmpty && !controller.isLoadingSubmissions.value) {
                    return _buildNoSubmissionsMessage(
                      controller.searchQuery.value.isNotEmpty
                          ? 'Tidak ada data cocok dengan pencarian "${controller.searchQuery.value}".'
                          : 'Belum ada data isian untuk form ini.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Padding bawah disesuaikan
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
      // Tidak ada bottomNavigationBar untuk tombol "Buat Pendataan Baru" di Admin View
    );
  }

  Widget _buildHeader(BuildContext context, TextEditingController searchController) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryHeaderColor, accentHeaderColor], // Warna Admin
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              tooltip: 'Kembali ke Dashboard',
              onPressed: () {
                Get.back();
              },
            ),
            title: Obx(() => Text( // Gunakan GetBuilder atau Obx untuk title
              controller.appBarTitle, // Menggunakan getter dari controller
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            )
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(30.0),
              shadowColor: Colors.black45,
              child: TextField(
                controller: searchController,
                onChanged: (value) => controller.changeSearchQuery(value),
                style: const TextStyle(color: textColorPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Cari KRT/NIK/User ID...', // Hint lebih spesifik untuk admin
                  hintStyle: TextStyle(color: textColorSecondary.withOpacity(0.7), fontSize: 14.5),
                  filled: true,
                  fillColor: searchFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: searchButtonBackgroundColor, // Warna Admin
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded, color: searchIconItselfColor, size: 22),
                      onPressed: () {
                        controller.changeSearchQuery(searchController.text);
                        FocusScope.of(context).unfocus(); // Tutup keyboard
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
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Daftar Semua Isian', // Judul untuk Admin
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: textColorPrimary,
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300, width: 1),
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
                icon: const Icon(Icons.sort_rounded, color: accentHeaderColor, size: 20),
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
    final submission = displayableSubmission.originalSubmission;
    String subtitleText = 'Dikirim: ${dateFormat.format(submission.submittedAt.toDate())}';
    if (submission.userId != null && submission.userId!.isNotEmpty) {
      subtitleText += '\nUser ID: ${submission.userId}';
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryHeaderColor.withOpacity(0.2),
              child: Icon(Icons.description_outlined, color: accentHeaderColor, size: 24),
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayableSubmission.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5, color: textColorPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitleText,
                    style: TextStyle(fontSize: 11.5, color: textColorSecondary.withOpacity(0.9), height: 1.3),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit Pengajuan',
                  icon: Icon(Icons.edit_note_rounded, color: editButtonColor, size: 26), // Ikon lebih besar
                  onPressed: () => controller.editSubmission(submission),
                ),
                const SizedBox(width: 0), // Kurangi jarak jika perlu
                IconButton(
                  tooltip: 'Hapus Pengajuan',
                  icon: Icon(Icons.delete_forever_rounded, color: deleteButtonColor, size: 26), // Ikon lebih besar
                  onPressed: () => controller.deleteSubmission(submission, displayableSubmission.displayTitle),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubmissionsMessage(String message) {
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
                      Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        message, // Pesan dinamis
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? "Coba kata kunci lain atau bersihkan pencarian."
                            : "Saat ini belum ada data yang tercatat untuk form ini.",
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
}