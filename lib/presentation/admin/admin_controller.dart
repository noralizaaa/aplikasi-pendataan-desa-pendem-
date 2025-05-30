import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarFormat, CalendarStyle, HeaderStyle, RangeSelectionMode, TableCalendar, isSameDay;
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';

// Package for CSV (add to pubspec.yaml if not already)
// import 'package:csv/csv.dart';
// Package for Excel (add to pubspec.yaml if not already)
// import 'package:excel/excel.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      _applyDashboardFilter();
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
    Map<String, String> formTitles = {};
    Map<String, int> dailyHouseholdCounts = {};

    QuerySnapshot formsMetaSnapshot = await _db.collection(_adminFormsCollectionPath).get();
    for (var formDoc in formsMetaSnapshot.docs) {
      formTitles[formDoc.id] = (formDoc.data() as Map<String,dynamic>)['title'] as String? ?? 'Form Tanpa Judul';
    }

    QuerySnapshot allSubmissionsSnapshot = await _db.collection(_formSubmissionsCollectionPath).get();
    for (var submissionDoc in allSubmissionsSnapshot.docs) {
      var data = submissionDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        String formId = data['formId'] as String? ?? '';
        String formTitle = data['formTitle'] as String? ?? '';

        if (formId.isNotEmpty) {
          submissionsByFormId.putIfAbsent(formId, () => []).add({
            'id': submissionDoc.id,
            'submittedAt': data['submittedAt'] as Timestamp?,
            'userId': data['userId'],
            'userName': data['userName'],
            'formTitle': formTitle,
            'answers': data['answers'], // Include answers for export
          });
        }

        if (formTitle.toLowerCase().contains('dc-penduduk') && data.containsKey('submittedAt') && data['submittedAt'] is Timestamp) {
          Timestamp submittedAtTimestamp = data['submittedAt'];
          DateTime date = submittedAtTimestamp.toDate().toLocal();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          dailyHouseholdCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    List<Map<String, dynamic>> tempFormEntries = [];
    submissionsByFormId.forEach((formId, submissionsList) {
      tempFormEntries.add({
        'formId': formId,
        'formTitle': formTitles[formId] ?? 'Form Tidak Dikenal ($formId)',
        'count': submissionsList.length,
        'submissions': submissionsList,
      });
    });
    _allFormEntriesWithSubmissions.assignAll(tempFormEntries);

    var sortedKeys = dailyHouseholdCounts.keys.toList()..sort();
    final sortedDailyCounts = { for (var k in sortedKeys) k: dailyHouseholdCounts[k]! };
    _fullSubmissionTrend.assignAll(sortedDailyCounts);
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
      lastDate: DateTime.now().add(const Duration(days:1)),
      initialDateRange: selectedStartDate.value != null && selectedEndDate.value != null
          ? DateTimeRange(start: selectedStartDate.value!, end: selectedEndDate.value!)
          : null,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AdminScreen.accentHeaderColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AdminScreen.accentHeaderColor),
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedStartDate.value = picked.start;
      selectedEndDate.value = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
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
        selectedEndDate.value = result['start'] != null
            ? DateTime(result['start']!.year, result['start']!.month, result['start']!.day, 23, 59, 59, 999)
            : null;
      }

      calendarRangeStart.value = result['start'];
      calendarRangeEnd.value = result['end'];
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
  }

  void onCalendarRangeSelected(DateTime? start, DateTime? end, DateTime newFocusedDay) {
    calendarRangeStart.value = start;
    calendarRangeEnd.value = end;
    focusedCalendarDay.value = newFocusedDay;

    selectedStartDate.value = start;
    if (end != null) {
      selectedEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    } else {
      selectedEndDate.value = null;
    }
  }

  void onCalendarDaySelected(DateTime selectedDay, DateTime newFocusedDay) {
    focusedCalendarDay.value = newFocusedDay;
    selectedStartDate.value = selectedDay;
    selectedEndDate.value = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 23, 59, 59, 999);

    calendarRangeStart.value = selectedDay;
    calendarRangeEnd.value = selectedDay;
  }

  void onCalendarPageChanged(DateTime newFocusedDay) {
    focusedCalendarDay.value = newFocusedDay;
  }

  void _applyDashboardFilter() {
    final bool isDateFilterActive = selectedStartDate.value != null && selectedEndDate.value != null;
    final DateTime? filterStartDate = selectedStartDate.value;
    final DateTime? filterEndDate = selectedEndDate.value;
    final String query = globalSearchQuery.value.toLowerCase().trim();

    debugPrint("_applyDashboardFilter: DateFilterActive=$isDateFilterActive, Start=${filterStartDate?.toIso8601String()}, End=${filterEndDate?.toIso8601String()}, Query='$query'");

    List<Map<String, dynamic>> tempFilteredSubmissionsSummary = [];
    int newTotalSubmissionsInPeriod = 0;

    for (var formEntry in _allFormEntriesWithSubmissions) {
      String formTitle = (formEntry['formTitle'] as String? ?? '').toLowerCase();
      bool matchesSearch = query.isEmpty || formTitle.contains(query);

      if (!matchesSearch) continue;

      List<Map<String, dynamic>> allSubmissionsForThisForm = List<Map<String, dynamic>>.from(formEntry['submissions'] ?? []);
      int countForDisplay = 0;

      if (isDateFilterActive) {
        for (var submissionData in allSubmissionsForThisForm) {
          if (formTitle.contains('dc-penduduk')) {
            if (submissionData.containsKey('submittedAt') && submissionData['submittedAt'] is Timestamp) {
              Timestamp submittedAtTimestamp = submissionData['submittedAt'];
              DateTime submissionDate = submittedAtTimestamp.toDate().toLocal();
              if (submissionDate.isAfter(filterStartDate!.subtract(const Duration(microseconds: 1))) &&
                  submissionDate.isBefore(filterEndDate!.add(const Duration(microseconds: 1)))) {
                countForDisplay++;
              }
            }
          } else {
            if (submissionData.containsKey('submittedAt') && submissionData['submittedAt'] is Timestamp) {
              Timestamp submittedAtTimestamp = submissionData['submittedAt'];
              DateTime submissionDate = submittedAtTimestamp.toDate().toLocal();
              if (submissionDate.isAfter(filterStartDate!.subtract(const Duration(microseconds: 1))) &&
                  submissionDate.isBefore(filterEndDate!.add(const Duration(microseconds: 1)))) {
                countForDisplay++;
              }
            }
          }
        }
      } else {
        if (formTitle.contains('dc-penduduk')) {
          countForDisplay = _fullSubmissionTrend.values.fold(0, (sum, element) => sum + element);
        } else {
          countForDisplay = formEntry['count'] as int? ?? 0;
        }
      }

      if (countForDisplay > 0 || formTitle.contains('dc-penduduk')) {
        tempFilteredSubmissionsSummary.add({
          'formId': formEntry['formId'],
          'formTitle': formEntry['formTitle'],
          'count': countForDisplay,
        });
      }

      if (formTitle.contains('dc-penduduk')) {
        newTotalSubmissionsInPeriod = countForDisplay;
      }
    }
    filteredFormSubmissions.assignAll(tempFilteredSubmissionsSummary);
    totalSubmissions.value = newTotalSubmissionsInPeriod;

    _filterSubmissionTrendByDate(filterStartDate, filterEndDate);

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
    debugPrint("Filtered Submissions Count: ${filteredFormSubmissions.length}, Total for period: $newTotalSubmissionsInPeriod");
    debugPrint("Submission Trend Keys: ${submissionTrend.keys.length}");
  }

  void _filterSubmissionTrendByDate(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      submissionTrend.assignAll(_fullSubmissionTrend);
      return;
    }
    Map<String, int> filteredDailyCounts = {};
    _fullSubmissionTrend.forEach((dateString, count) {
      try {
        DateTime trendDate = DateFormat('yyyy-MM-dd').parse(dateString);
        if (trendDate.isAfter(startDate.subtract(const Duration(microseconds: 1))) &&
            trendDate.isBefore(endDate.add(const Duration(microseconds: 1)))) {
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

  // Helper to get 'DC-Penduduk' submissions based on current filters
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
            if (submissionDate.isAfter(filterStartDate!.subtract(const Duration(microseconds: 1))) &&
                submissionDate.isBefore(filterEndDate!.add(const Duration(microseconds: 1)))) {
              dcPendudukSubmissions.add(submissionData);
            }
          }
        }
      } else {
        dcPendudukSubmissions.assignAll(allSubmissionsForDCPenduduk);
      }
    }
    return dcPendudukSubmissions;
  }

  Future<void> exportDataAsJson() async {
    Get.snackbar(
      'Export Data',
      'Mempersiapkan data untuk ekspor JSON...', // Sedikit ubah pesan
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    try {
      final List<Map<String, dynamic>> submissionsToExport = _getDcPendudukSubmissions();

      if (submissionsToExport.isEmpty) {
        Get.snackbar(
          'Info',
          'Tidak ada data penduduk untuk diekspor.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
        );
        return;
      }

      final List<Map<String, dynamic>> processedSubmissions = submissionsToExport.map((submission) {
        final Map<String, dynamic> processed = Map<String, dynamic>.from(submission);
        if (processed['submittedAt'] is Timestamp) {
          processed['submittedAt'] = (processed['submittedAt'] as Timestamp).toDate().toIso8601String();
        }
        return processed;
      }).toList();

      final String jsonString = jsonEncode(processedSubmissions);
      final List<int> fileBytes = utf8.encode(jsonString); // Konversi string ke bytes

      // Meminta izin penyimpanan (tetap relevan sebagai fallback atau untuk operasi picker tertentu)
      var storageStatus = await Permission.storage.request();
      // Untuk Android 13+, jika menargetkan API 33+, izin spesifik media mungkin lebih relevan
      // tergantung jenis file dan lokasi. Namun, untuk save file picker, ini umumnya ditangani sistem.
      // Pertimbangkan juga Permission.manageExternalStorage jika akses luas diperlukan (tidak disarankan untuk ini).

      if (!storageStatus.isGranted && !storageStatus.isLimited) { // Tambahkan .isLimited untuk iOS
        if (storageStatus.isPermanentlyDenied) {
          Get.snackbar(
            'Izin Ditolak Permanen',
            'Izin penyimpanan diperlukan. Aktifkan di pengaturan aplikasi.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.white)),
            ),
          );
        } else {
          Get.snackbar(
            'Izin Ditolak',
            'Izin penyimpanan diperlukan untuk melanjutkan.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
          );
        }
        return;
      }

      // Meminta pengguna memilih lokasi dan nama file untuk menyimpan
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data JSON Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(fileBytes), // Langsung sediakan bytes ke file picker
      );

      if (outputFile == null) {
        // Pengguna membatalkan dialog penyimpanan
        Get.snackbar(
          'Dibatalkan',
          'Proses ekspor data JSON dibatalkan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey.shade600,
          colorText: Colors.white,
        );
        return;
      }

      // Karena kita sudah menyediakan `bytes` ke `saveFile`,
      // file_picker seharusnya sudah menangani penyimpanan.
      // Jika `saveFile` hanya mengembalikan path dan kita perlu menulis manual:
      // final File file = File(outputFile);
      // await file.writeAsBytes(fileBytes); // atau await file.writeAsString(jsonString);

      Get.snackbar(
        'Berhasil!',
        'Data JSON berhasil diekspor.', // Path tidak selalu akurat/diketahui jika `bytes` digunakan
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        // Tombol 'Buka File' mungkin tidak selalu relevan jika path absolut tidak mudah didapatkan
        // atau jika file disimpan melalui Content URI. OpenFilex mungkin masih bisa bekerja pada beberapa kasus.
        // mainButton: TextButton(
        //   onPressed: () {
        //     OpenFilex.open(outputFile); // outputFile mungkin bukan path yang bisa langsung diakses OpenFilex
        //   },
        //   child: const Text('Buka File', style: TextStyle(color: Colors.white)),
        // ),
      );

    } catch (e, s) {
      debugPrint("Error exporting JSON: $e\n$s");
      Get.snackbar(
        'Error Export',
        'Gagal mengekspor data JSON: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Future<void> exportDataAsXlsx() async {
    final List<Map<String, dynamic>> submissions = _getDcPendudukSubmissions();
    if (submissions.isEmpty) {
      Get.snackbar('Info', 'Tidak ada data untuk diekspor ke XLSX.');
      return;
    }
    Get.snackbar('Export Data', 'Mengekspor data sebagai XLSX...');

    try {
      // TODO: Implementasi flattening data dan pembuatan bytes Excel di sini.
      // Misalnya, setelah Anda memiliki `List<int> excelBytes`:
      // final List<int> excelBytes = ... (hasil dari library excel Anda);

      // --- SIMULASI BYTES EXCEL (HAPUS ATAU GANTI DENGAN LOGIKA ANDA) ---
      // Ini hanya untuk demonstrasi agar fungsi bisa berjalan.
      // Ganti ini dengan logika pembuatan file Excel Anda yang sebenarnya.
      String dummyExcelContent = "ID,Name,Value\n1,DataA,100\n2,DataB,200";
      final List<int> excelBytes = utf8.encode(dummyExcelContent);
      // --- AKHIR SIMULASI BYTES EXCEL ---

      if (excelBytes.isEmpty) { // Tambahkan pengecekan jika bytes kosong setelah implementasi
        Get.snackbar('Error', 'Gagal menghasilkan file XLSX (data kosong).');
        return;
      }

      var storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        // ... (logika penanganan izin sama seperti di exportDataAsJson) ...
        Get.snackbar('Izin Ditolak', 'Izin penyimpanan diperlukan.');
        return;
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data XLSX Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes:  Uint8List(excelBytes as int),
      );

      if (outputFile == null) {
        Get.snackbar('Dibatalkan', 'Proses ekspor data XLSX dibatalkan.');
        return;
      }

      Get.snackbar('Berhasil!', 'Data XLSX (placeholder) berhasil diekspor.');

    } catch (e, s) {
      debugPrint("Error exporting XLSX: $e\n$s");
      Get.snackbar('Error Export', 'Gagal mengekspor data XLSX: ${e.toString()}');
    }
  }

  Future<void> exportDataAsCsv() async {
    final List<Map<String, dynamic>> submissions = _getDcPendudukSubmissions();
    if (submissions.isEmpty) {
      Get.snackbar('Info', 'Tidak ada data untuk diekspor ke CSV.');
      return;
    }
    Get.snackbar('Export Data', 'Mengekspor data sebagai CSV...');

    try {
      // TODO: Implementasi flattening data dan pembuatan string CSV di sini.
      // Misalnya, setelah Anda memiliki `String csvString`:
      // final String csvString = ... (hasil dari library csv Anda);

      // --- SIMULASI STRING CSV (HAPUS ATAU GANTI DENGAN LOGIKA ANDA) ---
      // Ini hanya untuk demonstrasi agar fungsi bisa berjalan.
      final String csvString = "ID,Nama Pengguna,Tanggal Submit\n1,UserA,2024-01-01\n2,UserB,2024-01-02";
      // --- AKHIR SIMULASI STRING CSV ---

      final List<int> fileBytes = utf8.encode(csvString);

      if (fileBytes.isEmpty) { // Tambahkan pengecekan jika bytes kosong setelah implementasi
        Get.snackbar('Error', 'Gagal menghasilkan file CSV (data kosong).');
        return;
      }

      var storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        // ... (logika penanganan izin sama seperti di exportDataAsJson) ...
        Get.snackbar('Izin Ditolak', 'Izin penyimpanan diperlukan.');
        return;
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Data CSV Sebagai...',
        fileName: 'data_penduduk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (outputFile == null) {
        Get.snackbar('Dibatalkan', 'Proses ekspor data CSV dibatalkan.');
        return;
      }

      Get.snackbar('Berhasil!', 'Data CSV (placeholder) berhasil diekspor.');

    } catch (e, s) {
      debugPrint("Error exporting CSV: $e\n$s");
      Get.snackbar('Error Export', 'Gagal mengekspor data CSV: ${e.toString()}');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}

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
                  if (start != null && end == null) {
                    // This handles the case where only one day is selected in a range mode,
                    // effectively making it a single-day selection for initial tap.
                  }
                });
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
              selectedDayPredicate: (day) {
                // This logic is mostly for `selectedDayPredicate` which is not used when `rangeSelectionMode` is `toggledOn`.
                // However, if you were to change `rangeSelectionMode` to `toggledOff` for single day selection,
                // this would be important. For range selection, `rangeStartDay` and `rangeEndDay` determine the highlighted range.
                return isSameDay(_rangeStart, day) || isSameDay(_rangeEnd, day);
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
                'end': _rangeEnd,
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