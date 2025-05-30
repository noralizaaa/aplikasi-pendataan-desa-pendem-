// lib/presentation/user/user_profile/user_profile_controller.dart
// Path: lib/presentation/user_profile/user_profile_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileController extends GetxController {
  final Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final TextEditingController usernameController = TextEditingController();
  int _pendataCounter = 0; // Tetap ada jika _generateDefaultUsername masih digunakan

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  final RxBool isLoading = true.obs;

  static const Color dialogBackgroundColor = Color(0xFFFFF3E0);
  static const Color buttonSaveColor = Colors.deepOrangeAccent;

  @override
  void onInit() {
    super.onInit();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    print("[UserProfileController] onInit called.");
    _loadUserProfile();
  }

  @override
  void onClose() {
    print("[UserProfileController] onClose called.");
    usernameController.dispose();
    super.onClose();
  }

  Future<void> _loadUserProfile() async {
    isLoading.value = true;
    User? currentUser = _auth.currentUser;
    String fetchedUsername = 'Pengguna'; // Default username
    String fetchedRole = 'Peran Tidak Diketahui';
    String? initialProgramId;

    if (Get.arguments != null && Get.arguments is Map) {
      initialProgramId = Get.arguments['programId'] as String?;
      // Ambil username dari argumen jika ada, jika tidak, pertahankan default
      fetchedUsername = Get.arguments['username'] ?? fetchedUsername;
      fetchedRole = Get.arguments['role'] ?? fetchedRole;
      print("[UserProfileController] Loaded from Get.arguments: Username (fallback): $fetchedUsername, Role (fallback): $fetchedRole, ProgramId: $initialProgramId");
    }

    if (currentUser != null) {
      try {
        print("[UserProfileController] Fetching user details from Firestore for UID: ${currentUser.uid}");
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          // --- PENYESUAIAN PENTING ---
          // Pastikan 'username' adalah field yang benar di Firestore Anda.
          // Jika field di Firestore adalah 'displayName', gunakan data['displayName'].
          // Prioritaskan pembacaan dari field yang akan Anda update.
          fetchedUsername = data['username'] as String? ?? // Asumsikan field di Firestore adalah 'username'
              data['displayName'] as String? ?? // Fallback jika 'displayName' masih ada
              fetchedUsername; // Fallback ke nilai sebelumnya jika keduanya null
          fetchedRole = data['role'] as String? ?? fetchedRole;
          print("[UserProfileController] Firestore User Details: Username: $fetchedUsername, Role: $fetchedRole");
        } else {
          print("[UserProfileController] User document not found in Firestore. Using FirebaseAuth display name or email.");
          fetchedUsername = currentUser.displayName ?? currentUser.email ?? fetchedUsername;
        }
      } catch (e) {
        print("Error fetching user details from Firestore: $e");
        // Jika error, coba fallback ke display name dari FirebaseAuth atau email
        fetchedUsername = currentUser.displayName ?? currentUser.email ?? fetchedUsername;
      }
    } else {
      print("[UserProfileController] No current user. Using default/argument username.");
    }

    // ... (sisa logika _loadUserProfile untuk role dan programId tetap sama)
    if (initialProgramId != null && initialProgramId.isNotEmpty && initialProgramId != '000') {
      try {
        DocumentSnapshot formDoc = await FirebaseFirestore.instance.collection('forms').doc(initialProgramId).get();
        if (formDoc.exists) {
          final formData = formDoc.data() as Map<String, dynamic>;
          fetchedRole = formData['nama'] ?? 'Program ID: $initialProgramId';
          print("[UserProfileController] Role updated based on programId '$initialProgramId': $fetchedRole");
        } else {
          fetchedRole = 'Program ID: $initialProgramId (Not Found)';
          final defaultRole = await _fetchDefaultAuthorityRole();
          if (defaultRole != null && (fetchedRole.startsWith("Program ID:") || fetchedRole == 'Peran Tidak Diketahui')) {
            fetchedRole = defaultRole;
          }
          initialProgramId = '000';
        }
      } catch (e) {
        print("Error fetching form for role based on programId: $e");
        fetchedRole = 'Error loading program role';
        final defaultRole = await _fetchDefaultAuthorityRole();
        if (defaultRole != null && (fetchedRole == 'Error loading program role' || fetchedRole == 'Peran Tidak Diketahui')) {
          fetchedRole = defaultRole;
        }
        initialProgramId = '000';
      }
    } else if (fetchedRole == 'Peran Tidak Diketahui' || fetchedRole.isEmpty) {
      final defaultRole = await _fetchDefaultAuthorityRole();
      if (defaultRole != null) {
        fetchedRole = defaultRole;
      }
      initialProgramId = '000';
    }

    if (fetchedUsername == 'Pengguna' && (Get.arguments == null || Get.arguments['username'] == null)) {
      if (currentUser == null) { // Hanya generate jika tidak ada user dan tidak ada argumen
        fetchedUsername = _generateDefaultUsername();
        print("[UserProfileController] No user/args/firestore name, generated default: $fetchedUsername");
      }
    }
    // --- AKHIR DARI SISA LOGIKA _loadUserProfile ---

    userProfile.value = UserProfile(
      username: fetchedUsername,
      role: fetchedRole,
      programId: initialProgramId,
    );

    usernameController.text = userProfile.value!.username;
    print("[UserProfileController] UserProfile loaded: Username: ${userProfile.value?.username}, Role: ${userProfile.value?.role}, ProgramID: ${userProfile.value?.programId}");
    isLoading.value = false;
  }

  String _generateDefaultUsername() {
    _pendataCounter++;
    return 'Pendata $_pendataCounter';
  }

  Future<String?> _fetchDefaultAuthorityRole() async {
    try {
      DocumentSnapshot defaultRoleDoc = await FirebaseFirestore.instance.collection('forms').doc('000').get();
      if (defaultRoleDoc.exists) {
        final data = defaultRoleDoc.data() as Map<String, dynamic>;
        return data['nama'] as String? ?? 'user (Default)';
      } else {
        print("PENTING: Dokumen '000' di collection 'forms' tidak ditemukan. Mohon buat dokumen tersebut di Firestore dengan field 'nama' untuk peran default.");
        return 'user';
      }
    } catch (e) {
      print("Error fetching default authority role from Firestore: $e");
      return 'user (Error)';
    }
  }

  void promptEditUsernameDialog() {
    if (userProfile.value != null) {
      usernameController.text = userProfile.value!.username;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Edit Username",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: usernameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Username Baru",
            hintText: "Masukkan username baru",
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actionsPadding: const EdgeInsets.all(12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final newUsername = usernameController.text.trim();
              final currentUsername = userProfile.value?.username ?? '';

              if (newUsername.isNotEmpty && newUsername != currentUsername) {
                Get.back();
                saveUsername(); // Panggil saveUsername setelah dialog ditutup
              } else if (newUsername.isEmpty) {
                Get.snackbar(
                  "Input Error",
                  "Username tidak boleh kosong.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade700,
                  colorText: Colors.white,
                );
              } else {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonSaveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void saveUsername() async {
    final newUsername = usernameController.text.trim();
    User? currentUser = _auth.currentUser;

    if (newUsername.isNotEmpty && userProfile.value != null && currentUser != null) {
      isLoading.value = true;
      try {
        // --- PERUBAHAN UTAMA: GUNAKAN NAMA FIELD YANG BENAR DI FIRESTORE ---
        // Ganti 'username' dengan nama field yang Anda gunakan di Firestore,
        // misalnya 'displayName' jika itu yang Anda gunakan.
        await _firestore.collection('users').doc(currentUser.uid).update({
          'username': newUsername, // ASUMSI: field di Firestore adalah 'username'
        });
        // ----------------------------------------------------------------

        // Update lokal setelah berhasil update di Firestore
        userProfile.value!.username = newUsername;
        userProfile.refresh(); // Memaksa GetX untuk merebuild widget yang menggunakan userProfile

        Get.snackbar(
          'Sukses',
          'Username berhasil diperbarui!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Opsional: Muat ulang seluruh profil untuk konsistensi penuh dari server
        // Jika update lokal dirasa cukup, baris ini bisa di-comment.
        // Namun, ini memastikan data yang ditampilkan selalu yang terbaru dari Firestore.
        // await _loadUserProfile(); // Jika diaktifkan, akan memicu loading lagi

      } catch (e) {
        Get.snackbar(
          'Error Update',
          'Gagal memperbarui username: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    } else if (newUsername.isEmpty) {
      Get.snackbar(
        'Error',
        'Username tidak boleh kosong!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } else if (currentUser == null) {
      Get.snackbar(
        'Error',
        'Pengguna tidak ditemukan. Tidak dapat menyimpan username.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> logout() async {
    // ... (kode logout Anda sudah baik, tidak perlu diubah terkait masalah ini)
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 48, color: Color(0xFFF57C00)),
              const SizedBox(height: 16),
              const Text(
                "Konfirmasi Logout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Apakah Anda yakin ingin keluar dari akun ini?",
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
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // Tutup dialog konfirmasi
                        isLoading.value = true;
                        try {
                          await _auth.signOut();
                          userProfile.value = null;
                          usernameController.clear(); // Bersihkan controller juga
                          Get.offAllNamed(AppRoutes.login);
                        } catch (e) {
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
                      child: const Text("Logout"),
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
}