import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/navigation/routes.dart';
import '../../domain/auth/models/auth_user.dart';
import '../../domain/auth/models/user_model.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isManualLogin = false.obs;
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
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        UserModel firestoreUserModel = UserModel.fromFirestore(userDoc as DocumentSnapshot<Map<String, dynamic>>);
        finalRoleFromFirestore = firestoreUserModel.role;
        print('DEBUG: User document found in Firestore. Role: $finalRoleFromFirestore');

        // Cek apakah field isLogin sudah ada, jika belum tambahkan
        Map<String, dynamic> updateData = {
          'isLogin': true,
          'lastLoginAt': FieldValue.serverTimestamp(),
        };

        // Jika field isLogin belum ada, tambahkan dengan timestamp
        if (!userData.containsKey('isLogin')) {
          updateData['isLoginFieldAddedAt'] = FieldValue.serverTimestamp();
          print('DEBUG: Adding isLogin field for the first time for user: ${firebaseUser.email}');
        }

        await _firestore.collection('users').doc(firebaseUser.uid).update(updateData);
        print('DEBUG: Updated isLogin to true for user: ${firebaseUser.email}');

      } else {
        print('DEBUG: User document NOT found in Firestore for UID: ${firebaseUser.uid}. Assigning default role and creating doc.');
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
        print('DEBUG: Created new user document with isLogin: true');
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
    isManualLogin.value = true;
    _loginAttemptCounter++;
    print('DEBUG: Attempting login via UI. Counter: $_loginAttemptCounter');

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Validasi Input Kosong
    if (email.isEmpty || password.isEmpty) {
      print('DEBUG: Login input empty. Email: "$email", Password: "$password"');
      Get.snackbar(
        'Input Tidak Lengkap',
        'Email dan password tidak boleh kosong.',
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

    // Validasi Format Email
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

    try {
      print('DEBUG: Attempting Firebase login. Email: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('DEBUG: Firebase login successful for ${userCredential.user?.email}. UID: ${userCredential.user?.uid}');

      // Navigasi akan ditangani oleh authStateChanges dan _loadAndSetAuthUser
      // yang akan mengupdate isLogin menjadi true

    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException - RAW ERROR CODE: "${e.code}", Message: "${e.message}"');

      String errorMessage;
      String normalizedCode = e.code.toLowerCase().replaceAll('error_', '').replaceAll('-', '_');

      switch (normalizedCode) {
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
        case 'network_request_failed':
        case 'auth_network_request_failed':
          errorMessage = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
          break;
        default:
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
      print('DEBUG: General login error: $e');
      Get.snackbar(
        'Error Tidak Dikenal',
        'Terjadi kesalahan tidak terduga: $e',
        snackPosition: SnackPosition.BOTTOM,
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
    print('DEBUG: Logout initiated.');

    try {
      // Update isLogin menjadi false di Firestore sebelum sign out
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'isLogin': false,
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
        print('DEBUG: Updated isLogin to false for user: ${currentUser.email}');
      }

      // Sign out dari Firebase Auth
      await _auth.signOut();
      loggedInAuthUser.value = null;

      print('DEBUG: Firebase sign out completed. Redirecting to LoginScreen.');
      Get.offAllNamed(AppRoutes.login);

    } catch (e) {
      print('DEBUG: Error during logout: $e');
      // Tetap sign out meskipun ada error saat update Firestore
      await _auth.signOut();
      loggedInAuthUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // Method untuk mengupdate semua user existing dengan field isLogin
  Future<void> addIsLoginFieldToAllUsers() async {
    try {
      print('DEBUG: Starting batch update to add isLogin field to all existing users');

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
          print('DEBUG: Will add isLogin field to user: ${userData['email'] ?? userData['uid']}');
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('DEBUG: Successfully added isLogin field to $updateCount users');

        Get.snackbar(
          'Update Berhasil',
          'Field isLogin berhasil ditambahkan ke $updateCount user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('DEBUG: All users already have isLogin field');
        Get.snackbar(
          'Info',
          'Semua user sudah memiliki field isLogin',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

    } catch (e) {
      print('DEBUG: Error adding isLogin field to users: $e');
      Get.snackbar(
        'Error',
        'Gagal menambahkan field isLogin: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}