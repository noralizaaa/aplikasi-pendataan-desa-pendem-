// lib/presentation/admin/submissions_form/submissions_form_controller.dart
import 'dart:convert'; // Untuk jsonEncode, utf8
import 'dart:io';     // Untuk Platform

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/input_form_user/input_user_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';

// --- Tambahkan Impor untuk Package Ekspor ---
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex; // Alias untuk menghindari konflik nama
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
// --- Akhir Tambahan Impor ---


// Helper class untuk item yang akan ditampilkan di list (tetap sama)
/// [DisplayableSubmission] adalah kelas pembantu untuk merepresentasikan data isian (submission)
/// yang telah diolah agar siap ditampilkan pada daftar antarmuka admin.
/// 
/// Menyimpan data asli serta properti tambahan untuk keperluan pencarian, pengurutan,
/// dan tampilan ringkasan (seperti nama KRT dan NIK).
class DisplayableSubmission {
  /// Objek submission asli dari domain model.
  final FormSubmission originalSubmission;
  /// Judul utama yang akan ditampilkan pada kartu daftar.
  final String displayTitle;
  /// Deskripsi atau info tambahan di bawah judul.
  final String displayDescription; 
  /// Teks nama yang digunakan sebagai kunci pengurutan.
  final String sortableNamePart;
  /// Teks ID/NIK yang digunakan sebagai kunci pengurutan.
  final String sortableIdPart;
  /// Nama Kepala Rumah Tangga hasil ekstraksi.
  final String namaKepalaKeluarga;
  /// NIK Kepala Rumah Tangga hasil ekstraksi.
  final String nikKepalaKeluarga;

  DisplayableSubmission({
    required this.originalSubmission,
    required this.displayTitle,
    required this.displayDescription, 
    required this.sortableNamePart,
    required this.sortableIdPart,
    required this.namaKepalaKeluarga,
    required this.nikKepalaKeluarga,
  });
}

