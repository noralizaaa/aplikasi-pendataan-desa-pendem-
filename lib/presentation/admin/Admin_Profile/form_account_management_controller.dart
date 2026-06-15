// lib/presentation/admin/Admin_Profile/form_account_management_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

import 'managed_account_model.dart';
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';

/// [AppUser] merepresentasikan data pengguna dasar yang diambil dari Firestore.
/// 
/// Digunakan untuk menampilkan daftar pengguna yang dapat diberi otoritas 
/// pada formulir tertentu.
class AppUser {
  /// ID unik pengguna (UID).
  final String id;
  /// Alamat email pengguna.
  final String email;
  /// Nama pengguna (opsional).
  final String? username;
  /// Peran pengguna dalam sistem (user, admin_desa, dll).
  final String role;

  AppUser({
    required this.id,
    required this.email,
    this.username,
    required this.role,
  });

  /// Membuat instance [AppUser] dari dokumen Firestore.
  factory AppUser.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final Map<String, dynamic> data = doc.data();

    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? 'N/A',
      username: data['username'] as String?,
      role: data['role'] as String? ?? 'user',
    );
  }
}

/// [FormAccountManagementController] mengelola hak akses akun untuk formulir spesifik.
/// 
/// Controller ini memungkinkan admin untuk:
/// 1. Melihat daftar akun yang memiliki otoritas pada suatu formulir.
/// 2. Menambah otoritas pengguna via email atau memilih dari daftar.
/// 3. Membuat akun sistem baru dan secara otomatis memberi otoritas jika perannya adalah 'user'.
/// 4. Menghapus otoritas akun dari formulir tertentu.
class FormAccountManagementController extends GetxController {
  /// ID formulir yang sedang dikelola.
  final RxString formId = ''.obs;
  /// Judul formulir yang sedang dikelola.
  final RxString formTitle = ''.obs;

  /// Daftar akun yang saat ini memiliki otoritas pada formulir ini.
  final RxList<ManagedAccount> accounts = <ManagedAccount>[].obs;
  /// Daftar pengguna yang memenuhi syarat untuk diberi otoritas (belum memiliki akses).
  final RxList<AppUser> eligibleUsers = <AppUser>[].obs;
  /// Data master seluruh pengguna dengan peran 'user'.
  final RxList<AppUser> _allFetchedUsers = <AppUser>[].obs;
  /// Daftar desa untuk keperluan dropdown saat pembuatan akun baru.
  final RxList<VillageModel> allVillages = <VillageModel>[].obs;

  /// Status pemuatan data utama.
  final RxBool isLoading = true.obs;
  /// Status pemrosesan aksi (tambah/hapus/buat akun).
  final RxBool isProcessing = false.obs;
  /// Status pemuatan data pengguna untuk dialog pilihan.
  final RxBool isLoadingUsersDialog = false.obs;

  /// Query pencarian untuk daftar akun terotorisasi.
  final RxString searchQuery = ''.obs;
  /// Query pencarian pengguna di dalam dialog pilihan.
  final RxString userSearchQueryDialog = ''.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _accountsSubscription;

  final TextEditingController emailInputController = TextEditingController();
  final TextEditingController userSearchDialogController = TextEditingController();
  final TextEditingController newUserEmailController = TextEditingController();
  final TextEditingController newUsernameController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  final RxBool obscureNewPassword = true.obs;

  static const Color primaryHeaderColor = Color(0xFFF57F17);
  static const Color deleteButtonColor = Colors.red;
  static const Color editButtonColor = Colors.green;
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color tertiaryColor = Color(0xFF2196F3);

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      formId.value = arguments['formId'] as String? ?? '';
      formTitle.value = arguments['formTitle'] as String? ?? 'Akun';

