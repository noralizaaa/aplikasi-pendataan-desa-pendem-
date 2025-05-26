// lib/presentation/admin/Admin_Profile/all_account_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_account_model.dart'; // Menggunakan AdminAccountModel
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Untuk navigasi ke form builder
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // For consistent colors

class AllAccountController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<AdminAccountModel> allAccounts = <AdminAccountModel>[].obs;
  final RxList<AdminAccountModel> filteredAccounts = <AdminAccountModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  static const String _usersCollectionPath = 'users'; // Nama koleksi pengguna Anda

  @override
  void onInit() {
    super.onInit();
    _listenToAllUsers();
    ever(searchQuery, (_) => _filterAccounts()); // Re-filter whenever search query changes
  }

  void _listenToAllUsers() {
    isLoading.value = true;
    _db.collection(_usersCollectionPath).snapshots().listen(
          (snapshot) {
        final fetchedAccounts = snapshot.docs
            .map((doc) => AdminAccountModel.fromMap(doc.id, doc.data()))
            .toList();
        allAccounts.assignAll(fetchedAccounts);
        _filterAccounts(); // Apply filter after fetching
        isLoading.value = false;
        print('AllAccountController: Fetched ${allAccounts.length} users.');
      },
      onError: (error) {
        Get.snackbar('Error Data Akun', 'Gagal mengambil daftar akun: $error',
            backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        print('Error fetching all users: $error');
      },
    );
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void _filterAccounts() {
    if (searchQuery.isEmpty) {
      filteredAccounts.assignAll(allAccounts);
    } else {
      filteredAccounts.assignAll(allAccounts.where((account) =>
      account.email.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          account.username.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList());
    }
  }

  Future<void> showCreateSystemUserDialog() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final RxString selectedRole = 'user'.obs; // Default role

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Modern rounded corners
        title: const Text(
          'Buat Akun Pengguna Baru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pengguna',
                  hintText: 'Masukkan nama pengguna',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Masukkan password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedRole.value,
                decoration: InputDecoration(
                  labelText: 'Peran',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: <String>['user', 'admin'] // Sesuaikan peran yang tersedia
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalizeFirst!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedRole.value = newValue;
                  }
                },
              )),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(15), // Consistent padding for actions
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700, // Text color for cancel
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _createSystemUser(
                emailController.text.trim(),
                passwordController.text.trim(),
                usernameController.text.trim(),
                selectedRole.value,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminScreen.primaryHeaderColor, // Consistent brand color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Buat Akun'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSystemUser(String email, String password, String username, String role) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      Get.snackbar('Error', 'Email, Password, dan Nama Pengguna tidak boleh kosong.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection(_usersCollectionPath).doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Sukses', 'Akun pengguna "$username" berhasil dibuat.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar.';
      } else {
        message = 'Gagal membuat akun: ${e.message}';
      }
      Get.snackbar('Error Membuat Akun', message,
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  Future<void> editAccount(AdminAccountModel account) async {
    final TextEditingController usernameController = TextEditingController(text: account.username);
    final TextEditingController emailController = TextEditingController(text: account.email);
    final RxString selectedRole = account.role.obs;

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Modern rounded corners
        title: const Text(
          'Edit Akun Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pengguna',
                  hintText: 'Masukkan nama pengguna baru',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade200, // Slightly darker to indicate disabled
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email typically shouldn't be edited easily
                style: const TextStyle(color: Colors.grey), // Text color for disabled field
              ),
              const SizedBox(height: 15),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedRole.value,
                decoration: InputDecoration(
                  labelText: 'Peran',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: <String>['user', 'admin'] // Sesuaikan peran yang tersedia
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalizeFirst!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedRole.value = newValue;
                  }
                },
              )),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(15),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _updateAccountDetails(
                account.uid,
                usernameController.text.trim(),
                selectedRole.value,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminScreen.primaryHeaderColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAccountDetails(String uid, String newUsername, String newRole) async {
    try {
      await _db.collection(_usersCollectionPath).doc(uid).update({
        'username': newUsername,
        'role': newRole,
      });
      Get.snackbar('Sukses', 'Detail akun berhasil diperbarui.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui akun: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteAccount(AdminAccountModel account) async {
    if (_auth.currentUser?.uid == account.uid) {
      Get.snackbar('Error', 'Anda tidak bisa menghapus akun Anda sendiri.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Konfirmasi Hapus',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${account.email}"? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
        ),
        actionsPadding: const EdgeInsets.all(15),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Get.back(); // Close dialog
              try {
                await _db.collection(_usersCollectionPath).doc(account.uid).delete();
                Get.snackbar('Berhasil', 'Akun "${account.email}" berhasil dihapus.',
                    backgroundColor: Colors.green, colorText: Colors.white);
              } on FirebaseAuthException catch (e) {
                String message;
                if (e.code == 'requires-recent-login') {
                  message = 'Untuk menghapus akun, admin perlu login kembali.';
                } else {
                  message = 'Gagal menghapus akun Firebase Auth: ${e.message}';
                }
                Get.snackbar('Error Hapus Akun', message,
                    backgroundColor: Colors.red, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('Error Hapus Akun', 'Terjadi kesalahan: $e',
                    backgroundColor: Colors.red, colorText: Colors.white);
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
    super.onClose();
  }
}