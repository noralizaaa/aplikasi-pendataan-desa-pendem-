// File: list_submission_form_controller.dart

import 'package:flutter/material.dart'; // Diperlukan untuk debounce
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
// Pastikan path ke model FormSubmission ini benar dan modelnya sudah diperbarui
// dengan field namaKepalaRumahTangga
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

// Helper class untuk item yang akan ditampilkan di list
class DisplayableSubmission {
  final FormSubmission originalSubmission;
  final String displayTitle;        // Akan berisi Nama KRT - NIK KRT (atau salah satunya/fallback)
  final String sortableNamePart;    // Nama KRT untuk sorting (lowercase)
  final String sortableIdPart;      // NIK KRT untuk sorting (jika ada)

  // Tambahkan field ini jika belum ada, untuk akses langsung di UI jika diperlukan terpisah
  final String namaKepalaKeluarga;
  final String nikKepalaKeluarga;


  DisplayableSubmission({
    required this.originalSubmission,
    required this.displayTitle,
    required this.sortableNamePart,
    required this.sortableIdPart,
    required this.namaKepalaKeluarga, // Pastikan ini ada di konstruktor
    required this.nikKepalaKeluarga,  // Pastikan ini ada di konstruktor
  });
}

class ListSubmissionFormController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString formId = ''.obs;
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs;

  final RxBool isLoadingStructure = true.obs;
  final RxBool isLoadingSubmissions = true.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final RxString currentSortOrder = 'Terbaru'.obs;
  // Sesuaikan opsi sorting
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Nama KRT A-Z', 'Nama KRT Z-A'];

  // !! PENTING: SESUAIKAN KODE PERTANYAAN INI DENGAN YANG ADA DI FORMULIR ANDA !!
  // Misalnya, jika questionCode untuk Nama KRT adalah "106"
  final List<String> _namaKrtPriorityCodes = ['106', 'NAMA_KEPALA_KELUARGA', 'NAMA_KRT'];
  // Misalnya, jika questionCode untuk NIK KRT adalah "NIK_KRT" atau kode lain
  final List<String> _nikKrtPriorityCodes = ['NIK_KRT', 'NIK_KEPALA_KELUARGA', '107']; // Contoh

  // Kode fallback jika KRT/NIK tidak ditemukan untuk displayTitle umum
  final List<String> _generalNamePriorityCodes = ['NAMA_LENGKAP', 'NAMA_RESPONDEN', 'NAMA'];
  final List<String> _generalIdPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];


  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 400));

    if (Get.arguments != null && Get.arguments is String) {
      formId.value = Get.arguments as String;
      if (formId.value.isNotEmpty) {
        _fetchFormStructure();
        _fetchSubmissions();
      } else {
        _setLoadingError("ID Form tidak valid.");
      }
    } else {
      _setLoadingError("Argumen ID Form tidak ditemukan.");
    }
  }

  void _setLoadingError(String message) {
    errorMessage.value = message;
    isLoadingStructure.value = false;
    isLoadingSubmissions.value = false;
    displayedSubmissions.clear(); // Pastikan list kosong jika ada error
  }

  Future<void> _fetchFormStructure() async {
    isLoadingStructure.value = true;
    errorMessage.value = ''; // Reset error message
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        formStructure.value = FormItem.fromFirestore(docSnapshot);
      } else {
        errorMessage.value = "Detail form tidak ditemukan.";
        formStructure.value = null;
      }
    } catch (e) {
      print("Error fetching form structure: $e");
      errorMessage.value = "Gagal memuat detail form: ${e.toString()}";
      formStructure.value = null;
    } finally {
      isLoadingStructure.value = false;
    }
  }

  Future<void> _fetchSubmissions() async {
    if (formId.value.isEmpty || _auth.currentUser == null) {
      if (_auth.currentUser == null) print("User not logged in.");
      // Tidak perlu set error di sini jika sudah dihandle di onInit atau _setLoadingError
      isLoadingSubmissions.value = false;
      _originalSubmissions.clear();
      _processSubmissionsForDisplay(); // Proses list kosong untuk update UI
      return;
    }
    isLoadingSubmissions.value = true;
    errorMessage.value = ''; // Reset error message
    try {
      Query query = _db
          .collection('formSubmissions')
          .where('formId', isEqualTo: formId.value)
          .where('userId', isEqualTo: _auth.currentUser!.uid);

      // Apply Firestore-based sorting for time-based orders
      if (currentSortOrder.value == 'Terbaru') {
        query = query.orderBy('submittedAt', descending: true);
      } else if (currentSortOrder.value == 'Terlama') {
        query = query.orderBy('submittedAt', descending: false);
      }
      // For name-based sorting, it's better done client-side after fetching
      // unless you denormalize the name to a top-level sortable field.

      final querySnapshot = await query.get();
      _originalSubmissions.assignAll(querySnapshot.docs
          .map((doc) => FormSubmission.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList());

      _processSubmissionsForDisplay();

    } catch (e) {
      print("Error fetching submissions: $e");
      errorMessage.value = "Gagal memuat daftar isian: ${e.toString()}";
      _originalSubmissions.clear();
      _processSubmissionsForDisplay();
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  // Fungsi ini tetap berguna untuk mengekstrak field lain jika diperlukan,
  // namun untuk Nama KRT, kita akan utamakan field langsung dari model jika ada.
  String _extractAnswerByPriority(List<QuestionAnswer> answers, List<String> priorityCodes) {
    for (String code in priorityCodes) {
      final answer = answers.firstWhereOrNull((qa) =>
      (qa.questionCode.trim().toUpperCase() == code.toUpperCase() || qa.questionId.trim().toUpperCase() == code.toUpperCase()) &&
          qa.answer != null && qa.answer.toString().trim().isNotEmpty);
      if (answer != null) {
        return answer.answer.toString().trim();
      }
    }
    return '';
  }

  void _processSubmissionsForDisplay() {
    List<DisplayableSubmission> processedList = [];
    for (var sub in _originalSubmissions) {
      // Menggunakan field namaKepalaRumahTangga dari model FormSubmission
      // yang sudah dipopulasi di factory fromFirestore
      String namaKRT = sub.namaKepalaRumahTangga ?? ""; // Ambil dari model, fallback ke string kosong

      // Untuk NIK, jika belum ada field langsung di model, kita ekstrak.
      // Jika Anda menambahkan field NIK langsung ke FormSubmission, gunakan seperti namaKRT.
      String nikKRT = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes);

      String currentDisplayTitle = "";
      if (namaKRT.isNotEmpty) {
        currentDisplayTitle = namaKRT;
      } else {
        // Fallback jika Nama KRT dan NIK KRT tidak ada
        // Coba ambil dari _generalNamePriorityCodes atau _generalIdPriorityCodes
        String generalName = _extractAnswerByPriority(sub.answers, _generalNamePriorityCodes);
        String generalId = _extractAnswerByPriority(sub.answers, _generalIdPriorityCodes);
        if (generalName.isNotEmpty) {
          currentDisplayTitle = generalName;
          if (generalId.isNotEmpty) currentDisplayTitle += " ($generalId)";
        } else if (generalId.isNotEmpty) {
          currentDisplayTitle = "ID: $generalId";
        } else {
          currentDisplayTitle = sub.formTitle; // Atau judul form sebagai fallback akhir
        }
      }

      // Filter berdasarkan searchQuery (case-insensitive)
      // Pastikan pencarian juga mencakup namaKRT dan nikKRT secara individual
      if (searchQuery.value.isNotEmpty) {
        bool matchesSearch =
            currentDisplayTitle.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                (namaKRT.isNotEmpty && namaKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (nikKRT.isNotEmpty && nikKRT.toLowerCase().contains(searchQuery.value.toLowerCase()));
        if (!matchesSearch) {
          continue; // Skip jika tidak cocok query
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: currentDisplayTitle,
        sortableNamePart: namaKRT.toLowerCase(), // Digunakan untuk sorting Nama KRT
        sortableIdPart: nikKRT.toLowerCase(),   // Digunakan jika ada sorting berdasarkan NIK
        namaKepalaKeluarga: namaKRT,
        nikKepalaKeluarga: nikKRT,
      ));
    }

    // Sorting
    if (currentSortOrder.value == 'Nama KRT A-Z') {
      processedList.sort((a, b) => a.sortableNamePart.compareTo(b.sortableNamePart));
    } else if (currentSortOrder.value == 'Nama KRT Z-A') {
      processedList.sort((a, b) => b.sortableNamePart.compareTo(a.sortableNamePart));
    } else if (currentSortOrder.value == 'Terlama' && !_originalSubmissions.any((s) => s.submittedAt == null)) {
      processedList.sort((a,b) => a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt));
    } else if (currentSortOrder.value == 'Terbaru' && !_originalSubmissions.any((s) => s.submittedAt == null)){ // Terbaru (default)
      processedList.sort((a,b) => b.originalSubmission.submittedAt.compareTo(a.originalSubmission.submittedAt));
    }
    // Jika submittedAt bisa null, tambahkan penanganan null di perbandingan

    displayedSubmissions.assignAll(processedList);
  }

  void changeSearchQuery(String query) {
    searchQuery.value = query;
    // debounce akan memanggil _processSubmissionsForDisplay
  }

  void changeSortOrder(String? newOrder) {
    if (newOrder != null && newOrder != currentSortOrder.value) {
      currentSortOrder.value = newOrder;
      // Jika sorting waktu, idealnya query ulang ke Firestore
      if (newOrder == 'Terbaru' || newOrder == 'Terlama') {
        _fetchSubmissions(); // Ini akan mengurutkan dari server dan memanggil _process lagi
      } else {
        _processSubmissionsForDisplay(); // Lakukan sorting di client untuk nama
      }
    }
  }

  void goToAddSubmission() {
    if (formId.value.isNotEmpty && formStructure.value != null) {
      Get.toNamed(AppRoutes.INPUT_FORM_USER, arguments: formId.value)?.then((result) {
        if (result == true || result == null) {
          refreshData();
        }
      });
    } else {
      Get.snackbar('Error', 'Tidak bisa membuat data baru, detail form belum termuat atau ID Form tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void editSubmission(FormSubmission submission) {
    if (formId.value.isEmpty || submission.id == null || formStructure.value == null) {
      Get.snackbar('Error', 'Tidak bisa mengedit, detail form belum termuat atau ID tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.toNamed(
      AppRoutes.INPUT_FORM_USER, // Pastikan ini adalah rute yang benar
      arguments: {
        'formId': formId.value,
        'submissionId': submission.id,
      },
    )?.then((result) { // Tambahkan .then untuk refresh jika ada perubahan
      if (result == true || result == null) { // Anggap null atau true sebagai indikasi ada perubahan
        refreshData();
      }
    });
  }

  void deleteSubmission(FormSubmission submission, String displayIdentifier) {
    Get.defaultDialog(
        title: "Konfirmasi Hapus",
        titleStyle: const TextStyle(fontWeight: FontWeight.w600),
        middleText: "Anda yakin ingin menghapus data isian '$displayIdentifier'?",
        textConfirm: "Ya, Hapus",
        textCancel: "Batal",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red.shade400,
        cancelTextColor: Colors.grey.shade700,
        onConfirm: () async {
          Get.back(); // Tutup dialog konfirmasi
          Get.dialog( // Tampilkan dialog loading
              const Center(child: CircularProgressIndicator(color: Colors.orange)), // Warna disesuaikan
              barrierDismissible: false
          );
          try {
            await _db.collection('formSubmissions').doc(submission.id).delete();
            Get.back(); // Tutup dialog loading
            Get.snackbar('Berhasil', "Data isian '$displayIdentifier' berhasil dihapus.",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
            _fetchSubmissions(); // Refresh list
          } catch (e) {
            Get.back(); // Tutup dialog loading
            Get.snackbar('Error', "Gagal menghapus data: ${e.toString()}",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
          }
        }
    );
  }

  Future<void> refreshData() async {
    errorMessage.value = ''; // Selalu reset error message saat refresh
    if (formId.value.isNotEmpty) {
      // Set loading true sebelum await
      isLoadingStructure.value = true;
      isLoadingSubmissions.value = true;
      searchQuery.value = ''; // Kosongkan search query saat refresh

      // Panggil fetch secara berurutan atau paralel jika tidak saling ketergantungan untuk state awal
      await _fetchFormStructure(); // Tunggu struktur form selesai
      await _fetchSubmissions();   // Kemudian fetch submissions (yang akan memanggil _processSubmissionsForDisplay)
    } else {
      _setLoadingError("ID Form tidak valid untuk refresh.");
    }
  }
}