      if (formId.value.isNotEmpty) {
        _listenToAccounts();
        _fetchVillages();
      } else {
        _handleError('Form ID tidak valid.');
      }
    } else {
      _handleError('Argumen tidak ditemukan.');
    }

    userSearchDialogController.addListener(() {
      userSearchQueryDialog.value = userSearchDialogController.text;
      _filterEligibleUsersForDialog();
    });
  }

  void _handleError(
      String message, {
        bool isOperationError = false,
      }) {
    Get.snackbar(
      isOperationError ? 'Operasi Gagal' : 'Error Sistem',
      message,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );

    if (!isOperationError && !isClosed) {
      isLoading.value = false;
    }

    if (!isClosed) {
      isProcessing.value = false;
      isLoadingUsersDialog.value = false;
    }
  }

  /// Mengambil daftar seluruh desa dari Firestore.
  Future<void> _fetchVillages() async {
    try {
      final snapshot = await _db.collection('villages').get();
      allVillages.assignAll(snapshot.docs.map((doc) => VillageModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint("Error fetching villages: $e");
    }
  }

  /// Mendengarkan perubahan data akun terotorisasi secara real-time.
  void _listenToAccounts() {
    isLoading.value = true;

    _accountsSubscription?.cancel();

    _accountsSubscription = _db
        .collection('adminForms')
        .doc(formId.value)
        .collection('managedAccounts')
        .orderBy('email')
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<ManagedAccount> loadedAccounts = snapshot.docs.map((doc) {
          return ManagedAccount.fromFirestore(doc);
        }).toList();

        if (!isClosed) {
          accounts.assignAll(loadedAccounts);

          if (isLoading.value) {
            isLoading.value = false;
          }
        }
      },
      onError: (error) {
        _handleError(
          'Gagal mengambil daftar akun terotorisasi: $error',
        );
      },
    );
  }

  /// Getter untuk mendapatkan daftar akun yang telah disaring berdasarkan pencarian.
  List<ManagedAccount> get filteredAccounts {
    final String query = searchQuery.value.toLowerCase().trim();

    if (query.isEmpty) {
      return accounts;
    }

    return accounts.where((ManagedAccount account) {
      final String emailLower = account.email.toLowerCase();
      return emailLower.contains(query);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Menampilkan dialog untuk menambah otoritas pengguna berdasarkan alamat email.
  void showAddAuthorityByEmailDialog() {
    emailInputController.clear();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tambah Otoritas via Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Untuk Form: "${formTitle.value}"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(
              height: 20,
              thickness: 1,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailInputController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Email Pengguna Terdaftar',
                hintText: 'contoh@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const Text(
              "Pengguna yang ditambahkan akan memiliki peran 'user' pada form ini.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
            },
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Obx(
                () {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryHeaderColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isProcessing.value
                    ? null
                    : () async {
                  final String email = emailInputController.text.trim();

                  if (email.isEmpty) {
                    Get.snackbar(
                      'Input Kosong',
                      'Email tidak boleh kosong.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (!GetUtils.isEmail(email)) {
                    Get.snackbar(
                      'Format Email Salah',
                      'Masukkan format email yang valid.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (Get.isDialogOpen == true) {
                    Navigator.of(Get.overlayContext!).pop();
                  }
                  
                  isProcessing.value = true;
                  await _findUserByEmailAndGrantAuthority(email);
                },
                child: isProcessing.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text(
                  'Tambah',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Mencari pengguna berdasarkan email dan memberikan otoritas jika ditemukan.
  Future<void> _findUserByEmailAndGrantAuthority(String email) async {
    isProcessing.value = true; // Redundant but safe if called elsewhere

    try {
      final QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        Get.snackbar(
          'Pengguna Tidak Ditemukan',
          'Tidak ada pengguna terdaftar dengan email "$email".',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final QueryDocumentSnapshot<Map<String, dynamic>> userDoc =
          usersSnapshot.docs.first;

      final Map<String, dynamic> userData = userDoc.data();

      await _grantAuthority(
        userDoc.id,
        userData['email'] as String? ?? email,
        'user',
      );
    } catch (e) {
      _handleError(
        'Gagal memproses penambahan via email: ${e.toString()}',
        isOperationError: true,
      );
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  /// Menyaring daftar pengguna yang layak (eligible) untuk ditampilkan di dialog pilihan.
  /// 
  /// Pengguna yang sudah memiliki otoritas tidak akan ditampilkan kembali.
  void _filterEligibleUsersForDialog() {
    final String query = userSearchQueryDialog.value.toLowerCase().trim();

    final Set<String?> existingAuthorizedUserIds = accounts.map((acc) {
      return acc.userId;
    }).toSet();

    final List<AppUser> filteredUsers = _allFetchedUsers.where((AppUser user) {
      final bool isAlreadyAuthorized = existingAuthorizedUserIds.contains(user.id);

      if (isAlreadyAuthorized) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final bool usernameMatches =
          user.username?.toLowerCase().contains(query) ?? false;

      final bool emailMatches = user.email.toLowerCase().contains(query);

      return usernameMatches || emailMatches;
    }).toList();

    if (!isClosed) {
      eligibleUsers.assignAll(filteredUsers);
    }
  }

  /// Menampilkan dialog untuk memilih pengguna dari daftar user yang ada di sistem.
  Future<void> showSelectUserFromListDialog() async {
    isLoadingUsersDialog.value = true;

    userSearchDialogController.clear();
    _allFetchedUsers.clear();
    eligibleUsers.clear();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: primaryHeaderColor,
            ),
            SizedBox(height: 15),
            Text('Memuat daftar pengguna...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'user')
          .orderBy('username')
          .get();

      final List<AppUser> loadedUsers = usersSnapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc);
      }).toList();

      if (!isClosed) {
        _allFetchedUsers.assignAll(loadedUsers);
        _filterEligibleUsersForDialog();
      }

      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      if (_allFetchedUsers.isEmpty) {
        Get.snackbar(
          'Tidak Ada Pengguna',
          "Tidak ada pengguna dengan peran 'user' yang terdaftar di sistem.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
        );
        return;
      }

      if (eligibleUsers.isEmpty && _allFetchedUsers.isNotEmpty) {
        Get.snackbar(
          'Semua Sudah Terotorisasi',
          "Semua pengguna 'user' sudah memiliki otoritas untuk form ini.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.lightBlue,
          colorText: Colors.white,
        );
        return;
      }

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            decoration: const BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Pengguna (Peran: User)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Untuk Form: "${formTitle.value}"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          content: SizedBox(
            width: double.maxFinite,
            height: Get.height * 0.55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: TextField(
                    controller: userSearchDialogController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                        () {
                      if (eligibleUsers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              userSearchQueryDialog.value.isEmpty
                                  ? "Tidak ada pengguna 'user' yang bisa dipilih."
                                  : "Tidak ada pengguna ditemukan untuk '${userSearchQueryDialog.value}'.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: eligibleUsers.length,
                        separatorBuilder: (context, index) {
                          return const Divider(
                            height: 0.5,
                            indent: 16,
                            endIndent: 16,
                            thickness: 0.5,
                          );
                        },
                        itemBuilder: (context, index) {
                          final AppUser user = eligibleUsers[index];

                          final String initial = user.username?.isNotEmpty == true
                              ? user.username![0]
                              : (user.email.isNotEmpty ? user.email[0] : '?');

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: secondaryColor.withValues(alpha: 0.15),
                              child: Text(
                                initial.toUpperCase(),
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              (user.username?.isNotEmpty == true) ? user.username! : user.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 6.0,
                            ),
                            onTap: () async {
                              if (Get.isDialogOpen == true) {
                                Navigator.of(Get.overlayContext!).pop();
                              }
                              isProcessing.value = true;
                              await _grantAuthority(
                                user.id,
                                user.email,
                                'user',
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Get.isDialogOpen == true) {
                  Navigator.of(Get.overlayContext!).pop();
                }
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      _handleError(
        'Gagal memuat daftar pengguna untuk dipilih: ${e.toString()}',
        isOperationError: true,
      );
    } finally {
      if (!isClosed) {
        isLoadingUsersDialog.value = false;
      }
    }
  }

  /// Memberikan hak akses (otoritas) kepada pengguna untuk formulir ini di Firestore.
  Future<void> _grantAuthority(
      String targetUserId,
      String targetUserEmail,
      String role,
      ) async {
    isProcessing.value = true; // Redundant but safe

    try {
      final DocumentReference<Map<String, dynamic>> managedAccountRef = _db
          .collection('adminForms')
          .doc(formId.value)
          .collection('managedAccounts')
          .doc(targetUserId);

      final DocumentSnapshot<Map<String, dynamic>> existingDoc =
      await managedAccountRef.get();

      if (existingDoc.exists) {
        Get.snackbar(
          'Sudah Ada Otoritas',
          'Pengguna "$targetUserEmail" sudah memiliki otoritas untuk form ini.',
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await managedAccountRef.set({
        'email': targetUserEmail,
        'userId': targetUserId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Otoritas Diberikan',
        'Otoritas untuk "$targetUserEmail" berhasil ditambahkan.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _handleError(
        'Gagal memberi otoritas: ${e.toString()}',
        isOperationError: true,
      );
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  /// Menampilkan dialog untuk membuat akun pengguna sistem baru.
  void showCreateSystemUserDialog() {
    debugPrint('FormAccountManagementController: Opening Create User Dialog');
    debugPrint('FormAccountManagementController: Villages available: ${allVillages.length}');

    newUserEmailController.clear();
    newUsernameController.clear();
    newPasswordController.clear();
    obscureNewPassword.value = true;

    final RxString selectedRole = 'user'.obs;
    final RxString selectedVillageId = ''.obs;
    final RxString selectedVillageName = ''.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Buat Akun Pengguna Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newUsernameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pengguna',
                  hintText: 'Masukkan nama pengguna',
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
              const SizedBox(height: 15),
              TextFormField(
                controller: newUserEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email pengguna',
                  prefixIcon: const Icon(Icons.email_outlined),
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
              const SizedBox(height: 15),
              Obx(
                    () {
                  return TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          obscureNewPassword.toggle();
                        },
                      ),
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
                  );
                },
              ),
              const SizedBox(height: 15),
              Obx(
                    () {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedRole.value,
                    decoration: InputDecoration(
                      labelText: 'Peran',
                      prefixIcon: const Icon(Icons.security_outlined),
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
                    items: ['global_admin', 'admin_desa', 'admin_rt', 'user'].map((String value) {
                      String label = value.replaceAll('_', ' ').capitalizeFirst ?? value;
                      if (value == 'admin_rt') label = 'Admin Monitoring';
                      if (value == 'global_admin') label = 'Global Admin';

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedRole.value = newValue;
                        if (newValue == 'global_admin') {
                          selectedVillageId.value = '';
                          selectedVillageName.value = '';
                        }
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 15),
              Obx(() {
                if (selectedRole.value == 'global_admin') return const SizedBox.shrink();

                return DropdownButtonFormField<String>(
                  initialValue: selectedVillageId.value.isEmpty ? null : selectedVillageId.value,
                  decoration: InputDecoration(
                    labelText: 'Desa',
                    prefixIcon: const Icon(Icons.holiday_village_outlined),
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
                  items: allVillages.map((VillageModel village) {
                    return DropdownMenuItem<String>(
                      value: village.villageId,
                      child: Text(village.villageName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedVillageId.value = newValue;
                      final selectedVillage = allVillages.firstWhereOrNull((v) => v.villageId == newValue);
                      if (selectedVillage != null) {
                        selectedVillageName.value = selectedVillage.villageName;
                      }
                    }
                  },
                );
              }),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(15),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Batal'),
          ),
          Obx(
                () {
              return ElevatedButton.icon(
                onPressed: isProcessing.value
                    ? null
                    : () async {
                  final String email = newUserEmailController.text.trim();
                  final String username =
                  newUsernameController.text.trim();
                  final String password =
                  newPasswordController.text.trim();
                  final String role = selectedRole.value;
                  final String vId = selectedVillageId.value;
                  final String vName = selectedVillageName.value;

                  if (email.isEmpty ||
                      username.isEmpty ||
                      password.isEmpty) {
                    Get.snackbar(
                      'Input Tidak Lengkap',
                      'Semua field harus diisi.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (role != 'global_admin' && vId.isEmpty) {
                    Get.snackbar('Error', 'Desa harus dipilih.');
                    return;
                  }

                  if (!GetUtils.isEmail(email)) {
                    Get.snackbar(
                      'Format Email Salah',
                      'Masukkan format email yang valid.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (password.length < 6) {
                    Get.snackbar(
                      'Password Lemah',
                      'Password minimal harus 6 karakter.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (Get.isDialogOpen == true) {
                    Navigator.of(Get.overlayContext!).pop();
                  }
                  
                  isProcessing.value = true;

                  await _processNewSystemUserCreation(
                    email,
                    password,
                    username,
                    role,
                    vId,
                    vName,
                  );
                },
                icon: isProcessing.value
                    ? const SizedBox.shrink()
                    : const Icon(
                  Icons.person_add_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: isProcessing.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Buat Akun',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryHeaderColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Memproses pembuatan akun baru dan memberikan otoritas secara otomatis jika perannya 'user'.
  Future<void> _processNewSystemUserCreation(
      String email,
      String password,
      String username,
      String role,
      String vId,
      String vName,
      ) async {
    isProcessing.value = true; // Redundant but safe

    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      fb_auth.FirebaseAuth secondaryAuth = fb_auth.FirebaseAuth.instanceFor(app: secondaryApp);

      final fb_auth.UserCredential userCredential =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb_auth.User? newUser = userCredential.user;

      if (newUser == null) {
        throw Exception('Gagal mendapatkan detail pengguna baru.');
      }

      final Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'displayName': username,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': newUser.uid,
      };

      if (role != 'global_admin') {
        userData['villageId'] = vId;
        userData['villageName'] = vName;
      }

      await _db.collection('users').doc(newUser.uid).set(userData);

      // Auto-grant authority if it's a regular user for this form
      if (role == 'user') {
        await _grantAuthority(newUser.uid, email, 'user');
      }

      await secondaryApp.delete();

      Get.snackbar(
        'Berhasil',
        'Akun pengguna baru "$username" ($email) berhasil dibuat.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal membuat akun pengguna baru.';

      if (e.code == 'weak-password') {
        errorMessage = 'Password yang diberikan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar untuk akun lain.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }

      _handleError(
        errorMessage,
        isOperationError: true,
      );
    } catch (e) {
      _handleError(
        'Terjadi kesalahan saat membuat pengguna: ${e.toString()}',
        isOperationError: true,
      );
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  void editAccount(ManagedAccount account) {
    Get.snackbar(
      'Info',
      'Fitur edit untuk akun ${account.email} belum diimplementasikan.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Menghapus otoritas akun dari formulir ini setelah konfirmasi.
  void deleteAccount(ManagedAccount account) {
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus otoritas untuk akun "${account.email}" dari form "${formTitle.value}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deleteButtonColor,
            ),
            onPressed: () async {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
              
              isProcessing.value = true;

              try {
                await _db
                    .collection('adminForms')
                    .doc(formId.value)
                    .collection('managedAccounts')
                    .doc(account.id)
                    .delete();

                Get.snackbar(
                  'Berhasil',
                  'Otoritas untuk akun "${account.email}" berhasil dihapus.',
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                _handleError(
                  'Gagal menghapus otoritas akun: ${e.toString()}',
                  isOperationError: true,
                );
              } finally {
                if (!isClosed) {
                  isProcessing.value = false;
                }
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _accountsSubscription?.cancel();

    emailInputController.dispose();
    userSearchDialogController.dispose();
    newUserEmailController.dispose();
    newUsernameController.dispose();
    newPasswordController.dispose();

    super.onClose();
  }
}
