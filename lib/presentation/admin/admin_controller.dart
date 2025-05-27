import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarFormat, CalendarStyle, HeaderStyle, RangeSelectionMode, TableCalendar, isSameDay;
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk akses warna tema

// Widget dialog kustom akan didefinisikan di admin_screen.dart atau file terpisah
// Untuk sekarang, controller hanya perlu tahu cara memicunya.

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxString adminName = 'Admin'.obs;
  final RxInt selectedPageIndex = 0.obs;
  final RxString globalSearchQuery = ''.obs;

  final RxBool isDashboardLoading = true.obs;
  final RxInt totalSubmissions = 0.obs;
  final RxInt totalActiveUsers = 0.obs;

  final RxList<Map<String, dynamic>> _allFormEntriesWithSubmissions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormSubmissions = <Map<String, dynamic>>[].obs;

  final RxMap<String, int> _fullSubmissionTrend = <String, int>{}.obs;
  final RxMap<String, int> submissionTrend = <String, int>{}.obs;

  final RxList<Map<String, dynamic>> _allFormAccessCounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFormAccessCounts = <Map<String, dynamic>>[].obs;

  // State inti untuk filter tanggal
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // State untuk TableCalendar (digunakan oleh dialog kustom)
  final Rx<DateTime> focusedCalendarDay = DateTime.now().obs;
  final Rx<DateTime?> calendarRangeStart = Rx<DateTime?>(null); // Ini akan jadi _rangeStart di dialog
  final Rx<DateTime?> calendarRangeEnd = Rx<DateTime?>(null);   // Ini akan jadi _rangeEnd di dialog
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

  void updateGlobalSearchQuery(String query) {
    globalSearchQuery.value = query;
  }

  void clearGlobalSearchQuery() {
    globalSearchQuery.value = '';
  }

  Future<void> fetchDashboardData() async {
    isDashboardLoading.value = true;
    try {
      await Future.wait([
        _fetchTotalActiveUsers(),
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

  Future<void> _fetchTotalActiveUsers() async {
    try {
      QuerySnapshot usersSnapshot = await _db.collection(_usersCollectionPath).get();
      totalActiveUsers.value = usersSnapshot.docs.length;
    } catch(e) {
      debugPrint("Error fetching total active users: $e");
      totalActiveUsers.value = 0;
    }
  }

  Future<void> _fetchAllSubmissionsAndGroupThem() async {
    Map<String, List<Map<String, dynamic>>> submissionsByFormId = {};
    Map<String, String> formTitles = {};
    Map<String, int> dailyCounts = {};

    QuerySnapshot formsMetaSnapshot = await _db.collection(_adminFormsCollectionPath).get();
    for (var formDoc in formsMetaSnapshot.docs) {
      formTitles[formDoc.id] = (formDoc.data() as Map<String,dynamic>)['title'] as String? ?? 'Form Tanpa Judul';
    }

    QuerySnapshot allSubmissionsSnapshot = await _db.collection(_formSubmissionsCollectionPath).get();
    for (var submissionDoc in allSubmissionsSnapshot.docs) {
      var data = submissionDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        String formId = data['formId'] as String? ?? '';
        if (formId.isNotEmpty) {
          submissionsByFormId.putIfAbsent(formId, () => []).add({
            'id': submissionDoc.id,
            'submittedAt': data['submittedAt'] as Timestamp?,
            'userId': data['userId'],
            'userName': data['userName'],
          });
        }
        if (data.containsKey('submittedAt') && data['submittedAt'] is Timestamp) {
          Timestamp submittedAtTimestamp = data['submittedAt'];
          DateTime date = submittedAtTimestamp.toDate().toLocal();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          dailyCounts.update(dateKey, (value) => value + 1, ifAbsent: () => 1);
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

    var sortedKeys = dailyCounts.keys.toList()..sort();
    final sortedDailyCounts = { for (var k in sortedKeys) k: dailyCounts[k]! };
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

  // Metode ini menggunakan showDateRangePicker bawaan Flutter (biasanya full screen di mobile)
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
      // Sinkronkan dengan state TableCalendar juga
      calendarRangeStart.value = selectedStartDate.value;
      calendarRangeEnd.value = selectedEndDate.value;
      if (selectedStartDate.value != null) {
        focusedCalendarDay.value = selectedStartDate.value!;
      }
    }
  }

  // --- BARU: Metode untuk menampilkan dialog TableCalendar kustom ---
  Future<void> openCustomDateRangePicker(BuildContext context) async {
    // Kirim state kalender saat ini ke dialog
    final result = await Get.dialog<Map<String, DateTime?>>(
      _CustomDateRangePickerDialog(
        initialFocusedDay: focusedCalendarDay.value,
        initialRangeStart: calendarRangeStart.value,
        initialRangeEnd: calendarRangeEnd.value,
        // Anda bisa teruskan warna tema jika dialog membutuhkannya
        // accentColor: AdminScreen.accentHeaderColor,
        // primaryColor: AdminScreen.primaryHeaderColor,
      ),
      barrierDismissible: true, // Pengguna bisa menutup dengan klik di luar dialog
    );

    if (result != null) { // Jika pengguna menekan "Pilih"
      selectedStartDate.value = result['start'];
      // Pastikan endDate adalah akhir hari
      if (result['end'] != null) {
        DateTime end = result['end']!;
        selectedEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      } else {
        // Jika hanya satu tanggal dipilih (mode rentang belum selesai atau mode tanggal tunggal)
        // Anggap rentang satu hari jika hanya start yang ada
        selectedEndDate.value = result['start'] != null
            ? DateTime(result['start']!.year, result['start']!.month, result['start']!.day, 23, 59, 59, 999)
            : null;
      }

      // Update state TableCalendar di controller untuk konsistensi
      calendarRangeStart.value = result['start'];
      calendarRangeEnd.value = result['end']; // end bisa null
      if (result['focused'] != null) {
        focusedCalendarDay.value = result['focused']!;
      } else if (result['start'] != null) {
        focusedCalendarDay.value = result['start']!;
      }
    }
    // _applyDashboardFilter() akan terpicu oleh 'ever' pada selectedStartDate/EndDate
  }
  // --- AKHIR: Metode untuk dialog TableCalendar kustom ---


  void resetDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    calendarRangeStart.value = null;
    calendarRangeEnd.value = null;
    focusedCalendarDay.value = DateTime.now();
  }

  // Metode callback untuk TableCalendar jika disematkan langsung (tidak dipakai jika hanya via dialog)
  void onCalendarRangeSelected(DateTime? start, DateTime? end, DateTime newFocusedDay) {
    calendarRangeStart.value = start;
    calendarRangeEnd.value = end;
    focusedCalendarDay.value = newFocusedDay;

    selectedStartDate.value = start;
    if (end != null) {
      selectedEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    } else {
      selectedEndDate.value = null; // Atau samakan dengan start untuk rentang 1 hari
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
    // ... (Implementasi _applyDashboardFilter Anda yang sudah dibenahi sebelumnya) ...
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
          if (submissionData.containsKey('submittedAt') && submissionData['submittedAt'] is Timestamp) {
            Timestamp submittedAtTimestamp = submissionData['submittedAt'];
            DateTime submissionDate = submittedAtTimestamp.toDate().toLocal();
            if (submissionDate.isAfter(filterStartDate!.subtract(const Duration(microseconds: 1))) &&
                submissionDate.isBefore(filterEndDate!.add(const Duration(microseconds: 1)))) {
              countForDisplay++;
            }
          }
        }
      } else {
        countForDisplay = formEntry['count'] as int? ?? 0;
      }

      tempFilteredSubmissionsSummary.add({
        'formId': formEntry['formId'],
        'formTitle': formEntry['formTitle'],
        'count': countForDisplay,
      });
      newTotalSubmissionsInPeriod += countForDisplay;
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
    // Key? key, // Key bisa ditambahkan jika perlu
    required this.initialFocusedDay,
    this.initialRangeStart,
    this.initialRangeEnd,
    this.accentColor = AdminScreen.accentHeaderColor, // Default dari AdminScreen
    this.primaryColor = AdminScreen.primaryHeaderColor, // Default dari AdminScreen
  }); // : super(key: key);

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
      contentPadding: const EdgeInsets.only(top: 12.0, bottom: 0), // Sesuaikan padding
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      content: SizedBox(
        width: Get.width < 400 ? Get.width * 0.9 : 380, // Sesuaikan lebar dialog
        child: Column( // Column untuk TableCalendar dan sedikit padding jika perlu
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: 'id_ID',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)), // Contoh batas akhir
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
                  // Jika mode toggledOn dan pengguna klik hari yang sama untuk start dan end,
                  // atau jika hanya start yang dipilih.
                  if (start != null && end == null) {
                    // Biarkan pengguna memilih tanggal akhir, atau anggap ini rentang 1 hari
                    // Jika Anda ingin langsung anggap 1 hari: _rangeEnd = start;
                  }
                });
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
              selectedDayPredicate: (day) {
                // Ini berguna jika rangeSelectionMode adalah .toggledOff
                // Untuk .toggledOn, rangeStartDay dan rangeEndDay lebih dominan.
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
            Get.back(result: null); // Kembalikan null jika dibatalkan
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
          child: const Text('Pilih', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (_rangeStart != null) {
              Get.back(result: { // Kembalikan Map dengan tanggal yang dipilih
                'start': _rangeStart,
                'end': _rangeEnd, // Bisa null jika hanya start yang dipilih
                'focused': _focusedDay,
              });
            } else {
              // Opsional: Tampilkan pesan jika tidak ada tanggal dipilih
              Get.snackbar("Info", "Silakan pilih setidaknya satu tanggal awal.", snackPosition: SnackPosition.BOTTOM);
            }
          },
        ),
      ],
    );
  }
}
