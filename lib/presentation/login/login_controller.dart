import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/navigation/routes.dart';
import '../../domain/auth/models/auth_user.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isManualLogin = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<AuthUser?> loggedInAuthUser = Rx<AuthUser?>(null);

  static int _loginAttemptCounter = 0;

  @override
  void onInit() async {
    super.onInit();
    debugPrint('DEBUG: LoginController onInit called.');

    // Paksa logout dan tunggu hingga selesai
    try {
      await _auth.signOut();
      debugPrint('DEBUG: Forcefully signed out on app start.');
      loggedInAuthUser.value = null;

      // Hanya navigasi jika belum di LoginScreen
      if (Get.currentRoute != AppRoutes.login) {
        await Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('DEBUG: Error during force sign out on start: $e');
    }

    // Dengarkan authStateChanges setelah logout selesai
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null && isManualLogin.value) {
        debugPrint('DEBUG: Auth State Changed - User ${firebaseUser.email} detected (Manual login). UID: ${firebaseUser.uid}');
        await _loadAndSetAuthUser(firebaseUser);
      } else {
        debugPrint('DEBUG: Auth State Changed - No user detected or not manual login. Staying on LoginScreen.');
        loggedInAuthUser.value = null;
      }
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    final context = Get.context;

    if (context == null) {
      debugPrint('Snackbar skipped: Get.context is null');
      return;
    }

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      debugPrint('Snackbar skipped: Overlay is null');
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
      margin: margin,
      borderRadius: borderRadius,
    );
  }

  Future<void> _loadAndSetAuthUser(User firebaseUser) async {
    debugPrint('DEBUG: _loadAndSetAuthUser for UID: ${firebaseUser.uid} started. Fetching Firestore data.');
    try {
      AuthUser tempAuthUser = AuthUser.fromFirebaseUser(firebaseUser);
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      String? finalRoleFromFirestore;
      String? finalProgramId;
      String? finalVillageId;
      String? finalVillageName;

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        finalRoleFromFirestore = userData['role'] as String? ?? 'user';
        finalVillageId = userData['villageId'] as String?;
        finalVillageName = userData['villageName'] as String?;
        debugPrint('DEBUG: User document found in Firestore. Role: $finalRoleFromFirestore');

        // Bungkus update dalam try-catch agar jika Firestore Rules melarang, login tetap lanjut
        try {
          Map<String, dynamic> updateData = {
            'isLogin': true,
            'lastLoginAt': FieldValue.serverTimestamp(),
          };

          if (!userData.containsKey('isLogin')) {
            updateData['isLoginFieldAddedAt'] = FieldValue.serverTimestamp();
          }

          await _firestore.collection('users').doc(firebaseUser.uid).update(updateData);
          debugPrint('DEBUG: Updated isLogin to true successfully.');
        } catch (updateError) {
          debugPrint('W/Firestore: Gagal update isLogin (Akses Dibatasi): $updateError');
          // Lanjutkan proses login meskipun update field isLogin gagal
        }
      } else {
        // ... (sisanya tetap sama)
        debugPrint('DEBUG: User document NOT found in Firestore for UID: ${firebaseUser.uid}. Assigning default role and creating doc.');
        finalRoleFromFirestore = 'user';
        finalProgramId = '000';
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'role': 'user',
          'programId': finalProgramId,
          'isLogin': true, // Set true saat pertama kali login
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint('DEBUG: Created new user document with isLogin: true');
      }

      loggedInAuthUser.value = tempAuthUser.copyWith(
        roleFromFirestore: finalRoleFromFirestore,
        programId: finalProgramId,
        villageId: finalVillageId,
        villageName: finalVillageName,
      );

      debugPrint('DEBUG: AuthUser set. DisplayName: ${loggedInAuthUser.value?.displayName}, Role: ${loggedInAuthUser.value?.roleFromFirestore}, ProgramId: ${loggedInAuthUser.value?.programId}');
      _navigateToAppropriatePage(loggedInAuthUser.value!);
    } catch (e) {
      debugPrint('ERROR: Failed to load user data from Firestore: $e');
      
      showSafeSnackbar(
        title: 'Error Data Pengguna',
        message: 'Gagal memuat data pengguna: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );

      loggedInAuthUser.value = AuthUser.fromFirebaseUser(firebaseUser).copyWith(
        roleFromFirestore: 'error_user',
        programId: '000',
      );
      debugPrint('DEBUG: Navigating with fallback AuthUser due to Firestore error.');
      _navigateToAppropriatePage(loggedInAuthUser.value!);
    }
  }

  Future<void> loginUser() async {
    isLoading.value = true;
    isManualLogin.value = true;
    errorMessage.value = ''; // Reset error message on new attempt
    _loginAttemptCounter++;
    debugPrint('DEBUG: Attempting login via UI. Counter: $_loginAttemptCounter');

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Validasi Input Kosong
    if (email.isEmpty || password.isEmpty) {
      debugPrint('DEBUG: Login input empty. Email: "$email", Password: "$password"');
      const String msg = 'Email dan password tidak boleh kosong.';
      errorMessage.value = msg;
      showSafeSnackbar(
        title: 'Input Tidak Lengkap',
        message: msg,
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

    // Validasi Format Email
    if (!GetUtils.isEmail(email)) {
      debugPrint('DEBUG: Invalid email format: "$email"');
      const String msg = 'Silakan masukkan alamat email yang valid.';
      errorMessage.value = msg;
      showSafeSnackbar(
        title: 'Format Email Salah',
        message: msg,
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

    try {
      debugPrint('DEBUG: Attempting Firebase login. Email: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('DEBUG: Firebase login successful for ${userCredential.user?.email}. UID: ${userCredential.user?.uid}');

      // Navigasi akan ditangani oleh authStateChanges dan _loadAndSetAuthUser
      // yang akan mengupdate isLogin menjadi true

    } on FirebaseAuthException catch (e) {
      debugPrint('DEBUG: FirebaseAuthException - RAW ERROR CODE: "${e.code}", Message: "${e.message}"');

      String errorMessage;
      String normalizedCode = e.code.toLowerCase().replaceAll('error_', '').replaceAll('-', '_');

      switch (normalizedCode) {
        case 'network_request_failed':
        case 'auth_network_request_failed':
          errorMessage = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
          break;
        case 'user_not_found':
        case 'auth_user_not_found':
          errorMessage = 'Akun dengan email ini tidak ditemukan. Silakan daftar atau cek email Anda.';
          break;
        case 'wrong_password':
        case 'auth_wrong_password':
          errorMessage = 'Password yang Anda masukkan salah. Silakan coba lagi.';
          break;
        case 'invalid_credential':
        case 'auth_invalid_credential':
          errorMessage = 'Email atau password yang Anda masukkan salah. Silakan periksa kembali.';
          break;
        case 'invalid_email':
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
        default:
          errorMessage = 'Terjadi kesalahan saat login. (Kode Asli: ${e.code})';
      }

      showSafeSnackbar(
        title: 'Login Gagal',
        message: errorMessage,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
      );
      
      this.errorMessage.value = errorMessage; // Simpan pesan error untuk ditampilkan di UI

    } catch (e) {
      debugPrint('DEBUG: General login error: $e');
      final String msg = 'Terjadi kesalahan tidak terduga: $e';
      errorMessage.value = msg;
      showSafeSnackbar(
        title: 'Error Tidak Dikenal',
        message: msg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      isManualLogin.value = false;
    }
  }

  void _navigateToAppropriatePage(AuthUser user) {
    debugPrint('DEBUG: _navigateToAppropriatePage - USER ROLE: "${user.roleFromFirestore}"');

    emailController.clear();
    passwordController.clear();

    if (user.isAdmin) {
      debugPrint('DEBUG: SUCCESS! Recognized as Admin. Redirecting to ADMIN Dashboard.');
      Get.offAllNamed(AppRoutes.adminPage);
    } else {
      debugPrint('DEBUG: Recognized as Regular User. Redirecting to USER Page.');
      Get.offAllNamed(AppRoutes.userPage);
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void logout() async {
    debugPrint('DEBUG: Logout initiated.');

    try {
      // Update isLogin menjadi false di Firestore sebelum sign out
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'isLogin': false,
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
        debugPrint('DEBUG: Updated isLogin to false for user: ${currentUser.email}');
      }

      // Sign out dari Firebase Auth
      await _auth.signOut();
      loggedInAuthUser.value = null;

      debugPrint('DEBUG: Firebase sign out completed. Redirecting to LoginScreen.');
      Get.offAllNamed(AppRoutes.login);

    } catch (e) {
      debugPrint('DEBUG: Error during logout: $e');
      // Tetap sign out meskipun ada error saat update Firestore
      await _auth.signOut();
      loggedInAuthUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // Method untuk mengupdate semua user existing dengan field isLogin
  Future<void> addIsLoginFieldToAllUsers() async {
    try {
      debugPrint('DEBUG: Starting batch update to add isLogin field to all existing users');

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      WriteBatch batch = _firestore.batch();
      int updateCount = 0;

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Cek apakah field isLogin sudah ada
        if (!userData.containsKey('isLogin')) {
          batch.update(doc.reference, {
            'isLogin': false, // Default false untuk user yang sudah ada
            'fieldAddedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
          debugPrint('DEBUG: Will add isLogin field to user: ${userData['email'] ?? userData['uid']}');
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        debugPrint('DEBUG: Successfully added isLogin field to $updateCount users');

        showSafeSnackbar(
          title: 'Update Berhasil',
          message: 'Field isLogin berhasil ditambahkan ke $updateCount user',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        debugPrint('DEBUG: All users already have isLogin field');
        showSafeSnackbar(
          title: 'Info',
          message: 'Semua user sudah memiliki field isLogin',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

    } catch (e) {
      debugPrint('DEBUG: Error adding isLogin field to users: $e');
      showSafeSnackbar(
        title: 'Error',
        message: 'Gagal menambahkan field isLogin: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}