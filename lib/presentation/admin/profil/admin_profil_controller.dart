// lib/presentation/admin/profil/admin_profil_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_profil_model.dart';
import '../../../infrastructure/navigation/routes.dart';

/// [AdminProfilController] mengelola profil pribadi dari pengguna dengan role Admin.
/// 
/// Controller ini menangani:
/// 1. Pengambilan data profil admin dari Firestore.
/// 2. Pembaruan informasi dasar seperti username.
/// 3. Proses keluar log (logout) dari sistem.
class AdminProfilController extends GetxController {
  /// Objek model yang menampung data lengkap profil admin.
  final Rx<AdminProfilModel?> adminProfile = Rx<AdminProfilModel?>(null);
  /// Menandakan apakah data sedang dalam proses pemuatan.
  final RxBool isLoading = true.obs;
  /// ID unik pengguna yang sedang login.
  final RxString currentUserId = ''.obs;

  /// Username yang ditampilkan pada antarmuka pengguna.
  final RxString displayUsername = 'Admin'.obs;
  /// Peran (role) pengguna yang ditampilkan pada antarmuka pengguna.
  final RxString displayRole = 'Admin'.obs;
  /// URL foto profil pengguna.
  final RxString displayPhotoUrl = ''.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kontroler teks untuk dialog pengeditan username.
  late TextEditingController usernameEditController;

  @override
  void onInit() {
    super.onInit();
    usernameEditController = TextEditingController();
    _initializeAndFetchProfile();
  }

  /// Mengecek status autentikasi dan memulai pengambilan data profil.
  Future<void> _initializeAndFetchProfile() async {
    isLoading.value = true;

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        isLoading.value = false;

        Get.snackbar(
          'Autentikasi Gagal',
          'User tidak ditemukan. Silakan login ulang.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        return;
      }

      currentUserId.value = currentUser.uid;
      await _fetchAdminProfileData(currentUser.uid);
    } catch (e) {
      debugPrint('Error inisialisasi profil admin: $e');

      isLoading.value = false;

      Get.snackbar(
        'Error Inisialisasi',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Mengambil data profil admin dari koleksi `users` di Firestore.
  /// 
  /// Memetakan data dari dokumen Firestore ke [AdminProfilModel] dan 
  /// memperbarui variabel reaktif display.
  Future<void> _fetchAdminProfileData(String userId) async {
    isLoading.value = true;

    try {
      final DocumentSnapshot<Map<String, dynamic>> profileDoc =
      await _db.collection('users').doc(userId).get();

      if (profileDoc.exists && profileDoc.data() != null) {
        final AdminProfilModel profile = AdminProfilModel.fromMap(
          userId,
          profileDoc.data()!,
        );

        adminProfile.value = profile;

        displayUsername.value = profile.username;
        displayRole.value = profile.role;
        displayPhotoUrl.value = profile.photoURL ?? '';

        usernameEditController.text = displayUsername.value;
      } else {
        adminProfile.value = null;
        displayUsername.value = 'Admin (Data Kosong)';
        displayRole.value = 'Admin (Data Kosong)';
        displayPhotoUrl.value = '';

        usernameEditController.text = displayUsername.value;

        Get.snackbar(
          'Info',
          'Data profil tidak ditemukan di database.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error memuat profil admin: $e');

      displayUsername.value = 'Admin (Error)';
      displayRole.value = 'Admin (Error)';
      displayPhotoUrl.value = '';

      usernameEditController.text = displayUsername.value;

      Get.snackbar(
        'Error Memuat Profil',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Menyegarkan data profil secara manual.
  Future<void> refreshProfile() async {
    if (currentUserId.value.isNotEmpty) {
      await _fetchAdminProfileData(currentUserId.value);
    } else {
      await _initializeAndFetchProfile();
    }
  }

  /// Menampilkan dialog input untuk mengubah username admin.
  void promptEditUsername() {
    usernameEditController.text = displayUsername.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Edit Username',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: usernameEditController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Username Baru',
            hintText: 'Masukkan username baru',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(12),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final String newUsername = usernameEditController.text.trim();

              if (newUsername.isEmpty) {
                Get.snackbar(
                  'Input Error',
                  'Username tidak boleh kosong.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade700,
                  colorText: Colors.white,
                );
                return;
              }

              if (newUsername == displayUsername.value) {
                Get.back();
                return;
              }

              Get.back();
              updateUsername(newUsername);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Memperbarui username pengguna di dokumen Firestore.
  /// 
  /// Memperbarui baik field `username` maupun `displayName` untuk sinkronisasi.
  Future<void> updateUsername(String newUsername) async {
    if (currentUserId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'User tidak teridentifikasi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      await _db.collection('users').doc(currentUserId.value).update({
        'username': newUsername,
        'displayName': newUsername,
      });

      displayUsername.value = newUsername;
      usernameEditController.text = newUsername;

      await _fetchAdminProfileData(currentUserId.value);

      Get.snackbar(
        'Berhasil',
        'Username berhasil diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error update username: $e');

      Get.snackbar(
        'Error Update',
        'Gagal memperbarui username: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Menangani proses keluar log (logout) dari aplikasi.
  /// 
  /// Menampilkan dialog konfirmasi sebelum menghapus sesi dan 
  /// mengarahkan kembali ke halaman login.
  Future<void> logout() async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                size: 48,
                color: Color(0xFFF57C00),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda yakin ingin keluar dari akun ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();

                        isLoading.value = true;

                        try {
                          await _auth.signOut();

                          adminProfile.value = null;
                          currentUserId.value = '';
                          displayUsername.value = 'Admin';
                          displayRole.value = 'Admin';
                          displayPhotoUrl.value = '';

                          Get.offAllNamed(AppRoutes.login);
                        } catch (e) {
                          debugPrint('Error logout: $e');

                          Get.snackbar(
                            'Error Logout',
                            'Gagal untuk logout: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          isLoading.value = false;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
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
    usernameEditController.dispose();
    super.onClose();
  }
}
