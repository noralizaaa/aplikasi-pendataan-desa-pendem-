// lib/presentation/user/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Hanya untuk Colors pada Get.snackbar jika diperlukan
import 'user_model.dart'; // Pastikan model ini memiliki field 'nama' (String) dan 'createdAt' (DateTime?)
// Pastikan Anda memiliki definisi AppRoutes atau ganti dengan string rute langsung
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Sesuaikan dengan path Anda

class UserController extends GetxController {
  // Data & State Utama
  final RxList<FormDataModel> formDataList = <FormDataModel>[].obs; // Daftar asli dari Firestore
  final RxBool isLoading = true.obs;

  // Detail Pengguna & Otorisasi
  final RxBool userHasAuthority = false.obs;
  final RxString userName = 'Pengguna'.obs; // Akan diupdate dari Firestore (username/displayName)
  final RxString userRole = ''.obs;         // Akan diupdate dari Firestore (role)
  final RxString userProgramId = ''.obs;

  // Pengurutan
  final RxString currentSortOrder = 'Default'.obs;
  final List<String> sortOptions = ['Default', 'Nama A-Z', 'Terbaru'];

  // Pencarian
  final RxString searchQuery = ''.obs; // Variabel untuk query pencarian

  // Instance Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter untuk daftar yang sudah difilter dan diurutkan
  RxList<FormDataModel> get sortedFormDataList {
    List<FormDataModel> listToProcess;

    // 1. Filter berdasarkan searchQuery
    if (searchQuery.value.isEmpty) {
      listToProcess = List<FormDataModel>.from(formDataList);
    } else {
      String lowerCaseQuery = searchQuery.value.toLowerCase();
      listToProcess = formDataList.where((form) {
        // Cari di field 'nama'. Tambahkan field lain jika perlu.
        // Pastikan 'nama' tidak null sebelum memanggil toLowerCase()
        return form.nama.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // 2. Urutkan daftar yang sudah difilter
    // Buat salinan untuk diurutkan agar tidak memodifikasi listToProcess secara langsung jika tidak perlu
    List<FormDataModel> sortedList = List<FormDataModel>.from(listToProcess);
    switch (currentSortOrder.value) {
      case 'Nama A-Z':
        sortedList.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        break;
      case 'Terbaru':
        sortedList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1; // nulls last (atau -1 jika ingin nulls first)
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!); // Terbaru duluan
        });
        break;
      default: // 'Default' order
      // Tidak ada pengurutan tambahan, menggunakan urutan setelah filter
        break;
    }
    return sortedList.obs;
  }

  // Method untuk mengubah urutan
  void changeSortOrder(String? newOrder) {
    if (newOrder != null && sortOptions.contains(newOrder)) {
      currentSortOrder.value = newOrder;
    }
  }

  // Method untuk memperbarui query pencarian
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  Future<void> _initializeController() async {
    isLoading.value = true;

    await _fetchUserDetails(); // Ambil detail pengguna dari Firestore terlebih dahulu

    final arguments = Get.arguments;
    print("----------------------------------------------------");
    print("DEBUG UserController _initializeController: Menerima Get.arguments = $arguments");

    if (arguments != null && arguments is Map) {
      print("DEBUG UserController _initializeController: Argumen ADALAH Map. Memproses...");
      userHasAuthority.value = arguments['hasAuthority'] as bool? ?? false;

      // Update userName dari argumen HANYA jika masih bernilai default/kosong
      // Ini menghargai kondisi "jika belum ada" (jika belum diambil dari Firestore)
      if (userName.value == 'Pengguna' || userName.value.isEmpty) {
        userName.value = arguments['userName']?.toString() ??
            _auth.currentUser?.displayName ?? // Fallback jika argumen tidak ada
            _auth.currentUser?.email ??
            'Pengguna';
      }
      // Catatan: userRole diatur utamanya oleh _fetchUserDetails.
      // Jika argumen juga bisa mengatur role, logika serupa akan diperlukan.

      String? programIdArg = arguments['programId']?.toString();
      if (programIdArg == "null" || programIdArg == null) {
        userProgramId.value = '';
        print("DEBUG UserController _initializeController: Argumen programId adalah '$programIdArg', diinterpretasikan sebagai kosong.");
      } else {
        userProgramId.value = programIdArg;
      }
    } else {
      print("DEBUG UserController _initializeController: Argumen NULL atau bukan Map.");
      userHasAuthority.value = false; // Default jika tidak ada argumen
      // Jika userName masih default setelah pengambilan dari Firestore dan tidak ada argumen
      if (userName.value == 'Pengguna' || userName.value.isEmpty) {
        userName.value = _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Pengguna';
      }
      userProgramId.value = '';
    }

    print("DEBUG UserController _initializeController: State setelah argumen: hasAuthority=${userHasAuthority.value}, programId='${userProgramId.value}', userName='${userName.value}', userRole='${userRole.value}'");
    print("----------------------------------------------------");

    await fetchFormData(); // isLoading.value akan di-set false di akhir fetchFormData
  }

