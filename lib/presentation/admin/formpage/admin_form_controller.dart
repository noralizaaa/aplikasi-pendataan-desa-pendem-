// lib/presentation/admin/formpage/admin_form_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For StreamSubscription

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

class AdminFormController extends GetxController {
  final RxList<FormItem> forms = <FormItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxString currentUserId = ''.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _formsSubscription;

  static const String _formsCollectionPath = 'adminForms';

  @override
  void onInit() {
    super.onInit();
    _initializeFirebaseAndListenToForms();
  }

  Future<void> _initializeFirebaseAndListenToForms() async {
    // isLoading.value = true; // isLoading sudah diatur true saat deklarasi atau di awal refreshForms
    // Jika dipanggil dari refresh, isLoading mungkin sudah true. Jika dari onInit, juga sudah true.
    // Jadi, baris ini bisa opsional di sini jika sudah dihandle di pemanggil atau deklarasi.
    // Namun, untuk memastikan, kita bisa set di sini juga, terutama jika metode ini bisa dipanggil dari tempat lain.
    if (!isLoading.value) isLoading.value = true;

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        currentUserId.value = user.uid;
        print('DEBUG: AdminFormController - User terautentikasi: ${user.uid}');
        _listenToForms();
      } else {
        print('DEBUG: AdminFormController - Tidak ada pengguna yang login. Halaman ini mungkin memerlukan autentikasi.');
        _listenToForms(); // Tetap coba listen, biarkan security rules yang handle
      }
    } catch (e) {
      Get.snackbar('Error Inisialisasi', 'Gagal: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      if(!isClosed) isLoading.value = false;
      print('Firebase initialization error in AdminFormController: $e');
    }
  }

  void _listenToForms() {
    _formsSubscription?.cancel();
    print('DEBUG: AdminFormController - Listening to collection: $_formsCollectionPath');
    _formsSubscription = _db
        .collection(_formsCollectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('DEBUG: AdminFormController - Menerima snapshot dengan ${snapshot.docs.length} form.');
      forms.assignAll(
          snapshot.docs.map((doc) => FormItem.fromFirestore(doc)).toList());
      if(!isClosed) isLoading.value = false; // Set false setelah data pertama atau error
    }, onError: (error) {
      Get.snackbar('Error Data Form', 'Gagal mengambil daftar form: $error',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      if(!isClosed) isLoading.value = false;
      print('Error fetching forms list from $_formsCollectionPath: $error');
    });
  }

  /// Metode publik untuk di-trigger oleh RefreshIndicator
  Future<void> refreshFormsData() async {
    print("DEBUG: AdminFormController - refreshFormsData() dipanggil.");
    // Set isLoading true di awal proses refresh
    if(!isClosed) isLoading.value = true;
    // Panggil ulang logika inisialisasi dan pendengaran data
    // _initializeFirebaseAndListenToForms akan menangani set isLoading ke false di akhirnya.
    await _initializeFirebaseAndListenToForms();
  }

  // ... (Metode addForm dan deleteForm tetap sama) ...
  Future<void> addForm(String title, String description, List<FormSection> sections) async {
    if (title.trim().isEmpty) {
      Get.snackbar('Input Error', 'Judul form tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Autentikasi Error', 'Anda harus login untuk menambahkan form.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      return;
    }

    bool previousIsLoading = isLoading.value; // Simpan state isLoading
    isLoading.value = true;
    try {
      final newFormItem = FormItem(id: '', title: title.trim(), description: description.trim(), createdAt: DateTime.now(), createdByUserId: currentUser.uid, sections: sections);
      await _db.collection(_formsCollectionPath).add(newFormItem.toFirestore());
      Get.snackbar('Berhasil', 'Form "$title" berhasil ditambahkan!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error Tambah Form', 'Gagal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      print('Error adding form: $e');
    } finally {
      if(!isClosed) isLoading.value = previousIsLoading; // Kembalikan ke state isLoading sebelumnya
    }
  }

  Future<void> deleteForm(String formId, String formTitle) async {
    if (_auth.currentUser == null) {
      Get.snackbar(
        'Autentikasi Error',
        'Anda harus login untuk menghapus form.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Penghapusan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin menghapus form "$formTitle"?\nTindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    label: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Get.back();
                      bool previousIsLoading = isLoading.value;
                      isLoading.value = true;
                      try {
                        await _db.collection(_formsCollectionPath).doc(formId).delete();
                        Get.snackbar(
                          'Berhasil',
                          'Form "$formTitle" berhasil dihapus!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Error Hapus Form',
                          'Gagal: ${e.toString()}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade400,
                          colorText: Colors.white,
                        );
                        print('Error deleting form: $e');
                      } finally {
                        if (!isClosed) isLoading.value = previousIsLoading;
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Hapus', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }



  @override
  void onClose() {
    _formsSubscription?.cancel();
    super.onClose();
  }
}