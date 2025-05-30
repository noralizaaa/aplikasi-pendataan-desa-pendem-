import 'dart:io';
import 'dart:convert'; // Untuk jsonEncode dan utf8
import 'dart:typed_data'; // Untuk Uint8List

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarFormat, CalendarStyle, HeaderStyle, RangeSelectionMode, TableCalendar, isSameDay;
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';

// Package for CSV (add to pubspec.yaml if not already)
// import 'package:csv/csv.dart';
// Package for Excel (add to pubspec.yaml if not already)
// import 'package:excel/excel.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (semua properti Rx Anda tetap sama) ...
  final RxString adminName = 'Admin'.obs;
  final RxInt selectedPageIndex = 0.obs;
  final RxString globalSearchQuery = ''.obs;

  final RxBool isDashboardLoading = true.obs;
  final RxInt totalSubmissions = 0.obs;

  final RxList<Map<String, dynamic>> _allFormEntriesWithSubmissions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormSubmissions = <Map<String, dynamic>>[].obs;

  final RxMap<String, int> _fullSubmissionTrend = <String, int>{}.obs;
  final RxMap<String, int> submissionTrend = <String, int>{}.obs;

  final RxList<Map<String, dynamic>> _allFormAccessCounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormAccessCounts = <Map<String, dynamic>>[].obs;

  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  final Rx<DateTime> focusedCalendarDay = DateTime.now().obs;
  final Rx<DateTime?> calendarRangeStart = Rx<DateTime?>(null);
  final Rx<DateTime?> calendarRangeEnd = Rx<DateTime?>(null);
  final Rx<RangeSelectionMode> calendarRangeSelectionMode = RangeSelectionMode.toggledOn.obs;

  static const String _usersCollectionPath = 'users';
  static const String _adminFormsCollectionPath = 'adminForms';
  static const String _formSubmissionsCollectionPath = 'formSubmissions';


  @override
  void onInit() {
    super.onInit();
    _fetchAdminName();
    fetchDashboardData();

    ever(selectedStartDate, (_) => _applyDashboardFilter());
    ever(selectedEndDate, (_) => _applyDashboardFilter());
    ever(globalSearchQuery, (_) => _applyDashboardFilter());
  }

  // --- Metode Helper untuk Izin ---
  Future<bool> _checkAndRequestFilePermissions() async {
    PermissionStatus status;
    AndroidDeviceInfo? androidInfo;
    int sdkInt = 0;

    if (Platform.isAndroid) {
      androidInfo = await DeviceInfoPlugin().androidInfo;
      sdkInt = androidInfo.version.sdkInt;
      debugPrint('Versi SDK Android: $sdkInt');
    } else {
      return true; // Anggap OK untuk platform lain
    }

    if (sdkInt >= 30) {
      debugPrint('Memeriksa izin MANAGE_EXTERNAL_STORAGE untuk Android 11+');
      status = await Permission.manageExternalStorage.status;
      debugPrint('Status MANAGE_EXTERNAL_STORAGE awal: $status');
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        debugPrint('Status MANAGE_EXTERNAL_STORAGE setelah request: $status');
      }
    } else {
      debugPrint('Memeriksa izin STORAGE untuk Android < 11');
      status = await Permission.storage.status;
      debugPrint('Status STORAGE awal: $status');
      if (!status.isGranted) {
        status = await Permission.storage.request();
        debugPrint('Status STORAGE setelah request: $status');
      }
    }

    if (status.isGranted) {
      debugPrint('Izin yang relevan diberikan.');
      return true;
    } else {
      // Penanganan UI jika ditolak (Snackbar)
      String message = 'Izin penyimpanan diperlukan untuk melanjutkan.';
      if (status.isPermanentlyDenied) {
        message = 'Izin penyimpanan ditolak permanen. Aktifkan di pengaturan aplikasi.';
      } else if (sdkInt >= 30 && status.isDenied) {
        message = 'Izin pengelolaan penyimpanan ditolak. Anda mungkin perlu mengaktifkannya secara manual di pengaturan aplikasi.';
      }

      Get.snackbar(
        'Izin Ditolak',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        mainButton: status.isPermanentlyDenied || (sdkInt >= 30 && status.isDenied) ? TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.white)),
        ) : null,
      );
      debugPrint('Izin ditolak (status: $status).');
      return false;
    }
  }

  // Helper function to recursively convert non-serializable items for JSON
  dynamic _convertToJsonSafe(dynamic item) {
    if (item is Timestamp) {
      return item.toDate().toIso8601String();
    } else if (item is DateTime) {
      return item.toIso8601String(); // Koreksi: toIso8601String()
    } else if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), _convertToJsonSafe(value)));
    } else if (item is List) {
      return item.map((element) => _convertToJsonSafe(element)).toList();
    }
    return item;
  }

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
  }

  void updateGlobalSearchQuery(String query) {
    globalSearchQuery.value = query;
  }

  void clearGlobalSearchQuery() {
    globalSearchQuery.value = '';
  }

  Future<void> _fetchAdminName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _db.collection(_usersCollectionPath).doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          adminName.value = (userDoc.data() as Map<String, dynamic>)['username'] as String? ?? user.displayName ?? 'Admin';
        } else {
          adminName.value = user.displayName ?? 'Admin';
        }
      } catch (e) {
        debugPrint("Error fetching admin name: $e");
        adminName.value = user.displayName ?? "Admin";
      }
    }
  }

  Future<void> fetchDashboardData() async {
    isDashboardLoading.value = true;
    try {
      await Future.wait([
        _fetchAllSubmissionsAndGroupThem(),
        _fetchFormAccessCountsMaster(),
      ]);
      _applyDashboardFilter(); // Pastikan ini dipanggil setelah data selesai di-load
    } catch (e) {
      Get.snackbar('Error Dashboard', 'Gagal memuat data dashboard: ${e.toString()}',
          backgroundColor: Colors.red.shade400, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      debugPrint('Dashboard data fetch error: $e');
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> _fetchAllSubmissionsAndGroupThem() async {
    Map<String, List<Map<String, dynamic>>> submissionsByFormId = {};
    Map<String, String> formTitles = {}; // formId -> formTitle dari adminForms
    Map<String, int> dailyHouseholdCounts = {}; // Khusus untuk tren 'dc-penduduk'

    // 1. Ambil semua metadata form (judul) dari adminForms
    QuerySnapshot formsMetaSnapshot = await _db.collection(_adminFormsCollectionPath).get();
    for (var formDoc in formsMetaSnapshot.docs) {
      formTitles[formDoc.id] = (formDoc.data() as Map<String,dynamic>)['title'] as String? ?? 'Form Tanpa Judul';
    }

    // 2. Ambil semua submissions
    QuerySnapshot allSubmissionsSnapshot = await _db.collection(_formSubmissionsCollectionPath).get();
    for (var submissionDoc in allSubmissionsSnapshot.docs) {
      var data = submissionDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        String formId = data['formId'] as String? ?? '';
        // Gunakan judul dari 'adminForms' jika ada, jika tidak fallback ke judul di submission (jika ada)
        String actualFormTitle = formTitles[formId] ?? data['formTitle'] as String? ?? 'Form Tidak Dikenal';

        if (formId.isNotEmpty) {
          submissionsByFormId.putIfAbsent(formId, () => []).add({
            'id': submissionDoc.id,
            'submittedAt': data['submittedAt'] as Timestamp?,
            'userId': data['userId'],
            'userName': data['userName'],
            'formId': formId, // Sertakan formId untuk referensi
            'formTitle': actualFormTitle, // Gunakan judul yang sudah ditentukan
            'answers': data['answers'],
          });
        }

        // Hitung tren harian hanya untuk form 'dc-penduduk' berdasarkan judul yang sudah ditentukan
        if (actualFormTitle.toLowerCase().contains('dc-penduduk') &&
            data.containsKey('submittedAt') && data['submittedAt'] is Timestamp) {
          Timestamp submittedAtTimestamp = data['submittedAt'];
          DateTime date = submittedAtTimestamp.toDate().toLocal();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          dailyHouseholdCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    // 3. Bentuk _allFormEntriesWithSubmissions
    List<Map<String, dynamic>> tempFormEntries = [];
    formTitles.forEach((formId, title) { // Iterasi berdasarkan form yang ada di adminForms
      List<Map<String, dynamic>> submissionsForThisForm = submissionsByFormId[formId] ?? [];
      tempFormEntries.add({
        'formId': formId,
        'formTitle': title,
        'count': submissionsForThisForm.length, // Jumlah total submission untuk form ini
        'submissions': submissionsForThisForm, // Semua detail submission untuk form ini
      });
    });

    // Jika ada submission yang formId-nya tidak ada di adminForms (kasus data inkonsisten)
    // Anda bisa memilih untuk menambahkannya juga atau mengabaikannya.
    // Untuk saat ini, kita hanya proses yang formId-nya dikenal dari adminForms.

    _allFormEntriesWithSubmissions.assignAll(tempFormEntries);

    var sortedKeys = dailyHouseholdCounts.keys.toList()..sort();
    final sortedDailyCounts = { for (var k in sortedKeys) k: dailyHouseholdCounts[k]! };
    _fullSubmissionTrend.assignAll(sortedDailyCounts); // Ini tren untuk 'dc-penduduk'
  }

  Future<void> _fetchFormAccessCountsMaster() async {
    List<Map<String, dynamic>> tempFormAccessCounts = [];
    try {
      QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();
      for (var formDoc in formsSnapshot.docs) {
        QuerySnapshot accessSnapshot = await _db.collection(_adminFormsCollectionPath)
            .doc(formDoc.id)
            .collection('managedAccounts')
            .get();
        tempFormAccessCounts.add({
          'formId': formDoc.id,
          'formTitle': (formDoc.data() as Map<String,dynamic>)['title'] as String? ?? 'Untitled Form',
          'accessCount': accessSnapshot.docs.length,
        });
      }
      _allFormAccessCounts.assignAll(tempFormAccessCounts);
    } catch(e) {
      debugPrint("Error fetching form access counts: $e");
    }
  }

  Future<void> pickDateRangeWithDefaultDialog(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days:1)), // Batas maksimal tanggal adalah hari ini + 1
      initialDateRange: selectedStartDate.value != null && selectedEndDate.value != null
          ? DateTimeRange(start: selectedStartDate.value!, end: selectedEndDate.value!)
          : null,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      // saveText: 'Simpan', // saveText tidak umum di showDateRangePicker standar
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AdminScreen.accentHeaderColor, // Warna utama
              onPrimary: Colors.white, // Warna teks di atas warna utama
              onSurface: Colors.black87, // Warna teks umum
              surface: Colors.white, // Warna permukaan dialog
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AdminScreen.accentHeaderColor), // Warna tombol teks
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedStartDate.value = picked.start;
      // Pastikan endDate mencakup keseluruhan hari
      selectedEndDate.value = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);

      // Update juga state untuk custom picker jika digunakan bergantian
      calendarRangeStart.value = selectedStartDate.value;
      calendarRangeEnd.value = selectedEndDate.value;
      if (selectedStartDate.value != null) {
        focusedCalendarDay.value = selectedStartDate.value!;
      }
    }
  }

  Future<void> openCustomDateRangePicker(BuildContext context) async {
    final result = await Get.dialog<Map<String, DateTime?>>(
      _CustomDateRangePickerDialog(
        initialFocusedDay: focusedCalendarDay.value,
        initialRangeStart: calendarRangeStart.value,
        initialRangeEnd: calendarRangeEnd.value,
      ),
      barrierDismissible: true,
    );

    if (result != null) {
      selectedStartDate.value = result['start'];
      if (result['end'] != null) {
        DateTime end = result['end']!;
        selectedEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      } else {
        // Jika hanya start date yang dipilih dari custom picker, set end date sama dengan start date
        selectedEndDate.value = result['start'] != null
            ? DateTime(result['start']!.year, result['start']!.month, result['start']!.day, 23, 59, 59, 999)
            : null;
      }

      calendarRangeStart.value = result['start'];
      calendarRangeEnd.value = result['end'] ?? result['start']; // Jika end null, samakan dengan start

      if (result['focused'] != null) {
        focusedCalendarDay.value = result['focused']!;
      } else if (result['start'] != null) {
        focusedCalendarDay.value = result['start']!;
      }
    }
  }

  void resetDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    calendarRangeStart.value = null;
    calendarRangeEnd.value = null;
    focusedCalendarDay.value = DateTime.now();
    // _applyDashboardFilter(); // Ini akan dipanggil oleh `ever`
  }

  void onCalendarRangeSelected(DateTime? start, DateTime? end, DateTime newFocusedDay) {
    calendarRangeStart.value = start;
    calendarRangeEnd.value = end;
    focusedCalendarDay.value = newFocusedDay;

    // Update filter utama juga
    selectedStartDate.value = start;
    if (end != null) {
      selectedEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    } else {
      // Jika hanya start yang dipilih (end is null), maka filter end disamakan dengan start
      selectedEndDate.value = start != null
          ? DateTime(start.year, start.month, start.day, 23, 59, 59, 999)
          : null;
    }
  }

  // Dipanggil ketika satu hari dipilih di kalender (jika range mode off atau untuk logika khusus)
  void onCalendarDaySelected(DateTime selectedDay, DateTime newFocusedDay) {
    focusedCalendarDay.value = newFocusedDay;
    // Set range start dan end ke hari yang sama
    calendarRangeStart.value = selectedDay;
    calendarRangeEnd.value = selectedDay;

    // Update filter utama
    selectedStartDate.value = selectedDay;
    selectedEndDate.value = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 23, 59, 59, 999);
  }

  void onCalendarPageChanged(DateTime newFocusedDay) {
    focusedCalendarDay.value = newFocusedDay;
  }

  void _applyDashboardFilter() {
    final bool isDateFilterActive = selectedStartDate.value != null && selectedEndDate.value != null;
    final DateTime? filterStartDate = selectedStartDate.value;
    // Pastikan filterEndDate mencakup keseluruhan hari terakhir
    final DateTime? filterEndDate = selectedEndDate.value;
    final String query = globalSearchQuery.value.toLowerCase().trim();

    debugPrint("_applyDashboardFilter: DateFilterActive=$isDateFilterActive, Start=${filterStartDate?.toIso8601String()}, End=${filterEndDate?.toIso8601String()}, Query='$query'");

    List<Map<String, dynamic>> tempFilteredSubmissionsSummary = [];
    int dcPendudukSubmissionsInPeriod = 0;

    for (var formEntry in _allFormEntriesWithSubmissions) {
      String formTitle = (formEntry['formTitle'] as String? ?? '').toLowerCase();
      bool matchesSearch = query.isEmpty || formTitle.contains(query);

      if (!matchesSearch) continue;

      List<Map<String, dynamic>> submissionsForThisForm = List<Map<String, dynamic>>.from(formEntry['submissions'] ?? []);
      int countInPeriod = 0;

      if (isDateFilterActive) {
        for (var submissionData in submissionsForThisForm) {
          if (submissionData.containsKey('submittedAt') && submissionData['submittedAt'] is Timestamp) {
            Timestamp submittedAtTimestamp = submissionData['submittedAt'];
            DateTime submissionDate = submittedAtTimestamp.toDate().toLocal();
            // Pengecekan rentang tanggal yang lebih tepat
            if (!submissionDate.isBefore(filterStartDate!) && !submissionDate.isAfter(filterEndDate!)) {
              countInPeriod++;
            }
          }
        }
      } else {
        // Jika tidak ada filter tanggal, countInPeriod adalah total submission untuk form tersebut
        countInPeriod = submissionsForThisForm.length;
      }

      // Jika form adalah 'dc-penduduk', simpan hitungannya untuk totalSubmissions.value
      if (formTitle.contains('dc-penduduk')) {
        dcPendudukSubmissionsInPeriod = countInPeriod;
      }

      // Selalu tampilkan semua form yang cocok dengan search query, meskipun countInPeriod 0
      // Kecuali jika Anda ingin menyembunyikan form yang tidak ada submissionnya dalam periode/query
      tempFilteredSubmissionsSummary.add({
        'formId': formEntry['formId'],
        'formTitle': formEntry['formTitle'], // Gunakan judul asli dari _allFormEntriesWithSubmissions
        'count': countInPeriod, // Jumlah submission dalam periode filter
      });
    }

    filteredFormSubmissions.assignAll(tempFilteredSubmissionsSummary);
    totalSubmissions.value = dcPendudukSubmissionsInPeriod; // Ini khusus untuk 'dc-penduduk'

    // Filter tren submission (yang diasumsikan untuk 'dc-penduduk')
    _filterSubmissionTrendByDate(filterStartDate, filterEndDate);

    // Filter Form Access Counts berdasarkan query
    List<Map<String, dynamic>> tempFilteredAccessCounts = [];
    if (query.isEmpty) {
      tempFilteredAccessCounts.addAll(_allFormAccessCounts);
    } else {
      for (var accessEntry in _allFormAccessCounts) {
        String formTitle = (accessEntry['formTitle'] as String? ?? '').toLowerCase();
        if (formTitle.contains(query)) {
          tempFilteredAccessCounts.add(accessEntry);
        }
      }
    }
    filteredFormAccessCounts.assignAll(tempFilteredAccessCounts);

    debugPrint("Filtered Submissions Summary Count: ${filteredFormSubmissions.length}, Total DC-Penduduk in period: $dcPendudukSubmissionsInPeriod");
    debugPrint("Submission Trend Keys (DC-Penduduk): ${submissionTrend.keys.length}");
  }

  void _filterSubmissionTrendByDate(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      submissionTrend.assignAll(_fullSubmissionTrend); // Tampilkan semua jika tidak ada filter tanggal
      return;
    }
    Map<String, int> filteredDailyCounts = {};
    _fullSubmissionTrend.forEach((dateString, count) {
      try {
        DateTime trendDate = DateFormat('yyyy-MM-dd').parse(dateString);
        // Pengecekan rentang tanggal yang lebih tepat
        if (!trendDate.isBefore(startDate) && !trendDate.isAfter(endDate)) {
          filteredDailyCounts[dateString] = count;
        }
      } catch (e) {
        debugPrint("Error parsing trend date: $dateString, error: $e");
      }
    });
    var sortedKeys = filteredDailyCounts.keys.toList()..sort();
    final sortedFilteredCounts = { for (var k in sortedKeys) k: filteredDailyCounts[k]! };
    submissionTrend.assignAll(sortedFilteredCounts);
  }

  List<Map<String, dynamic>> _getDcPendudukSubmissions() {
    final bool isDateFilterActive = selectedStartDate.value != null && selectedEndDate.value != null;
    final DateTime? filterStartDate = selectedStartDate.value;
    final DateTime? filterEndDate = selectedEndDate.value;

    List<Map<String, dynamic>> dcPendudukSubmissions = [];

    final dcFormEntry = _allFormEntriesWithSubmissions.firstWhereOrNull(
          (entry) => (entry['formTitle'] as String? ?? '').toLowerCase().contains('dc-penduduk'),
    );

    if (dcFormEntry != null) {
      List<Map<String, dynamic>> allSubmissionsForDCPenduduk = List<Map<String, dynamic>>.from(dcFormEntry['submissions'] ?? []);

      if (isDateFilterActive) {
        for (var submissionData in allSubmissionsForDCPenduduk) {
          if (submissionData.containsKey('submittedAt') && submissionData['submittedAt'] is Timestamp) {
            Timestamp submittedAtTimestamp = submissionData['submittedAt'];
            DateTime submissionDate = submittedAtTimestamp.toDate().toLocal();
            // Pengecekan rentang tanggal yang lebih tepat
            if (!submissionDate.isBefore(filterStartDate!) && !submissionDate.isAfter(filterEndDate!)) {
              dcPendudukSubmissions.add(submissionData);
            }
          }
        }
      } else {
        // Jika tidak ada filter tanggal, ambil semua submission 'dc-penduduk'
        dcPendudukSubmissions.addAll(allSubmissionsForDCPenduduk);
      }
    }
    return dcPendudukSubmissions;
  }

  Future<void> exportDataAsJson() async {
    Get.snackbar(
      'Export Data',
      'Mempersiapkan data untuk ekspor JSON...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.blue.shade200,
    );

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      debugPrint("Izin penyimpanan tidak diberikan. Proses ekspor JSON dihentikan.");
      Get.closeCurrentSnackbar(); // Tutup snackbar loading
      return;
    }
    debugPrint("Izin penyimpanan diberikan. Melanjutkan ekspor JSON.");

    try {
      final List<Map<String, dynamic>> submissionsToExport = _getDcPendudukSubmissions();

      if (submissionsToExport.isEmpty) {
        Get.closeCurrentSnackbar();
        Get.snackbar(
          'Info',
          'Tidak ada data penduduk untuk diekspor pada periode yang dipilih.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
        );
        return;
      }

      final List<Map<String, dynamic>> processedSubmissions = submissionsToExport.map((submission) {
        final Map<String, dynamic> processed = {};
        submission.forEach((key, value) {
          processed[key.toString()] = _convertToJsonSafe(value);
        });
        return processed;
      }).toList();

      debugPrint("Data siap di-encode ke JSON. Jumlah entri: ${processedSubmissions.length}");
      if (kDebugMode && processedSubmissions.isNotEmpty) {
        // debugPrint("Contoh entri pertama (setelah konversi): ${processedSubmissions.first}");
      }

      String jsonString;
      try {
        jsonString = const JsonEncoder.withIndent('  ').convert(processedSubmissions);
        debugPrint("JSON String berhasil dibuat. Panjang: ${jsonString.length}");
      } catch (e, s) {
        debugPrint("CRITICAL: Error saat jsonEncode: $e\nStacktrace: $s");
        Get.closeCurrentSnackbar();
        Get.snackbar('Error Internal', 'Gagal mengonversi data ke JSON: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white, duration: const Duration(seconds: 5));
        return;
      }

      final List<int> fileBytes = utf8.encode(jsonString);
      debugPrint("JSON bytes siap. Ukuran: ${fileBytes.length} bytes");
      Get.closeCurrentSnackbar(); // Tutup snackbar loading sebelum dialog picker

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data JSON Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile == null) {
        Get.snackbar(
          'Dibatalkan',
          'Proses ekspor data JSON dibatalkan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey.shade600,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        'Berhasil!',
        'Data JSON berhasil diekspor.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } catch (e, s) {
      debugPrint("FATAL Error exporting JSON: $e\nStacktrace: $s");
      Get.closeCurrentSnackbar(); // Pastikan snackbar loading ditutup jika ada error
      Get.snackbar(
        'Error Export Tidak Terduga',
        'Terjadi kesalahan fatal: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 7),
      );
    }
  }

  Future<void> exportDataAsXlsx() async {
    Get.snackbar(
      'Export Data',
      'Mempersiapkan data untuk ekspor XLSX...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.blue.shade200,
    );

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      debugPrint("Izin penyimpanan tidak diberikan. Proses ekspor XLSX dihentikan.");
      Get.closeCurrentSnackbar();
      return;
    }
    debugPrint("Izin penyimpanan diberikan. Melanjutkan ekspor XLSX.");

    final List<Map<String, dynamic>> submissions = _getDcPendudukSubmissions();
    if (submissions.isEmpty) {
      Get.closeCurrentSnackbar();
      Get.snackbar('Info', 'Tidak ada data penduduk untuk diekspor ke XLSX pada periode yang dipilih.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // TODO: Implementasikan logika pembuatan file Excel di sini dengan library.
      // Contoh: final List<int>? excelBytes = await _generateExcelBytes(submissions);
      // Jika _generateExcelBytes async, pastikan di-await.

      // --- SIMULASI BYTES EXCEL (GANTI DENGAN IMPLEMENTASI NYATA) ---
      debugPrint("Memulai simulasi pembuatan bytes Excel...");
      // PENTING: Ini bukan file XLSX yang valid. Anda HARUS menggunakan library.
      String placeholderContent = "ID\tNama\tAlamat\n1\tBudi\tJl. Merdeka\n2\tAni\tJl. Pahlawan";
      final List<int> excelBytes = utf8.encode(placeholderContent);
      debugPrint("Simulasi bytes Excel selesai. Ukuran: ${excelBytes.length}");
      // --- AKHIR SIMULASI ---

      if (excelBytes.isEmpty /*excelBytes == null || excelBytes.isEmpty*/) {
        Get.closeCurrentSnackbar();
        Get.snackbar('Error', 'Gagal menghasilkan data untuk file XLSX (data kosong).', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      Get.closeCurrentSnackbar();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data XLSX Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(excelBytes),
      );

      if (outputFile == null) {
        Get.snackbar('Dibatalkan', 'Proses ekspor data XLSX dibatalkan.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      Get.snackbar('Berhasil!', 'Data XLSX (placeholder) berhasil diekspor.', snackPosition: SnackPosition.BOTTOM);

    } catch (e, s) {
      debugPrint("FATAL Error exporting XLSX: $e\nStacktrace: $s");
      Get.closeCurrentSnackbar();
      Get.snackbar('Error Export XLSX', 'Gagal mengekspor data XLSX: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> exportDataAsCsv() async {
    Get.snackbar(
      'Export Data',
      'Mempersiapkan data untuk ekspor CSV...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.blue.shade200,
    );

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      debugPrint("Izin penyimpanan tidak diberikan. Proses ekspor CSV dihentikan.");
      Get.closeCurrentSnackbar();
      return;
    }
    debugPrint("Izin penyimpanan diberikan. Melanjutkan ekspor CSV.");

    final List<Map<String, dynamic>> submissions = _getDcPendudukSubmissions();
    if (submissions.isEmpty) {
      Get.closeCurrentSnackbar();
      Get.snackbar('Info', 'Tidak ada data penduduk untuk diekspor ke CSV pada periode yang dipilih.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // TODO: Implementasikan logika pembuatan string CSV di sini dengan library.
      // Contoh: final String csvString = await _generateCsvString(submissions);
      // Jika _generateCsvString async, pastikan di-await.

      // --- SIMULASI STRING CSV (GANTI DENGAN IMPLEMENTASI NYATA) ---
      debugPrint("Memulai simulasi pembuatan string CSV...");
      final StringBuffer csvBuffer = StringBuffer();
      // Header (ambil dari keys di 'answers' atau tentukan secara manual)
      // Untuk contoh, kita buat header sederhana
      csvBuffer.writeln("ID Pengguna,Nama Pengguna,Tanggal Submit,Form ID,Form Judul");
      for (var sub in submissions) {
        String submittedAt = "";
        if (sub['submittedAt'] is Timestamp) {
          submittedAt = (sub['submittedAt'] as Timestamp).toDate().toIso8601String();
        } else if (sub['submittedAt'] is String) { // Jika sudah dikonversi oleh _convertToJsonSafe
          submittedAt = sub['submittedAt'];
        }
        csvBuffer.writeln(
            "${sub['userId'] ?? ''}," +
                "${sub['userName'] ?? ''}," +
                "$submittedAt," +
                "${sub['formId'] ?? ''}," +
                "\"${(sub['formTitle'] ?? '').replaceAll('"', '""')}\"" // Handle kutip dalam judul
        );
        // Anda perlu menambahkan data dari 'answers' di sini.
      }
      final String csvString = csvBuffer.toString();
      debugPrint("Simulasi string CSV selesai. Panjang: ${csvString.length}");
      // --- AKHIR SIMULASI ---

      final List<int> fileBytes = utf8.encode(csvString);

      if (fileBytes.isEmpty) {
        Get.closeCurrentSnackbar();
        Get.snackbar('Error', 'Gagal menghasilkan data untuk file CSV (data kosong).', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      Get.closeCurrentSnackbar();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data CSV Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile == null) {
        Get.snackbar('Dibatalkan', 'Proses ekspor data CSV dibatalkan.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      Get.snackbar('Berhasil!', 'Data CSV (placeholder) berhasil diekspor.', snackPosition: SnackPosition.BOTTOM);

    } catch (e, s) {
      debugPrint("FATAL Error exporting CSV: $e\nStacktrace: $s");
      Get.closeCurrentSnackbar();
      Get.snackbar('Error Export CSV', 'Gagal mengekspor data CSV: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
} // Akhir dari AdminController

// _CustomDateRangePickerDialog tetap sama seperti sebelumnya
class _CustomDateRangePickerDialog extends StatefulWidget {
  final DateTime initialFocusedDay;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;
  final Color accentColor;
  final Color primaryColor;

  const _CustomDateRangePickerDialog({
    required this.initialFocusedDay,
    this.initialRangeStart,
    this.initialRangeEnd,
    this.accentColor = AdminScreen.accentHeaderColor,
    this.primaryColor = AdminScreen.primaryHeaderColor,
  });

  @override
  State<_CustomDateRangePickerDialog> createState() => _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<_CustomDateRangePickerDialog> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay;
    _rangeStart = widget.initialRangeStart;
    _rangeEnd = widget.initialRangeEnd;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pilih Rentang Tanggal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.only(top: 12.0, bottom: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      content: SizedBox(
        width: Get.width < 400 ? Get.width * 0.9 : 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: 'id_ID',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: AdminScreen.titlePageColor),
                leftChevronIcon: Icon(Icons.chevron_left, color: widget.accentColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: widget.accentColor),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: widget.accentColor, shape: BoxShape.circle),
                rangeStartDecoration: BoxDecoration(color: widget.accentColor, shape: BoxShape.circle),
                rangeEndDecoration: BoxDecoration(color: widget.accentColor, shape: BoxShape.circle),
                rangeHighlightColor: widget.primaryColor.withOpacity(0.3),
                todayDecoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.6), shape: BoxShape.circle),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red.shade400),
              ),
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _focusedDay = focused;
                  _rangeStart = start;
                  _rangeEnd = end;
                });
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
              selectedDayPredicate: (day) {
                if (_rangeStart == null) return false;
                if (_rangeEnd == null) return isSameDay(_rangeStart, day);
                return (day.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
                    day.isBefore(_rangeEnd!.add(const Duration(days: 1)))) ||
                    isSameDay(_rangeStart, day) || isSameDay(_rangeEnd, day);
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          onPressed: () {
            Get.back(result: null);
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
          child: const Text('Pilih', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (_rangeStart != null) {
              Get.back(result: {
                'start': _rangeStart,
                'end': _rangeEnd ?? _rangeStart,
                'focused': _focusedDay,
              });
            } else {
              Get.snackbar("Info", "Silakan pilih setidaknya satu tanggal awal.", snackPosition: SnackPosition.BOTTOM);
            }
          },
        ),
      ],
    );
  }
}