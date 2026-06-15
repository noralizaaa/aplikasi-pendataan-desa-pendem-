// lib/presentation/admin/Admin_Profile/admin_account_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';

/// [AdminAccountController] mengelola daftar formulir yang dapat dikelola oleh Admin.
/// 
/// Controller ini merupakan bagian dari pilar **Form Management** pada sisi profil admin,
/// yang memungkinkan admin untuk melihat, menyegarkan, dan menghapus formulir pendataan.
class AdminAccountController extends GetxController {
  /// Daftar formulir yang tersedia untuk dikelola.
  final RxList<FormItem> listedForms = <FormItem>[].obs;
  /// Menandakan status pemuatan data dari Firestore.
  final RxBool isLoading = true.obs;
  /// ID user admin yang sedang aktif.
  final RxString currentUserId = ''.obs;
  /// Peran (role) admin untuk menentukan batasan akses.
  final RxString userRole = ''.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _formsCollectionPath = 'adminForms';

  @override
  void onInit() {
    super.onInit();
    _initializeAndLoadForms();
  }

  /// Getter untuk mengecek apakah role saat ini memiliki akses terbatas.
  /// 
  /// Menggunakan [UserModel.isRestrictedAdmin] untuk menentukan apakah admin 
  /// hanya boleh melihat data desa tertentu saja.
  bool get isRestricted {
    final userModel = UserModel(uid: '', role: userRole.value);
    return userModel.isRestrictedAdmin;
  }

  /// Menginisialisasi data admin dan memicu pengambilan daftar formulir.
  /// 
  /// Mengambil data dari [AdminController] jika sudah terdaftar, 
  /// atau melakukan fallback ke Firebase Auth & Firestore.
  Future<void> _initializeAndLoadForms() async {
    isLoading.value = true;

    try {
      // 1. Prioritas: Ambil data dari AdminController jika sudah ada
      if (Get.isRegistered<AdminController>()) {
        final adminCtrl = Get.find<AdminController>();
        if (adminCtrl.userRole.value.isNotEmpty) {
          userRole.value = adminCtrl.userRole.value;
          currentUserId.value = adminCtrl.adminName.value; // UID as fallback display

          if (isRestricted) {
             debugPrint('AdminAccountController: Role dibatasi ($userRole). Melewatkan pengambilan form.');
             listedForms.clear();
             isLoading.value = false;
             return;
          }
        }
      }

      // 2. Fallback: Ambil data dari Firebase Auth & Firestore
      final User? user = _auth.currentUser;
      if (user != null) {
        currentUserId.value = user.uid;
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final String role = (userDoc.data()?['role'] as String? ?? 'user').toLowerCase().trim();
          userRole.value = role;
          
          if (isRestricted) {
            debugPrint('AdminAccountController: Role dibatasi via Firestore ($role).');
            listedForms.clear();
            isLoading.value = false;
            return; 
          }
        }
      }

      // 3. Hanya fetch forms jika role diizinkan
      await fetchListedForms();
    } catch (e) {
      debugPrint('Error in AdminAccountController initialization: $e');

      Get.snackbar(
        'Error Inisialisasi',
        'Gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Mengambil daftar formulir dari koleksi `adminForms` di Firestore.
  /// 
  /// Melakukan pengecekan [isRestricted] untuk mencegah pengambilan data 
  /// jika admin tidak memiliki izin yang cukup.
  Future<void> fetchListedForms() async {
    // Proteksi tambahan agar tidak fetch data jika role dibatasi
    if (isRestricted) {
      if (!isClosed) listedForms.clear();
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(_formsCollectionPath)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('AdminAccountController: Tidak ada dokumen form ditemukan.');
        if (!isClosed) listedForms.clear();
        return;
      }

      final List<FormItem> loadedForms = snapshot.docs.map((doc) {
        return FormItem.fromFirestore(doc);
      }).toList();

      if (!isClosed) {
        listedForms.assignAll(loadedForms);
      }

      debugPrint('AdminAccountController: Fetched ${loadedForms.length} forms.');
    } catch (e) {
      debugPrint('Error fetching forms: $e');

      Get.snackbar(
        'Error Data Form',
        'Gagal mengambil daftar form.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Menyegarkan daftar formulir secara manual dari server.
  Future<void> refreshListedForms() async {
    if (isLoading.value || isRestricted) {
      return;
    }

    isLoading.value = true;

    try {
      await fetchListedForms();
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Berpindah ke halaman Form Builder untuk mengedit detail formulir.
  void navigateToFormDetail(FormItem form) {
    if (isRestricted) {
      Get.snackbar('Akses Dibatasi', 'Anda tidak memiliki izin untuk mengelola form.');
      return;
    }
    
    Get.toNamed(
      AppRoutes.adminFormBuilder,
      arguments: form.id,
    );
  }

  /// Menghapus dokumen formulir dari Firestore setelah konfirmasi pengguna.
  /// 
  /// Menampilkan dialog konfirmasi dan memberikan feedback melalui snackbar 
  /// setelah proses penghapusan berhasil atau gagal.
  void deleteForm(String formId, String formTitle) {
    if (isRestricted) return;

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
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus form "$formTitle"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Get.back();

              isLoading.value = true;

              try {
                await _db
                    .collection(_formsCollectionPath)
                    .doc(formId)
                    .delete();

                listedForms.removeWhere((form) {
                  return form.id == formId;
                });

                Get.snackbar(
                  'Berhasil',
                  'Form "$formTitle" berhasil dihapus.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                debugPrint('Error deleting form: $e');

                Get.snackbar(
                  'Error',
                  'Gagal menghapus form: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } finally {
                if (!isClosed) {
                  isLoading.value = false;
                }
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
