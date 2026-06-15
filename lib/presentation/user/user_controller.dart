// lib/presentation/user/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Hanya untuk Colors pada Get.snackbar jika diperlukan
import '../../domain/auth/models/user_model.dart';
import 'user_model.dart'; // Pastikan model ini memiliki field 'nama' (String) dan 'createdAt' (DateTime?)
// Pastikan Anda memiliki definisi AppRoutes atau ganti dengan string rute langsung
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Sesuaikan dengan path Anda

/// [UserController] mengelola state dan logika untuk halaman utama level Pengguna (Petugas).
/// 
/// Controller ini bertanggung jawab untuk:
/// 1. Mengelola profil ringkas petugas dan identitas wilayah tugas (Desa).
/// 2. Mengambil daftar formulir yang diperbolehkan diakses oleh petugas tersebut.
/// 3. Menangani fitur pencarian dan pengurutan daftar formulir.
/// 4. Menyediakan fitur logout yang aman.
class UserController extends GetxController {
  // --- Data & State Utama ---
  /// Daftar asli formulir (FormDataModel) yang dimuat dari Firestore.
  final RxList<FormDataModel> formDataList = <FormDataModel>[].obs; 
  /// Menandakan status pemuatan data sedang berlangsung.
  final RxBool isLoading = true.obs;

  // --- Detail Pengguna & Otorisasi ---
  /// Menandakan apakah pengguna memiliki otoritas administratif global (Admin).
  final RxBool userHasAuthority = false.obs;
  /// Nama pengguna yang ditampilkan di UI.
  final RxString userName = 'Pengguna'.obs; 
  /// Peran pengguna (misal: 'user', 'petugas', 'admin_desa').
  final RxString userRole = ''.obs;       
  /// ID Desa tempat pengguna bertugas.
  final RxString userVillageId = ''.obs;  
  /// ID Program atau kategori tugas pengguna.
  final RxString userProgramId = ''.obs;

  // --- Fitur Pengurutan ---
  /// Kriteria pengurutan aktif.
  final RxString currentSortOrder = 'Default'.obs;
  /// Pilihan opsi pengurutan yang tersedia.
  final List<String> sortOptions = ['Default', 'Nama A-Z', 'Terbaru'];

  // --- Fitur Pencarian ---
  /// Kata kunci pencarian judul formulir.
  final RxString searchQuery = ''.obs; 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Menampilkan snackbar yang aman dari kendala konteks (context) atau overlay null.
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

  /// Getter reaktif untuk mendapatkan daftar formulir yang sudah melewati 
  /// proses penyaringan (search) dan pengurutan (sort).
  RxList<FormDataModel> get sortedFormDataList {
    List<FormDataModel> listToProcess;

    // 1. Filter berdasarkan searchQuery
    if (searchQuery.value.isEmpty) {
      listToProcess = List<FormDataModel>.from(formDataList);
    } else {
      String lowerCaseQuery = searchQuery.value.toLowerCase();
      listToProcess = formDataList.where((form) {
        return form.nama.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // 2. Urutkan daftar yang sudah difilter
    List<FormDataModel> sortedList = List<FormDataModel>.from(listToProcess);
    switch (currentSortOrder.value) {
      case 'Nama A-Z':
        sortedList.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        break;
      case 'Terbaru':
        sortedList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!); // Terbaru duluan
        });
        break;
      default: // 'Default' order
        break;
    }
    return sortedList.obs;
  }

  /// Mengubah kriteria pengurutan daftar formulir.
  void changeSortOrder(String? newOrder) {
    if (newOrder != null && sortOptions.contains(newOrder)) {
      currentSortOrder.value = newOrder;
    }
  }

  /// Memperbarui kata kunci pencarian.
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Inisialisasi controller: Memuat detail user, memproses argumen, dan mengambil data form.
  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  Future<void> _initializeController() async {
    isLoading.value = true; // Set loading di awal

    // Ambil detail pengguna dari Firestore terlebih dahulu
    // Ini penting untuk memastikan userName terbaru sebelum mengambil data form
    // jika ada logika yang bergantung pada detail pengguna.
    await _fetchUserDetails();

    final arguments = Get.arguments;
    debugPrint("----------------------------------------------------");
    debugPrint("DEBUG UserController _initializeController: Menerima Get.arguments = $arguments");

    if (arguments != null && arguments is Map) {
      debugPrint("DEBUG UserController _initializeController: Argumen ADALAH Map. Memproses...");
      userHasAuthority.value = arguments['hasAuthority'] as bool? ?? userHasAuthority.value; // Pertahankan nilai jika sudah ada

      // userName sudah di-fetch oleh _fetchUserDetails, jadi argumen bisa menjadi fallback
      // atau tidak digunakan sama sekali untuk userName di sini.
      // Jika Anda ingin argumen tetap bisa mengoverride, uncomment baris di bawah
      // if (arguments['userName'] != null) {
      // userName.value = arguments['userName'].toString();
      // }

      String? programIdArg = arguments['programId']?.toString();
      if (programIdArg == "null" || programIdArg == null) {
        userProgramId.value = '';
      } else {
        userProgramId.value = programIdArg;
      }
    } else {
      debugPrint("DEBUG UserController _initializeController: Argumen NULL atau bukan Map.");
      // userHasAuthority dan userProgramId akan tetap pada nilai default atau yang sudah di-set
      // userName sudah di-fetch oleh _fetchUserDetails()
    }

    debugPrint("DEBUG UserController _initializeController: State setelah argumen & fetch user: hasAuthority=${userHasAuthority.value}, programId='${userProgramId.value}', userName='${userName.value}', userRole='${userRole.value}'");
    debugPrint("----------------------------------------------------");

    // Panggil fetchFormData yang sekarang juga akan me-refresh user details (jika diperlukan)
    // isLoading.value akan di-set false di akhir fetchFormData
    await fetchFormData();
  }

