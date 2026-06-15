// File: list_submission_form_controller.dart

import 'dart:async'; // Tambahkan untuk TimeoutException
import 'dart:io';    // Tambahkan untuk SocketException
import 'dart:convert'; // Tambahkan untuk JSON
import 'package:http/http.dart' as http; // Tambahkan untuk Local API
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/input_form_user/input_user_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';

/// [DisplayableSubmission] adalah kelas pembantu untuk item yang akan ditampilkan pada daftar.
/// 
/// Menyimpan data asli [FormSubmission] beserta properti tambahan yang telah diproses 
/// untuk mempermudah pencarian, pengurutan, dan tampilan visual di UI petugas.
class DisplayableSubmission {
  /// Objek isian asli dari database.
  final FormSubmission originalSubmission;
  /// Judul tampilan (biasanya nama KRT).
  final String displayTitle;        
  /// Deskripsi singkat di bawah judul.
  final String displayDescription; 
  /// Teks bagian nama yang digunakan untuk pengurutan.
  final String sortableNamePart;    
  /// Teks ID (NIK) yang digunakan untuk pengurutan.
  final String sortableIdPart;      
  /// Periode pendataan (format YYYY-MM).
  final String period; 
  /// Status isian (draft, submitted, locked).
  final String status; 
  /// Menandakan apakah data sudah dikunci.
  final bool isLocked;

  /// Nama Kepala Keluarga hasil ekstraksi.
  final String namaKepalaKeluarga;
  /// NIK Kepala Keluarga hasil ekstraksi.
  final String nikKepalaKeluarga;


  DisplayableSubmission({
    required this.originalSubmission,
    required this.displayTitle,
    this.displayDescription = '', 
    required this.sortableNamePart,
    required this.sortableIdPart,
    required this.period, 
    required this.status, 
    required this.isLocked, 
    required this.namaKepalaKeluarga, 
    required this.nikKepalaKeluarga,  
  });
}

