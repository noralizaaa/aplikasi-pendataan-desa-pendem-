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

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

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
      print('DEBUG: Firebase login successful for ${userCredential.user?.email}. UID: ${userCredential.user?.uid}');
      // Navigasi akan ditangani oleh authStateChanges
    } on FirebaseAuthException catch (e) {
      print('ERROR: FirebaseAuthException during UI login: ${e.code} - ${e.message}');
      Get.snackbar(
        'Login Gagal',
        'Error: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      print('ERROR: Unexpected exception during UI login: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isManualLogin.value = false; // Reset setelah login selesai
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