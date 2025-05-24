// lib/presentation/login/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Uncomment jika Anda siap mengintegrasikan Firestore untuk role
import '../../infrastructure/navigation/routes.dart'; // Pastikan path ini benar
import '../../domain/auth/models/user_model.dart';   // Impor UserModel

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Uncomment untuk Firestore

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  // Menyimpan data user yang login, termasuk perannya
  final Rx<UserModel?> loggedInUser = Rx<UserModel?>(null);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Mengambil peran pengguna dari backend/database.
  /// Ganti metode ini dengan logika pengambilan peran dari Firestore Anda.
  Future<String> _fetchUserRole(String uid) async {
    // --- AWAL SIMULASI PENGAMBILAN ROLE ---
    // Ini adalah simulasi. Dalam aplikasi nyata, Anda akan mengambil data ini
    // dari Firestore atau backend Anda menggunakan UID pengguna.
    // Contoh dengan Firestore (pastikan Anda sudah setup Firestore dan collection 'users'):
    /*
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        // Menggunakan UserModel.fromFirestore untuk membuat objek UserModel
        // UserModel tempUser = UserModel.fromFirestore(userDoc);
        // return tempUser.role;
        return (userDoc.data()!['role'] as String?) ?? 'user'; // Ambil role, default 'user'
      }
      return 'user'; // Default role jika dokumen tidak ada
    } catch (e) {
      print("Error fetching user role: $e");
      return 'user'; // Default role jika terjadi error
    }
    */

    // Untuk simulasi saat ini, kita tentukan peran berdasarkan email
    // JANGAN GUNAKAN LOGIKA INI DI APLIKASI PRODUKSI!
    if (emailController.text.toLowerCase().contains('admin')) {
      return 'admin';
    }
    return 'user';
    // --- AKHIR SIMULASI PENGAMBILAN ROLE ---
  }

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Username dan Password tidak boleh kosong",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        User firebaseUser = userCredential.user!;
        // Ambil peran pengguna
        String role = await _fetchUserRole(firebaseUser.uid);

        // Buat dan simpan instance UserModel
        loggedInUser.value = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          role: role,
        );

        Get.snackbar(
          "Sukses",
          "Login berhasil! Peran Anda: $role",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Arahkan pengguna berdasarkan perannya
        if (role == 'admin') {
          Get.offAllNamed(AppRoutes.adminPage);
        } else {
          // Asumsikan selain admin adalah 'user' atau peran lain yang mengarah ke userPage
          Get.offAllNamed(AppRoutes.userPage);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      // Menggunakan kode error yang lebih baru dan umum dari Firebase Auth
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'INVALID_LOGIN_CREDENTIALS': // Mencakup user tidak ditemukan atau password salah
          errorMessage = 'Username atau Password salah.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          errorMessage = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          errorMessage = 'Terlalu banyak percobaan login. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          errorMessage = 'Gagal terhubung ke jaringan. Periksa koneksi internet Anda.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan login: ${e.message}';
      }
      Get.snackbar(
        "Login Gagal",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Login Gagal",
        "Terjadi kesalahan tidak diketahui: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fungsi untuk logout pengguna.
  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _auth.signOut();
      loggedInUser.value = null; // Bersihkan data pengguna yang login
      Get.offAllNamed(AppRoutes.login); // Arahkan kembali ke halaman login
    } catch (e) {
      Get.snackbar(
        "Logout Gagal",
        "Terjadi kesalahan saat logout: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