  /// Fungsi internal untuk memuat informasi profil pengguna dari Firestore.
  /// 
  /// Mendeteksi nama tampilan (username/displayName), peran (role), dan desa asal.
  Future<void> _fetchUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        debugPrint("DEBUG UserController _fetchUserDetails: Mencoba mengambil detail pengguna UID: ${currentUser.uid} dari koleksi 'users'.");
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          String? firestoreUsername = data['username'] as String?;
          String? firestoreDisplayName = data['displayName'] as String?;

          if (firestoreUsername != null && firestoreUsername.isNotEmpty) {
            userName.value = firestoreUsername;
          } else if (firestoreDisplayName != null && firestoreDisplayName.isNotEmpty) {
            userName.value = firestoreDisplayName;
          } else {
            userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
          }
          userRole.value = (data['role'] as String? ?? '').toLowerCase().trim();

          userVillageId.value = data['villageId'] as String? ?? '';
          debugPrint("DEBUG UserController _fetchUserDetails: Sukses. userName diatur ke '${userName.value}', userRole diatur ke '${userRole.value}', userVillageId diatur ke '${userVillageId.value}'.");
        } else {
          debugPrint("DEBUG UserController _fetchUserDetails: Dokumen pengguna tidak ditemukan. Menggunakan fallback dari Auth.");
          userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
          userRole.value = '';
        }
      } catch (e, s) {
        Get.snackbar(
          'Error Profil Pengguna',
          'Gagal mengambil detail pengguna: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        debugPrint('ERROR UserController _fetchUserDetails: $e');
        debugPrint('Stack trace: $s');
        userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna'; // Fallback
        userRole.value = ''; // Reset role
      }
    } else {
      debugPrint("DEBUG UserController _fetchUserDetails: Tidak ada pengguna yang login.");
      userName.value = 'Pengguna';
      userRole.value = '';
      userHasAuthority.value = false; // Jika tidak ada user, tidak ada authority
    }
  }

  /// Mengambil daftar formulir dari Firestore berdasarkan hak akses pengguna.
  /// 
  /// Logika Akses:
  /// 1. Admin Global: Melihat seluruh formulir di 'adminForms'.
  /// 2. Akses Terkelola: Melihat formulir yang secara spesifik diberikan via subkoleksi 'managedAccounts'.
  /// 3. Akses Desa: Melihat formulir yang memiliki ID Desa yang sama dengan user.
  Future<void> fetchFormData() async {
    isLoading.value = true; // Set loading di awal setiap fetch
    debugPrint("DEBUG UserController fetchFormData: Memulai.");

    await _fetchUserDetails();

    debugPrint("DEBUG UserController fetchFormData: Detail pengguna di-refresh. userName='${userName.value}', userRole='${userRole.value}', hasAuthority awal=${userHasAuthority.value}");


    User? currentUser = _auth.currentUser;
    List<FormDataModel> newFormsToDisplay = [];

    try {
      if (currentUser == null) {
        debugPrint("DEBUG UserController fetchFormData: Pengguna tidak login. Mengosongkan form.");
        formDataList.clear();
        userHasAuthority.value = false; // Pastikan authority false jika tidak ada user
        // isLoading.value akan di-set false di finally
        return;
      }

      // Cek otoritas menggunakan helper terpusat
      final userModel = UserModel(uid: '', role: userRole.value);

      if (userModel.isGlobalAdmin) {
        userHasAuthority.value = true;
        debugPrint("DEBUG UserController fetchFormData: User teridentifikasi sebagai Admin Global berdasarkan role '${userRole.value}'.");
      } else {
        // Jika bukan admin global (misal: admin_desa atau admin_rt), 
        // defaultnya tidak memiliki otoritas global (melihat semua form).
        // Otoritas spesifik per form akan dicek di bawah berdasarkan villageId.
        userHasAuthority.value = false;
        debugPrint("DEBUG UserController fetchFormData: User BUKAN Admin Global berdasarkan role '${userRole.value}'.");
      }


      if (userHasAuthority.value) {
        debugPrint("DEBUG UserController fetchFormData: Pengguna adalah Admin Global. Mengambil semua dari 'adminForms'.");
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        newFormsToDisplay = adminFormsSnapshot.docs.map((doc) {
          return FormDataModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        debugPrint("DEBUG UserController fetchFormData: Admin Global - Ditemukan ${newFormsToDisplay.length} form.");
      } else {
        // Logika untuk Admin Desa dan Pengguna Biasa
        debugPrint("DEBUG UserController fetchFormData: Memeriksa akses untuk role '${userRole.value}' (VillageId: ${userVillageId.value}).");
        
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        
        for (var formAdminDoc in adminFormsSnapshot.docs) {
          Map<String, dynamic> formData = formAdminDoc.data() as Map<String, dynamic>;
          String? formVillageId = formData['villageId'] as String?;
          bool isGeneralForm = formVillageId == null || formVillageId.isEmpty;

          // 1. Cek Otoritas Spesifik (managedAccounts) - Berlaku untuk SEMUA role (User & Admin Desa)
          // Ini mencakup Form Umum yang diijinkan dan akses lintas desa
          bool hasManagedAccess = false;
          try {
            DocumentSnapshot managedAccountDoc = await _firestore
                .collection('adminForms')
                .doc(formAdminDoc.id)
                .collection('managedAccounts')
                .doc(currentUser.uid)
                .get();
            hasManagedAccess = managedAccountDoc.exists;
          } catch (accessError) {
            // Jika permission-denied, abaikan saja dan anggap tidak punya akses via managedAccounts
            debugPrint("DEBUG UserController fetchFormData: Skip managedAccounts check for ${formAdminDoc.id} due to: $accessError");
          }

          if (hasManagedAccess) {
            debugPrint("DEBUG UserController fetchFormData: Akses DIIJINKAN via managedAccounts untuk formId '${formAdminDoc.id}'.");
            newFormsToDisplay.add(FormDataModel.fromMap(formData, formAdminDoc.id));
            continue; // Sudah dapat akses, lanjut ke form berikutnya
          }

          // 2. Cek Akses Otomatis Berdasarkan Desa (VillageId)
          // Sekarang berlaku untuk Admin Desa, Admin Monitoring, DAN User biasa dalam desa yang sama
          if (userModel.isAdmin || userRole.value == 'user' || userRole.value == 'petugas') {
            bool hasVillageMatch = !isGeneralForm && formVillageId == userVillageId.value;
            
            if (hasVillageMatch) {
              debugPrint("DEBUG UserController fetchFormData: Akses OTOMATIS (Satu Desa) untuk formId '${formAdminDoc.id}'.");
              newFormsToDisplay.add(FormDataModel.fromMap(formData, formAdminDoc.id));
              continue;
            }
          }
          
          debugPrint("DEBUG UserController fetchFormData: TIDAK ada akses untuk formId '${formAdminDoc.id}'.");
        }
        debugPrint("DEBUG UserController fetchFormData: Selesai memproses. Total ${newFormsToDisplay.length} form ditemukan.");
      }
      formDataList.assignAll(newFormsToDisplay);
    } catch (e, s) {
      showSafeSnackbar(
        title: 'Error Pengambilan Data Form',
        message: 'Gagal mengambil data form: ${e.toString()}',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      debugPrint('ERROR UserController fetchFormData: $e');
      debugPrint('Stack trace: $s');
      formDataList.clear();
    } finally {
      isLoading.value = false;
      debugPrint("DEBUG UserController fetchFormData: Selesai. isLoading: ${isLoading.value}. Jumlah form di list: ${formDataList.length}");
    }
  }

  /// Menangani proses keluar log (logout) pengguna.
  /// 
  /// Menghapus sesi, mereset seluruh state controller, dan mengalihkan ke halaman login.
  void logout() async {
    debugPrint("DEBUG UserController: Proses logout pengguna.");
    try {
      await _auth.signOut(); // Lakukan sign out

      // Reset semua state ke nilai awal
      userHasAuthority.value = false;
      userProgramId.value = '';
      userVillageId.value = '';
      userName.value = 'Pengguna'; // Reset ke default
      userRole.value = '';       // Reset ke default
      formDataList.clear();
      currentSortOrder.value = 'Default';
      searchQuery.value = ''; // Reset query pencarian saat logout
      isLoading.value = false; // Tidak perlu loading true karena langsung redirect

      // Arahkan ke halaman login. Menggunakan offAllNamed untuk membersihkan stack navigasi.
      Get.offAllNamed(AppRoutes.login);
      debugPrint("DEBUG UserController: Logout berhasil, navigasi ke ${AppRoutes.login}.");
    } catch (e) {
      debugPrint("DEBUG UserController: Error saat logout - $e");
      Get.snackbar(
        'Error Logout',
        'Gagal melakukan logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      // Meskipun error, coba reset state dan arahkan ke login
      userHasAuthority.value = false;
      userProgramId.value = '';
      userVillageId.value = '';
      userName.value = 'Pengguna';
      userRole.value = '';
      formDataList.clear();
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}