import 'dart:async'; // Tambahkan untuk Timer
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Tambahkan ini untuk Uint8List
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'
    show
    CalendarFormat,
    CalendarStyle,
    HeaderStyle,
    RangeSelectionMode,
    TableCalendar,
    isSameDay;

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';

/// [AdminController] adalah pusat kendali (Orchestrator) untuk fitur Admin.
/// 
/// Controller ini mengelola tiga pilar utama:
/// 1. **Dashboard**: Monitoring statistik, tren grafik harian, dan status server lokal.
/// 2. **Form Management**: Agregasi data laporan dari Cloud (Firestore) & Lokal (API) serta fitur Ekspor.
/// 3. **Account & Security**: Verifikasi Role (RBAC) dan sinkronisasi wilayah tugas (RT/RW/Desa).
class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Nama admin yang sedang login.
  final RxString adminName = 'Admin'.obs;
  /// Role pengguna (admin_global, admin_desa, admin_rw, admin_rt).
  final RxString userRole = ''.obs;
  /// ID Desa tempat admin bertugas.
  final RxString villageId = ''.obs;
  /// Nama Desa tempat admin bertugas.
  final RxString villageName = ''.obs;
  /// Wilayah tugas RT admin (digunakan untuk filtering data).
  final RxString userRt = ''.obs; // Tambahan
  /// Wilayah tugas RW admin (digunakan untuk filtering data).
  final RxString userRw = ''.obs; // Tambahan
  /// Index halaman aktif pada Bottom Navigation (0: Dashboard, 1: Form, 2: Profil).
  final RxInt selectedPageIndex = 0.obs;
  /// Query pencarian global untuk menyaring judul formulir.
  final RxString globalSearchQuery = ''.obs;

  /// Menandakan apakah proses pengambilan data dashboard sedang berjalan.
  final RxBool isDashboardLoading = false.obs;
  /// Menandakan apakah data dashboard sudah berhasil dimuat minimal satu kali.
  final RxBool hasDashboardLoaded = false.obs;
  /// Status koneksi ke server fisik di desa (Hybrid Connectivity).
  final RxBool isLocalServerOnline = false.obs; // Tambahan

  /// Data master seluruh laporan yang dikelompokkan berdasarkan formulir.
  final RxList<Map<String, dynamic>> _allFormEntriesWithSubmissions =
      <Map<String, dynamic>>[].obs;

  /// Data laporan yang telah melewati filter (pencarian, tanggal, RT/RW).
  final RxList<Map<String, dynamic>> filteredFormSubmissions =
      <Map<String, dynamic>>[].obs;

  /// Formulir yang sedang dipilih untuk ditampilkan grafik trennya.
  final Rx<Map<String, dynamic>?> selectedFormForChart =
  Rx<Map<String, dynamic>?>(null);

  /// Peta data harian untuk visualisasi grafik (Tanggal -> Jumlah Setoran).
  final RxMap<String, int> submissionTrend = <String, int>{}.obs;

  /// Data jumlah akun petugas yang memiliki akses ke setiap formulir.
  final RxList<Map<String, dynamic>> _allFormAccessCounts =
      <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> filteredFormAccessCounts =
      <Map<String, dynamic>>[].obs;

  /// Tanggal awal filter rentang waktu.
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  /// Tanggal akhir filter rentang waktu.
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  final Rx<DateTime> focusedCalendarDay = DateTime.now().obs;
  final Rx<DateTime?> calendarRangeStart = Rx<DateTime?>(null);
  final Rx<DateTime?> calendarRangeEnd = Rx<DateTime?>(null);

  final Rx<RangeSelectionMode> calendarRangeSelectionMode =
      RangeSelectionMode.toggledOn.obs;

  /// Timer untuk pembaruan data otomatis.
  Timer? _autoRefreshTimer; // Timer untuk auto refresh
  static const int _refreshIntervalSeconds = 60; // Interval refresh (misal tiap 60 detik)

  static const String _usersCollectionPath = 'users';
  static const String _adminFormsCollectionPath = 'adminForms';
  static const String _formSubmissionsCollectionPath = 'formSubmissions';

  /// Inisialisasi controller, memuat profil, dan memulai auto-refresh.
  @override
  void onInit() {
    super.onInit();

    // 1. Ambil data profil, lalu otomatis panggil fetch dashboard
    _fetchAdminName().then((_) {
      if (!isClosed && !hasDashboardLoaded.value) {
        debugPrint('AdminController: Auto-loading dashboard after profile fetch...');
        fetchDashboardData();
      }
    });

    ever(selectedStartDate, (_) {
      _applyDashboardFilter();
    });

    ever(selectedEndDate, (_) {
      _applyDashboardFilter();
    });

    ever(globalSearchQuery, (_) {
      _applyDashboardFilter();
    });

    // Inisialisasi Auto Refresh
    _startAutoRefresh();
  }

  /// Mengaktifkan timer untuk memperbarui data dashboard secara berkala.
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: _refreshIntervalSeconds), (timer) {
      // Hanya refresh jika sedang di tab Dashboard (index 0) dan tidak sedang loading
      if (selectedPageIndex.value == 0 && !isDashboardLoading.value && Get.currentRoute == AppRoutes.adminPage) {
        debugPrint('AdminController: Auto refreshing dashboard data...');
        fetchDashboardData();
      }
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  /// Helper untuk menampilkan snackbar yang aman dari context null atau overlay issue.
  static void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
  }) {
    if (Get.context == null) return;
    if (Overlay.maybeOf(Get.context!) == null) {
      debugPrint('Snackbar skipped: No overlay found in context');
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  /// Pemicu pemuatan data dashboard hanya jika belum pernah dimuat.
  Future<void> loadDashboardIfNeeded() async {
    // Re-fetch user role every time we check dashboard, just to be sure
    await _fetchAdminName();

    if (hasDashboardLoaded.value) {
      return;
    }

    await fetchDashboardData();
  }

  /// Fungsi utama untuk mengambil seluruh data dashboard secara paralel (Cloud + Lokal).
  Future<void> fetchDashboardData() async {
    if (isDashboardLoading.value) {
      return;
    }

    isDashboardLoading.value = true;

    try {
      await Future.wait([
        _fetchAllSubmissionsAndGroupThem(),
        _fetchFormAccessCountsMaster(),
      ]);

      _applyDashboardFilter();

      hasDashboardLoaded.value = true;
    } catch (e) {
      debugPrint('Error Dashboard: $e');

      showSafeSnackbar(
        title: 'Error Dashboard',
        message: 'Gagal memuat data dashboard: ${e.toString()}',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDashboardLoading.value = false;
    }
  }

  /// Mengambil profil Admin dari Firestore dan memverifikasi hak akses (RBAC).
  Future<void> _fetchAdminName() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      adminName.value = 'Admin';
      return;
    }

    debugPrint('AdminController: Fetching user info for UID: ${user.uid}');

    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _db.collection(_usersCollectionPath).doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final Map<String, dynamic> data = userDoc.data()!;

        adminName.value =
            data['username'] as String? ?? user.displayName ?? 'Admin';
        
        // Normalisasi role dan villageId agar pengecekan konsisten
        String fetchedRole = (data['role'] as String? ?? 'user').toLowerCase().trim();
        userRole.value = fetchedRole;
        villageId.value = (data['villageId'] as String? ?? '').trim();
        villageName.value = (data['villageName'] as String? ?? '').trim();
        userRt.value = (data['rt']?.toString() ?? '').trim(); // Tambahan
        userRw.value = (data['rw']?.toString() ?? '').trim(); // Tambahan
        
        debugPrint('AdminController: ROLE DETECTED: "$fetchedRole", VILLAGE: "${villageId.value}", RT: "${userRt.value}", RW: "${userRw.value}"');
        
        final userModel = UserModel(
          uid: user.uid, 
          email: user.email, 
          role: fetchedRole,
          rt: userRt.value,
          rw: userRw.value,
        );
        
        // Pengecekan keamanan menggunakan helper terpusat
        if (!userModel.isAdmin) {
           debugPrint('AdminController: NOT AN ADMIN! Redirecting to User Page...');
           Get.offAllNamed(AppRoutes.userPage);
           return;
        }

        debugPrint('AdminController: User info found. Name: ${adminName.value}, Role: ${userRole.value}, Village: ${villageId.value}');
      } else {
        debugPrint('AdminController: No user document found for UID in collection "$_usersCollectionPath".');
        adminName.value = user.displayName ?? 'Admin';
        userRole.value = 'user';
        villageId.value = '';
        villageName.value = '';
      }
    } catch (e) {
      debugPrint('AdminController: Error fetching admin name/role: $e');
      adminName.value = user.displayName ?? 'Admin';
    }
  }

  /// Mengambil seluruh data setoran formulir dari Firestore dan Server Lokal secara Hybrid.
  Future<void> _fetchAllSubmissionsAndGroupThem() async {
    final Map<String, List<Map<String, dynamic>>> submissionsByFormId = {};
    final Map<String, String> formTitles = {};
    
    // Cache untuk data profil user (agar tidak fetch berulang)
    final Map<String, Map<String, String>> userProfileCache = {};

    final QuerySnapshot<Map<String, dynamic>> formsMetaSnapshot =
        await _db.collection(_adminFormsCollectionPath).get();

    final userModel = UserModel(uid: '', role: userRole.value);
    final String vId = villageId.value.trim();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> formDoc in formsMetaSnapshot.docs) {
      final Map<String, dynamic> formData = formDoc.data();
      final String? formVillageId = formData['villageId'] as String?;

      if (userModel.isRestrictedAdmin) {
        if (formVillageId != vId) continue;
      }

      formTitles[formDoc.id] = formData['title'] as String? ?? 'Form Tanpa Judul';
    }

    // --- 1. AMBIL DARI FIREBASE ---
    Query<Map<String, dynamic>> submissionsQuery = _db.collection(_formSubmissionsCollectionPath);

    if (userModel.isRestrictedAdmin) {
      if (vId.isNotEmpty) {
        submissionsQuery = submissionsQuery.where('villageId', isEqualTo: vId);
      } else {
        submissionsQuery = submissionsQuery.where('villageId', isEqualTo: 'BLOCK_ALL_DATA');
      }
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> allSubmissionsSnapshot = await submissionsQuery
          .orderBy('submittedAt', descending: true)
          .limit(200)
          .get();

      for (final doc in allSubmissionsSnapshot.docs) {
        final data = doc.data();
        final String fId = data['formId'] as String? ?? '';
        final String uId = data['userId'] as String? ?? '';
        if (fId.isEmpty || !formTitles.containsKey(fId)) continue;

        submissionsByFormId.putIfAbsent(fId, () => []);
        
        // Ambil period jika ada
        String period = data['period'] as String? ?? '';
        if (period.isEmpty && data['submittedAt'] != null) {
          final dt = (data['submittedAt'] as Timestamp).toDate();
          period = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
        }

        // --- LOGIKA FILTER: PAKSA PAKAI PROFIL PETUGAS (ABAIKAN ISI FORM) ---
        String resRt = '';
        String resRw = '';

        if (uId.isNotEmpty) {
          // Selalu ambil dari profil user (cache) untuk akurasi 100% berdasarkan akun
          if (!userProfileCache.containsKey(uId)) {
            final uDoc = await _db.collection('users').doc(uId).get();
            if (uDoc.exists) {
              userProfileCache[uId] = {
                'rt': uDoc.data()?['rt']?.toString() ?? '',
                'rw': uDoc.data()?['rw']?.toString() ?? '',
              };
            } else {
              // Jika user tidak ditemukan, baru gunakan field di dokumen sebagai fallback terakhir
              userProfileCache[uId] = {
                'rt': data['rt']?.toString() ?? '',
                'rw': data['rw']?.toString() ?? '',
              };
            }
          }
          resRt = userProfileCache[uId]?['rt'] ?? '';
          resRw = userProfileCache[uId]?['rw'] ?? '';
        }

        submissionsByFormId[fId]!.add({
          'id': doc.id,
          'submittedAt': data['submittedAt'],
          'userId': uId,
          'userName': data['userName'],
          'formId': fId,
          'formTitle': formTitles[fId],
          'answers': data['answers'],
          'period': period,
          'rt': resRt,
          'rw': resRw,
          'source': 'Cloud',
        });
      }
    } catch (e) {
      debugPrint('AdminController: Error Firestore: $e');
    }

    // --- 2. AMBIL DARI LOCAL SERVER (Hybrid Logic) ---
    try {
      final QuerySnapshot<Map<String, dynamic>> villageSnap = await _db.collection('villages').get();
      final List<VillageModel> villagesWithLocalApi = villageSnap.docs
          .map((doc) => VillageModel.fromFirestore(doc))
          .where((v) => v.serverType == 'local_api')
          .toList();

      List<VillageModel> targets = [];
      if (userModel.isGlobalAdmin) {
        // Admin Global mengambil dari SEMUA server lokal yang terdaftar
        targets = villagesWithLocalApi;
      } else if (vId.isNotEmpty) {
        // Admin Desa hanya mengambil dari server desanya sendiri
        targets = villagesWithLocalApi.where((v) => v.villageId == vId).toList();
      }

      for (var village in targets) {
        try {
          String baseUrl = village.apiBaseUrl ?? "http://${village.localIpAddress}:${village.port}";
          if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

          final response = await http.get(Uri.parse('$baseUrl/api/submissions')).timeout(const Duration(seconds: 4));
          
          if (response.statusCode == 200) {
            if (village.villageId == vId || userModel.isGlobalAdmin) isLocalServerOnline.value = true;
            
            final List<dynamic> localData = jsonDecode(response.body);
            for (var item in localData) {
              final String fId = item['formId'] as String? ?? '';
              if (fId.isEmpty || !formTitles.containsKey(fId)) continue;

              final timestamp = _parseToTimestamp(item['submittedAt']);
              final dt = timestamp.toDate();
              final String period = item['period'] as String? ?? "${dt.year}-${dt.month.toString().padLeft(2, '0')}";

              // Ambil RT/RW (Lokal biasanya sudah menyertakan field ini di level teratas)
              String resRt = item['rt']?.toString() ?? '';
              String resRw = item['rw']?.toString() ?? '';
              
              // HAPUS: Deteksi dari dalam answers untuk menjaga konsistensi filter by user

              submissionsByFormId.putIfAbsent(fId, () => []);
              submissionsByFormId[fId]!.add({
                'id': item['id'],
                'submittedAt': timestamp,
                'userId': item['userId'],
                'userName': item['userName'],
                'formId': fId,
                'formTitle': formTitles[fId],
                'answers': item['answers'],
                'period': period,
                'rt': resRt,
                'rw': resRw,
                'source': 'Lokal (${village.villageName})',
              });
            }
          }
        } catch (e) {
          debugPrint('AdminController: Gagal akses server ${village.villageName}: $e');
        }
      }
    } catch (e) {
      debugPrint('AdminController: Error scanning local servers: $e');
    }

    final List<Map<String, dynamic>> tempFormEntries = [];
    formTitles.forEach((String fId, String title) {
      final List<Map<String, dynamic>> subs = submissionsByFormId[fId] ?? [];
      // Urutkan gabungan berdasarkan waktu terbaru
      subs.sort((a, b) {
        final tA = (a['submittedAt'] as Timestamp).toDate();
        final tB = (b['submittedAt'] as Timestamp).toDate();
        return tB.compareTo(tA);
      });

      tempFormEntries.add({
        'formId': fId,
        'formTitle': title,
        'submissions': subs,
      });
    });

    _allFormEntriesWithSubmissions.assignAll(tempFormEntries);
  }

  Timestamp _parseToTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is String) {
      try {
        return Timestamp.fromDate(DateTime.parse(val));
      } catch (_) {}
    }
    return Timestamp.now();
  }

  /// Mengambil jumlah akun petugas yang memiliki akses ke setiap formulir.
  Future<void> _fetchFormAccessCountsMaster() async {
    final List<Map<String, dynamic>> tempFormAccessCounts = [];
    final userModel = UserModel(uid: '', role: userRole.value);
    final String vId = villageId.value.trim();

    try {
      final QuerySnapshot<Map<String, dynamic>> formsSnapshot =
      await _db.collection(_adminFormsCollectionPath).get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> formDoc
      in formsSnapshot.docs) {
        final Map<String, dynamic> formData = formDoc.data();
        final String? formVillageId = formData['villageId'] as String?;

        // Filter Akses Form untuk Dashboard
        if (userModel.isRestrictedAdmin) {
          if (formVillageId != vId) continue;
        }

        int accessCount = 0;
        
        // OPTIMASI: Admin Monitoring/Desa biasanya tidak punya izin managedAccounts,
        // dan tidak butuh info ini di dashboard utama. Lewati saja untuk menghemat load.
        bool isGlobalAdmin = userModel.isGlobalAdmin;

        if (isGlobalAdmin) {
          try {
            final QuerySnapshot<Map<String, dynamic>> accessSnapshot = await _db
                .collection(_adminFormsCollectionPath)
                .doc(formDoc.id)
                .collection('managedAccounts')
                .get();
            accessCount = accessSnapshot.docs.length;
          } catch (e) {
            debugPrint('AdminController: Skip access count for form ${formDoc.id} (Permission Denied)');
            accessCount = 0; 
          }
        }

        tempFormAccessCounts.add({
          'formId': formDoc.id,
          'formTitle': formData['title'] as String? ?? 'Untitled Form',
          'accessCount': accessCount,
        });
      }

      _allFormAccessCounts.assignAll(tempFormAccessCounts);
    } catch (e) {
      debugPrint('Error fetching form access counts master: $e');
    }
  }

  /// Inti logika penyaringan dashboard berdasarkan pencarian, tanggal, dan wilayah (RT/RW).
  void _applyDashboardFilter() {
    selectedFormForChart.value = null;
    submissionTrend.clear();

    final userModel = UserModel(
      uid: '', 
      role: userRole.value,
      rt: userRt.value,
      rw: userRw.value,
    );
    final String rtFilter = userRt.value.trim();
    final String rwFilter = userRw.value.trim();

    final bool isDateFilterActive =
        selectedStartDate.value != null && selectedEndDate.value != null;

    final DateTime? filterStartDate = selectedStartDate.value;
    final DateTime? filterEndDate = selectedEndDate.value;

    final String query = globalSearchQuery.value.toLowerCase().trim();

    final List<Map<String, dynamic>> tempFilteredSubmissionsSummary = [];

    for (final Map<String, dynamic> formEntry in _allFormEntriesWithSubmissions) {
      final String formTitle = (formEntry['formTitle'] as String? ?? '').toLowerCase();
      final bool matchesSearch = query.isEmpty || formTitle.contains(query);

      if (!matchesSearch) continue;

      final List<Map<String, dynamic>> allSubmissionsForForm =
          List<Map<String, dynamic>>.from(formEntry['submissions'] ?? []);

      final List<Map<String, dynamic>> submissionsAfterFilter = [];

      // Helper untuk normalisasi (Ambil hanya angka: "RT 13" -> "13", "01" -> "1")
      String norm(String? s) {
        if (s == null || s.toString().trim().isEmpty) return "";
        // Buang semua karakter kecuali angka
        String digits = s.toString().replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isEmpty) return s.toString().trim().toLowerCase(); 
        // Buang nol di depan (leading zeros)
        String result = digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
        return result.isEmpty ? "0" : result;
      }

      for (final Map<String, dynamic> sub in allSubmissionsForForm) {
        // 1. FILTER RT/RW UNTUK ADMIN RT & RW (Strict Petugas Filtering)
        if (userModel.isAdminRt || userModel.isAdminRw) {
          String subRt = norm(sub['rt']);
          String subRw = norm(sub['rw']);
          
          String fRt = norm(rtFilter);
          String fRw = norm(rwFilter);

          // Admin RW (fRt = 0 atau kosong): Bisa lihat semua RT di RW tersebut
          bool isRwLevelOnly = fRt == '0' || fRt.isEmpty;

          bool matchRW = fRw.isEmpty || subRw == fRw;
          bool matchRT = isRwLevelOnly || subRt == fRt;
          
          if (!matchRW || !matchRT) continue;
        }

        // 2. FILTER TANGGAL
        if (isDateFilterActive && sub['submittedAt'] is Timestamp) {
          final DateTime submissionDate = (sub['submittedAt'] as Timestamp).toDate().toLocal();
          if (submissionDate.isBefore(filterStartDate!) || submissionDate.isAfter(filterEndDate!)) {
            continue;
          }
        }

        submissionsAfterFilter.add(sub);
      }

      tempFilteredSubmissionsSummary.add({
        'formId': formEntry['formId'],
        'formTitle': formEntry['formTitle'],
        'count': submissionsAfterFilter.length,
        'submissions': submissionsAfterFilter,
      });
    }

    filteredFormSubmissions.assignAll(tempFilteredSubmissionsSummary);

    final List<Map<String, dynamic>> tempFilteredAccessCounts = [];

    if (query.isEmpty) {
      tempFilteredAccessCounts.addAll(_allFormAccessCounts);
    } else {
      for (final Map<String, dynamic> accessEntry in _allFormAccessCounts) {
        final String formTitle =
        (accessEntry['formTitle'] as String? ?? '').toLowerCase();

        if (formTitle.contains(query)) {
          tempFilteredAccessCounts.add(accessEntry);
        }
      }
    }

    filteredFormAccessCounts.assignAll(tempFilteredAccessCounts);
  }

  /// Memperbarui data grafik tren harian untuk formulir tertentu.
  void updateChartForForm(Map<String, dynamic> formEntry) {
    final String fId = formEntry['formId'] ?? '';
    debugPrint('AdminController: Memperbarui grafik untuk formId: $fId');

    if (selectedFormForChart.value?['formId'] == fId) {
      selectedFormForChart.value = null;
      submissionTrend.clear();
      return;
    }

    selectedFormForChart.value = formEntry;
    submissionTrend.clear();

    final Map<String, int> dailyCounts = {};
    final List<Map<String, dynamic>> subs = List<Map<String, dynamic>>.from(formEntry['submissions'] ?? []);

    debugPrint('AdminController: Menghitung tren dari ${subs.length} data.');

    for (final Map<String, dynamic> sub in subs) {
      final dynamic rawDate = sub['submittedAt'];
      DateTime? date;

      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is String) {
        date = DateTime.tryParse(rawDate);
      }

      if (date != null) {
        final String dateKey = DateFormat('yyyy-MM-dd').format(date.toLocal());
        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }
    }

    if (dailyCounts.isEmpty) {
      debugPrint('AdminController: dailyCounts KOSONG! Pastikan field submittedAt ada dan valid.');
    } else {
      final List<String> sortedKeys = dailyCounts.keys.toList()..sort();
      final Map<String, int> sortedDailyCounts = {
        for (final String key in sortedKeys) key: dailyCounts[key]!,
      };
      submissionTrend.assignAll(sortedDailyCounts);
      debugPrint('AdminController: Tren berhasil diupdate: ${sortedDailyCounts.length} hari terdeteksi.');
    }
  }

  /// Handler perubahan tab pada Bottom Navigation.
  void onPageChanged(int index) {
    selectedPageIndex.value = index;

    // Trigger load jika data belum pernah dimuat dan masuk ke tab Dashboard
    if (index == 0 && !hasDashboardLoaded.value && !isDashboardLoading.value) {
      loadDashboardIfNeeded();
    }
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

  /// Membuka dialog pemilihan rentang tanggal kalender.
  Future<void> openCustomDateRangePicker(BuildContext context) async {
    final Map<String, DateTime?>? result =
    await Get.dialog<Map<String, DateTime?>>(
      _CustomDateRangePickerDialog(
        initialFocusedDay: focusedCalendarDay.value,
        initialRangeStart: calendarRangeStart.value,
        initialRangeEnd: calendarRangeEnd.value,
      ),
      barrierDismissible: true,
    );

    if (result == null) {
      return;
    }

    selectedStartDate.value = result['start'];

    if (result['end'] != null) {
      final DateTime end = result['end']!;

      selectedEndDate.value = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
        59,
        999,
      );
    } else {
      final DateTime? start = result['start'];

      selectedEndDate.value = start != null
          ? DateTime(
        start.year,
        start.month,
        start.day,
        23,
        59,
        59,
        999,
      )
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

  // --- LOGIKA EXPORT DATA (CSV & JSON) ---
  dynamic _recursiveSanitize(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(val.toDate().toLocal());
    } else if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), _recursiveSanitize(v)));
    } else if (val is List) {
      return val.map((e) => _recursiveSanitize(e)).toList();
    }
    return val;
  }

  String _cleanCsvText(String? text) {
    if (text == null) return "";
    return text.replaceAll(RegExp(r'[\n\r\t]'), ' ').trim();
  }

  String _formatAnswerForCsv(dynamic answer) {
    if (answer == null) return "";
    if (answer is List) return answer.map((e) => e.toString()).join(', ');
    if (answer is Map) {
      if (answer.containsKey('latitude')) return "Lat: ${answer['latitude']}, Lon: ${answer['longitude']}";
      if (answer.containsKey('imageUrl')) return answer['imageUrl'] ?? "";
      return answer.toString();
    }
    String s = answer.toString();
    if (s.startsWith('Timestamp(')) {
      try {
        final match = RegExp(r'seconds=(\d+)').firstMatch(s);
        if (match != null) {
          final seconds = int.parse(match.group(1)!);
          final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return DateFormat('dd/MM/yyyy').format(date);
        }
      } catch (_) {}
    }
    return s;
  }

  /// Menghasilkan file ekspor (CSV/JSON) dari data formulir.
  Future<void> exportFormSubmissions({
    required String formId,
    required String format, // 'json' atau 'csv'
    String? period, // Opsional: YYYY-MM
  }) async {
    debugPrint('AdminController: Memulai ekspor untuk form $formId, format: $format, periode: $period');
    try {
      final formEntry = _allFormEntriesWithSubmissions.firstWhereOrNull((e) => e['formId'] == formId);
      if (formEntry == null) {
        throw "Data form tidak ditemukan.";
      }

      List<Map<String, dynamic>> subs = List<Map<String, dynamic>>.from(formEntry['submissions']);
      
      if (period != null && period.isNotEmpty) {
        subs = subs.where((s) => s['period']?.toString() == period).toList();
      }

      if (subs.isEmpty) {
        showSafeSnackbar(title: 'Kosong', message: 'Tidak ada data untuk diekspor.', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      // Gunakan logika pembersihan dan perapihan yang sama dengan SubmissionsFormController
      String fileContent = '';
      String cleanTitle = formEntry['formTitle'].toString().replaceAll(RegExp(r'[^\w\s]'), '_').replaceAll(' ', '_');
      String fileName = 'Export_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}';

      if (format == 'json') {
        fileContent = jsonEncode(_recursiveSanitize(subs));
        fileName += '.json';
      } else {
        // CSV yang lebih rapi
        fileContent = _generateTidyCSV(subs);
        fileName += '.csv';
      }

      final Uint8List bytes = Uint8List.fromList(utf8.encode(fileContent));
      
      // Delimiter BOM untuk Excel
      Uint8List finalBytes = bytes;
      if (format == 'csv') {
        finalBytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes]);
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Hasil Ekspor',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format],
        bytes: finalBytes,
      );

      if (outputFile != null) {
        showSafeSnackbar(title: 'Berhasil', message: 'File berhasil disimpan.', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      showSafeSnackbar(title: 'Gagal Export', message: e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Membuat struktur CSV yang rapi dengan kolom dinamis berdasarkan pertanyaan formulir.
  String _generateTidyCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    // Header dasar
    List<String> headers = ['No', 'ID', 'Desa', 'RW', 'RT', 'Petugas', 'Waktu', 'Sumber', 'Periode'];
    Set<String> dynamicHeaders = {};
    
    for (var item in data) {
      final answers = item['answers'] as List<dynamic>?;
      if (answers != null) {
        for (var ans in answers) {
          String label = _cleanCsvText(ans['questionText'] ?? ans['questionId'] ?? 'Unknown');
          String qId = ans['questionId']?.toString() ?? '';
          if (qId.contains('_')) {
            final parts = qId.split('_');
            if (int.tryParse(parts.last) != null) {
              label = "$label (Anggota ${int.parse(parts.last) + 1})";
            }
          }
          dynamicHeaders.add(label);
        }
      }
    }

    List<String> sortedDynamic = dynamicHeaders.toList()..sort();
    headers.addAll(sortedDynamic);

    String csv = headers.map((h) => '"$h"').join(';') + '\n';

    for (int i = 0; i < data.length; i++) {
      var item = data[i];
      Map<String, String> row = {};
      row['No'] = (i + 1).toString();
      row['ID'] = item['id']?.toString() ?? '';
      row['Desa'] = _cleanCsvText(item['villageName']?.toString() ?? '-');
      row['RW'] = _cleanCsvText(item['rw']?.toString() ?? '-');
      row['RT'] = _cleanCsvText(item['rt']?.toString() ?? '-');
      row['Petugas'] = _cleanCsvText(item['userName']?.toString() ?? '');
      
      DateTime dt = _parseToTimestamp(item['submittedAt']).toDate().toLocal();
      row['Waktu'] = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      
      row['Sumber'] = item['source']?.toString() ?? 'Cloud';
      row['Periode'] = item['period']?.toString() ?? '';

      final answers = item['answers'] as List<dynamic>?;
      if (answers != null) {
        for (var ans in answers) {
          String label = _cleanCsvText(ans['questionText'] ?? ans['questionId'] ?? 'Unknown');
          String qId = ans['questionId']?.toString() ?? '';
           if (qId.contains('_')) {
            final parts = qId.split('_');
            if (int.tryParse(parts.last) != null) {
              label = "$label (Anggota ${int.parse(parts.last) + 1})";
            }
          }
          row[label] = _cleanCsvText(_formatAnswerForCsv(ans['answer']));
        }
      }
      csv += headers.map((h) {
        String val = row[h] ?? '';
        return '"${val.replaceAll('"', '""')}"';
      }).join(';') + '\n';
    }
    return csv;
  }
}

class _CustomDateRangePickerDialog extends StatefulWidget {
  final DateTime initialFocusedDay;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;

  const _CustomDateRangePickerDialog({
    required this.initialFocusedDay,
    this.initialRangeStart,
    this.initialRangeEnd,
  });

  @override
  State<_CustomDateRangePickerDialog> createState() {
    return _CustomDateRangePickerDialogState();
  }
}

class _CustomDateRangePickerDialogState
    extends State<_CustomDateRangePickerDialog> {
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
      title: const Text(
        'Pilih Rentang Tanggal',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.only(
        top: 12.0,
        bottom: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      content: SizedBox(
        width: Get.width < 400 ? Get.width * 0.9 : 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: 'id_ID',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(
                const Duration(days: 365),
              ),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.titlePageColor,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AdminTheme.accentHeaderColor,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AdminTheme.accentHeaderColor,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AdminTheme.accentHeaderColor,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: const BoxDecoration(
                  color: AdminTheme.accentHeaderColor,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: AdminTheme.accentHeaderColor,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: AdminTheme.primaryHeaderColor.withValues(alpha: 0.3),
                todayDecoration: BoxDecoration(
                  color: AdminTheme.primaryHeaderColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Colors.red.shade400,
                ),
              ),
              onRangeSelected: (
                  DateTime? start,
                  DateTime? end,
                  DateTime focused,
                  ) {
                setState(() {
                  _focusedDay = focused;
                  _rangeStart = start;
                  _rangeEnd = end;
                });
              },
              onPageChanged: (DateTime focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
              selectedDayPredicate: (DateTime day) {
                if (_rangeStart == null) {
                  return false;
                }

                if (_rangeEnd == null) {
                  return isSameDay(_rangeStart, day);
                }

                final bool isInRange =
                    day.isAfter(
                      _rangeStart!.subtract(
                        const Duration(days: 1),
                      ),
                    ) &&
                        day.isBefore(
                          _rangeEnd!.add(
                            const Duration(days: 1),
                          ),
                        );

                return isInRange ||
                    isSameDay(_rangeStart, day) ||
                    isSameDay(_rangeEnd, day);
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back(result: null);
          },
          child: const Text(
            'Batal',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.accentHeaderColor,
          ),
          onPressed: () {
            if (_rangeStart != null) {
              Get.back(
                result: {
                  'start': _rangeStart,
                  'end': _rangeEnd ?? _rangeStart,
                  'focused': _focusedDay,
                },
              );
            } else {
              AdminController.showSafeSnackbar(
                title: 'Info',
                message: 'Silakan pilih setidaknya satu tanggal awal.',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          child: const Text(
            'Pilih',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}