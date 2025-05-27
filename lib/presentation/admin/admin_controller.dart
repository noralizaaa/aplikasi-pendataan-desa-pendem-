// lib/presentation/admin/admin_controller.dart

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext for date picker
import 'package:intl/intl.dart'; // Needed for DateFormat

// Ensure these imports are correct based on your project structure
// import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Tidak digunakan secara langsung di controller ini
// import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_model.dart'; // Tidak digunakan secara langsung
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Needed for AdminScreen colors

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // For AdminScreen header
  final RxString adminName = 'Admin'.obs;
  final RxInt selectedPageIndex = 0.obs;

  // For Global Search
  final RxString globalSearchQuery = ''.obs;

  // For Dashboard (BI)
  final RxBool isDashboardLoading = true.obs;
  final RxInt totalSubmissions = 0.obs; // Akan diupdate oleh _applyDashboardFilter
  final RxInt totalActiveUsers = 0.obs;

  // Data master dan hasil filter untuk submisi form
  final RxList<Map<String, dynamic>> formSubmissions = <Map<String, dynamic>>[].obs; // Master data
  final RxList<Map<String, dynamic>> filteredFormSubmissions = <Map<String, dynamic>>[].obs; // Data terfilter untuk UI

  // Data master dan hasil filter untuk tren submisi
  final RxMap<String, int> _fullSubmissionTrend = <String, int>{}.obs; // Master data tren penuh
  final RxMap<String, int> submissionTrend = <String, int>{}.obs; // Tren terfilter untuk UI

  // Data master dan hasil filter untuk akses form
  final RxList<Map<String, dynamic>> formAccessCounts = <Map<String, dynamic>>[].obs; // Master data
  final RxList<Map<String, dynamic>> filteredFormAccessCounts = <Map<String, dynamic>>[].obs; // Data terfilter untuk UI

  // Date Filtering
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  static const String _usersCollectionPath = 'users';
  static const String _adminFormsCollectionPath = 'adminForms';

  @override
  void onInit() {
    super.onInit();
    _fetchAdminName();
    fetchDashboardData(); // Load all dashboard data on init

    // Re-apply filter whenever the selected date range or search query changes
    ever(selectedStartDate, (_) => _applyDashboardFilter());
    ever(selectedEndDate, (_) => _applyDashboardFilter());
    ever(globalSearchQuery, (_) => _applyDashboardFilter()); // Listener untuk search query
  }

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
  }

  Future<void> _fetchAdminName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _db.collection(_usersCollectionPath).doc(user.uid).get();
        if (userDoc.exists) {
          adminName.value = userDoc.get('username') ?? 'Admin';
        }
      } catch (e) {
        debugPrint("Error fetching admin name: $e");
        adminName.value = "Admin"; // Fallback
      }
    }
  }

  // --- Metode untuk Search Bar Global ---
  void updateGlobalSearchQuery(String query) {
    globalSearchQuery.value = query;
  }

  void clearGlobalSearchQuery() {
    globalSearchQuery.value = '';
    // Jika menggunakan TextEditingController, clear juga controllernya:
    // searchBarController.clear();
  }

  Future<void> fetchDashboardData() async {
    isDashboardLoading.value = true;
    try {
      await Future.wait([
        _fetchTotalActiveUsers(), // Ini bisa tetap karena tidak terpengaruh filter
        _fetchFormSubmissionDataAndCounts(), // Menggabungkan pengambilan data submisi dan counts awal
        _fetchFullSubmissionTrend(), // Mengambil data tren penuh
        _fetchFormAccessCountsMaster(), // Mengambil data akses form penuh
      ]);
      _applyDashboardFilter(); // Terapkan filter awal (yang mungkin tidak ada, jadi menampilkan semua)
    } catch (e) {
      Get.snackbar('Error Dashboard', 'Gagal memuat data dashboard: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      debugPrint('Dashboard data fetch error: $e');
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> _fetchTotalActiveUsers() async {
    QuerySnapshot usersSnapshot = await _db.collection(_usersCollectionPath).get();
    totalActiveUsers.value = usersSnapshot.docs.length;
  }

  // Mengambil data submisi form, termasuk detail submisi untuk filtering tanggal
  Future<void> _fetchFormSubmissionDataAndCounts() async {
    List<Map<String, dynamic>> tempFormSubmissions = [];
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();

    for (var formDoc in formsSnapshot.docs) {
      QuerySnapshot submissionsSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('submissions')
          .get();

      tempFormSubmissions.add({
        'formId': formDoc.id,
        'formTitle': formDoc.get('title') ?? 'Untitled Form',
        'count': submissionsSnapshot.docs.length, // Count awal sebelum filter tanggal
        'submissions': submissionsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Pastikan 'createdAt' ada dan merupakan Timestamp
          return {'id': doc.id, ...data};
        }).toList(),
      });
    }
    formSubmissions.assignAll(tempFormSubmissions);
  }


  Future<void> _fetchFullSubmissionTrend() async {
    Map<String, int> dailyCounts = {};
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();

    for (var formDoc in formsSnapshot.docs) {
      QuerySnapshot submissionsSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('submissions')
          .get();

      for (var submissionDoc in submissionsSnapshot.docs) {
        var data = submissionDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
          Timestamp createdAt = data['createdAt'];
          DateTime date = createdAt.toDate().toLocal();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          dailyCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    var sortedKeys = dailyCounts.keys.toList()..sort();
    final sortedDailyCounts = { for (var k in sortedKeys) k: dailyCounts[k]! };
    _fullSubmissionTrend.assignAll(sortedDailyCounts);
    // submissionTrend.assignAll(sortedDailyCounts); // Akan dihandle oleh _applyDashboardFilter
  }

  Future<void> _fetchFormAccessCountsMaster() async {
    List<Map<String, dynamic>> tempFormAccessCounts = [];
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();

    for (var formDoc in formsSnapshot.docs) {
      QuerySnapshot accessSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('managedAccounts')
          .get();

      tempFormAccessCounts.add({
        'formId': formDoc.id,
        'formTitle': formDoc.get('title') ?? 'Untitled Form',
        'accessCount': accessSnapshot.docs.length,
      });
    }
    formAccessCounts.assignAll(tempFormAccessCounts);
    // filteredFormAccessCounts.assignAll(tempFormAccessCounts); // Akan dihandle oleh _applyDashboardFilter
  }


  Future<void> pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days:1)), // Agar bisa memilih hari ini sepenuhnya
      initialDateRange: selectedStartDate.value != null && selectedEndDate.value != null
          ? DateTimeRange(start: selectedStartDate.value!, end: selectedEndDate.value!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AdminScreen.primaryHeaderColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              secondary: AdminScreen.accentHeaderColor,
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AdminScreen.accentHeaderColor),
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
            appBarTheme: const AppBarTheme(backgroundColor: AdminScreen.primaryHeaderColor, foregroundColor: Colors.white, elevation: 0),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontWeight: FontWeight.bold),
              labelLarge: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedStartDate.value = picked.start;
      // Atur selectedEndDate ke akhir hari untuk cakupan penuh
      selectedEndDate.value = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
    }
  }

  void resetDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
  }

  void _applyDashboardFilter() {
    final bool isDateFilterActive = selectedStartDate.value != null && selectedEndDate.value != null;
    final DateTime? filterStartDate = selectedStartDate.value;
    // EndDate sudah diatur ke akhir hari saat pemilihan
    final DateTime? filterEndDate = selectedEndDate.value;

    final String searchQuery = globalSearchQuery.value.toLowerCase().trim();

    // 1. Filter Form Submissions (filteredFormSubmissions dan totalSubmissions)
    List<Map<String, dynamic>> tempFilteredFormSubmissions = [];
    int newTotalSubmissions = 0;

    for (var formEntry in formSubmissions) { // Iterasi master data
      String formTitle = (formEntry['formTitle'] as String? ?? '').toLowerCase();
      bool matchesSearch = searchQuery.isEmpty || formTitle.contains(searchQuery);

      if (!matchesSearch) continue; // Lewati jika tidak cocok dengan query pencarian

      int countForThisFormInDateRange = 0;
      if (isDateFilterActive) {
        List<dynamic> submissions = formEntry['submissions'] as List<dynamic>;
        for (var submissionData in submissions) {
          if (submissionData is Map<String, dynamic> && submissionData.containsKey('createdAt') && submissionData['createdAt'] is Timestamp) {
            Timestamp createdAtTimestamp = submissionData['createdAt'];
            DateTime submissionDate = createdAtTimestamp.toDate().toLocal();
            if (submissionDate.isAfter(filterStartDate!.subtract(const Duration(microseconds: 1))) &&
                submissionDate.isBefore(filterEndDate!.add(const Duration(microseconds: 1)))) {
              countForThisFormInDateRange++;
            }
          }
        }
      } else {
        // Jika tidak ada filter tanggal, gunakan count asli dari formEntry (yang sudah cocok search query)
        countForThisFormInDateRange = formEntry['count'] as int? ?? 0;
      }

      // Hanya tambahkan jika count > 0 (jika ada filter tanggal) ATAU jika tidak ada filter tanggal
      if (isDateFilterActive && countForThisFormInDateRange > 0) {
        tempFilteredFormSubmissions.add({
          'formId': formEntry['formId'],
          'formTitle': formEntry['formTitle'],
          'count': countForThisFormInDateRange,
        });
        newTotalSubmissions += countForThisFormInDateRange;
      } else if (!isDateFilterActive) { // Selalu tambahkan jika cocok search dan tidak ada filter tanggal
        tempFilteredFormSubmissions.add({
          'formId': formEntry['formId'],
          'formTitle': formEntry['formTitle'],
          'count': countForThisFormInDateRange, // Ini adalah count asli jika tidak ada filter tanggal
        });
        newTotalSubmissions += countForThisFormInDateRange;
      }
    }
    filteredFormSubmissions.assignAll(tempFilteredFormSubmissions);
    totalSubmissions.value = newTotalSubmissions;

    // 2. Filter Submission Trend (submissionTrend) by date only
    _filterSubmissionTrendByDate(filterStartDate, filterEndDate);

    // 3. Filter Form Access Counts (filteredFormAccessCounts) by text search only
    List<Map<String, dynamic>> tempFilteredAccessCounts = [];
    for (var accessEntry in formAccessCounts) { // Iterasi master data
      String formTitle = (accessEntry['formTitle'] as String? ?? '').toLowerCase();
      if (searchQuery.isEmpty || formTitle.contains(searchQuery)) {
        tempFilteredAccessCounts.add(accessEntry);
      }
    }
    filteredFormAccessCounts.assignAll(tempFilteredAccessCounts);
  }

  void _filterSubmissionTrendByDate(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      submissionTrend.assignAll(_fullSubmissionTrend); // Reset ke data tren penuh
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

  @override
  void onClose() {
    // Jika menggunakan TextEditingController untuk search bar, dispose di sini
    // searchBarController.dispose();
    super.onClose();
  }
}