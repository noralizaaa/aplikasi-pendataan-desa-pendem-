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
  final RxString userName = 'Pengguna'.obs; // Akan diupdate dari Firestore displayName
  final RxString userRole = ''.obs;
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
        // Contoh jika ingin mencari di field lain juga (misal 'deskripsi'):
        // return form.nama.toLowerCase().contains(lowerCaseQuery) ||
        //        (form.deskripsi?.toLowerCase().contains(lowerCaseQuery) ?? false);
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

    await _fetchUserDetails();

    final arguments = Get.arguments;
    print("----------------------------------------------------");
    print("DEBUG UserController _initializeController: Menerima Get.arguments = $arguments");

    if (arguments != null && arguments is Map) {
      print("DEBUG UserController _initializeController: Argumen ADALAH Map. Memproses...");
      userHasAuthority.value = arguments['hasAuthority'] as bool? ?? false;
      if (userName.value == 'Pengguna' || userName.value.isEmpty) {
        userName.value = arguments['userName']?.toString() ??
            _auth.currentUser?.displayName ??
            _auth.currentUser?.email ??
            'Pengguna';
      }
      String? programIdArg = arguments['programId']?.toString();
      if (programIdArg == "null" || programIdArg == null) {
        userProgramId.value = '';
        print("DEBUG UserController _initializeController: Argumen programId adalah '$programIdArg', diinterpretasikan sebagai kosong.");
      } else {
        userProgramId.value = programIdArg;
      }
    } else {
      print("DEBUG UserController _initializeController: Argumen NULL atau bukan Map.");
      userHasAuthority.value = false;
      if (userName.value == 'Pengguna' || userName.value.isEmpty) {
        userName.value = _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Pengguna';
      }
      userProgramId.value = '';
    }

    print("DEBUG UserController _initializeController: State setelah argumen: hasAuthority=${userHasAuthority.value}, programId='${userProgramId.value}', userName='${userName.value}', userRole='${userRole.value}'");
    print("----------------------------------------------------");

    await fetchFormData(); // isLoading.value akan di-set false di akhir fetchFormData
  }

  Future<void> _fetchUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        print("DEBUG UserController _fetchUserDetails: Mencoba mengambil detail pengguna UID: ${currentUser.uid}");
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get(); // ASUMSI: koleksi 'users'

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          userName.value = data['displayName'] as String? ?? userName.value;
          userRole.value = data['role'] as String? ?? '';
          print("DEBUG UserController _fetchUserDetails: Sukses. displayName: ${userName.value}, role: ${userRole.value}");
        } else {
          print("DEBUG UserController _fetchUserDetails: Dokumen pengguna tidak ditemukan di Firestore untuk UID: ${currentUser.uid}. Menggunakan fallback.");
          userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
          userRole.value = '';
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
        userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna';
        userRole.value = '';
      }
    } else {
      print("DEBUG UserController _fetchUserDetails: Tidak ada pengguna yang login. Tidak dapat mengambil detail.");
      userName.value = 'Pengguna';
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
    userName.value = 'Pengguna';
    userRole.value = '';
    formDataList.clear();
    currentSortOrder.value = 'Default';
    searchQuery.value = ''; // Reset query pencarian saat logout
    isLoading.value = true; // Set isLoading true karena halaman berikutnya mungkin butuh loading

    Get.offAllNamed(AppRoutes.login);
  }
}