// lib/presentation/admin/submissions_form/submissions_form_controller.dart
import 'dart:convert'; // Untuk jsonEncode, utf8
import 'dart:io';     // Untuk Platform
import 'dart:typed_data'; // Untuk Uint8List

import 'package:flutter/foundation.dart'; // <<< DIPERBAIKI: Impor untuk kDebugMode
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format nama file dan tanggal
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

// --- Tambahkan Impor untuk Package Ekspor ---
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex; // Alias untuk menghindari konflik nama
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
// --- Akhir Tambahan Impor ---


// Helper class untuk item yang akan ditampilkan di list (tetap sama)
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

  final RxString formId = ''.obs;
  final RxString initialFormTitle = ''.obs;
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs;

  final RxBool isLoadingStructure = true.obs;
  final RxBool isLoadingSubmissions = true.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final RxString currentSortOrder = 'Terbaru'.obs;
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Nama KRT A-Z', 'Nama KRT Z-A'];

  final List<String> _namaKrtPriorityCodes = ['106', 'NAMA_KEPALA_KELUARGA', 'NAMA_KRT'];
  final List<String> _nikKrtPriorityCodes = ['NIK_KRT', 'NIK_KEPALA_KELUARGA', '107'];
  final List<String> _generalNamePriorityCodes = ['NAMA_LENGKAP', 'NAMA_RESPONDEN', 'NAMA'];
  final List<String> _generalIdPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];

  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;
  String get appBarTitle => formStructure.value?.title ?? initialFormTitle.value;

  final RxBool isExporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 400));

    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      formId.value = Get.arguments['formId'] ?? '';
      initialFormTitle.value = Get.arguments['formTitle'] ?? 'Daftar Submissions';

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
        errorMessage.value = "Struktur form tidak ditemukan.";
        formStructure.value = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching form structure (Admin): $e");
      }
      errorMessage.value = "Gagal memuat struktur form: ${e.toString()}";
      formStructure.value = null;
    } finally {
      isLoadingStructure.value = false;
      update();
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
          .where('formId', isEqualTo: formId.value);

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
      if (kDebugMode) {
        print("Error fetching submissions (Admin): $e");
      }
      errorMessage.value = "Gagal memuat daftar isian: ${e.toString()}";
      _originalSubmissions.clear();
      _processSubmissionsForDisplay();
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
      String namaKRT = sub.namaKepalaRumahTangga?.isNotEmpty == true
          ? sub.namaKepalaRumahTangga!
          : _extractAnswerByPriority(sub.answers, _namaKrtPriorityCodes);

      String nikKRT = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes);
      String displayNikKRT = (nikKRT.isNotEmpty && nikKRT != "1") ? nikKRT : "";

      String currentDisplayTitle = "";
      if (namaKRT.isNotEmpty) {
        currentDisplayTitle = namaKRT;
        if (displayNikKRT.isNotEmpty) {
          currentDisplayTitle += " - $displayNikKRT";
        }
      } else if (displayNikKRT.isNotEmpty) {
        currentDisplayTitle = "NIK: $displayNikKRT";
      } else {
        String generalName = _extractAnswerByPriority(sub.answers, _generalNamePriorityCodes);
        String generalId = _extractAnswerByPriority(sub.answers, _generalIdPriorityCodes);
        String displayGeneralId = (generalId.isNotEmpty && generalId != "1") ? generalId : "";

        if (generalName.isNotEmpty) {
          currentDisplayTitle = generalName;
          if (displayGeneralId.isNotEmpty) currentDisplayTitle += " ($displayGeneralId)";
        } else if (displayGeneralId.isNotEmpty) {
          currentDisplayTitle = "ID: $displayGeneralId";
        } else {
          currentDisplayTitle = "Data ${sub.formTitle}";
        }
      }

      if (searchQuery.value.isNotEmpty) {
        bool matchesSearch =
            currentDisplayTitle.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                (namaKRT.isNotEmpty && namaKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (displayNikKRT.isNotEmpty && displayNikKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (sub.userName.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (sub.userId?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false);
        if (!matchesSearch) {
          continue;
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: currentDisplayTitle,
        sortableNamePart: namaKRT.toLowerCase(),
        sortableIdPart: displayNikKRT.toLowerCase(),
        namaKepalaKeluarga: namaKRT,
        nikKepalaKeluarga: displayNikKRT,
      ));
    }

    if (currentSortOrder.value == 'Nama KRT A-Z') {
      processedList.sort((a, b) => a.sortableNamePart.compareTo(b.sortableNamePart));
    } else if (currentSortOrder.value == 'Nama KRT Z-A') {
      processedList.sort((a, b) => b.sortableNamePart.compareTo(a.sortableNamePart));
    } else if (currentSortOrder.value == 'Terlama' && _originalSubmissions.any((s) => s.submittedAt != null)) {
      processedList.sort((a,b) {
        if (a.originalSubmission.submittedAt == null && b.originalSubmission.submittedAt == null) return 0;
        if (a.originalSubmission.submittedAt == null) return 1; // nulls last
        if (b.originalSubmission.submittedAt == null) return -1; // nulls last
        return a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt);
      });
    } else if (currentSortOrder.value == 'Terbaru' && _originalSubmissions.any((s) => s.submittedAt != null)){
      processedList.sort((a,b) {
        if (a.originalSubmission.submittedAt == null && b.originalSubmission.submittedAt == null) return 0;
        if (a.originalSubmission.submittedAt == null) return 1; // nulls last
        if (b.originalSubmission.submittedAt == null) return -1; // nulls last
        return b.originalSubmission.submittedAt.compareTo(a.originalSubmission.submittedAt);
      });
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
        _fetchSubmissions(); // Re-fetch to apply server-side sorting for time-based orders
      } else {
        _processSubmissionsForDisplay(); // Client-side sort for name-based orders
      }
    }
  }

  void editSubmission(FormSubmission submission) {
    if (formId.value.isEmpty || submission.id == null || formStructure.value == null) {
      Get.snackbar('Error', 'Tidak bisa mengedit, detail form belum termuat atau ID submission tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.toNamed(
      AppRoutes.INPUT_FORM_USER,
      arguments: {
        'formId': formId.value,
        'submissionId': submission.id,
        'isAdminEdit': true,
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
        middleText: "Anda yakin ingin menghapus data isian '$displayIdentifier' (User: ${submission.userName})?",
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
            Get.back(); // close progress dialog
            Get.snackbar('Berhasil', "Data isian '$displayIdentifier' berhasil dihapus.",
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
            _fetchSubmissions(); // Refresh list
          } catch (e) {
            Get.back(); // close progress dialog
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
      // searchQuery.value = ''; // Consider if search query should be reset on refresh
      await _fetchFormStructure(); // Fetch structure first
      await _fetchSubmissions(); // Then fetch submissions
    } else {
      _setLoadingError("ID Form tidak valid untuk refresh.");
    }
  }

  // --- METHOD HELPER UNTUK EKSPOR ---
  Future<bool> _checkAndRequestFilePermissions() async {
    PermissionStatus status;
    bool isPermanentlyDenied = false; // Deklarasikan di luar scope if

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo; // Variabel ini sekarang lokal di scope if
      if (androidInfo.version.sdkInt >= 30) { // Android 11 (API 30) dan lebih tinggi
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
      } else { // Android 10 (API 29) dan lebih rendah
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }
      // Tentukan isPermanentlyDenied di dalam scope Platform.isAndroid setelah status didapatkan
      isPermanentlyDenied = status.isPermanentlyDenied ||
          (androidInfo.version.sdkInt >=30 && status.isDenied && !(await Permission.manageExternalStorage.status.isGranted));

    } else { // Untuk iOS atau platform lain, anggap izin ada atau akan ditangani OS
      return true;
    }

    if (status.isGranted) {
      return true;
    } else {
      String message = 'Izin penyimpanan diperlukan untuk ekspor data.';
      if (isPermanentlyDenied) { // Gunakan variabel isPermanentlyDenied yang sudah di-assign
        message = 'Izin penyimpanan ditolak permanen. Aktifkan di pengaturan aplikasi.';
      }
      Get.snackbar(
        'Izin Ditolak',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        mainButton: isPermanentlyDenied ? TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.white)),
        ) : null,
      );
      return false;
    }
  }

  dynamic _convertValueForExport(dynamic item) {
    if (item is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.toDate().toLocal());
    } else if (item is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.toLocal());
    } else if (item is GeoPoint) {
      return "Lat: ${item.latitude}, Lon: ${item.longitude}";
    } else if (item is List) {
      return item.join('; ');
    } else if (item is Map) {
      try {
        return jsonEncode(item);
      } catch (_) {
        return item.toString();
      }
    }
    return item?.toString() ?? '';
  }

  List<Map<String, dynamic>> _prepareDataForNestedJsonExport() {
    if (_originalSubmissions.isEmpty) return [];

    return _originalSubmissions.map((submission) {
      Map<String, dynamic> questionAnswersMap = {};
      for (var answer in submission.answers) {
        String key = answer.questionCode.isNotEmpty ? answer.questionCode : answer.questionId;
        questionAnswersMap[key] = _convertValueForExport(answer.answer);
      }

      return {
        'submission_id': submission.id,
        'form_id': submission.formId,
        'form_title': submission.formTitle,
        'user_id_pengisi': submission.userId,
        'nama_pengisi': submission.userName,
        'submitted_at': _convertValueForExport(submission.submittedAt),
        'updated_at': submission.updatedAt != null ? _convertValueForExport(submission.updatedAt) : null,
        'location': submission.location != null ? _convertValueForExport(submission.location) : null,
        'responses': questionAnswersMap,
      };
    }).toList();
  }

  ({List<Map<String, dynamic>> data, List<String> headers}) _prepareDataForExport() {
    final defaultHeadersOnError = [
      'Submission_ID', 'Form_ID', 'Form_Judul', 'User_ID_Pengisi', 'Nama_Pengisi',
      'Waktu_Pengisian', 'Waktu_Update', 'Lokasi'
    ];
    if (_originalSubmissions.isEmpty) {
      return (data: [], headers: defaultHeadersOnError);
    }

    Map<String, String> questionCodeToHeaderTextMap = {};
    Set<String> allUniqueQuestionCodes = <String>{};

    if (formStructure.value != null) {
      for (var section in formStructure.value!.sections) {
        for (var question in section.questions) {
          String code = question.code?.isNotEmpty == true ? question.code! : question.id;
          if (code.isNotEmpty) {
            allUniqueQuestionCodes.add(code);
            questionCodeToHeaderTextMap[code] = question.questionText.isNotEmpty ? question.questionText : code;
          }
        }
      }
    }

    for (var submission in _originalSubmissions) {
      for (var answer in submission.answers) {
        String code = answer.questionCode.isNotEmpty ? answer.questionCode : answer.questionId;
        if (code.isNotEmpty) {
          allUniqueQuestionCodes.add(code);
          if (!questionCodeToHeaderTextMap.containsKey(code) ||
              (questionCodeToHeaderTextMap[code] == code && answer.questionText.isNotEmpty)) {
            questionCodeToHeaderTextMap[code] = answer.questionText.isNotEmpty ? answer.questionText : code;
          }
        }
      }
    }
    List<String> sortedUniqueQuestionCodes = allUniqueQuestionCodes.toList()..sort();

    List<String> finalHeaders = [
      'Submission_ID', 'Form_ID', 'Form_Judul', 'User_ID_Pengisi', 'Nama_Pengisi', 'Waktu_Pengisian',
    ];

    bool hasUpdatedAtColumn = _originalSubmissions.any((s) => s.updatedAt != null);
    bool hasLocationColumn = _originalSubmissions.any((s) => s.location != null);

    if (hasUpdatedAtColumn) finalHeaders.add('Waktu_Update');
    if (hasLocationColumn) finalHeaders.add('Lokasi');

    for (String questionCode in sortedUniqueQuestionCodes) {
      finalHeaders.add(questionCodeToHeaderTextMap[questionCode] ?? questionCode);
    }

    List<Map<String, dynamic>> processedData = _originalSubmissions.map((submission) {
      Map<String, dynamic> rowData = {};
      rowData['Submission_ID'] = submission.id ?? 'N/A';
      rowData['Form_ID'] = submission.formId;
      rowData['Form_Judul'] = submission.formTitle;
      rowData['User_ID_Pengisi'] = submission.userId ?? '';
      rowData['Nama_Pengisi'] = submission.userName ?? '';
      rowData['Waktu_Pengisian'] = _convertValueForExport(submission.submittedAt);

      if (hasUpdatedAtColumn) {
        rowData['Waktu_Update'] = submission.updatedAt != null ? _convertValueForExport(submission.updatedAt) : '';
      }
      if (hasLocationColumn) {
        rowData['Lokasi'] = submission.location != null ? _convertValueForExport(submission.location) : '';
      }

      Map<String, dynamic> answerMap = {};
      for (var answer in submission.answers) {
        String key = answer.questionCode.isNotEmpty ? answer.questionCode : answer.questionId;
        if (key.isNotEmpty) {
          answerMap[key] = _convertValueForExport(answer.answer);
        }
      }

      for (String questionCode in sortedUniqueQuestionCodes) {
        String headerText = questionCodeToHeaderTextMap[questionCode] ?? questionCode;
        rowData[headerText] = answerMap[questionCode] ?? '';
      }
      return rowData;
    }).toList();

    return (data: processedData, headers: finalHeaders);
  }

  Future<void> exportSubmissionsAsJson() async {
    if (isExporting.value) return;
    isExporting.value = true;
    Get.snackbar('Export JSON', 'Mempersiapkan data...', showProgressIndicator: true, duration: const Duration(seconds: 120), dismissDirection: DismissDirection.horizontal, backgroundColor: Colors.blue.shade600, colorText: Colors.white);

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final List<Map<String, dynamic>> dataToExport = _prepareDataForNestedJsonExport();

    if (dataToExport.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      Get.snackbar('Info', 'Tidak ada data untuk diekspor.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      String jsonString = const JsonEncoder.withIndent('  ').convert(dataToExport);
      final List<int> fileBytes = utf8.encode(jsonString);
      Get.closeCurrentSnackbar();

      String defaultFileName = 'export_json_${formStructure.value?.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '') ?? formId.value}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data JSON Sebagai...',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile != null) {
        Get.snackbar('Berhasil', 'Data JSON berhasil diekspor.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        Get.snackbar('Dibatalkan', 'Ekspor JSON dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      Get.snackbar('Error', 'Gagal mengekspor JSON: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      if (kDebugMode) {
        print('JSON Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportSubmissionsAsCsv() async {
    if (isExporting.value) return;
    isExporting.value = true;
    Get.snackbar('Export CSV', 'Mempersiapkan data...', showProgressIndicator: true, duration: const Duration(seconds: 120), dismissDirection: DismissDirection.horizontal, backgroundColor: Colors.blue.shade600, colorText: Colors.white);

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final result = _prepareDataForExport();
    final List<Map<String, dynamic>> flatData = result.data;
    final List<String> headers = result.headers;

    if (flatData.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      Get.snackbar('Info', 'Tidak ada data untuk diekspor.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (headers.isEmpty && flatData.isNotEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      Get.snackbar('Error', 'Tidak dapat menentukan header untuk CSV.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      List<List<dynamic>> csvData = [headers];
      for (var rowMap in flatData) {
        List<dynamic> row = headers.map((header) => rowMap[header] ?? '').toList();
        csvData.add(row);
      }

      String csvString = const ListToCsvConverter().convert(csvData);
      final List<int> fileBytes = utf8.encode(csvString);
      Get.closeCurrentSnackbar();

      String defaultFileName = 'export_csv_${formStructure.value?.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '') ?? formId.value}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data CSV Sebagai...',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile != null) {
        Get.snackbar('Berhasil', 'Data CSV berhasil diekspor.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        Get.snackbar('Dibatalkan', 'Ekspor CSV dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      Get.snackbar('Error', 'Gagal mengekspor CSV: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      if (kDebugMode) {
        print('CSV Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportSubmissionsAsXlsx() async {
    if (isExporting.value) return;
    isExporting.value = true;
    Get.snackbar('Export XLSX', 'Mempersiapkan data...', showProgressIndicator: true, duration: const Duration(seconds: 120), dismissDirection: DismissDirection.horizontal, backgroundColor: Colors.blue.shade600, colorText: Colors.white);

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final result = _prepareDataForExport();
    final List<Map<String, dynamic>> flatData = result.data;
    final List<String> headers = result.headers;

    if (flatData.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      Get.snackbar('Info', 'Tidak ada data untuk diekspor.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (headers.isEmpty && flatData.isNotEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      Get.snackbar('Error', 'Tidak dapat menentukan header untuk XLSX.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      var excel = ex.Excel.createExcel();
      String sheetNameInput = formStructure.value?.title ?? 'Data Export';
      String sanitizedSheetName = sheetNameInput.replaceAll(RegExp(r'[\\/*?:[\]]'), ''); // Karakter invalid Excel
      sanitizedSheetName = sanitizedSheetName.replaceAll(RegExp(r"'"), ''); // Hapus juga single quote
      if (sanitizedSheetName.length > 31) {
        sanitizedSheetName = sanitizedSheetName.substring(0, 31);
      }
      if (sanitizedSheetName.isEmpty) {
        sanitizedSheetName = 'DataExport';
      }
      ex.Sheet sheetObject = excel[sanitizedSheetName];


      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = ex.TextCellValue(headers[i]);
        // <<< DIPERBAIKI: Gunakan nilai hex string langsung untuk warna latar belakang
      }

      for (int rowIndex = 0; rowIndex < flatData.length; rowIndex++) {
        Map<String, dynamic> rowMap = flatData[rowIndex];
        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          var cell = sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
          dynamic value = rowMap[headers[colIndex]];

          if (value is num) {
            cell.value = ex.DoubleCellValue(value.toDouble());
          } else if (value is bool) {
            cell.value = ex.BoolCellValue(value);
          } else if (value is DateTime) {
            cell.value = ex.DateTimeCellValue.fromDateTime(value.toUtc());
          } else if (value is String) {
            double? numValue = double.tryParse(value);
            DateTime? dateValue;
            bool looksLikeNumericId = RegExp(r'^\d{10,}$').hasMatch(value);
            bool looksLikeDateOrTimeSeparator = value.contains(':') || value.contains('/') || value.contains('-');

            if (numValue != null && !looksLikeNumericId && !looksLikeDateOrTimeSeparator) {
              cell.value = ex.DoubleCellValue(numValue);
            } else {
              try {
                if (value.length == 19 && value[10] == ' ' && value[4] == '-' && value[7] == '-') {
                  dateValue = DateFormat('yyyy-MM-dd HH:mm:ss', 'id_ID').parseStrict(value, true).toUtc();
                }
              } catch (_) { /* ignore parse error */ }

              if (dateValue != null) {
                cell.value = ex.DateTimeCellValue.fromDateTime(dateValue);
              } else {
                cell.value = ex.TextCellValue(value);
              }
            }
          } else {
            cell.value = ex.TextCellValue(value?.toString() ?? '');
          }
        }
      }

      // <<< DIPERBAIKI: Hapus parameter includeMaxRowsAndCols jika tidak ada
      List<int>? fileBytes = excel.save();
      Get.closeCurrentSnackbar();

      if (fileBytes == null || fileBytes.isEmpty) {
        isExporting.value = false;
        Get.snackbar('Error', 'Gagal menghasilkan file XLSX.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      String defaultFileName = 'export_xlsx_${formStructure.value?.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '') ?? formId.value}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data XLSX Sebagai...',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile != null) {
        Get.snackbar('Berhasil', 'Data XLSX berhasil diekspor.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        Get.snackbar('Dibatalkan', 'Ekspor XLSX dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      Get.snackbar('Error', 'Gagal mengekspor XLSX: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      if (kDebugMode) { // Pastikan kDebugMode dari flutter/foundation.dart
        print('XLSX Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }
}