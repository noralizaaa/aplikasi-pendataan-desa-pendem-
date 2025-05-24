// Path: lib/presentation/user_profile/user_profile_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_model.dart';
import 'package:flutter/material.dart'; // For TextEditinngController, SnackBar

class UserProfileController extends GetxController {
  final Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final TextEditingController usernameController = TextEditingController();

  static int _pendataCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
  }

  @override
  void onClose() {
    usernameController.dispose();
    super.onClose();
  }

  Future<void> _loadUserProfile() async {
    String initialUsername = 'Pengguna';
    String initialRole = 'Peran Tidak Diketahui';
    String? initialProgramId; // Keep as nullable

    if (Get.arguments != null && Get.arguments is Map) {
      initialUsername = Get.arguments['username'] ?? _generateDefaultUsername();
      initialRole = Get.arguments['role'] ?? 'Peran Tidak Diketahui';
      initialProgramId = Get.arguments['programId'] as String?; // Cast to String?
    } else {
      initialUsername = _generateDefaultUsername();
    }

    if (initialProgramId != null && initialProgramId.isNotEmpty && initialProgramId != '000') { // Added check for '000'
      try {
        DocumentSnapshot formDoc = await FirebaseFirestore.instance.collection('forms').doc(initialProgramId).get();
        if (formDoc.exists) {
          final formData = formDoc.data() as Map<String, dynamic>;
          initialRole = formData['nama'] ?? 'Program ID: $initialProgramId';
        } else {
          initialRole = 'Program ID: $initialProgramId (Not Found)';
          // Fallback to default authority role if specific program ID not found
          final defaultRole = await _fetchDefaultAuthorityRole();
          if (defaultRole != null) initialRole = defaultRole;
          initialProgramId = '000'; // Set to default '000' if not found
        }
      } catch (e) {
        print("Error fetching form for role: $e");
        initialRole = 'Error loading role';
        // Fallback to default authority role on error
        final defaultRole = await _fetchDefaultAuthorityRole();
        if (defaultRole != null) initialRole = defaultRole;
        initialProgramId = '000'; // Set to default '000' on error
      }
    } else {
      // If initialProgramId is null, empty, or '000', fetch the default authority role
      final defaultRole = await _fetchDefaultAuthorityRole();
      if (defaultRole != null) {
        initialRole = defaultRole;
      }
      initialProgramId = '000'; // Ensure it's '000' if no specific program ID
    }

    userProfile.value = UserProfile(
      username: initialUsername,
      role: initialRole,
      programId: initialProgramId, // Passed correctly as nullable
    );

    // Only set text if userProfile.value is not null
    if (userProfile.value != null) {
      usernameController.text = userProfile.value!.username;
    }
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
        return data['nama'] ?? 'Tidak ada otoritas (Default)';
      } else {
        print("Firestore document for default role '000' not found. Please create it.");
        return 'Tidak ada otoritas';
      }
    } catch (e) {
      print("Error fetching default authority role from Firestore: $e");
      return 'Tidak ada otoritas (Error)';
    }
  }

  void saveUsername() {
    final newUsername = usernameController.text.trim();
    if (newUsername.isNotEmpty && userProfile.value != null) {
      // Direct assignment is now possible because 'username' is non-final
      userProfile.value!.username = newUsername;
      userProfile.refresh(); // Important to notify GetX about the change in the object
      Get.snackbar(
        'Sukses',
        'Username berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // TODO: In a real app, save this 'newUsername' to Firebase/backend here
      // Example: FirebaseFirestore.instance.collection('users').doc(userId).update({'username': newUsername});
    } else {
      Get.snackbar(
        'Error',
        'Username tidak boleh kosong!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void logout() {
    print('User logged out');
    Get.offAllNamed(AppRoutes.login);
  }
}