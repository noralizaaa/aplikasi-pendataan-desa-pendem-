// lib/presentation/admin/Admin_Profile/admin_account_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Import model FormItem dari path yang benar
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
// Import AppRoutes jika Anda melakukan navigasi dari sini (misalnya ke form builder)
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

class AdminAccountController extends GetxController {
  // Mengganti accountCategories dengan listedForms bertipe FormItem
  final RxList<FormItem> listedForms = <FormItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxString currentUserId = ''.obs; // Opsional

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _formsSubscriptionAccountTab; // Nama subscription yang berbeda

  // Path koleksi tempat form disimpan (HARUS SAMA dengan di AdminFormBuilderController & AdminController untuk dashboard)
  static const String _formsCollectionPath = 'adminForms';

  @override
  void onInit() {
    super.onInit();
    _initializeFirebaseAndLoadFormsForAccountTab();
  }

  Future<void> _initializeFirebaseAndLoadFormsForAccountTab() async {
    isLoading.value = true;
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        currentUserId.value = user.uid;
      } else {
        print('AdminAccountController (Tab Akun): Tidak ada pengguna yang login.');
      }
      _listenToFormsForAccountTab();
    } catch (e) {
      Get.snackbar('Error Inisialisasi', 'Gagal: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      isLoading.value = false;
      print('Firebase initialization error in AdminAccountController (Tab Akun): $e');
    }
  }

  void _listenToFormsForAccountTab() {
    print('AdminAccountController (Tab Akun): Listening to collection: $_formsCollectionPath');

    _formsSubscriptionAccountTab?.cancel();
    _formsSubscriptionAccountTab = _db
        .collection(_formsCollectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.docs.isEmpty) {
          print('AdminAccountController (Tab Akun): Tidak ada dokumen form ditemukan di $_formsCollectionPath');
        }
        listedForms.assignAll(snapshot.docs
            .map((doc) => FormItem.fromFirestore(doc))
            .toList());
        isLoading.value = false;
        print('AdminAccountController (Tab Akun): Fetched ${listedForms.length} forms.');
      },
      onError: (error) {
        Get.snackbar('Error Data Form (Tab Akun)', 'Gagal mengambil daftar form: $error',
            backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        print('Error fetching forms from $_formsCollectionPath for Account Tab: $error');
      },
    );
  }

  Future<void> refreshListedForms() async {
    isLoading.value = true;
    // Anda bisa memilih untuk hanya get() atau re-attach listener
    // Re-attaching listener:
    await _initializeFirebaseAndLoadFormsForAccountTab();
    // Atau jika ingin get() sekali jalan untuk refresh:
    /*
    try {
      final snapshot = await _db.collection(_formsCollectionPath).orderBy('createdAt', descending: true).get();
      if (snapshot.docs.isNotEmpty) {
        listedForms.assignAll(snapshot.docs.map((doc) => FormItem.fromFirestore(doc)).toList());
      } else {
        listedForms.clear();
      }
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
    */
  }

  void navigateToFormDetail(FormItem form) {
    // Aksi ketika item form diklik di tab "Account"
    // Misalnya, navigasi ke halaman untuk mengedit form tersebut
    Get.toNamed(AppRoutes.adminFormBuilder, arguments: form.id);
    print('Navigasi ke form builder untuk: ${form.title}');
  }

  // Jika Anda perlu fungsi delete di sini juga (untuk konsistensi dengan gambar/keinginan sebelumnya)
  void deleteForm(String formId, String formTitle) {
    if (_auth.currentUser == null) {
      Get.snackbar('Autentikasi Error', 'Anda harus login untuk menghapus form.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      return;
    }
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus form "$formTitle"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              isLoading.value = true; // Bisa gunakan isDeleting.value jika ada
              try {
                await _db.collection(_formsCollectionPath).doc(formId).delete();
                Get.snackbar('Berhasil', 'Form "$formTitle" berhasil dihapus.',
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
                // Stream akan otomatis update UI
              } catch (e) {
                Get.snackbar('Error', 'Gagal menghapus form: $e',
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
              } finally {
                if(!isClosed) isLoading.value = false;
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  void onClose() {
    _formsSubscriptionAccountTab?.cancel();
    super.onClose();
  }
}