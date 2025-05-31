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
  final RxString userRole = ''.obs;       // Akan diupdate dari Firestore (role)
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

  // Dipanggil saat controller siap dan setelah widget tree selesai dibangun.
  // Ini adalah tempat yang baik untuk memanggil fetch data awal jika diperlukan
  // atau jika ada logika yang bergantung pada argumen navigasi.
  @override
  void onReady() {
    super.onReady();
    // Jika Anda ingin memastikan data selalu fresh saat halaman ini menjadi aktif lagi
    // Anda bisa mempertimbangkan untuk memanggil fetchFormData() di sini juga,
    // atau menggunakan mekanisme lain seperti WidgetsBindingObserver.
    // Untuk kasus refresh manual, perubahan di fetchFormData() sudah cukup.
  }

  Future<void> _initializeController() async {
    isLoading.value = true; // Set loading di awal

    // Ambil detail pengguna dari Firestore terlebih dahulu
    // Ini penting untuk memastikan userName terbaru sebelum mengambil data form
    // jika ada logika yang bergantung pada detail pengguna.
    await _fetchUserDetails();

    final arguments = Get.arguments;
    print("----------------------------------------------------");
    print("DEBUG UserController _initializeController: Menerima Get.arguments = $arguments");

    if (arguments != null && arguments is Map) {
      print("DEBUG UserController _initializeController: Argumen ADALAH Map. Memproses...");
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
      print("DEBUG UserController _initializeController: Argumen NULL atau bukan Map.");
      // userHasAuthority dan userProgramId akan tetap pada nilai default atau yang sudah di-set
      // userName sudah di-fetch oleh _fetchUserDetails()
    }

    print("DEBUG UserController _initializeController: State setelah argumen & fetch user: hasAuthority=${userHasAuthority.value}, programId='${userProgramId.value}', userName='${userName.value}', userRole='${userRole.value}'");
    print("----------------------------------------------------");

    // Panggil fetchFormData yang sekarang juga akan me-refresh user details (jika diperlukan)
    // isLoading.value akan di-set false di akhir fetchFormData
    await fetchFormData();
  }

  Future<void> _fetchUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        print("DEBUG UserController _fetchUserDetails: Mencoba mengambil detail pengguna UID: ${currentUser.uid} dari koleksi 'users'.");
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
          userRole.value = data['role'] as String? ?? '';
          print("DEBUG UserController _fetchUserDetails: Sukses. userName diatur ke '${userName.value}', userRole diatur ke '${userRole.value}'.");
        } else {
          print("DEBUG UserController _fetchUserDetails: Dokumen pengguna tidak ditemukan. Menggunakan fallback dari Auth.");
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
        print('ERROR UserController _fetchUserDetails: $e');
        print('Stack trace: $s');
        userName.value = currentUser.displayName ?? currentUser.email ?? 'Pengguna'; // Fallback
        userRole.value = ''; // Reset role
      }
    } else {
      print("DEBUG UserController _fetchUserDetails: Tidak ada pengguna yang login.");
      userName.value = 'Pengguna';
      userRole.value = '';
      userHasAuthority.value = false; // Jika tidak ada user, tidak ada authority
    }
  }

  Future<void> fetchFormData() async {
    isLoading.value = true; // Set loading di awal setiap fetch
    print("DEBUG UserController fetchFormData: Memulai.");

    // **PERUBAHAN KUNCI: Panggil _fetchUserDetails di sini**
    // Ini memastikan detail pengguna (termasuk username) selalu terbaru saat refresh.
    await _fetchUserDetails();
    print("DEBUG UserController fetchFormData: Detail pengguna di-refresh. userName='${userName.value}', userRole='${userRole.value}', hasAuthority awal=${userHasAuthority.value}");


    User? currentUser = _auth.currentUser;
    List<FormDataModel> newFormsToDisplay = [];

    try {
      if (currentUser == null) {
        print("DEBUG UserController fetchFormData: Pengguna tidak login. Mengosongkan form.");
        formDataList.clear();
        userHasAuthority.value = false; // Pastikan authority false jika tidak ada user
        // isLoading.value akan di-set false di finally
        return;
      }

      // Cek otoritas berdasarkan role dari Firestore (userRole.value)
      // Jika userRole adalah 'adminGlobal' (atau nama role admin Anda), maka userHasAuthority = true
      // Ini lebih aman daripada bergantung pada argumen navigasi saja.
      if (userRole.value.toLowerCase() == 'adminglobal' || userRole.value.toLowerCase() == 'admin') { // Sesuaikan dengan nama role admin Anda
        userHasAuthority.value = true;
        print("DEBUG UserController fetchFormData: User teridentifikasi sebagai Admin Global berdasarkan role '${userRole.value}'.");
      } else {
        // Jika bukan admin global, defaultnya tidak memiliki otoritas global.
        // Otoritas spesifik per form akan dicek di bawah.
        userHasAuthority.value = false; // Set ke false jika bukan admin dari role
        print("DEBUG UserController fetchFormData: User BUKAN Admin Global berdasarkan role '${userRole.value}'.");
      }


      if (userHasAuthority.value) {
        print("DEBUG UserController fetchFormData: Pengguna adalah Admin Global. Mengambil semua dari 'adminForms'.");
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        newFormsToDisplay = adminFormsSnapshot.docs.map((doc) {
          return FormDataModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        print("DEBUG UserController fetchFormData: Admin Global - Ditemukan ${newFormsToDisplay.length} form.");
      } else {
        // Pengguna biasa atau admin dengan akses terbatas
        String currentUserId = currentUser.uid;
        print("DEBUG UserController fetchFormData: Pengguna biasa (ID: $currentUserId) atau admin terbatas. Memeriksa managedAccounts...");
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
        print("DEBUG UserController fetchFormData: Pengguna Biasa/Terbatas - Total ${newFormsToDisplay.length} form diotorisasi.");
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

  void logout() async {
    print("DEBUG UserController: Proses logout pengguna.");
    try {
      await _auth.signOut(); // Lakukan sign out

      // Reset semua state ke nilai awal
      userHasAuthority.value = false;
      userProgramId.value = '';
      userName.value = 'Pengguna'; // Reset ke default
      userRole.value = '';       // Reset ke default
      formDataList.clear();
      currentSortOrder.value = 'Default';
      searchQuery.value = ''; // Reset query pencarian saat logout
      isLoading.value = false; // Tidak perlu loading true karena langsung redirect

      // Arahkan ke halaman login. Menggunakan offAllNamed untuk membersihkan stack navigasi.
      Get.offAllNamed(AppRoutes.login);
      print("DEBUG UserController: Logout berhasil, navigasi ke ${AppRoutes.login}.");
    } catch (e) {
      print("DEBUG UserController: Error saat logout - $e");
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
      userName.value = 'Pengguna';
      userRole.value = '';
      formDataList.clear();
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}