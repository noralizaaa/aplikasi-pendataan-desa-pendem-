import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'
    show
    CalendarFormat,
    CalendarStyle,
    HeaderStyle,
    RangeSelectionMode,
    TableCalendar,
    isSameDay;
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxString adminName = 'Admin'.obs;
  final RxInt selectedPageIndex = 0.obs;
  final RxString globalSearchQuery = ''.obs;

  final RxBool isDashboardLoading = true.obs;

  final RxList<Map<String, dynamic>> _allFormEntriesWithSubmissions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormSubmissions =
      <Map<String, dynamic>>[].obs;

  final Rx<Map<String, dynamic>?> selectedFormForChart =
  Rx<Map<String, dynamic>?>(null);

  final RxMap<String, int> submissionTrend = <String, int>{}.obs;

  final RxList<Map<String, dynamic>> _allFormAccessCounts =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormAccessCounts =
      <Map<String, dynamic>>[].obs;

  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  final Rx<DateTime> focusedCalendarDay = DateTime.now().obs;
  final Rx<DateTime?> calendarRangeStart = Rx<DateTime?>(null);
  final Rx<DateTime?> calendarRangeEnd = Rx<DateTime?>(null);
  final Rx<RangeSelectionMode> calendarRangeSelectionMode =
      RangeSelectionMode.toggledOn.obs;

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

  /// **Logika Inti untuk Klik Kartu**
  /// Memperbarui grafik berdasarkan form yang dipilih.
  void updateChartForForm(Map<String, dynamic> formEntry) {
    if (selectedFormForChart.value?['formId'] == formEntry['formId']) {
      selectedFormForChart.value = null;
      submissionTrend.clear();
      return;
    }

    selectedFormForChart.value = formEntry;
    Map<String, int> dailyCounts = {};

    // **FIX**: Data 'submissions' di sini sudah difilter sebelumnya oleh `_applyDashboardFilter`.
    // Tidak perlu lagi melakukan filter tanggal di sini, sehingga lebih efisien dan akurat.
    List<Map<String, dynamic>> submissions =
    List.from(formEntry['submissions'] ?? []);

    for (var sub in submissions) {
      if (sub['submittedAt'] is Timestamp) {
        DateTime date = (sub['submittedAt'] as Timestamp).toDate().toLocal();
        String dateKey = DateFormat('yyyy-MM-dd').format(date);
        dailyCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    var sortedKeys = dailyCounts.keys.toList()..sort();
    final sortedDailyCounts = {for (var k in sortedKeys) k: dailyCounts[k]!};
    submissionTrend.assignAll(sortedDailyCounts);
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
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> _fetchAllSubmissionsAndGroupThem() async {
    Map<String, List<Map<String, dynamic>>> submissionsByFormId = {};
    Map<String, String> formTitles = {};

    QuerySnapshot formsMetaSnapshot =
    await _db.collection(_adminFormsCollectionPath).get();
    for (var formDoc in formsMetaSnapshot.docs) {
      formTitles[formDoc.id] = (formDoc.data()
      as Map<String, dynamic>)['title'] as String? ??
          'Form Tanpa Judul';
    }

    QuerySnapshot allSubmissionsSnapshot =
    await _db.collection(_formSubmissionsCollectionPath).get();
    for (var submissionDoc in allSubmissionsSnapshot.docs) {
      var data = submissionDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        String formId = data['formId'] as String? ?? '';
        String actualFormTitle = formTitles[formId] ??
            data['formTitle'] as String? ??
            'Form Tidak Dikenal';

        if (formId.isNotEmpty) {
          submissionsByFormId.putIfAbsent(formId, () => []).add({
            'id': submissionDoc.id,
            'submittedAt': data['submittedAt'] as Timestamp?,
            'userId': data['userId'],
            'userName': data['userName'],
            'formId': formId,
            'formTitle': actualFormTitle,
            'answers': data['answers'],
          });
        }
      }
    }

    List<Map<String, dynamic>> tempFormEntries = [];
    formTitles.forEach((formId, title) {
      List<Map<String, dynamic>> submissionsForThisForm =
          submissionsByFormId[formId] ?? [];
      tempFormEntries.add({
        'formId': formId,
        'formTitle': title,
        // 'count' tidak lagi diperlukan di sini karena akan dihitung saat filter
        'submissions': submissionsForThisForm,
      });
    });

    _allFormEntriesWithSubmissions.assignAll(tempFormEntries);
  }

  /// **Logika Inti untuk Filter**
  /// Menerapkan filter dan mempersiapkan data untuk UI.
  void _applyDashboardFilter() {
    selectedFormForChart.value = null;
    submissionTrend.clear();

    final bool isDateFilterActive =
        selectedStartDate.value != null && selectedEndDate.value != null;
    final DateTime? filterStartDate = selectedStartDate.value;
    final DateTime? filterEndDate = selectedEndDate.value;
    final String query = globalSearchQuery.value.toLowerCase().trim();

    List<Map<String, dynamic>> tempFilteredSubmissionsSummary = [];

    for (var formEntry in _allFormEntriesWithSubmissions) {
      String formTitle =
      (formEntry['formTitle'] as String? ?? '').toLowerCase();
      bool matchesSearch = query.isEmpty || formTitle.contains(query);

      if (!matchesSearch) continue;

      List<Map<String, dynamic>> allSubmissionsForForm =
      List<Map<String, dynamic>>.from(formEntry['submissions'] ?? []);

      // **FIX**: Membuat list baru untuk menampung submission yang sudah terfilter.
      List<Map<String, dynamic>> submissionsInPeriod = [];

      if (isDateFilterActive) {
        for (var submissionData in allSubmissionsForForm) {
          if (submissionData.containsKey('submittedAt') &&
              submissionData['submittedAt'] is Timestamp) {
            DateTime submissionDate =
            (submissionData['submittedAt'] as Timestamp).toDate().toLocal();
            if (!submissionDate.isBefore(filterStartDate!) &&
                !submissionDate.isAfter(filterEndDate!)) {
              submissionsInPeriod.add(submissionData);
            }
          }
        }
      } else {
        submissionsInPeriod.addAll(allSubmissionsForForm);
      }

      // Data yang dikirim ke UI sekarang berisi jumlah dan list submission yang sudah konsisten.
      tempFilteredSubmissionsSummary.add({
        'formId': formEntry['formId'],
        'formTitle': formEntry['formTitle'],
        'count': submissionsInPeriod.length, // Jumlah yang sudah difilter
        'submissions': submissionsInPeriod,   // List yang sudah difilter
      });
    }

    filteredFormSubmissions.assignAll(tempFilteredSubmissionsSummary);

    List<Map<String, dynamic>> tempFilteredAccessCounts = [];
    if (query.isEmpty) {
      tempFilteredAccessCounts.addAll(_allFormAccessCounts);
    } else {
      for (var accessEntry in _allFormAccessCounts) {
        String formTitle =
        (accessEntry['formTitle'] as String? ?? '').toLowerCase();
        if (formTitle.contains(query)) {
          tempFilteredAccessCounts.add(accessEntry);
        }
      }
    }
    filteredFormAccessCounts.assignAll(tempFilteredAccessCounts);
  }

  // Sisa method di bawah ini tidak ada perubahan.

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
        adminName.value = user.displayName ?? "Admin";
      }
    }
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

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
  }

  void updateGlobalSearchQuery(String query) {
    globalSearchQuery.value = query;
  }

  void clearGlobalSearchQuery() {
    globalSearchQuery.value = '';
  }

  void resetDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    calendarRangeStart.value = null;
    calendarRangeEnd.value = null;
    focusedCalendarDay.value = DateTime.now();
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
      calendarRangeEnd.value = result['end'] ?? result['start'];

      if (result['focused'] != null) {
        focusedCalendarDay.value = result['focused']!;
      } else if (result['start'] != null) {
        focusedCalendarDay.value = result['start']!;
      }
    }
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
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

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