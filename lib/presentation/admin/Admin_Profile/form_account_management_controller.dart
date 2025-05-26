// lib/presentation/admin/Admin_Profile/form_account_management_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias untuk FirebaseAuth
import 'managed_account_model.dart';

// Placeholder User Model (pastikan sesuai dengan struktur di /users)
class AppUser {
  final String id;
  final String email;
  final String? username;
  final String role;

  AppUser({required this.id, required this.email, this.username, required this.role});

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? 'N/A',
      username: data['username'] as String?,
      role: data['role'] as String? ?? 'user',
    );
  }
}


class FormAccountManagementController extends GetxController {
  final RxString formId = ''.obs;
  final RxString formTitle = ''.obs;
  final RxList<ManagedAccount> accounts = <ManagedAccount>[].obs;
  final RxList<AppUser> eligibleUsers = <AppUser>[].obs;
  final RxList<AppUser> _allFetchedUsers = <AppUser>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isLoadingUsersDialog = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString userSearchQueryDialog = ''.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance; // Instance FirebaseAuth
  StreamSubscription? _accountsSubscription;

  // Controllers untuk dialog
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
  static const Color tertiaryColor = Color(0xFF2196F3); // Warna untuk tombol "Buat Akun Baru"

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      formId.value = arguments['formId'] ?? '';
      formTitle.value = arguments['formTitle'] ?? 'Akun';
      if (formId.value.isNotEmpty) {
        _listenToAccounts();
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

  void _handleError(String message, {bool isOperationError = false}) {
    Get.snackbar(isOperationError ? 'Operasi Gagal' : 'Error Sistem', message,
        backgroundColor: Colors.red.shade700, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    if (!isOperationError) isLoading.value = false;
    isProcessing.value = false;
    isLoadingUsersDialog.value = false;
  }

  void _listenToAccounts() {
    isLoading.value = true;
    _accountsSubscription?.cancel();
    _accountsSubscription = _db
        .collection('adminForms')
        .doc(formId.value)
        .collection('managedAccounts')
        .orderBy('email')
        .snapshots()
        .listen((snapshot) {
      accounts.assignAll(snapshot.docs
          .map((doc) => ManagedAccount.fromFirestore(doc))
          .toList());
      if(isLoading.value) isLoading.value = false;
    }, onError: (error) {
      _handleError('Gagal mengambil daftar akun terotorisasi: $error');
    });
  }

  List<ManagedAccount> get filteredAccounts {
    if (searchQuery.value.isEmpty) return accounts;
    return accounts
        .where((account) =>
        account.email.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void showAddAuthorityByEmailDialog() {
    emailInputController.clear();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tambah Otoritas via Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Untuk Form: "${formTitle.value}"', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            const Divider(height: 20, thickness: 1),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const Text(
              "Pengguna yang ditambahkan akan memiliki peran 'user' pada form ini.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryHeaderColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: isProcessing.value ? null : () async {
              final email = emailInputController.text.trim();
              if (email.isNotEmpty) {
                Get.back();
                await _findUserByEmailAndGrantAuthority(email);
              } else {
                Get.snackbar('Input Kosong', 'Email tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
              }
            },
            child: isProcessing.value
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _findUserByEmailAndGrantAuthority(String email) async {
    isProcessing.value = true;
    try {
      final usersSnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        Get.snackbar('Pengguna Tidak Ditemukan', 'Tidak ada pengguna terdaftar dengan email "$email".',
            backgroundColor: Colors.orange.shade700, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        isProcessing.value = false;
        return;
      }
      final userDoc = usersSnapshot.docs.first;
      await _grantAuthority(userDoc.id, userDoc.data()['email'] as String? ?? email, 'user');
    } catch (e) {
      _handleError('Gagal memproses penambahan via email: ${e.toString()}', isOperationError: true);
    } finally {
      if(!isClosed) isProcessing.value = false;
    }
  }

  void _filterEligibleUsersForDialog() {
    final query = userSearchQueryDialog.value.toLowerCase();
    final Set<String?> existingAuthorizedUserIds = accounts.map((acc) => acc.userId).toSet();

    if (query.isEmpty) {
      eligibleUsers.assignAll(
          _allFetchedUsers.where((user) => !existingAuthorizedUserIds.contains(user.id)).toList()
      );
    } else {
      eligibleUsers.assignAll(
          _allFetchedUsers.where((user) {
            final bool matchesQuery =
                (user.username?.toLowerCase().contains(query) ?? false) ||
                    user.email.toLowerCase().contains(query);
            return matchesQuery && !existingAuthorizedUserIds.contains(user.id);
          }).toList()
      );
    }
  }

  Future<void> showSelectUserFromListDialog() async {
    isLoadingUsersDialog.value = true;
    userSearchDialogController.clear();
    userSearchQueryDialog.value = '';
    _allFetchedUsers.clear();
    eligibleUsers.clear();

    Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryHeaderColor),
              SizedBox(height: 15),
              Text("Memuat daftar pengguna..."),
            ],
          ),
        ),
        barrierDismissible: false);

    try {
      final usersSnapshot = await _db.collection('users').where('role', isEqualTo: 'user').orderBy('username').get();
      _allFetchedUsers.assignAll(usersSnapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
      _filterEligibleUsersForDialog();
      Get.back();

      if (_allFetchedUsers.isEmpty) {
        Get.snackbar("Tidak Ada Pengguna", "Tidak ada pengguna dengan peran 'user' yang terdaftar di sistem.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4), backgroundColor: Colors.blueGrey, colorText: Colors.white);
        isLoadingUsersDialog.value = false;
        return;
      }
      if (eligibleUsers.isEmpty && _allFetchedUsers.isNotEmpty) {
        Get.snackbar("Semua Sudah Terotorisasi", "Semua pengguna dengan peran 'user' sudah memiliki otoritas untuk form ini.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4), backgroundColor: Colors.lightBlue, colorText: Colors.white);
        isLoadingUsersDialog.value = false;
        return;
      }

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          titlePadding: const EdgeInsets.all(0),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Pengguna (Peran: User)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                Text('Untuk Form: "${formTitle.value}"', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: TextField(
                    controller: userSearchDialogController,
                    decoration: InputDecoration(
                      hintText: "Cari nama atau email...",
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (eligibleUsers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            userSearchQueryDialog.value.isEmpty
                                ? "Tidak ada pengguna 'user' yang bisa dipilih saat ini (mungkin semua sudah terotorisasi)."
                                : "Tidak ada pengguna ditemukan untuk '${userSearchQueryDialog.value}'.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: eligibleUsers.length,
                      separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 16, endIndent: 16, thickness: 0.5),
                      itemBuilder: (context, index) {
                        final user = eligibleUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: secondaryColor.withOpacity(0.15),
                            child: Text(
                              (user.username?.isNotEmpty == true ? user.username![0] : user.email[0]).toUpperCase(),
                              style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user.username ?? user.email, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          subtitle: Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                          onTap: () async {
                            Get.back();
                            await _grantAuthority(user.id, user.email, 'user');
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: const Text("Batal", style: TextStyle(color: Colors.grey, fontSize: 15))),
          ],
        ),
        barrierDismissible: false,
      );

    } catch (e) {
      Get.back();
      _handleError('Gagal memuat daftar pengguna untuk dipilih: ${e.toString()}', isOperationError: true);
    } finally {
      if(!isClosed) isLoadingUsersDialog.value = false;
    }
  }

  Future<void> _grantAuthority(String targetUserId, String targetUserEmail, String role) async {
    isProcessing.value = true;
    try {
      final managedAccountRef = _db.collection('adminForms').doc(formId.value).collection('managedAccounts').doc(targetUserId);
      final existingDoc = await managedAccountRef.get();
      if (existingDoc.exists) {
        Get.snackbar('Sudah Ada Otoritas', 'Pengguna "$targetUserEmail" sudah memiliki otoritas untuk form ini.',
            backgroundColor: Colors.blue.shade600, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        isProcessing.value = false;
        return;
      }
      await managedAccountRef.set({
        'email': targetUserEmail,
        'userId': targetUserId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Otoritas Diberikan', 'Otoritas untuk "$targetUserEmail" (Peran: $role) berhasil ditambahkan.',
          backgroundColor: Colors.green.shade600, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      _handleError('Gagal memberi otoritas: ${e.toString()}', isOperationError: true);
    } finally {
      if(!isClosed) isProcessing.value = false;
    }
  }

  // --- FUNGSI UNTUK MEMBUAT PENGGUNA SISTEM BARU (UI DIBENAHI) ---
  void showCreateSystemUserDialog() {
    newUserEmailController.clear();
    newUsernameController.clear();
    newPasswordController.clear();
    obscureNewPassword.value = true;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Sudut lebih membulat
        titlePadding: const EdgeInsets.all(0), // Hapus padding default
        title: Container( // Header Kustom
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: tertiaryColor, // Menggunakan warna tertiary (biru)
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: const Center( // Judul di tengah
            child: Text(
              'Buat Akun Pengguna Baru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Informasi Akun", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTextField(
                controller: newUsernameController,
                labelText: 'Username',
                hintText: 'Masukkan username unik',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: newUserEmailController,
                labelText: 'Email',
                hintText: 'contoh@email.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Obx(() => _buildTextField(
                controller: newPasswordController,
                labelText: 'Password',
                hintText: 'Minimal 6 karakter',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: obscureNewPassword.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNewPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => obscureNewPassword.toggle(),
                ),
              )),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Pengguna baru akan otomatis dibuat dengan peran 'user'.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              )
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsAlignment: MainAxisAlignment.spaceBetween, // Tombol menyebar
        actions: [
          OutlinedButton( // Tombol Batal dengan outline
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          Obx(() => ElevatedButton.icon( // Tombol Buat Akun dengan ikon
            style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor, // Warna tombol utama
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: isProcessing.value ? null : () async {
              final email = newUserEmailController.text.trim();
              final username = newUsernameController.text.trim();
              final password = newPasswordController.text.trim();

              if (email.isEmpty || username.isEmpty || password.isEmpty) {
                Get.snackbar('Input Tidak Lengkap', 'Semua field harus diisi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
                return;
              }
              if (password.length < 6) {
                Get.snackbar('Password Lemah', 'Password minimal harus 6 karakter.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
                return;
              }
              Get.back();
              await _processNewSystemUserCreation(email, password, username);
            },
            icon: isProcessing.value ? Container() : const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
            label: isProcessing.value
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Buat Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Helper widget untuk TextField agar lebih konsisten
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: tertiaryColor.withOpacity(0.8), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: tertiaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      ),
    );
  }


  Future<void> _processNewSystemUserCreation(String email, String password, String username) async {
    isProcessing.value = true;
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      fb_auth.User? newUser = userCredential.user;

      if (newUser != null) {
        await _db.collection('users').doc(newUser.uid).set({
          'username': username,
          'email': email,
          'displayName': username,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'uid': newUser.uid,
        });
        Get.snackbar('Berhasil', 'Akun pengguna baru "$username" ($email) berhasil dibuat.',
            backgroundColor: Colors.green.shade600, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      } else {
        throw Exception("Gagal mendapatkan detail pengguna baru dari Firebase Auth.");
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = "Gagal membuat akun pengguna baru.";
      if (e.code == 'weak-password') { errorMessage = 'Password yang diberikan terlalu lemah.'; }
      else if (e.code == 'email-already-in-use') { errorMessage = 'Email ini sudah terdaftar untuk akun lain.'; }
      else if (e.code == 'invalid-email') { errorMessage = 'Format email tidak valid.'; }
      _handleError(errorMessage, isOperationError: true);
    } catch (e) {
      _handleError('Terjadi kesalahan: ${e.toString()}', isOperationError: true);
    } finally {
      if(!isClosed) isProcessing.value = false;
    }
  }
  // --- AKHIR FUNGSI BARU ---

  void editAccount(ManagedAccount account) { /* ... */ }
  void deleteAccount(ManagedAccount account) { /* ... */ }
  void updateSearchQuery(String query) { /* ... */ }

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
