// lib/presentation/admin/submissions_form/submissions_form_controller.dart
import 'package:flutter/material.dart'; // Diperlukan untuk debounce
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// FirebaseAuth tidak diperlukan lagi untuk mengambil semua submission
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk FormItem
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart'; // Untuk FormSubmission
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Untuk AppRoutes

// Helper class untuk item yang akan ditampilkan di list
class DisplayableSubmission {
  final FormSubmission originalSubmission;
  final String displayTitle;
  final String sortableNamePart;
  final String sortableIdPart;
  final String namaKepalaKeluarga;
  final String nikKepalaKeluarga;

  DisplayableSubmission({
    required this.originalSubmission,
    required this.displayTitle,
    required this.sortableNamePart,
    required this.sortableIdPart,
    required this.namaKepalaKeluarga,
    required this.nikKepalaKeluarga,
  });
}

class SubmissionsFormController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxString formId = ''.obs; // ID form yang dipilih dari dashboard admin
  final RxString initialFormTitle = ''.obs; // Judul form awal dari argumen
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs;

  final RxBool isLoadingStructure = true.obs;
  final RxBool isLoadingSubmissions = true.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final RxString currentSortOrder = 'Terbaru'.obs;
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Nama KRT A-Z', 'Nama KRT Z-A'];

  // Kode prioritas untuk mencari nama dan NIK, sesuaikan dengan form Anda
  final List<String> _namaKrtPriorityCodes = ['106', 'NAMA_KEPALA_KELUARGA', 'NAMA_KRT'];
  final List<String> _nikKrtPriorityCodes = ['NIK_KRT', 'NIK_KEPALA_KELUARGA', '107'];
  final List<String> _generalNamePriorityCodes = ['NAMA_LENGKAP', 'NAMA_RESPONDEN', 'NAMA'];
  final List<String> _generalIdPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];

  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;

  String get appBarTitle => formStructure.value?.title ?? initialFormTitle.value;


  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 400));

    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      formId.value = Get.arguments['formId'] ?? '';
      initialFormTitle.value = Get.arguments['formTitle'] ?? 'Daftar Submissions'; // Fallback title

      if (formId.value.isNotEmpty) {
        _fetchFormStructure();
        _fetchSubmissions();
      } else {
        _setLoadingError("ID Form tidak valid.");
      }
    } else {
      _setLoadingError("Argumen ID Form dan Judul tidak ditemukan.");
    }
  }

  void _setLoadingError(String message) {
    errorMessage.value = message;
    isLoadingStructure.value = false;
    isLoadingSubmissions.value = false;
    displayedSubmissions.clear();
  }

  Future<void> _fetchFormStructure() async {
    isLoadingStructure.value = true;
    errorMessage.value = '';
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        formStructure.value = FormItem.fromFirestore(docSnapshot);
      } else {
        errorMessage.value = "Detail form tidak ditemukan.";
        formStructure.value = null; // Pastikan null jika tidak ditemukan
      }
    } catch (e) {
      print("Error fetching form structure (Admin): $e");
      errorMessage.value = "Gagal memuat detail form: ${e.toString()}";
      formStructure.value = null; // Pastikan null jika error
    } finally {
      isLoadingStructure.value = false;
      update(); // Untuk update AppBar title jika initialFormTitle digunakan
    }
  }

  Future<void> _fetchSubmissions() async {
    if (formId.value.isEmpty) {
      _setLoadingError("ID Form kosong, tidak bisa fetch submissions.");
      return;
    }
    isLoadingSubmissions.value = true;
    errorMessage.value = '';
    try {
      Query query = _db
          .collection('formSubmissions')
          .where('formId', isEqualTo: formId.value); // Hanya filter berdasarkan formId

      if (currentSortOrder.value == 'Terbaru') {
        query = query.orderBy('submittedAt', descending: true);
      } else if (currentSortOrder.value == 'Terlama') {
        query = query.orderBy('submittedAt', descending: false);
      }

      final querySnapshot = await query.get();
      _originalSubmissions.assignAll(querySnapshot.docs
          .map((doc) => FormSubmission.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList());
      _processSubmissionsForDisplay();
    } catch (e) {
      print("Error fetching submissions (Admin): $e");
      errorMessage.value = "Gagal memuat daftar isian: ${e.toString()}";
      _originalSubmissions.clear();
      _processSubmissionsForDisplay(); // Update UI dengan list kosong
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

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
      String namaKRT = sub.namaKepalaRumahTangga ?? _extractAnswerByPriority(sub.answers, _namaKrtPriorityCodes);
      String nikKRT = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes); // Anda mungkin perlu field NIK_KRT di FormSubmission

      String currentDisplayTitle = "";
      if (namaKRT.isNotEmpty) {
        currentDisplayTitle = namaKRT;
        if (nikKRT.isNotEmpty) currentDisplayTitle += " - NIK: $nikKRT";
      } else if (nikKRT.isNotEmpty) {
        currentDisplayTitle = "NIK: $nikKRT";
      }
      else {
        String generalName = _extractAnswerByPriority(sub.answers, _generalNamePriorityCodes);
        String generalId = _extractAnswerByPriority(sub.answers, _generalIdPriorityCodes);
        if (generalName.isNotEmpty) {
          currentDisplayTitle = generalName;
          if (generalId.isNotEmpty) currentDisplayTitle += " ($generalId)";
        } else if (generalId.isNotEmpty) {
          currentDisplayTitle = "ID: $generalId";
        } else {
          // Fallback ke ID submission jika tidak ada info lain
          currentDisplayTitle = "Submission ID: ${sub.id ?? 'N/A'}";
        }
      }

      if (searchQuery.value.isNotEmpty) {
        bool matchesSearch =
            currentDisplayTitle.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                (namaKRT.isNotEmpty && namaKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (nikKRT.isNotEmpty && nikKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (sub.userId?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false) ;// Tambah pencarian by User ID
        if (!matchesSearch) {
          continue;
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: currentDisplayTitle,
        sortableNamePart: namaKRT.toLowerCase(),
        sortableIdPart: nikKRT.toLowerCase(),
        namaKepalaKeluarga: namaKRT,
        nikKepalaKeluarga: nikKRT,
      ));
    }

    if (currentSortOrder.value == 'Nama KRT A-Z') {
      processedList.sort((a, b) => a.sortableNamePart.compareTo(b.sortableNamePart));
    } else if (currentSortOrder.value == 'Nama KRT Z-A') {
      processedList.sort((a, b) => b.sortableNamePart.compareTo(a.sortableNamePart));
    } else if (currentSortOrder.value == 'Terlama' && !_originalSubmissions.any((s) => s.submittedAt == null)) {
      processedList.sort((a,b) => a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt));
    } else if (currentSortOrder.value == 'Terbaru' && !_originalSubmissions.any((s) => s.submittedAt == null)){
      processedList.sort((a,b) => b.originalSubmission.submittedAt.compareTo(a.originalSubmission.submittedAt));
    }
    displayedSubmissions.assignAll(processedList);
  }

  void changeSearchQuery(String query) {
    searchQuery.value = query;
  }

  void changeSortOrder(String? newOrder) {
    if (newOrder != null && newOrder != currentSortOrder.value) {
      currentSortOrder.value = newOrder;
      if (newOrder == 'Terbaru' || newOrder == 'Terlama') {
        _fetchSubmissions();
      } else {
        _processSubmissionsForDisplay();
      }
    }
  }

  void editSubmission(FormSubmission submission) {
    if (formId.value.isEmpty || submission.id == null || formStructure.value == null) {
      Get.snackbar('Error', 'Tidak bisa mengedit, detail form belum termuat atau ID submission tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // Untuk admin, mungkin rutenya berbeda atau ada parameter tambahan
    // Jika rutenya sama dengan user:
    Get.toNamed(
      AppRoutes.INPUT_FORM_USER, // Asumsi admin juga bisa mengedit via form yang sama
      arguments: {
        'formId': formId.value,
        'submissionId': submission.id,
        'isAdminEdit': true, // Tambahkan flag jika perlu perlakuan khusus di InputUserScreen/Controller
      },
    )?.then((result) {
      if (result == true || result == null) {
        refreshData();
      }
    });
  }

  void deleteSubmission(FormSubmission submission, String displayIdentifier) {
    Get.defaultDialog(
        title: "Konfirmasi Hapus",
        titleStyle: const TextStyle(fontWeight: FontWeight.w600),
        middleText: "Anda yakin ingin menghapus data isian '$displayIdentifier' (User: ${submission.userId ?? 'N/A'})?",
        textConfirm: "Ya, Hapus",
        textCancel: "Batal",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red.shade400,
        cancelTextColor: Colors.grey.shade700,
        onConfirm: () async {
          Get.back();
          Get.dialog(
              const Center(child: CircularProgressIndicator(color: Colors.orange)),
              barrierDismissible: false
          );
          try {
            await _db.collection('formSubmissions').doc(submission.id).delete();
            Get.back();
            Get.snackbar('Berhasil', "Data isian '$displayIdentifier' berhasil dihapus.",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
            _fetchSubmissions();
          } catch (e) {
            Get.back();
            Get.snackbar('Error', "Gagal menghapus data: ${e.toString()}",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
          }
        }
    );
  }

  Future<void> refreshData() async {
    errorMessage.value = '';
    if (formId.value.isNotEmpty) {
      isLoadingStructure.value = true;
      isLoadingSubmissions.value = true;
      searchQuery.value = '';

      await _fetchFormStructure();
      await _fetchSubmissions();
    } else {
      _setLoadingError("ID Form tidak valid untuk refresh.");
    }
  }
}