/// [SubmissionsFormController] mengelola daftar hasil pendataan (submissions) untuk formulir tertentu.
/// 
/// Controller ini menangani:
/// 1. Pengambilan data isian secara hybrid (Cloud Firestore + Server Lokal Desa).
/// 2. Filtering canggih berdasarkan pencarian, periode, desa, status, dan wilayah (RT/RW).
/// 3. Pengurutan data (Terbaru, Terlama, Nama A-Z).
/// 4. Fitur Ekspor data ke format CSV, XLSX (Excel), dan JSON yang rapi dan terstruktur.
class SubmissionsFormController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Cache untuk menyimpan nama pengguna agar tidak perlu fetch berulang ke Firestore.
  final Map<String, String> _userNamesCache = {};

  // --- State Identitas & Filter ---
  /// ID formulir yang sedang dibuka.
  final RxString formId = ''.obs;
  /// Peran admin yang sedang login.
  final RxString userRole = ''.obs;
  /// ID Desa admin.
  final RxString villageId = ''.obs;
  /// Nomor RT wilayah tugas admin.
  final RxString userRt = ''.obs; 
  /// Nomor RW wilayah tugas admin.
  final RxString userRw = ''.obs; 
  /// Judul formulir awal dari argumen navigasi.
  final RxString initialFormTitle = ''.obs;
  
  /// Struktur detail formulir (sections, questions).
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  /// Daftar isian asli hasil pengambilan data.
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  /// Daftar isian yang sudah diproses (filtered & sorted) untuk ditampilkan di UI.
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs;

  // --- State Pemuatan & Error ---
  final RxBool isLoadingStructure = true.obs;
  final RxBool isLoadingSubmissions = true.obs;
  final RxString errorMessage = ''.obs;

  // --- State UI & Filter Dinamis ---
  /// Kata kunci pencarian isian.
  final RxString searchQuery = ''.obs;
  /// Kriteria pengurutan yang aktif.
  final RxString currentSortOrder = 'Terbaru'.obs;
  /// Filter periode pendataan yang dipilih.
  final RxString selectedPeriodFilter = 'Semua'.obs; 
  /// Filter desa tertentu (untuk Admin Global).
  final RxString selectedVillageFilter = 'Semua'.obs; 
  /// Filter status isian (draft/submitted/locked).
  final RxString selectedStatusFilter = 'Semua'.obs; 
  /// Daftar desa yang tersedia untuk difilter.
  final RxList<Map<String, String>> availableVillages = <Map<String, String>>[].obs; 
  /// Daftar periode waktu yang tersedia berdasarkan data di database.
  final RxList<String> availablePeriods = <String>['Semua'].obs; 

  /// Opsi pilihan pengurutan.
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Nama KRT A-Z', 'Nama KRT Z-A'];
  /// Opsi pilihan status.
  final List<String> statusOptions = ['Semua', 'draft', 'submitted', 'locked'];

  // --- Konstanta Identifikasi Data (Smart Extraction) ---
  final List<String> _namaKrtPriorityCodes = ['106', 'NAMA_KEPALA_KELUARGA', 'NAMA_KRT'];
  final List<String> _nikKrtPriorityCodes = ['NIK_KRT', 'NIK_KEPALA_KELUARGA', '107'];
  final List<String> _generalNamePriorityCodes = ['NAMA_LENGKAP', 'NAMA_RESPONDEN', 'NAMA'];
  final List<String> _generalIdPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];

  /// Menggabungkan status loading struktur dan isian.
  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;
  /// Judul halaman dinamis berdasarkan nama formulir.
  String get appBarTitle => formStructure.value?.title ?? initialFormTitle.value;

  /// Menandakan status proses ekspor sedang berjalan.
  final RxBool isExporting = false.obs;

  late final TextEditingController searchController;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });

    // Menjalankan filter ulang dengan delay (debounce) agar tidak memberatkan UI saat mengetik.
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 400));

    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      formId.value = Get.arguments['formId'] ?? '';
      initialFormTitle.value = Get.arguments['formTitle'] ?? 'Daftar Submissions';

      if (formId.value.isNotEmpty) {
        _fetchUserInfo().then((_) {
          _fetchFormStructure();
          _fetchVillages(); 
          _fetchAvailablePeriods(); 
          _fetchSubmissions();
        });
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

  /// Mengambil informasi profil admin (role, village, RT/RW) untuk pembatasan data.
  Future<void> _fetchUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userRole.value = userDoc.data()?['role'] as String? ?? 'user';
          villageId.value = userDoc.data()?['villageId'] as String? ?? '';
          userRt.value = (userDoc.data()?['rt']?.toString() ?? '').trim(); // Tambahan
          userRw.value = (userDoc.data()?['rw']?.toString() ?? '').trim(); // Tambahan
        }
      } catch (e) {
        debugPrint("Error fetching user info: $e");
      }
    }
  }

  /// Mengambil struktur formulir untuk mengetahui urutan pertanyaan saat ekspor.
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

  /// Mengambil daftar desa untuk opsi filter wilayah.
  Future<void> _fetchVillages() async {
    try {
      final snapshot = await _db.collection('villages').get();
      availableVillages.assignAll(snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['villageName'] as String? ?? doc.id,
      }).toList());
    } catch (e) {
      debugPrint("Error fetching villages: $e");
    }
  }

  /// Mengambil daftar periode pendataan yang tersedia dari koleksi submissions.
  Future<void> _fetchAvailablePeriods() async {
    try {
      // Ambil periode unik dari submissions yang ada untuk form ini
      final snapshot = await _db.collection('formSubmissions')
          .where('formId', isEqualTo: formId.value)
          .get();
      
      final periods = snapshot.docs
          .map((doc) => doc.data()['period'] as String?)
          .where((p) => p != null)
          .cast<String>()
          .toSet()
          .toList();
      
      periods.sort((a, b) => b.compareTo(a)); // Terbaru di atas
      availablePeriods.assignAll(['Semua', ...periods]);
    } catch (e) {
      debugPrint("Error fetching periods: $e");
    }
  }

  /// Fungsi utama pengambilan data isian secara Hybrid (Firestore + Server Lokal).
  /// 
  /// Menerapkan [Strict Filtering] pada level RT/RW berdasarkan akun petugas yang mengisi,
  /// guna menjamin akurasi distribusi data per wilayah tugas.
  Future<void> _fetchSubmissions() async {
    if (formId.value.isEmpty) {
      _setLoadingError("ID Form kosong, tidak bisa fetch submissions.");
      return;
    }
    isLoadingSubmissions.value = true;
    errorMessage.value = '';
    try {
      final String currentRole = userRole.value.toLowerCase().trim();
      final userModel = UserModel(uid: '', role: currentRole);
      
      List<FormSubmission> allSubmissions = [];

      // --- 1. AMBIL DARI FIREBASE ---
      Query query = _db.collection('formSubmissions').where('formId', isEqualTo: formId.value);
      if (userModel.isRestrictedAdmin && villageId.value.isNotEmpty) {
        query = query.where('villageId', isEqualTo: villageId.value);
      }
      
      if (selectedPeriodFilter.value != 'Semua') query = query.where('period', isEqualTo: selectedPeriodFilter.value);
      if (selectedVillageFilter.value != 'Semua') query = query.where('villageId', isEqualTo: selectedVillageFilter.value);
      if (selectedStatusFilter.value != 'Semua') query = query.where('status', isEqualTo: selectedStatusFilter.value);

      final querySnapshot = await query.get();
      List<FormSubmission> cloudSubmissions = querySnapshot.docs
          .map((doc) => FormSubmission.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // --- FILTER RT/RW DI MEMORI (STRICT PETUGAS FILTERING) ---
      if (userModel.isAdminRt || userModel.isAdminRw) {
        String norm(String? s) {
          if (s == null || s.toString().trim().isEmpty) return "";
          String digits = s.toString().replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isEmpty) return s.toString().trim().toLowerCase(); 
          String result = digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
          return result.isEmpty ? "0" : result;
        }

        final String fRt = norm(userRt.value);
        final String fRw = norm(userRw.value);
        final bool isRwLevel = fRt == '0' || fRt.isEmpty;

        final Map<String, Map<String, String>> tempUserCache = {};
        List<FormSubmission> filteredList = [];

        for (var sub in cloudSubmissions) {
          String subRt = '';
          String subRw = '';

          // PAKSA LOOKUP PROFIL: Mengabaikan data di dalam dokumen/form
          if (sub.userId.isNotEmpty) {
            if (!tempUserCache.containsKey(sub.userId)) {
              final uDoc = await _db.collection('users').doc(sub.userId).get();
              if (uDoc.exists) {
                tempUserCache[sub.userId] = {
                  'rt': uDoc.data()?['rt']?.toString() ?? '',
                  'rw': uDoc.data()?['rw']?.toString() ?? '',
                };
              } else {
                // Fallback hanya jika user sudah dihapus dari DB
                tempUserCache[sub.userId] = {
                  'rt': sub.rt ?? '',
                  'rw': sub.rw ?? '',
                };
              }
            }
            subRt = norm(tempUserCache[sub.userId]?['rt']);
            subRw = norm(tempUserCache[sub.userId]?['rw']);
          }

          bool matchRW = fRw.isEmpty || subRw == fRw;
          bool matchRT = isRwLevel || subRt == fRt;

          if (matchRW && matchRT) {
            filteredList.add(sub);
          } else {
            debugPrint('FILTER REJECTED: User(${sub.userName}) RT:$subRt RW:$subRw vs Admin RT:$fRt RW:$fRw');
          }
        }
        cloudSubmissions = filteredList;
      }

      allSubmissions.addAll(cloudSubmissions);

      // --- 2. AMBIL DARI SEMUA SERVER LOKAL TERDAFTAR (Hybrid) ---
      try {
        final villageSnap = await _db.collection('villages').get();
        final List<VillageModel> localVillages = villageSnap.docs
            .map((doc) => VillageModel.fromFirestore(doc))
            .where((v) => v.serverType == 'local_api')
            .toList();

        List<VillageModel> targets = [];
        if (userModel.isGlobalAdmin) {
          targets = localVillages;
        } else if (villageId.value.isNotEmpty) {
          targets = localVillages.where((v) => v.villageId == villageId.value).toList();
        }

        for (var v in targets) {
          try {
            String baseUrl = v.apiBaseUrl ?? "http://${v.localIpAddress}:${v.port}";
            if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
            
            final response = await http.get(Uri.parse('$baseUrl/api/submissions?formId=${formId.value}')).timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              List<dynamic> localData = jsonDecode(response.body);
              
              // --- FILTER TAMBAHAN UNTUK ADMIN RT & RW (LOKAL) ---
              if (userModel.isAdminRt || userModel.isAdminRw) {
                String norm(String? s) {
                  if (s == null || s.trim().isEmpty) return "";
                  String digits = s.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return s.trim().toLowerCase(); 
                  return digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
                }
                
                final String fRt = norm(userRt.value);
                final String fRw = norm(userRw.value);
                final bool isRwLevel = fRt == '0' || fRt.isEmpty;

                localData = localData.where((item) {
                  String subRt = norm(item['rt']?.toString());
                  String subRw = norm(item['rw']?.toString());
                  
                  // Fallback Lokal jika field top-level kosong
                  if (subRt.isEmpty || subRw.isEmpty) {
                    final List<dynamic>? ansList = item['answers'] as List<dynamic>?;
                    if (ansList != null) {
                      for (var ans in ansList) {
                        final qText = ans['questionText']?.toString().toUpperCase() ?? '';
                        final qId = ans['questionId']?.toString().toUpperCase() ?? '';
                        final val = norm(ans['answer']?.toString());
                        if (subRw.isEmpty && (qId == '105' || qId == 'RW' || qText == 'RW' || qText.contains('RUKUN WARGA'))) subRw = val;
                        if (subRt.isEmpty && (qId == '104' || qId == 'RT' || qText == 'RT' || qText.contains('RUKUN TETANGGA'))) subRt = val;
                      }
                    }
                  }

                  bool matchRW = fRw.isEmpty || subRw == fRw;
                  bool matchRT = isRwLevel || subRt == fRt;
                  return matchRW && matchRT;
                }).toList();
              }

              allSubmissions.addAll(localData.map((item) => FormSubmission.fromMap(item, item['id'])).toList());
            }
          } catch (e) {
            debugPrint("Gagal akses server ${v.villageName}: $e");
          }
        }
      } catch (e) {
        debugPrint("Error scanning local servers for list: $e");
      }

      // --- 3. PROSES & SORTING AKHIR ---
      _originalSubmissions.assignAll(allSubmissions);
      _processSubmissionsForDisplay();
    } catch (e) {
      debugPrint("Error fetching submissions (Admin): $e");
      errorMessage.value = "Gagal memuat daftar isian: ${e.toString()}";
      _originalSubmissions.clear();
      _processSubmissionsForDisplay();
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  String _extractAnswerByPriority(List<QuestionAnswer> answers, List<String> priorityIds) {
    for (String id in priorityIds) {
      final answer = answers.firstWhereOrNull((qa) =>
      qa.questionId.trim().toUpperCase() == id.toUpperCase() &&
          qa.answer != null && qa.answer.toString().trim().isNotEmpty);
      if (answer != null) {
        return answer.answer.toString().trim();
      }
    }
    return '';
  }

  /// Mengolah data isian mentah menjadi objek siap tampil dengan metadata identitas responden.
  /// 
  /// Menerapkan [Fallback Logic] untuk mencari nama KRT atau NIK responden jika judul tampilan kosong.
  void _processSubmissionsForDisplay() {
    List<DisplayableSubmission> processedList = [];
    for (var sub in _originalSubmissions) {
      // 1. Prioritas Utama: Menggunakan displayTitle dari submission jika ada
      String currentDisplayTitle = sub.displayTitle ?? '';
      String currentDisplayDescription = sub.displayDescription ?? '';

      // 2. Fallback jika displayTitle kosong: Cari Nama KRT / NIK secara manual
      String namaKRT = sub.namaKepalaRumahTangga?.isNotEmpty == true
          ? sub.namaKepalaRumahTangga!
          : _extractAnswerByPriority(sub.answers, _namaKrtPriorityCodes);

      String nikKRT = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes);
      String displayNikKRT = (nikKRT.isNotEmpty && nikKRT != "1") ? nikKRT : "";

      if (currentDisplayTitle.isEmpty) {
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
      }

      if (searchQuery.value.isNotEmpty) {
        bool matchesSearch =
            currentDisplayTitle.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                currentDisplayDescription.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                (namaKRT.isNotEmpty && namaKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (displayNikKRT.isNotEmpty && displayNikKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (sub.userName.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (sub.userId.toLowerCase().contains(searchQuery.value.toLowerCase()));
        if (!matchesSearch) {
          continue;
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: currentDisplayTitle,
        displayDescription: currentDisplayDescription,
        sortableNamePart: (currentDisplayTitle.isNotEmpty ? currentDisplayTitle : namaKRT).toLowerCase(),
        sortableIdPart: (displayNikKRT.isNotEmpty ? displayNikKRT : nikKRT).toLowerCase(),
        namaKepalaKeluarga: namaKRT,
        nikKepalaKeluarga: displayNikKRT,
      ));
    }

    if (currentSortOrder.value == 'Nama KRT A-Z') {
      processedList.sort((a, b) => a.sortableNamePart.compareTo(b.sortableNamePart));
    } else if (currentSortOrder.value == 'Nama KRT Z-A') {
      processedList.sort((a, b) => b.sortableNamePart.compareTo(a.sortableNamePart));
    } else if (currentSortOrder.value == 'Terlama') {
      processedList.sort((a,b) => a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt));
    } else if (currentSortOrder.value == 'Terbaru'){
      processedList.sort((a,b) => b.originalSubmission.submittedAt.compareTo(a.originalSubmission.submittedAt));
    }
    displayedSubmissions.assignAll(processedList);
  }

  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    bool showProgressIndicator = false,
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
      showProgressIndicator: showProgressIndicator,
    );
  }

  void changeSearchQuery(String query) {
    searchQuery.value = query;
  }

  void changeSortOrder(String? newOrder) {
    if (newOrder != null && newOrder != currentSortOrder.value) {
      currentSortOrder.value = newOrder;
      _fetchSubmissions();
    }
  }

  void changePeriodFilter(String period) {
    selectedPeriodFilter.value = period;
    _fetchSubmissions();
  }

  /// Membuka halaman formulir dalam mode Edit atau Tampilan (Read-Only).
  /// 
  /// Jika peran adalah Admin Monitoring (RT/RW), maka data hanya akan dibuka dalam mode baca.
  void editSubmission(FormSubmission submission) {
    if (formId.value.isEmpty || submission.id == null || formStructure.value == null) {
      showSafeSnackbar(
        title: 'Error', 
        message: 'Tidak bisa mengedit, detail form belum termuat atau ID submission tidak valid.',
        snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    final userModel = UserModel(uid: '', role: userRole.value);
    final bool isReadOnlyUser = userModel.isAdminRt;

    Get.toNamed(
      AppRoutes.inputFormUser,
      arguments: {
        'formId': formId.value,
        'submissionId': submission.id,
        'villageId': submission.villageId, 
        'isAdminEdit': !isReadOnlyUser, // Jika Admin RT, ini false agar tidak masuk mode edit full
        'isReadOnlyView': isReadOnlyUser, // Flag tambahan untuk memastikan read-only
      },
    )?.then((result) {
      if (result == true || result == null) {
        refreshData();
      }
    });
  }

  /// Menghapus data isian dari Firestore setelah konfirmasi.
  /// 
  /// Akses hapus diblokir untuk Admin Monitoring (RT/RW) demi integritas data lapangan.
  void deleteSubmission(FormSubmission submission, String displayIdentifier) {
    // PROTEKSI: Admin RT tidak boleh hapus
    final userModel = UserModel(uid: '', role: userRole.value);
    if (userModel.isAdminRt) {
      showSafeSnackbar(
        title: 'Akses Ditolak', 
        message: 'Admin Monitoring tidak diperbolehkan menghapus data.',
        backgroundColor: Colors.orange, 
        colorText: Colors.white
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus data isian '$displayIdentifier' (User: ${submission.userName})?"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back(); // Tutup dialog konfirmasi

              Get.dialog(
                const Center(child: CircularProgressIndicator(color: Colors.orange)),
                barrierDismissible: false,
              );

              try {
                await _db.collection('formSubmissions').doc(submission.id).delete();

                // Pastikan dialog loading ditutup dengan aman
                Get.back();

                showSafeSnackbar(
                  title: 'Berhasil',
                  message: "Data '$displayIdentifier' berhasil dihapus.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                );
                _fetchSubmissions();
              } catch (e) {
                Get.back();
                showSafeSnackbar(
                  title: 'Error',
                  message: "Gagal menghapus: ${e.toString()}",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade700,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
  /// Mengecek dan meminta izin penyimpanan file (untuk Android lama < API 30).
  Future<bool> _checkAndRequestFilePermissions() async {
    // Pada Android 11+ (API 30), FilePicker.saveFile menggunakan Storage Access Framework (SAF)
    // yang tidak memerlukan izin MANAGE_EXTERNAL_STORAGE atau STORAGE untuk menyimpan file
    // ke lokasi yang dipilih pengguna.
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 30) {
        PermissionStatus status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true;
  }

  /// Membersihkan data secara rekursif agar valid untuk format JSON (konversi Timestamp ke String).
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

  dynamic _convertValueForExport(dynamic item) {
    if (item == null) return '';
    if (item is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.toDate().toLocal());
    } else if (item is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.toLocal());
    } else if (item is GeoPoint) {
      return "${item.latitude}, ${item.longitude}";
    } else if (item is List) {
      return item.map((e) => (e is Map || e is List) ? jsonEncode(_recursiveSanitize(e)) : e.toString()).join('|');
    } else if (item is Map) {
      return jsonEncode(_recursiveSanitize(item));
    }
    return item.toString();
  }

  /// Menyiapkan data isian ke dalam format JSON yang terstruktur dan dalam (nested).
  List<Map<String, dynamic>> _prepareDataForNestedJsonExport() {
    final List<FormSubmission> targetSubmissions = 
        displayedSubmissions.map((e) => e.originalSubmission).toList();

    if (targetSubmissions.isEmpty) return [];

    return targetSubmissions.map((submission) {
      Map<String, dynamic> responses = {};
      for (var answer in submission.answers) {
        responses[answer.questionId] = _recursiveSanitize(answer.answer);
      }

      return {
        'id': submission.id,
        'form_title': submission.formTitle,
        'petugas': _getResolvedUserName(submission),
        'desa': submission.villageName,
        'rt': submission.rt,
        'rw': submission.rw,
        'periode': submission.period,
        'waktu': _convertValueForExport(submission.submittedAt),
        'alamat': submission.locationAddress,
        'koordinat': submission.latitude != null ? "${submission.latitude}, ${submission.longitude}" : null,
        'responses': responses,
      };
    }).toList();
  }

  /// Menyiapkan data isian ke dalam format tabel rata (flat) dengan kolom dinamis.
  /// 
  /// Mendukung pengelompokan jawaban jika terdapat pertanyaan berulang (repeatable groups).
  ({List<Map<String, dynamic>> data, List<String> headers}) _prepareDataForExport() {
    final List<FormSubmission> targetSubmissions = 
        displayedSubmissions.map((e) => e.originalSubmission).toList();

    if (targetSubmissions.isEmpty) {
      return (data: [], headers: []);
    }

    // 1. Definisikan Header Dasar yang Rapi
    List<String> finalHeaders = [
      'No', 'ID_Data', 'Desa', 'RW', 'RT', 'Petugas', 'Periode', 
      'Waktu_Isi', 'Alamat_Lokasi', 'Latitude', 'Longitude', 'Foto'
    ];

    // 2. Kumpulkan semua ID Pertanyaan yang ada di data
    // Kita ingin mengelompokkan berdasarkan Anggota jika ada repeatable group
    Map<String, String> questionHeadersMap = {};
    Set<String> allAnswerKeys = {};
    
    for (var sub in targetSubmissions) {
      for (var ans in sub.answers) {
        allAnswerKeys.add(ans.questionId);
        
        // Buat Label Header yang rapi
        String headerLabel = ans.questionText;
        if (ans.questionId.contains('_')) {
           final parts = ans.questionId.split('_');
           final indexStr = parts.last;
           final int? idx = int.tryParse(indexStr);
           if (idx != null) {
              headerLabel = "$headerLabel (Anggota ${idx + 1})";
           }
        }
        questionHeadersMap[ans.questionId] = headerLabel;
      }
    }

    // Urutkan header pertanyaan: 
    // Kita coba ikuti urutan di formStructure, tapi dukung anggota group
    List<String> sortedQuestionKeys = [];
    if (formStructure.value != null) {
      for (var section in formStructure.value!.sections) {
        for (var q in section.questions) {
          // Cari semua key yang diawali dengan ID ini (untuk handle _0, _1 dst)
          List<String> matchedKeys = allAnswerKeys.where((k) => k == q.id || k.startsWith("${q.id}_")).toList();
          matchedKeys.sort((a, b) {
             if (a == q.id) return -1;
             if (b == q.id) return 1;
             return a.compareTo(b);
          });
          sortedQuestionKeys.addAll(matchedKeys);
        }
      }
    }
    
    // Tambahkan key yang mungkin tidak ada di structure tapi ada di data
    for (var key in allAnswerKeys) {
      if (!sortedQuestionKeys.contains(key)) sortedQuestionKeys.add(key);
    }

    // Tambahkan label header ke list final
    for (var key in sortedQuestionKeys) {
      finalHeaders.add(questionHeadersMap[key] ?? key);
    }

    // 3. Proses Baris Data
    List<Map<String, dynamic>> processedData = [];
    for (int i = 0; i < targetSubmissions.length; i++) {
      final sub = targetSubmissions[i];
      Map<String, dynamic> row = {};
      row['No'] = i + 1;
      row['ID_Data'] = sub.id ?? '-';
      row['Desa'] = sub.villageName ?? '-';
      row['RW'] = sub.rw ?? '-';
      row['RT'] = sub.rt ?? '-';
      row['Petugas'] = _getResolvedUserName(sub);
      row['Periode'] = sub.period ?? '-';
      row['Waktu_Isi'] = _convertValueForExport(sub.submittedAt);
      row['Alamat_Lokasi'] = sub.locationAddress ?? '-';
      row['Latitude'] = sub.latitude ?? '';
      row['Longitude'] = sub.longitude ?? '';
      row['Foto'] = sub.imageUrl ?? (sub.imageUrls?.isNotEmpty == true ? sub.imageUrls!.first : '');

      // Isi jawaban
      Map<String, dynamic> subAnswers = { for (var a in sub.answers) a.questionId : _convertValueForExport(a.answer) };
      for (var key in sortedQuestionKeys) {
        String headerLabel = questionHeadersMap[key] ?? key;
        row[headerLabel] = subAnswers[key] ?? '';
      }
      processedData.add(row);
    }

    return (data: processedData, headers: finalHeaders);
  }


  /// Mengambil username dari koleksi 'users' untuk semua data lama yang userName-nya kosong.
  /// Mengambil username petugas dari Firestore jika data submissions lama memiliki field kosong.
  Future<void> _fetchAndCacheUsernamesFromFirestore() async {
    // 1. Kumpulkan semua userId unik yang perlu dicari namanya.
    final uidsToFetch = _originalSubmissions
        .where((s) => (s.userName.isEmpty) && (s.userId.isNotEmpty))
        .map((s) => s.userId)
        .toSet();

    // 2. Jangan lakukan apa-apa jika tidak ada yang perlu dicari.
    uidsToFetch.removeWhere((uid) => _userNamesCache.containsKey(uid));
    if (uidsToFetch.isEmpty) return;

    // 3. Cari username untuk setiap UID yang dibutuhkan.
    for (final uid in uidsToFetch) {
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          // Ambil field 'username' sesuai permintaan Anda.
          final usernameFromUsersCollection = userDoc.data()!['username'] as String?;
          // Simpan di cache, beri nilai fallback jika field-nya kosong.
          _userNamesCache[uid] = usernameFromUsersCollection ?? 'Username Kosong di DB';
        } else {
          // Jika dokumen user tidak ditemukan.
          _userNamesCache[uid] = 'User Tidak Ditemukan di DB';
        }
      } catch (e) {
        _userNamesCache[uid] = 'Error Saat Lookup';
        if (kDebugMode) { print('Error fetching username for $uid: $e'); }
      }
    }
  }

  /// Mendapatkan nama pengisi yang sudah final (menggunakan cache jika perlu).
  String _getResolvedUserName(FormSubmission submission) {
    // 1. Jika userName di data submission sudah ada, langsung gunakan.
    if (submission.userName.isNotEmpty) {
      return submission.userName;
    }
    // 2. Jika kosong, coba cari di cache yang sudah kita isi.
    return _userNamesCache[submission.userId] ?? 'UID: ${submission.userId}'; // Fallback jika tidak ada di cache
  }

  /// Melakukan ekspor data ke file format JSON.
  Future<void> exportSubmissionsAsJson() async {
    if (isExporting.value) return;
    isExporting.value = true;
    showSafeSnackbar(
      title: 'Export JSON', 
      message: 'Mempersiapkan data...', 
      showProgressIndicator: true, 
      duration: const Duration(seconds: 120), 
      backgroundColor: Colors.blue.shade600, 
      colorText: Colors.white
    );

    await _fetchAndCacheUsernamesFromFirestore();

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final List<Map<String, dynamic>> dataToExport = _prepareDataForNestedJsonExport();

    if (dataToExport.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      showSafeSnackbar(
        title: 'Info', 
        message: 'Tidak ada data untuk diekspor.', 
        snackPosition: SnackPosition.BOTTOM
      );
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
        showSafeSnackbar(
          title: 'Berhasil', 
          message: 'Data JSON berhasil diekspor.', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.green.shade600, 
          colorText: Colors.white
        );
      } else {
        showSafeSnackbar(title: 'Dibatalkan', message: 'Ekspor JSON dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      showSafeSnackbar(
        title: 'Error', 
        message: 'Gagal mengekspor JSON: ${e.toString()}', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red.shade700, 
        colorText: Colors.white
      );
      if (kDebugMode) {
        print('JSON Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }

  /// Melakukan ekspor data ke file format CSV.
  /// 
  /// Menggunakan delimiter [;] dan [UTF-8 BOM] agar langsung terbaca rapi di Microsoft Excel.
  Future<void> exportSubmissionsAsCsv() async {
    if (isExporting.value) return;
    isExporting.value = true;
    showSafeSnackbar(
      title: 'Export CSV', 
      message: 'Mempersiapkan data...', 
      showProgressIndicator: true, 
      duration: const Duration(seconds: 120), 
      backgroundColor: Colors.blue.shade600, 
      colorText: Colors.white
    );

    await _fetchAndCacheUsernamesFromFirestore();

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final result = _prepareDataForExport();
    final List<Map<String, dynamic>> flatData = result.data;
    final List<String> headers = result.headers;

    if (flatData.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      showSafeSnackbar(title: 'Info', message: 'Tidak ada data untuk diekspor.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (headers.isEmpty && flatData.isNotEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      showSafeSnackbar(title: 'Error', message: 'Tidak dapat menentukan header untuk CSV.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      List<List<dynamic>> csvData = [headers];
      for (var rowMap in flatData) {
        List<dynamic> row = headers.map((header) => rowMap[header] ?? '').toList();
        csvData.add(row);
      }

      // Gunakan semicolon (;) sebagai pemisah karena Excel di Indonesia biasanya menggunakan semicolon (;) sebagai delimiter default.
      // Tambahkan BOM (Byte Order Mark) agar Excel mendeteksi encoding UTF-8 dan pembagian kolom dengan benar.
      String csvString = const ListToCsvConverter(fieldDelimiter: ';').convert(csvData);
      final List<int> csvEncoded = utf8.encode(csvString);
      final List<int> fileBytes = [0xEF, 0xBB, 0xBF, ...csvEncoded];
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
        showSafeSnackbar(
          title: 'Berhasil', 
          message: 'Data CSV berhasil diekspor.', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.green.shade600, 
          colorText: Colors.white
        );
      } else {
        showSafeSnackbar(title: 'Dibatalkan', message: 'Ekspor CSV dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      showSafeSnackbar(
        title: 'Error', 
        message: 'Gagal mengekspor CSV: ${e.toString()}', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red.shade700, 
        colorText: Colors.white
      );
      if (kDebugMode) {
        print('CSV Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }

  /// Melakukan ekspor data ke file format XLSX (Excel) asli.
  /// 
  /// Menyertakan styling (Warna, Tebal, Border) dan penanganan cerdas untuk tipe data NIK/ID 
  /// agar tidak berubah menjadi notasi ilmiah.
  Future<void> exportSubmissionsAsXlsx() async {
    if (isExporting.value) return;
    isExporting.value = true;
    showSafeSnackbar(
      title: 'Export XLSX', 
      message: 'Mempersiapkan data...', 
      showProgressIndicator: true, 
      duration: const Duration(seconds: 120), 
      backgroundColor: Colors.blue.shade600, 
      colorText: Colors.white
    );

    await _fetchAndCacheUsernamesFromFirestore();

    bool hasPermission = await _checkAndRequestFilePermissions();
    if (!hasPermission) {
      isExporting.value = false; Get.closeCurrentSnackbar(); return;
    }

    final result = _prepareDataForExport();
    final List<Map<String, dynamic>> flatData = result.data;
    final List<String> headers = result.headers;

    if (flatData.isEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      showSafeSnackbar(title: 'Info', message: 'Tidak ada data untuk diekspor.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (headers.isEmpty && flatData.isNotEmpty) {
      isExporting.value = false; Get.closeCurrentSnackbar();
      showSafeSnackbar(title: 'Error', message: 'Tidak dapat menentukan header untuk XLSX.', snackPosition: SnackPosition.BOTTOM);
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
      
      // Hapus sheet default 'Sheet1' jika ada
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
      
      ex.Sheet sheetObject = excel[sanitizedSheetName];

      // Definisikan Style untuk Header (Tebal, Background Oranye, Tengah)
      ex.CellStyle headerStyle = ex.CellStyle(
        bold: true,
        backgroundColorHex: ex.ExcelColor.fromHexString("#FB8C00"), // Warna Oranye Header Aplikasi
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        fontColorHex: ex.ExcelColor.fromHexString("#FFFFFF"), // Putih
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      );

      // Definisikan Style untuk Data (Border Tipis)
      ex.CellStyle dataStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: ex.VerticalAlign.Center,
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      );

      // Tulis Header
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = ex.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
        
        // Atur lebar kolom yang lebih proporsional
        double estimatedWidth = (headers[i].length + 12).toDouble();
        sheetObject.setColumnWidth(i, estimatedWidth.clamp(12.0, 60.0));
      }

      // Tulis Data
      for (int rowIndex = 0; rowIndex < flatData.length; rowIndex++) {
        Map<String, dynamic> rowMap = flatData[rowIndex];
        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          var cell = sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
          dynamic value = rowMap[headers[colIndex]];
          
          cell.cellStyle = dataStyle;

          if (value is num) {
            cell.value = ex.DoubleCellValue(value.toDouble());
          } else if (value is bool) {
            cell.value = ex.BoolCellValue(value);
          } else if (value is String) {
            // Logika cerdas untuk mendeteksi ID (NIK/KK) agar tidak menjadi format scientific
            bool looksLikeNumericId = RegExp(r'^\d{10,}$').hasMatch(value);
            
            if (looksLikeNumericId) {
              cell.value = ex.TextCellValue(value); // Biarkan sebagai teks agar tidak berubah di Excel
            } else {
              // Jika value bisa diubah ke angka tapi bukan ID panjang
              double? numValue = double.tryParse(value.replaceAll(',', '.'));
              if (numValue != null && !value.contains('-') && !value.contains(':') && value.length < 10) {
                cell.value = ex.DoubleCellValue(numValue);
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
        showSafeSnackbar(title: 'Error', message: 'Gagal menghasilkan file XLSX.', snackPosition: SnackPosition.BOTTOM);
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
        showSafeSnackbar(
          title: 'Berhasil', 
          message: 'Data XLSX berhasil diekspor.', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.green.shade600, 
          colorText: Colors.white
        );
      } else {
        showSafeSnackbar(title: 'Dibatalkan', message: 'Ekspor XLSX dibatalkan.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, s) {
      Get.closeCurrentSnackbar();
      showSafeSnackbar(
        title: 'Error', 
        message: 'Gagal mengekspor XLSX: ${e.toString()}', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red.shade700, 
        colorText: Colors.white
      );
      if (kDebugMode) { // Pastikan kDebugMode dari flutter/foundation.dart
        print('XLSX Export Error: $e\n$s');
      }
    } finally {
      isExporting.value = false;
    }
  }
}