// lib/presentation/admin/Admin_Profile/all_account_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_account_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart';
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';

/// [AllAccountController] mengelola daftar seluruh akun pengguna dalam sistem.
/// 
/// Controller ini menyediakan fitur:
/// 1. Sinkronisasi real-time daftar pengguna dari Firestore.
/// 2. Pembuatan akun baru (System User) dengan role tertentu.
/// 3. Pencarian, pengeditan, dan penghapusan akun pengguna.
/// 4. Filtering otomatis berdasarkan wilayah tugas admin (Role-Based Access).
class AllAccountController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Daftar seluruh akun yang diambil dari database.
  final RxList<AdminAccountModel> allAccounts = <AdminAccountModel>[].obs;
  /// Daftar akun yang telah disaring berdasarkan query pencarian.
  final RxList<AdminAccountModel> filteredAccounts = <AdminAccountModel>[].obs;
  /// Daftar desa untuk keperluan dropdown saat pembuatan/pengeditan akun.
  final RxList<VillageModel> allVillages = <VillageModel>[].obs;
  /// Status loading data.
  final RxBool isLoading = true.obs;
  /// Peran admin yang sedang login.
  final RxString userRole = ''.obs;
  /// ID desa admin yang sedang login.
  final RxString villageId = ''.obs;
  /// Nama desa admin yang sedang login.
  final RxString villageName = ''.obs;
  /// Query pencarian akun (email/username).
  final RxString searchQuery = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;

  static const String _usersCollectionPath = 'users';

  @override
  void onInit() {
    super.onInit();

    _fetchVillages();
    _listenToAllUsers();

    // Jalankan filter otomatis setiap kali query pencarian berubah.
    ever(searchQuery, (_) {
      _filterAccounts();
    });
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

  /// Mendengarkan perubahan data pengguna secara real-time dari Firestore.
  /// 
  /// Menerapkan filter wilayah tugas jika admin memiliki role [admin_desa].
  void _listenToAllUsers() {
    isLoading.value = true;

    _usersSubscription?.cancel();

    _fetchUserInfo().then((_) {
      Query<Map<String, dynamic>> usersQuery = _db.collection(_usersCollectionPath);

      // Filtering for admin_desa (only show accounts from their village)
      if ((userRole.value == 'admin_desa' || userRole.value == 'admindesa') && villageId.value.isNotEmpty) {
        usersQuery = usersQuery.where('villageId', isEqualTo: villageId.value);
      }

      _usersSubscription = usersQuery.snapshots().listen(
            (QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<AdminAccountModel> fetchedAccounts = snapshot.docs.map((doc) {
            return AdminAccountModel.fromMap(doc.id, doc.data());
          }).toList();

          if (!isClosed) {
            allAccounts.assignAll(fetchedAccounts);
            _filterAccounts();
            isLoading.value = false;
          }

          debugPrint('AllAccountController: Fetched ${fetchedAccounts.length} users.');
        },
        onError: (error) {
          debugPrint('Error fetching all users: $error');

          if (!isClosed) {
            isLoading.value = false;
          }

          showSafeSnackbar(
            title: 'Error Data Akun',
            message: 'Gagal mengambil daftar akun: $error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      );
    });
  }

  /// Mengambil informasi profil admin yang sedang aktif.
  Future<void> _fetchUserInfo() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userRole.value = userDoc.data()?['role'] as String? ?? 'user';
          villageId.value = userDoc.data()?['villageId'] as String? ?? '';
          villageName.value = userDoc.data()?['villageName'] as String? ?? '';
        }
      } catch (e) {
        debugPrint("Error fetching user info: $e");
      }
    }
  }

  /// Memperbarui query pencarian global.
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Menyaring daftar akun berdasarkan nama pengguna atau email.
  void _filterAccounts() {
    final String query = searchQuery.value.toLowerCase().trim();

    if (query.isEmpty) {
      filteredAccounts.assignAll(allAccounts);
      return;
    }

    final List<AdminAccountModel> result = allAccounts.where((account) {
      final String email = account.email.toLowerCase();
      final String username = account.username.toLowerCase();

      return email.contains(query) || username.contains(query);
    }).toList();

    filteredAccounts.assignAll(result);
  }

  /// Helper untuk menampilkan snackbar yang aman dari context null.
  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
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
    );
  }

  /// Menampilkan dialog untuk pembuatan akun pengguna baru.
  /// 
  /// Dialog ini mencakup pemilihan role, desa, dan wilayah tugas RT/RW.
  Future<void> showCreateSystemUserDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController rtController = TextEditingController();
    final TextEditingController rwController = TextEditingController();
    final RxString selectedRole = 'user'.obs;
    final RxString selectedVillageId = ''.obs;
    final RxString selectedVillageName = ''.obs;

    await Get.dialog(
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
                controller: usernameController,
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
                controller: emailController,
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
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                      String label = value.replaceAll('_', ' ').toUpperCase() ?? value;
                      if (value == 'admin_rt') label = 'ADMIN MONITORING (RT/RW)';
                      if (value == 'global_admin') label = 'GLOBAL ADMIN';
                      
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
                
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedVillageId.value.isEmpty ? null : selectedVillageId.value,
                      decoration: InputDecoration(
                        labelText: 'Desa',
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    ),
                    if (selectedRole.value == 'admin_rt' || selectedRole.value == 'user') ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: rtController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'RT',
                                hintText: '001',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: rwController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'RW',
                                hintText: '001',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
          ElevatedButton(
            onPressed: () async {
              final String email = emailController.text.trim();
              final String password = passwordController.text.trim();
              final String username = usernameController.text.trim();
              final String role = selectedRole.value;
              final String vId = selectedVillageId.value;
              final String vName = selectedVillageName.value;
              final String rt = rtController.text.trim();
              final String rw = rwController.text.trim();

              if (email.isEmpty || password.isEmpty || username.isEmpty) {
                showSafeSnackbar(
                  title: 'Error',
                  message: 'Semua field harus diisi.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (role != 'global_admin' && vId.isEmpty) {
                showSafeSnackbar(
                  title: 'Error',
                  message: 'Desa harus dipilih untuk Admin Desa atau User.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
              await _createSystemUser(
                email,
                password,
                username,
                role,
                vId,
                vName,
                rt: rt,
                rw: rw,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.accentHeaderColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: const Text('Buat Akun'),
          ),
        ],
      ),
    );
  }

  /// Proses pembuatan akun baru di Firebase Auth dan Firestore.
  /// 
  /// Menggunakan [Secondary Firebase App] agar admin tidak ter-logout 
  /// saat mendaftarkan user baru.
  Future<void> _createSystemUser(
      String email,
      String password,
      String username,
      String role,
      String selectedVillageId,
      String selectedVillageName, {
      String? rt,
      String? rw,
      }) async {
    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final UserCredential userCredential =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String newUid = userCredential.user!.uid;

      final Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role != 'global_admin') {
        userData['villageId'] = selectedVillageId;
        userData['villageName'] = selectedVillageName;
      }
      
      if (role == 'admin_rt' || role == 'user') {
        userData['rt'] = rt;
        userData['rw'] = rw;
      }

      await _db.collection(_usersCollectionPath).doc(newUid).set(userData);

      await secondaryApp.delete();

      showSafeSnackbar(
        title: 'Sukses',
        message: 'Akun pengguna "$username" berhasil dibuat.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal membuat akun: ${e.message}';
      showSafeSnackbar(title: 'Error', message: message, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      showSafeSnackbar(title: 'Error', message: 'Terjadi kesalahan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Menampilkan dialog untuk mengedit detail akun pengguna.
  Future<void> editAccount(AdminAccountModel account) async {
    final TextEditingController usernameController =
    TextEditingController(text: account.username);
    final TextEditingController rtController = TextEditingController(text: account.rt ?? '');
    final TextEditingController rwController = TextEditingController(text: account.rw ?? '');

    final RxString selectedRole = account.role.obs;
    final RxString selectedVillageId = (account.villageId ?? '').obs;
    final RxString selectedVillageName = (account.villageName ?? '').obs;

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Edit Akun Pengguna',
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
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pengguna',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                    ),
                    items: ['global_admin', 'admin_desa', 'admin_rt', 'user'].map((String value) {
                      String label = value.replaceAll('_', ' ').toUpperCase() ?? value;
                      if (value == 'admin_rt') label = 'ADMIN MONITORING (RT/RW)';
                      if (value == 'global_admin') label = 'GLOBAL ADMIN';
                      
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
                
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedVillageId.value.isEmpty ? null : selectedVillageId.value,
                      decoration: InputDecoration(
                        labelText: 'Desa',
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    ),
                    if (selectedRole.value == 'admin_rt' || selectedRole.value == 'user') ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: rtController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'RT',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: rwController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'RW',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
          ElevatedButton(
            onPressed: () async {
              final String newUsername = usernameController.text.trim();
              final String newRole = selectedRole.value;
              final String vId = selectedVillageId.value;
              final String vName = selectedVillageName.value;
              final String rt = rtController.text.trim();
              final String rw = rwController.text.trim();

              if (newRole != 'global_admin' && vId.isEmpty) {
                showSafeSnackbar(
                  title: 'Error',
                  message: 'Desa harus dipilih.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
              await _updateAccountDetails(
                account.uid,
                newUsername,
                newRole,
                vId,
                vName,
                rt: rt,
                rw: rw,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.accentHeaderColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Memperbarui detail akun pengguna di Firestore.
  Future<void> _updateAccountDetails(
      String uid,
      String newUsername,
      String newRole,
      String vId,
      String vName, {
      String? rt,
      String? rw,
      }) async {
    try {
      final Map<String, dynamic> updateData = {
        'username': newUsername,
        'role': newRole,
      };

      if (newRole != 'global_admin') {
        updateData['villageId'] = vId;
        updateData['villageName'] = vName;
      } else {
        updateData['villageId'] = null;
        updateData['villageName'] = null;
      }
      
      if (newRole == 'admin_rt' || newRole == 'user') {
        updateData['rt'] = rt;
        updateData['rw'] = rw;
      } else {
        updateData['rt'] = null;
        updateData['rw'] = null;
      }

      await _db.collection(_usersCollectionPath).doc(uid).update(updateData);
      showSafeSnackbar(title: 'Sukses', message: 'Detail akun diperbarui.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      showSafeSnackbar(title: 'Error', message: 'Gagal memperbarui akun: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Menghapus akun pengguna dari Firestore setelah konfirmasi.
  Future<void> deleteAccount(AdminAccountModel account) async {
    if (_auth.currentUser?.uid == account.uid) {
      showSafeSnackbar(
        title: 'Error',
        message: 'Anda tidak bisa menghapus akun sendiri.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus akun "${account.email}"?'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
              try {
                await _db.collection(_usersCollectionPath).doc(account.uid).delete();
                showSafeSnackbar(title: 'Berhasil', message: 'Akun dihapus.', backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                showSafeSnackbar(title: 'Error', message: 'Gagal hapus akun: $e', backgroundColor: Colors.red, colorText: Colors.white);
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
    _usersSubscription?.cancel();
    super.onClose();
  }
}
