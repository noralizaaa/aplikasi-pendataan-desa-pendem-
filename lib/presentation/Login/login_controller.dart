import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/navigation/routes.dart'; // Pastikan path ini benar
import '../../domain/auth/models/auth_user.dart'; // Pastikan path ini benar
import '../../domain/auth/models/user_model.dart'; // Pastikan path ini benar

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isManualLogin = false.obs; // Untuk mencegah login otomatis
  final Rx<AuthUser?> loggedInAuthUser = Rx<AuthUser?>(null);

  static int _loginAttemptCounter = 0;

  @override
  void onInit() async {
    super.onInit();
    print('DEBUG: LoginController onInit called.');

    // Paksa logout dan tunggu hingga selesai
    try {
      await _auth.signOut();
      print('DEBUG: Forcefully signed out on app start.');
      loggedInAuthUser.value = null;

      // Hanya navigasi jika belum di LoginScreen
      if (Get.currentRoute != AppRoutes.login) {
        await Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('DEBUG: Error during force sign out on start: $e');
    }

    // Dengarkan authStateChanges setelah logout selesai
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null && isManualLogin.value) {
        print('DEBUG: Auth State Changed - User ${firebaseUser.email} detected (Manual login). UID: ${firebaseUser.uid}');
        await _loadAndSetAuthUser(firebaseUser);
      } else {
        print('DEBUG: Auth State Changed - No user detected or not manual login. Staying on LoginScreen.');
        loggedInAuthUser.value = null;
        // Tidak navigasi, biarkan tetap di LoginScreen
      }
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> _loadAndSetAuthUser(User firebaseUser) async {
    print('DEBUG: _loadAndSetAuthUser for UID: ${firebaseUser.uid} started. Fetching Firestore data.');
    try {
      AuthUser tempAuthUser = AuthUser.fromFirebaseUser(firebaseUser);
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      String? finalRoleFromFirestore;
      String? finalProgramId;

      if (userDoc.exists) {
        UserModel firestoreUserModel = UserModel.fromFirestore(userDoc as DocumentSnapshot<Map<String, dynamic>>);
        finalRoleFromFirestore = firestoreUserModel.role;
        print('DEBUG: User document found in Firestore. Role: $finalRoleFromFirestore');
      } else {
        print('DEBUG: User document NOT found in Firestore for UID: ${firebaseUser.uid}. Assigning default role and creating doc.');
        finalRoleFromFirestore = 'user';
        finalProgramId = '000';
        await _firestore.collection('users').doc(firebaseUser.uid).set(
            UserModel(uid: firebaseUser.uid, email: firebaseUser.email, role: 'user').toFirestore());
      }

      loggedInAuthUser.value = tempAuthUser.copyWith(
        roleFromFirestore: finalRoleFromFirestore,
        programId: finalProgramId,
      );

      print('DEBUG: AuthUser set. DisplayName: ${loggedInAuthUser.value?.displayName}, Role: ${loggedInAuthUser.value?.roleFromFirestore}, ProgramId: ${loggedInAuthUser.value?.programId}');
      _navigateToAppropriatePage(loggedInAuthUser.value!);
    } catch (e) {
      print('ERROR: Failed to load user data from Firestore: $e');
      Get.snackbar(
        'Error Data Pengguna',
        'Gagal memuat data pengguna: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      loggedInAuthUser.value = AuthUser.fromFirebaseUser(firebaseUser).copyWith(
        roleFromFirestore: 'error_user',
        programId: '000',
      );
      print('DEBUG: Navigating with fallback AuthUser due to Firestore error.');
      _navigateToAppropriatePage(loggedInAuthUser.value!);
    }
  }

  Future<void> loginUser() async {
    isLoading.value = true;
    isManualLogin.value = true; // Tandai sebagai login manual
    _loginAttemptCounter++;
    print('DEBUG: Attempting login via UI. Counter: $_loginAttemptCounter');

    // Di dalam fungsi loginUser(), sebelum blok try untuk FirebaseAuth
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

// --- AWAL PERBAIKAN ---

// 1. Validasi Input Kosong
    if (email.isEmpty || password.isEmpty) {
      print(
          'DEBUG: Login input empty. Email: "$email", Password: "$password"'); // Lebih detail
      Get.snackbar(
        'Input Tidak Lengkap', // Judul lebih generik jika ada validasi lain
        'Email dan password tidak boleh kosong.', // Pesan lebih jelas
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        // Warna yang sedikit berbeda untuk warning
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      isLoading.value =
      false; // Pastikan isLoading di-reset jika validasi gagal
      isManualLogin.value = false; // Reset juga jika perlu
      return; // Hentikan eksekusi lebih lanjut
    }

// 2. (Opsional) Validasi Format Email Sederhana
    if (!GetUtils.isEmail(email)) {
      print('DEBUG: Invalid email format: "$email"');
      Get.snackbar(
        'Format Email Salah',
        'Silakan masukkan alamat email yang valid.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      isLoading.value = false;
      isManualLogin.value = false;
      return;
    }

// 3. (Opsional) Validasi Panjang Password Minimum (jika ada aturan)
// if (password.length < 6) {
//   print('DEBUG: Password too short.');
//   Get.snackbar(
//     'Password Terlalu Pendek',
//     'Password minimal harus 6 karakter.',
//     snackPosition: SnackPosition.BOTTOM,
//     backgroundColor: Colors.orangeAccent,
//     colorText: Colors.white,
//     margin: const EdgeInsets.all(12),
//     borderRadius: 8,
//     duration: const Duration(seconds: 3),
//   );
//   isLoading.value = false;
//   isManualLogin.value = false;
//   return;
// }

// --- AKHIR PERBAIKAN ---

// Setelah semua validasi lolos, baru lanjutkan ke proses login Firebase
    try {
      isLoading.value =
      true; // isLoading bisa di-set di sini jika validasi dipisah
      isManualLogin.value = true;
      _loginAttemptCounter++;
      print(
          'DEBUG: Attempting login via UI. Counter: $_loginAttemptCounter. Email: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('DEBUG: Firebase login successful for ${userCredential.user
          ?.email}. UID: ${userCredential.user?.uid}');
      // Navigasi akan ditangani oleh authStateChanges
    } on FirebaseAuthException catch (e) {
      // ... (penanganan error FirebaseAuthException)
    } catch (e) {
      // ... (penanganan error umum)
    } finally {
      isLoading.value = false;
      isManualLogin.value =
      false; // Reset setelah login selesai (baik sukses maupun gagal)
    }

    try {
      if (email.isEmpty || password.isEmpty) {
        print('DEBUG: Login input empty.');
        Get.snackbar(
          'Input Kosong',
          'Silakan isi email dan password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('DEBUG: Firebase login successful for ${userCredential.user
          ?.email}. UID: ${userCredential.user?.uid}');
      // Navigasi akan ditangani oleh authStateChanges

    } on FirebaseAuthException catch (e) {
      // Pastikan ini masih ada dan Anda melihat outputnya di konsol saat error terjadi
      print('DEBUG: FirebaseAuthException - RAW ERROR CODE: "${e.code}", Message: "${e.message}"');

      String errorMessage;
      // Normalisasi kode error untuk konsistensi (opsional tapi bisa membantu)
      String normalizedCode = e.code.toLowerCase().replaceAll('error_', '').replaceAll('-', '_');
      // Contoh: 'auth/invalid-credential' menjadi 'auth_invalid_credential'
      // 'INVALID_CREDENTIAL' menjadi 'invalid_credential'


      // switch (e.code) { // Anda bisa tetap menggunakan e.code jika lebih suka
      switch (normalizedCode) { // Atau gunakan versi yang dinormalisasi
        case 'user_not_found': // Cocok untuk 'user-not-found' atau 'auth/user-not-found'
        case 'auth_user_not_found':
          errorMessage = 'Akun dengan email ini tidak ditemukan. Silakan daftar atau cek email Anda.';
          break;
        case 'wrong_password': // Cocok untuk 'wrong-password' atau 'auth/wrong-password'
        case 'auth_wrong_password':
          errorMessage = 'Password yang Anda masukkan salah. Silakan coba lagi.';
          break;

      // --- INI BAGIAN PENTING UNTUK KASUS ANDA ---
        case 'invalid_credential': // Cocok untuk 'invalid-credential'
        case 'auth_invalid_credential': // Cocok untuk 'auth/invalid-credential'
          errorMessage = 'Email atau password yang Anda masukkan salah. Silakan periksa kembali.';
          break;
      // ------------------------------------------

        case 'invalid_email': // Cocok untuk 'invalid-email' atau 'auth/invalid-email'
        case 'auth_invalid_email':
          errorMessage = 'Format email yang Anda masukkan tidak valid.';
          break;
        case 'user_disabled':
        case 'auth_user_disabled':
          errorMessage = 'Akun ini telah dinonaktifkan. Hubungi administrator.';
          break;
        case 'too_many_requests':
        case 'auth_too_many_requests':
          errorMessage = 'Terlalu banyak percobaan login. Silakan coba lagi nanti atau reset password Anda.';
          break;
        case 'network_request_failed':
        case 'auth_network_request_failed':
          errorMessage = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
          break;
        default:
        // Jika kode yang dinormalisasi pun tidak cocok, tampilkan kode asli dari Firebase
          errorMessage = 'Terjadi kesalahan saat login. (Kode Asli: ${e.code})';
      }

      Get.snackbar(
        'Login Gagal',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      // ... (penanganan error umum lainnya)
    } finally {
      isLoading.value = false;
      isManualLogin.value = false;
    }
  }

  void _navigateToAppropriatePage(AuthUser user) {
    String actualDisplayName = user.displayName ?? 'Pendata Default';
    String? userProgramId = user.programId;
    String userRole = user.roleFromFirestore ?? 'Pengguna Umum';
    bool hasAuthority = (user.roleFromFirestore == 'admin' || user.programId != '000');

    print('DEBUG: _navigateToAppropriatePage - Final navigation parameters:');
    print('DEBUG:   DisplayName: "$actualDisplayName"');
    print('DEBUG:   Role: "$userRole"');
    print('DEBUG:   ProgramId: "$userProgramId"');
    print('DEBUG:   HasAuthority: $hasAuthority');

    emailController.clear();
    passwordController.clear();

    if (user.roleFromFirestore == 'admin' || user.programId == 'admin') {
      print('DEBUG: Routing to Admin Page.');
      Get.offAllNamed(AppRoutes.adminPage);
    } else {
      print('DEBUG: Routing to User Page.');
      Get.offAllNamed(AppRoutes.userPage);
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void logout() async {
    print('DEBUG: Logout initiated. Signing out from Firebase.');
    await _auth.signOut();
    loggedInAuthUser.value = null;
    print('DEBUG: Redirecting to LoginScreen after logout.');
    Get.offAllNamed(AppRoutes.login);
  }
}