/// [ListSubmissionFormController] mengelola daftar isian petugas untuk satu formulir spesifik.
/// 
/// Controller ini menangani:
/// 1. Pengambilan data isian user dari Firebase atau Server Lokal Desa secara Hybrid.
/// 2. Fitur **Auto Duplicate Bulanan**: Menyalin data keluarga dari periode sebelumnya otomatis.
/// 3. Pencarian dan pengurutan data isian petugas secara lokal.
/// 4. Navigasi untuk penambahan, pengeditan, dan penghapusan data isian.
class ListSubmissionFormController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper untuk menampilkan snackbar yang aman dari context null atau overlay issue.
  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    final context = Get.context;
    if (context == null) {
      debugPrint('Snackbar skipped: Get.context is null');
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('Snackbar skipped: Overlay is null');
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
      margin: margin,
      borderRadius: borderRadius,
    );
  }

  /// ID formulir yang sedang dikelola daftar isiannya.
  final RxString formId = ''.obs;
  /// Struktur detail formulir (untuk metadata).
  final Rx<FormItem?> formStructure = Rx<FormItem?>(null);
  /// Daftar asli seluruh isian yang diambil dari database.
  final RxList<FormSubmission> _originalSubmissions = <FormSubmission>[].obs;
  /// Daftar isian yang telah difilter dan diurutkan untuk ditampilkan di UI.
  final RxList<DisplayableSubmission> displayedSubmissions = <DisplayableSubmission>[].obs;

  /// Status loading struktur formulir.
  final RxBool isLoadingStructure = true.obs;
  /// Status loading data isian.
  final RxBool isLoadingSubmissions = true.obs;
  /// Pesan error jika terjadi kendala pengambilan data.
  final RxString errorMessage = ''.obs;

  /// Kata kunci pencarian isian.
  final RxString searchQuery = ''.obs;
  /// Kriteria pengurutan isian (Terbaru, Nama A-Z, dll).
  final RxString currentSortOrder = 'Terbaru'.obs;
  
  late final TextEditingController searchController;

  /// Opsi pilihan pengurutan yang tersedia.
  final List<String> sortOptions = ['Terbaru', 'Terlama', 'Nama KRT A-Z', 'Nama KRT Z-A'];

  // !! PENTING: SESUAIKAN KODE PERTANYAAN INI DENGAN YANG ADA DI FORMULIR ANDA !!
  // Menambahkan 107 atau kode NIK lainnya untuk prioritas NIK
  final List<String> _nikKrtPriorityCodes = ['107', 'NIK_KRT', 'NIK_KEPALA_KELUARGA', 'NIK'];

  // Kode fallback jika KRT/NIK tidak ditemukan untuk displayTitle umum
  final List<String> _generalNamePriorityCodes = ['NAMA_LENGKAP', 'NAMA_RESPONDEN', 'NAMA'];
  final List<String> _generalIdPriorityCodes = ['NIK', 'NO_KK', 'NOMOR_KK'];

  /// Menggabungkan status loading struktur dan data isian.
  bool get isLoading => isLoadingStructure.value || isLoadingSubmissions.value;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });

    // Melakukan proses filter ulang dengan debounce agar UI tetap responsif saat mengetik.
    debounce(searchQuery, (_) => _processSubmissionsForDisplay(), time: const Duration(milliseconds: 400));

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

  /// Menampilkan pesan error dan menghentikan status loading.
  void _setLoadingError(String message) {
    errorMessage.value = message;
    isLoadingStructure.value = false;
    isLoadingSubmissions.value = false;
    displayedSubmissions.clear(); // Pastikan list kosong jika ada error
  }

  /// Mengambil struktur formulir dari Firestore.
  Future<void> _fetchFormStructure() async {
    isLoadingStructure.value = true;
    errorMessage.value = ''; // Reset error message
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        formStructure.value = FormItem.fromFirestore(docSnapshot);
      } else {
        errorMessage.value = "Detail form tidak ditemukan.";
        formStructure.value = null;
      }
    } catch (e) {
      print("Error fetching form structure: $e");
      errorMessage.value = "Gagal memuat detail form: ${e.toString()}";
      formStructure.value = null;
    } finally {
      isLoadingStructure.value = false;
    }
  }

  /// Mengambil daftar isian milik petugas secara Hybrid (Firebase + Lokal).
  /// 
  /// Secara otomatis memicu fitur [Auto Duplicate] jika diaktifkan pada formulir ini.
  Future<void> _fetchSubmissions() async {
    final user = _auth.currentUser;
    if (formId.value.isEmpty || user == null) {
      isLoadingSubmissions.value = false;
      _originalSubmissions.clear();
      _processSubmissionsForDisplay();
      return;
    }
    isLoadingSubmissions.value = true;
    errorMessage.value = '';
    
    try {
      // 1. Ambil info Desa User untuk cek Local API
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final villageId = userDoc.data()?['villageId'] as String?;
      
      VillageModel? village;
      if (villageId != null) {
        final villageDoc = await _db.collection('villages').doc(villageId).get();
        if (villageDoc.exists) {
          village = VillageModel.fromFirestore(villageDoc);
        }
      }

      final bool useLocalApi = village?.serverType == 'local_api';
      List<FormSubmission> allSubmissions = [];

      if (useLocalApi) {
        // --- AMBIL DARI LAPTOP/SERVER DESA ---
        String baseUrl = village!.apiBaseUrl ?? "http://${village.localIpAddress}:${village.port}";
        if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        
        // Kirim parameter autoDuplicate ke server
        final bool shouldAutoDup = formStructure.value?.autoDuplicateMonthly ?? false;
        final url = Uri.parse('$baseUrl/api/submissions?formId=${formId.value}&userId=${user.uid}&autoDuplicate=$shouldAutoDup');
        
        final response = await http.get(url).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          List<dynamic> localData = jsonDecode(response.body);
          allSubmissions = localData.map((item) => FormSubmission.fromMap(item, item['id'])).toList();
        } else {
          errorMessage.value = "Server desa merespon dengan error (${response.statusCode})";
          debugPrint("Gagal ambil data dari server desa: ${response.statusCode}");
        }
      } else {
        // --- AMBIL DARI FIREBASE (DEFAULT) ---
        // Jalankan pengecekan duplikasi otomatis bulanan jika fitur aktif
        if (formStructure.value != null && formStructure.value!.autoDuplicateMonthly) {
          await _checkAndHandleAutoDuplicate();
        }

        final querySnapshot = await _db
            .collection('formSubmissions')
            .where('formId', isEqualTo: formId.value)
            .where('userId', isEqualTo: user.uid)
            .get(const GetOptions(source: Source.server));

        allSubmissions = querySnapshot.docs
            .map((doc) => FormSubmission.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      }

      _originalSubmissions.assignAll(allSubmissions);
      _processSubmissionsForDisplay();

    } catch (e, stack) {
      debugPrint("Error fetching submissions: $e\n$stack");
      if (e is TimeoutException) {
        errorMessage.value = "Koneksi ke server desa timeout (20 detik). Pastikan laptop admin aktif dan Anda terhubung ke WiFi yang sama.";
      } else if (e is SocketException) {
        errorMessage.value = "Tidak dapat terhubung ke server desa. Periksa koneksi WiFi atau alamat IP laptop admin.";
      } else {
        errorMessage.value = "Gagal memuat daftar isian: ${e.toString()}";
      }
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  /// Fungsi inti untuk menangani duplikasi data keluarga otomatis antar periode.
  /// 
  /// Alur kerja:
  /// 1. Mengecek data keluarga yang sudah ada di bulan sekarang.
  /// 2. Mengambil seluruh data keluarga dari bulan lalu.
  /// 3. Jika keluarga bulan lalu belum ada di bulan sekarang, buatkan salinan datanya (Deep Copy)
  ///    dengan status 'submitted' agar data historis tetap terjaga.
  Future<void> _checkAndHandleAutoDuplicate() async {
    final String uid = _auth.currentUser!.uid;
    final String currentPeriod = DateFormat('yyyy-MM').format(DateTime.now());
    final String previousPeriod = _getPreviousPeriod(currentPeriod);

    debugPrint('AutoDuplicate: Mengecek data $previousPeriod untuk diduplikat ke $currentPeriod');

    // 1. Ambil data bulan ini untuk melihat siapa yang sudah ada
    final currentSubmissionsSnap = await _db.collection('formSubmissions')
        .where('formId', isEqualTo: formId.value)
        .where('userId', isEqualTo: uid)
        .where('period', isEqualTo: currentPeriod)
        .get();

    final Set<String> existingFamilyKeys = currentSubmissionsSnap.docs.map((doc) {
      final sub = FormSubmission.fromFirestore(doc);
      return _getUniqueFamilyKey(sub);
    }).toSet();

    // 2. Ambil data bulan lalu
    final previousSubmissionsSnap = await _db.collection('formSubmissions')
        .where('formId', isEqualTo: formId.value)
        .where('userId', isEqualTo: uid)
        .where('period', isEqualTo: previousPeriod)
        .get();

    if (previousSubmissionsSnap.docs.isEmpty) return;

    final WriteBatch batch = _db.batch();
    int duplicateCount = 0;

    for (var doc in previousSubmissionsSnap.docs) {
      final prevSub = FormSubmission.fromFirestore(doc);
      final String familyKey = _getUniqueFamilyKey(prevSub);

      // Jika keluarga ini BELUM ada di bulan sekarang, buat duplikatnya
      if (!existingFamilyKeys.contains(familyKey)) {
        final DocumentReference newDocRef = _db.collection('formSubmissions').doc();
        
        // Buat objek submission baru (Deep Copy)
        final newSubmission = FormSubmission(
          id: newDocRef.id,
          formId: prevSub.formId,
          formTitle: prevSub.formTitle,
          userId: prevSub.userId,
          userName: prevSub.userName,
          period: currentPeriod,
          villageId: prevSub.villageId,
          villageName: prevSub.villageName,
          submittedAt: Timestamp.now(),
          createdAt: Timestamp.now(),
          answers: prevSub.answers, // Salin seluruh jawaban
          location: prevSub.location,
          latitude: prevSub.latitude,
          longitude: prevSub.longitude,
          locationAddress: prevSub.locationAddress,
          status: "submitted", // Langsung Submitted sesuai permintaan
          isAutoGenerated: true,
          duplicatedFromPeriod: previousPeriod,
          namaKepalaRumahTangga: prevSub.namaKepalaRumahTangga,
          displayTitle: prevSub.displayTitle,
          displayDescription: prevSub.displayDescription,
          computedSummary: prevSub.computedSummary,
        );

        batch.set(newDocRef, newSubmission.toFirestore());
        duplicateCount++;
      }
    }

    if (duplicateCount > 0) {
      await batch.commit();
      debugPrint('AutoDuplicate: Berhasil menduplikat $duplicateCount keluarga ke periode $currentPeriod');
    }
  }

  String _getPreviousPeriod(String currentPeriod) {
    final parts = currentPeriod.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    if (month == 1) {
      month = 12;
      year--;
    } else {
      month--;
    }
    return "$year-${month.toString().padLeft(2, '0')}";
  }

  /// Menghasilkan key unik untuk identifikasi keluarga berdasarkan NIK atau Nama KRT.
  String _getUniqueFamilyKey(FormSubmission sub) {
    // 1. Utamakan NIK jika ada
    String nik = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes);
    if (nik.isNotEmpty && nik != "1") return "NIK_$nik";

    // 2. Gunakan Nama Kepala Keluarga
    String name = sub.namaKepalaRumahTangga ?? _extractAnswerByPriority(sub.answers, ['106', 'NAMA_KEPALA_KELUARGA', '102']);
    if (name.isNotEmpty) return "NAME_${name.toLowerCase().trim()}";

    // 3. Fallback terakhir
    return "SUB_${sub.id}";
  }

  // Fungsi ini tetap berguna untuk mengekstrak field lain jika diperlukan,
  // namun untuk Nama KRT, kita akan utamakan field langsung dari model jika ada.
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

  /// Memproses data isian mentah menjadi objek [DisplayableSubmission] siap tampil.
  /// 
  /// Mencakup logika ekstraksi cerdas nama KRT/NIK untuk judul kartu serta filter pencarian lokal.
  void _processSubmissionsForDisplay() {
    List<DisplayableSubmission> processedList = [];
    for (var sub in _originalSubmissions) {
      String namaKRT = sub.namaKepalaRumahTangga ?? "";
      String nikKRT = _extractAnswerByPriority(sub.answers, _nikKrtPriorityCodes);

      String currentDisplayTitle = sub.displayTitle ?? "";
      String currentDisplayDescription = sub.displayDescription ?? "";

      if (currentDisplayTitle.isEmpty) {
        if (namaKRT.isNotEmpty) {
          currentDisplayTitle = namaKRT;
        } else {
          String generalName = _extractAnswerByPriority(sub.answers, _generalNamePriorityCodes);
          String generalId = _extractAnswerByPriority(sub.answers, _generalIdPriorityCodes);
          if (generalName.isNotEmpty) {
            currentDisplayTitle = generalName;
            if (generalId.isNotEmpty) currentDisplayTitle += " ($generalId)";
          } else if (generalId.isNotEmpty) {
            currentDisplayTitle = "ID: $generalId";
          } else {
            currentDisplayTitle = sub.formTitle;
          }
        }
      }

      if (searchQuery.value.isNotEmpty) {
        bool matchesSearch =
            currentDisplayTitle.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                currentDisplayDescription.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                (namaKRT.isNotEmpty && namaKRT.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
                (nikKRT.isNotEmpty && nikKRT.toLowerCase().contains(searchQuery.value.toLowerCase()));
        if (!matchesSearch) {
          continue;
        }
      }

      processedList.add(DisplayableSubmission(
        originalSubmission: sub,
        displayTitle: currentDisplayTitle,
        displayDescription: currentDisplayDescription,
        sortableNamePart: namaKRT.toLowerCase(),
        sortableIdPart: nikKRT.toLowerCase(),
        period: sub.period ?? 'N/A',
        status: sub.status,
        isLocked: sub.isLocked,
        namaKepalaKeluarga: namaKRT,
        nikKepalaKeluarga: nikKRT,
      ));
    }

    // Sorting
    if (currentSortOrder.value == 'Nama KRT A-Z') {
      processedList.sort((a, b) => a.sortableNamePart.compareTo(b.sortableNamePart));
    } else if (currentSortOrder.value == 'Nama KRT Z-A') {
      processedList.sort((a, b) => b.sortableNamePart.compareTo(a.sortableNamePart));
    } else if (currentSortOrder.value == 'Terlama') {
      processedList.sort((a,b) => a.originalSubmission.submittedAt.compareTo(b.originalSubmission.submittedAt));
    } else if (currentSortOrder.value == 'Terbaru'){ // Terbaru (default)
      processedList.sort((a,b) => b.originalSubmission.submittedAt.compareTo(a.originalSubmission.submittedAt));
    }
    // Jika submittedAt bisa null, tambahkan penanganan null di perbandingan

    displayedSubmissions.assignAll(processedList);
  }

  void changeSearchQuery(String query) {
    searchQuery.value = query;
    // debounce akan memanggil _processSubmissionsForDisplay
  }

  void changeSortOrder(String? newOrder) {
    if (newOrder != null && newOrder != currentSortOrder.value) {
      currentSortOrder.value = newOrder;
      // Jika sorting waktu, idealnya query ulang ke Firestore
      if (newOrder == 'Terbaru' || newOrder == 'Terlama') {
        _fetchSubmissions(); // Ini akan mengurutkan dari server dan memanggil _process lagi
      } else {
        _processSubmissionsForDisplay(); // Lakukan sorting di client untuk nama
      }
    }
  }

  /// Berpindah ke halaman input untuk menambahkan data isian baru yang kosong.
  void goToAddSubmission() {
    if (formId.value.isNotEmpty && formStructure.value != null) {
      // Gunakan arguments string (hanya formId) untuk memicu mode BUAT BARU yang bersih
      Get.toNamed(AppRoutes.inputFormUser, arguments: formId.value)?.then((result) {
        if (result == true || result == null) {
          refreshData();
        }
      });
    } else {
      Get.snackbar('Error', 'Tidak bisa membuat data baru, detail form belum termuat atau ID Form tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Berpindah ke halaman input dalam mode Edit untuk mengubah data isian yang sudah ada.
  void editSubmission(FormSubmission submission) {
    if (formId.value.isEmpty || submission.id == null || formStructure.value == null) {
      Get.snackbar('Error', 'Tidak bisa mengedit, detail form belum termuat atau ID tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.toNamed(
      AppRoutes.inputFormUser, // Pastikan ini adalah rute yang benar
      arguments: {
        'formId': formId.value,
        'submissionId': submission.id,
        'villageId': submission.villageId, // Tambahkan villageId agar lebih konsisten
      },
    )?.then((result) { // Tambahkan .then untuk refresh jika ada perubahan
      if (result == true || result == null) { // Anggap null atau true sebagai indikasi ada perubahan
        refreshData();
      }
    });
  }

  /// Menghapus data isian dari database (Firebase atau Server Lokal Desa) setelah konfirmasi.
  void deleteSubmission(FormSubmission submission, String displayIdentifier) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus data isian '$displayIdentifier'?"),
        actions: [
          TextButton(
            onPressed: () {
              // Menutup dialog dengan Navigator standar agar lebih stabil
              if (Get.context != null) {
                Navigator.of(Get.overlayContext ?? Get.context!).pop();
              } else {
                Get.back();
              }
            },
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // 1. Tutup dialog konfirmasi segera
              if (Get.context != null) {
                Navigator.of(Get.overlayContext ?? Get.context!).pop();
              } else {
                Get.back();
              }

              // 2. Gunakan loading overlay GetX yang stabil
              Get.showOverlay(
                asyncFunction: () async {
                  try {
                    // Cek apakah pakai Local API
                    final user = _auth.currentUser;
                    if (user == null) return;
                    
                    final userDoc = await _db.collection('users').doc(user.uid).get();
                    final villageId = userDoc.data()?['villageId'] as String?;
                    
                     VillageModel? village;
                    if (villageId != null) {
                      final villageDoc = await _db.collection('villages').doc(villageId).get();
                      if (villageDoc.exists) {
                        village = VillageModel.fromFirestore(villageDoc);
                      }
                    }

                    if (village?.serverType == 'local_api') {
                      // --- HAPUS DI LAPTOP ---
                      String baseUrl = village!.apiBaseUrl ?? "http://${village.localIpAddress}:${village.port}";
                      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
                      
                      final url = Uri.parse('$baseUrl/api/submissions/${submission.id}');
                      final response = await http.delete(url).timeout(const Duration(seconds: 10));
                      
                      if (response.statusCode != 200) {
                        throw "Gagal menghapus di server desa: ${response.statusCode}";
                      }
                    } else {
                      // --- HAPUS DI FIREBASE ---
                      await _db.collection('formSubmissions').doc(submission.id).delete();
                    }
                    
                    showSafeSnackbar(
                      title: 'Berhasil',
                      message: "Data '$displayIdentifier' telah dihapus.",
                      backgroundColor: Colors.green.shade600,
                      colorText: Colors.white,
                    );
                    
                    // Gunakan delay kecil agar snackbar muncul dulu sebelum list di-refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                    await _fetchSubmissions();
                  } catch (e) {
                    showSafeSnackbar(
                      title: 'Error', 
                      message: "Gagal menghapus data: $e", 
                      backgroundColor: Colors.red, 
                      colorText: Colors.white
                    );
                  }
                },
                loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Menyegarkan seluruh data (Struktur + Isian) secara manual.
  Future<void> refreshData() async {
    errorMessage.value = ''; // Selalu reset error message saat refresh
    if (formId.value.isNotEmpty) {
      // Set loading true sebelum await
      isLoadingStructure.value = true;
      isLoadingSubmissions.value = true;
      searchQuery.value = ''; // Kosongkan search query saat refresh

      // Panggil fetch secara berurutan atau paralel jika tidak saling ketergantungan untuk state awal
      await _fetchFormStructure(); // Tunggu struktur form selesai
      await _fetchSubmissions();   // Kemudian fetch submissions (yang akan memanggil _processSubmissionsForDisplay)
    } else {
      _setLoadingError("ID Form tidak valid untuk refresh.");
    }
  }
}