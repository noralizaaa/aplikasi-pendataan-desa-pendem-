// lib/presentation/user/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Hanya untuk Colors pada Get.snackbar jika diperlukan
import 'user_model.dart';
// Pastikan Anda memiliki definisi AppRoutes atau ganti dengan string rute langsung
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

class UserController extends GetxController {
  final RxList<FormDataModel> formDataList = <FormDataModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool userHasAuthority = false.obs; // Default krusial ke false
  final RxString userName = 'Pengguna'.obs;
  final RxString userProgramId = ''.obs; // Default krusial ke string kosong

  final RxString currentSortOrder = 'Default'.obs;
  final List<String> sortOptions = ['Default', 'Nama A-Z', 'Terbaru'];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<FormDataModel> get sortedFormDataList {
    List<FormDataModel> listToSort = List<FormDataModel>.from(formDataList);
    switch (currentSortOrder.value) {
      case 'Nama A-Z':
        listToSort.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        break;
      case 'Terbaru':
        listToSort.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      default:
        break;
    }
    return listToSort.obs;
  }

  void changeSortOrder(String? newOrder) {
    if (newOrder != null && sortOptions.contains(newOrder)) {
      currentSortOrder.value = newOrder;
    }
  }

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;
    // --- BLOK DEBUG ARGUMEN (PENTING!) ---
    print("----------------------------------------------------");
    print("DEBUG UserController onInit: Menerima Get.arguments = $arguments");
    if (arguments == null) {
      print("DEBUG UserController onInit: Get.arguments adalah NULL!");
    } else if (arguments is! Map) {
      print("DEBUG UserController onInit: Get.arguments BUKAN Map! Tipe: ${arguments.runtimeType}");
    }
    // --- AKHIR BLOK DEBUG ---

    if (arguments != null && arguments is Map) {
      print("DEBUG UserController onInit: Argumen ADALAH Map. Memproses...");
      userHasAuthority.value = arguments['hasAuthority'] as bool? ?? false;
      userName.value = arguments['userName']?.toString() ?? _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Pengguna';
      String? programIdArg = arguments['programId']?.toString();
      if (programIdArg == "null" || programIdArg == null) { // Menangani string "null" dan null asli
        userProgramId.value = '';
        print("DEBUG UserController onInit: Argumen programId adalah '$programIdArg', diinterpretasikan sebagai kosong.");
      } else {
        userProgramId.value = programIdArg;
      }
    } else {
      print("DEBUG UserController onInit: Argumen NULL atau bukan Map. Menggunakan nilai default (hasAuthority=false).");
      userHasAuthority.value = false; // Default jika tidak ada argumen
      userName.value = _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Pengguna';
      userProgramId.value = '';     // Default jika tidak ada argumen
    }
    print("DEBUG UserController onInit: State Final setelah proses argumen: hasAuthority=${userHasAuthority.value}, programId='${userProgramId.value}', userName='${userName.value}'");
    print("----------------------------------------------------");

    // fetchFormData akan selalu dipanggil. Logika di dalamnya akan menentukan tindakan.
    fetchFormData();
  }

  Future<void> fetchFormData() async {
    isLoading.value = true;
    print("DEBUG UserController fetchFormData: Memulai. hasAuthority awal=${userHasAuthority.value}");
    User? currentUser = _auth.currentUser;
    List<FormDataModel> newFormsToDisplay = [];

    try {
      if (userHasAuthority.value) {
        // Skenario 1: Admin Global - Ambil semua form yang terdefinisi di 'adminForms'
        print("DEBUG UserController fetchFormData: Pengguna adalah Admin Global (berdasarkan argumen). Mengambil semua definisi form dari 'adminForms'.");
        QuerySnapshot adminFormsSnapshot = await _firestore.collection('adminForms').get();
        newFormsToDisplay = adminFormsSnapshot.docs.map((doc) {
          return FormDataModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        print("DEBUG UserController fetchFormData: Admin Global - Ditemukan ${newFormsToDisplay.length} form dari 'adminForms'.");

      } else if (currentUser != null) {
        // Skenario 2: Pengguna biasa (atau jika hasAuthority tidak true) - Cek otorisasi via 'managedAccounts'
        String currentUserId = currentUser.uid;
        print("DEBUG UserController fetchFormData: Pengguna biasa (ID: $currentUserId) atau hasAuthority=false. Memeriksa managedAccounts...");

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
            print("DEBUG UserController fetchFormData: Pengguna diotorisasi untuk formId '${formAdminDoc.id}'. Menggunakan data dari dokumen adminForms ini.");
            newFormsToDisplay.add(
                FormDataModel.fromMap(formAdminDoc.data() as Map<String, dynamic>, formAdminDoc.id)
            );
          } else {
            print("DEBUG UserController fetchFormData: Pengguna TIDAK diotorisasi untuk formId '${formAdminDoc.id}' via managedAccounts.");
          }
        }
        print("DEBUG UserController fetchFormData: Pengguna Biasa - Total ${newFormsToDisplay.length} form diotorisasi dan datanya diambil dari 'adminForms'.");
      } else {
        print("DEBUG UserController fetchFormData: Pengguna tidak login. Tidak ada form yang diambil.");
      }

      formDataList.assignAll(newFormsToDisplay);

    } catch (e, s) {
      Get.snackbar(
        'Error Pengambilan Data',
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
    userHasAuthority.value = false;
    userProgramId.value = '';
    userName.value = 'Pengguna';
    formDataList.clear();
    currentSortOrder.value = 'Default';
    _auth.signOut();
    Get.offAllNamed(AppRoutes.login); // Pastikan AppRoutes.login terdefinisi
  }
}