// lib/presentation/admin/admin_controller.dart

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext for date picker
import 'package:intl/intl.dart'; // Needed for DateFormat

// Ensure these imports are correct based on your project structure
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Needed for AdminScreen colors

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // For AdminScreen header
  final RxString adminName = 'Admin'.obs;
  final RxInt selectedPageIndex = 0.obs;

  // For Dashboard (BI)
  final RxBool isDashboardLoading = true.obs;
  final RxInt totalSubmissions = 0.obs;
  final RxInt totalActiveUsers = 0.obs;
  final RxList<Map<String, dynamic>> formSubmissions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormSubmissions = <Map<String, dynamic>>[].obs;
  final RxMap<String, int> submissionTrend = <String, int>{}.obs; // Date string (yyyy-MM-dd) to count

  // For Form Access Overview
  final RxList<Map<String, dynamic>> formAccessCounts = <Map<String, dynamic>>[].obs;

  // Date Filtering
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // Collection Paths (Ensure these match your Firestore structure)
  static const String _usersCollectionPath = 'users';
  static const String _adminFormsCollectionPath = 'adminForms';
  // Assuming actual data submissions are stored in a 'submissions' subcollection under each form
  // e.g., 'adminForms/{formId}/submissions/{submissionId}'
  // And form access is 'adminForms/{formId}/managedAccounts/{accountId}'

  @override
  void onInit() {
    super.onInit();
    _fetchAdminName();
    fetchDashboardData(); // Load all dashboard data on init

    // Re-apply filter whenever the selected date range changes
    // This is useful if you fetch all data first and then filter locally.
    ever(selectedStartDate, (_) => _applyDashboardFilter());
    ever(selectedEndDate, (_) => _applyDashboardFilter());
  }

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
    // You might want to re-fetch or update data for other tabs here
    // if their data isn't controlled by real-time streams (like AdminFormPage or AdminAccountPage might be).
  }

  Future<void> _fetchAdminName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _db.collection(_usersCollectionPath).doc(user.uid).get();
      if (userDoc.exists) {
        adminName.value = userDoc.get('username') ?? 'Admin';
      }
    }
  }

  /// --- Dashboard Data Fetching ---
  /// Fetches all necessary data for the dashboard.
  /// This method is called on init and on refresh.
  Future<void> fetchDashboardData() async {
    isDashboardLoading.value = true;
    try {
      // Use Future.wait to fetch all data concurrently for better performance
      await Future.wait([
        _fetchTotalSubmissions(),
        _fetchTotalActiveUsers(),
        _fetchFormSubmissionCounts(),
        _fetchSubmissionTrend(),
        _fetchFormAccessCounts(),
      ]);
      _applyDashboardFilter(); // Apply initial filter or re-filter after new data
    } catch (e) {
      Get.snackbar('Error Dashboard', 'Gagal memuat data dashboard: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      debugPrint('Dashboard data fetch error: $e'); // Use debugPrint for detailed console logs
    } finally {
      isDashboardLoading.value = false;
    }
  }

  /// Fetches the total number of submissions across all forms.
  Future<void> _fetchTotalSubmissions() async {
    int count = 0;
    // Get all form definitions
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();
    // For each form, get the count of documents in its 'submissions' subcollection
    for (var formDoc in formsSnapshot.docs) {
      QuerySnapshot submissionsSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('submissions')
          .get();
      count += submissionsSnapshot.docs.length;
    }
    totalSubmissions.value = count;
  }

  /// Fetches the total number of active users.
  /// (Currently counts all users in the 'users' collection. Define 'active' more precisely if needed.)
  Future<void> _fetchTotalActiveUsers() async {
    QuerySnapshot usersSnapshot = await _db.collection(_usersCollectionPath).get();
    totalActiveUsers.value = usersSnapshot.docs.length;
  }

  /// Fetches submission counts for each individual form.
  Future<void> _fetchFormSubmissionCounts() async {
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
        'count': submissionsSnapshot.docs.length,
        'submissions': submissionsSnapshot.docs.map((doc) => doc.data()).toList(), // Store raw submission data for date filtering
      });
    }
    formSubmissions.assignAll(tempFormSubmissions);
  }

  /// Fetches data to build the submission trend (e.g., daily counts).
  Future<void> _fetchSubmissionTrend() async {
    Map<String, int> dailyCounts = {};
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();

    for (var formDoc in formsSnapshot.docs) {
      QuerySnapshot submissionsSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('submissions')
          .get();

      for (var submissionDoc in submissionsSnapshot.docs) {
        // Assuming 'createdAt' is a Timestamp field in your submission documents
        Timestamp? createdAt = submissionDoc.get('createdAt');
        if (createdAt != null) {
          DateTime date = createdAt.toDate().toLocal(); // Convert to local time
          String dateKey = DateFormat('yyyy-MM-dd').format(date); // Format to "YYYY-MM-DD"
          dailyCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    // Sort trend data by date for consistent display (optional, but good practice)
    var sortedKeys = dailyCounts.keys.toList()..sort();
    final sortedDailyCounts = { for (var k in sortedKeys) k: dailyCounts[k]! };
    submissionTrend.assignAll(sortedDailyCounts);
  }

  /// Fetches the number of users who have access to each form.
  Future<void> _fetchFormAccessCounts() async {
    List<Map<String, dynamic>> tempFormAccessCounts = [];
    QuerySnapshot formsSnapshot = await _db.collection(_adminFormsCollectionPath).get();

    for (var formDoc in formsSnapshot.docs) {
      // Get the count of documents in the 'managedAccounts' subcollection for each form
      QuerySnapshot accessSnapshot = await _db.collection(_adminFormsCollectionPath)
          .doc(formDoc.id)
          .collection('managedAccounts') // Assuming 'managedAccounts' is the subcollection
          .get();

      tempFormAccessCounts.add({
        'formId': formDoc.id,
        'formTitle': formDoc.get('title') ?? 'Untitled Form',
        'accessCount': accessSnapshot.docs.length,
      });
    }
    formAccessCounts.assignAll(tempFormAccessCounts);
  }


  /// --- Date Filtering Logic ---
  /// Shows a date range picker and updates the selected date range.
  Future<void> pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Start date for the picker
      lastDate: DateTime.now(), // End date for the picker (today)
      initialDateRange: selectedStartDate.value != null && selectedEndDate.value != null
          ? DateTimeRange(start: selectedStartDate.value!, end: selectedEndDate.value!)
          : null, // Set initial range if already selected
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            // Customize the DateRangePicker theme here
            colorScheme: const ColorScheme.light(
              primary: AdminScreen.primaryHeaderColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black87, // Calendar text color
              secondary: AdminScreen.accentHeaderColor, // Selection fill color
              onSecondary: Colors.white, // Selected day text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AdminScreen.accentHeaderColor, // "Cancel" and "OK" button text color
              ),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0), // Rounded corners for the dialog
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AdminScreen.primaryHeaderColor, // Top bar background
              foregroundColor: Colors.white, // Back button and title color
              elevation: 0,
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(fontWeight: FontWeight.bold), // Year selector
              titleLarge: TextStyle(fontWeight: FontWeight.bold), // Month/Year display
              labelLarge: TextStyle(fontWeight: FontWeight.bold), // OK/CANCEL button text
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedStartDate.value = picked.start;
      selectedEndDate.value = picked.end;
      // The `_applyDashboardFilter()` will be triggered by the `ever` reaction in `onInit`.
    }
  }

  /// Resets the date filter to show all data.
  void resetDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    // The `_applyDashboardFilter()` will be triggered by the `ever` reaction in `onInit`.
  }

  /// Applies the selected date filter to the dashboard data.
  void _applyDashboardFilter() {
    // If no date range is selected, show all available submissions
    if (selectedStartDate.value == null || selectedEndDate.value == null) {
      filteredFormSubmissions.assignAll(formSubmissions);
      // Recalculate total submissions based on the full list
      totalSubmissions.value = formSubmissions.fold(0, (sum, element) => sum + (element['count'] as int));
      // Reset trend filter as well
      _filterSubmissionTrendByDate(null, null); // Pass nulls to reset trend filter
      return;
    }

    // Define the start and end of the selected date range, including the full day
    final DateTime startOfDay = DateTime(selectedStartDate.value!.year, selectedStartDate.value!.month, selectedStartDate.value!.day);
    final DateTime endOfDay = DateTime(selectedEndDate.value!.year, selectedEndDate.value!.month, selectedEndDate.value!.day, 23, 59, 59);

    List<Map<String, dynamic>> tempFiltered = [];
    int newTotalSubmissions = 0;

    for (var formEntry in formSubmissions) {
      int count = 0;
      List<dynamic> submissions = formEntry['submissions'] as List<dynamic>; // Access the stored raw submissions

      for (var submissionData in submissions) {
        Timestamp? createdAtTimestamp = submissionData['createdAt'];
        if (createdAtTimestamp != null) {
          DateTime submissionDate = createdAtTimestamp.toDate().toLocal();
          // Check if the submission date falls within the selected range (inclusive)
          if (submissionDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && submissionDate.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
            count++;
          }
        }
      }
      if (count > 0) { // Only include forms that have submissions within the filtered range
        tempFiltered.add({
          'formId': formEntry['formId'],
          'formTitle': formEntry['formTitle'],
          'count': count,
        });
        newTotalSubmissions += count;
      }
    }
    filteredFormSubmissions.assignAll(tempFiltered);
    totalSubmissions.value = newTotalSubmissions; // Update total submissions metric

    // Apply the date filter to the submission trend data
    _filterSubmissionTrendByDate(startOfDay, endOfDay);
  }

  /// Filters the submission trend data based on the provided date range.
  void _filterSubmissionTrendByDate(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      // If no date range or reset, re-fetch the full trend or re-assign from the initial full trend.
      // For simplicity, re-fetch here, but you could store a 'fullTrendData' and assign from it.
      _fetchSubmissionTrend(); // Re-fetch the full trend
      return;
    }

    Map<String, int> filteredDailyCounts = {};
    submissionTrend.forEach((dateString, count) {
      DateTime trendDate = DateFormat('yyyy-MM-dd').parse(dateString);
      // Check if the trend date falls within the selected range (inclusive)
      if (trendDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) && trendDate.isBefore(endDate.add(const Duration(milliseconds: 1)))) {
        filteredDailyCounts[dateString] = count;
      }
    });
    // Sort filtered trend data by date
    var sortedKeys = filteredDailyCounts.keys.toList()..sort();
    final sortedFilteredCounts = { for (var k in sortedKeys) k: filteredDailyCounts[k]! };
    submissionTrend.assignAll(sortedFilteredCounts);
  }

  @override
  void onClose() {
    // You should typically cancel any Firestore stream subscriptions here if you were using .snapshots().listen()
    // and storing the StreamSubscription objects.
    super.onClose();
  }
}