  // METHOD YANG DIMODIFIKASI untuk mengambil username dan role
  Future<void> _fetchUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        print("DEBUG UserController _fetchUserDetails: Mencoba mengambil detail pengguna UID: ${currentUser.uid} dari koleksi 'users'.");
        // ASUMSI: koleksi untuk detail pengguna adalah 'users' sesuai contoh Firestore Anda
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          // Ambil username:
          // 1. Prioritaskan field 'username' dari Firestore.
          // 2. Fallback ke field 'displayName' dari Firestore.
          // 3. Fallback ke currentUser.displayName dari Firebase Auth.
          // 4. Fallback ke currentUser.email dari Firebase Auth.
          // 5. Fallback ke 'Pengguna' jika semua di atas null/kosong.
          String? firestoreUsername = data['username'] as String?;
          String? firestoreDisplayName = data['displayName'] as String?;

          if (firestoreUsername != null && firestoreUsername.isNotEmpty) {
            userName.value = firestoreUsername;
          } else if (firestoreDisplayName != null && firestoreDisplayName.isNotEmpty) {
            userName.value = firestoreDisplayName;
          } else {
            // Fallback ke properti Auth jika field Firestore tidak ada/kosong
            userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
          }

          // Ambil role:
          // Prioritaskan field 'role' dari Firestore. Default ke string kosong jika tidak ada.
          userRole.value = data['role'] as String? ?? '';

          print("DEBUG UserController _fetchUserDetails: Sukses. userName diatur ke '${userName.value}', userRole diatur ke '${userRole.value}'.");
        } else {
          print("DEBUG UserController _fetchUserDetails: Dokumen pengguna tidak ditemukan di Firestore untuk UID: ${currentUser.uid}. Menggunakan fallback dari Auth.");
          // Jika dokumen Firestore tidak ada, gunakan info dari Firebase Auth.
          userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
          userRole.value = ''; // Tidak ada role jika dokumen tidak ada.
        }
      } catch (e, s) {
        Get.snackbar(
          'Error Profil Pengguna',
          'Gagal mengambil detail pengguna dari Firestore: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        print('ERROR UserController _fetchUserDetails: $e');
        print('Stack trace: $s');
        // Jika terjadi error, gunakan info dari Firebase Auth sebagai fallback.
        userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
        userRole.value = ''; // Reset role jika error.
      }
    } else {
      print("DEBUG UserController _fetchUserDetails: Tidak ada pengguna yang login. Tidak dapat mengambil detail.");
      userName.value = 'Pengguna'; // Default jika tidak ada user.
      userRole.value = '';
    }
  }

  Future<void> fetchFormData() async {
    // isLoading.value sudah true dari _initializeController
    print("DEBUG UserController fetchFormData: Memulai. hasAuthority awal=${userHasAuthority.value}");
    User? currentUser = _auth.currentUser;
    List<FormDataModel> newFormsToDisplay = [];

    try {
      if (userHasAuthority.value) {
        print("DEBUG UserController fetchFormData: Pengguna adalah Admin Global. Mengambil semua dari 'adminForms'.");
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        newFormsToDisplay = adminFormsSnapshot.docs.map((doc) {
          return FormDataModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        print("DEBUG UserController fetchFormData: Admin Global - Ditemukan ${newFormsToDisplay.length} form.");
      } else if (currentUser != null) {
        String currentUserId = currentUser.uid;
        print("DEBUG UserController fetchFormData: Pengguna biasa (ID: $currentUserId). Memeriksa managedAccounts...");
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        print("DEBUG UserController fetchFormData: Ditemukan ${adminFormsSnapshot.docs.length} dokumen di adminForms untuk diperiksa.");

        for (var formAdminDoc in adminFormsSnapshot.docs) {
          DocumentSnapshot managedAccountDoc = await _firestore
              .collection('adminForms')
              .doc(formAdminDoc.id)
              .collection('managedAccounts')
              .doc(currentUserId)
              .get();

          if (managedAccountDoc.exists) {
            print("DEBUG UserController fetchFormData: Pengguna diotorisasi untuk formId '${formAdminDoc.id}'.");
            newFormsToDisplay.add(
                FormDataModel.fromMap(formAdminDoc.data() as Map<String, dynamic>, formAdminDoc.id)
            );
          } else {
            print("DEBUG UserController fetchFormData: Pengguna TIDAK diotorisasi untuk formId '${formAdminDoc.id}'.");
          }
        }
        print("DEBUG UserController fetchFormData: Pengguna Biasa - Total ${newFormsToDisplay.length} form diotorisasi.");
      } else {
        print("DEBUG UserController fetchFormData: Pengguna tidak login. Tidak ada form yang diambil.");
      }
      formDataList.assignAll(newFormsToDisplay);
    } catch (e, s) {
      Get.snackbar(
        'Error Pengambilan Data Form',
        'Gagal mengambil data form: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print('ERROR UserController fetchFormData: $e');
      print('Stack trace: $s');
      formDataList.clear();
    } finally {
      isLoading.value = false;
      print("DEBUG UserController fetchFormData: Selesai. isLoading: ${isLoading.value}. Jumlah form di list: ${formDataList.length}");
    }
  }

  void logout() {
    print("DEBUG UserController: Proses logout pengguna.");
    _auth.signOut(); // Lakukan sign out dulu

    // Reset semua state ke nilai awal
    userHasAuthority.value = false;
    userProgramId.value = '';
    userName.value = 'Pengguna'; // Reset ke default
    userRole.value = '';       // Reset ke default
    formDataList.clear();
    currentSortOrder.value = 'Default';
    searchQuery.value = ''; // Reset query pencarian saat logout
    isLoading.value = true; // Set isLoading true karena halaman berikutnya mungkin butuh loading

    Get.offAllNamed(AppRoutes.login);
  }
}