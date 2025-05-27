import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

// Helper class untuk item yang akan ditampilkan di list
class DisplayableSubmission {
  final FormSubmission originalSubmission;
  final String displayTitle; // Misal: "Nama: Budi, NIK: 123" atau "Yanto Subagyoxxx"
  final String sortableNamePart; // Bagian nama untuk sorting (lowercase)
  final String sortableIdPart;   // Bagian NIK/KK untuk sorting (jika ada)

  DisplayableSubmission({
    required this.originalSubmission,
    required this.displayTitle,
    required this.sortableNamePart,
    required this.sortableIdPart,
  });
}

class ListSubmissionFormController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString formId = ''.obs;
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs; // Diubah

  final RxBool isLoadingStructure = true.obs;
  final RxBool isLoadingSubmissions = true.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final RxString currentSortOrder = 'Terbaru'.obs;
  // Opsi sorting bisa disesuaikan jika identifier utama bukan hanya nama
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Identifier A-Z', 'Identifier Z-A'];

  // Prioritas kode pertanyaan untuk identifier utama (nama)
  final List<String> _namePriorityCodes = ['NAMA_LENGKAP', 'NAMA_KEPALA_KELUARGA', 'NAMA_RESPONDEN', 'NAMA'];
  // Prioritas kode pertanyaan untuk identifier sekunder (ID numerik)
  final List<String> _idPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];

  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 500));

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
  }

  Future<void> _fetchFormStructure() async {
    isLoadingStructure.value = true;
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        formStructure.value = FormItem.fromFirestore(docSnapshot);
      } else {
        errorMessage.value = "Detail form tidak ditemukan.";
      }
    } catch (e) {
      print("Error fetching form structure: $e");
      errorMessage.value = "Gagal memuat detail form.";
    } finally {
      isLoadingStructure.value = false;
    }
  }

  Future<void> _fetchSubmissions() async {
    if (formId.value.isEmpty || _auth.currentUser == null) {
      if (_auth.currentUser == null) print("User not logged in.");
      isLoadingSubmissions.value = false;
      _originalSubmissions.clear();
      _processSubmissionsForDisplay();
      return;
    }
    isLoadingSubmissions.value = true;
    try {
      Query query = _db
          .collection('formSubmissions')
          .where('formId', isEqualTo: formId.value)
          .where('userId', isEqualTo: _auth.currentUser!.uid);

      // Default order dari Firestore, sorting lebih lanjut di client jika perlu
      query = query.orderBy('submittedAt', descending: (currentSortOrder.value == 'Terbaru'));

      final querySnapshot = await query.get();
      _originalSubmissions.assignAll(querySnapshot.docs
          .map((doc) => FormSubmission.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList());

      _processSubmissionsForDisplay();

    } catch (e) {
      print("Error fetching submissions: $e");
      errorMessage.value = "Gagal memuat daftar submission: ${e.toString()}"; // Tampilkan error spesifik
      // Get.snackbar('Error', 'Gagal memuat daftar submission: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  String _extractAnswerByPriority(List<QuestionAnswer> answers, List<String> priorityCodes) {
    for (String code in priorityCodes) {
      final answer = answers.firstWhereOrNull((qa) => qa.questionCode.trim().toUpperCase() == code.toUpperCase() && qa.answer != null && qa.answer.toString().trim().isNotEmpty);
      if (answer != null) {
        return answer.answer.toString();
      }
    }
    return '';
  }

  void _processSubmissionsForDisplay() {
    List<DisplayableSubmission> processedList = [];
    for (var sub in _originalSubmissions) {
      String namePart = _extractAnswerByPriority(sub.answers, _namePriorityCodes);
      String idPart = _extractAnswerByPriority(sub.answers, _idPriorityCodes);

      String displayTitle = "";
      if (namePart.isNotEmpty && idPart.isNotEmpty) {
        displayTitle = "$namePart - $idPart";
      } else if (namePart.isNotEmpty) {
        displayTitle = namePart;
      } else if (idPart.isNotEmpty) {
        displayTitle = "ID: $idPart";
      } else {
        // Fallback jika tidak ada NAMA atau NIK/NO_KK
        displayTitle = sub.userName.isNotEmpty ? "Oleh: ${sub.userName}" : "Submission ID: ${sub.id?.substring(0,6) ?? 'N/A'}";
      }

      // Filter berdasarkan searchQuery (case-insensitive)
      if (searchQuery.value.isNotEmpty) {
        if (!displayTitle.toLowerCase().contains(searchQuery.value.toLowerCase())) {
          continue; // Skip jika tidak cocok query
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: displayTitle,
        sortableNamePart: namePart.toLowerCase(),
        sortableIdPart: idPart.toLowerCase(),
      ));
    }

    // Sorting
    if (currentSortOrder.value == 'Identifier A-Z') {
      processedList.sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
    } else if (currentSortOrder.value == 'Identifier Z-A') {
      processedList.sort((a, b) => b.displayTitle.toLowerCase().compareTo(a.displayTitle.toLowerCase()));
    } else if (currentSortOrder.value == 'Terlama') {
      // Jika _fetchSubmissions sudah orderBy submittedAt ascending, ini tidak perlu
      // Jika defaultnya descending, maka kita perlu reverse atau sort ulang
      processedList.sort((a,b) => a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt));
    } else { // Terbaru (default)
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
      _processSubmissionsForDisplay(); // Proses ulang dengan sort order baru
    }
  }

  void goToAddSubmission() {
    if (formId.value.isNotEmpty) {
      Get.toNamed(AppRoutes.INPUT_FORM_USER, arguments: formId.value);
    } else {
      Get.snackbar('Error', 'Tidak bisa membuat data baru, ID Form tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void editSubmission(FormSubmission submission) {
    Get.snackbar('Info', 'Fitur Edit untuk submission ID: ${submission.id} belum diimplementasikan.',
        snackPosition: SnackPosition.BOTTOM);
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
          Get.back();
          Get.dialog(
              const Center(child: CircularProgressIndicator()),
              barrierDismissible: false
          );
          try {
            await _db.collection('formSubmissions').doc(submission.id).delete();
            Get.back();
            Get.snackbar('Berhasil', "Data isian '$displayIdentifier' berhasil dihapus.",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
            _fetchSubmissions(); // Refresh
          } catch (e) {
            Get.back();
            Get.snackbar('Error', "Gagal menghapus data: ${e.toString()}",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
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
      // currentSortOrder.value = 'Terbaru'; // Biarkan sort order tetap
      await Future.wait([
        _fetchFormStructure(),
        _fetchSubmissions(),
      ]);
    } else {
      _setLoadingError("ID Form tidak valid untuk refresh.");
    }
  }
}