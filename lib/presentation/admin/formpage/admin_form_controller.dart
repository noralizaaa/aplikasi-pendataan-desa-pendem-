// lib/presentation/admin/formpage/admin_form_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';

/// [AdminFormController] mengelola daftar formulir pendataan di sisi Admin.
/// 
/// Controller ini bertanggung jawab untuk:
/// 1. Sinkronisasi real-time daftar formulir dari Firestore.
/// 2. Melakukan filter daftar formulir berdasarkan wilayah tugas Admin (RBAC).
/// 3. Menangani operasi CRUD dasar pada level formulir (Tambah, Duplikat, Hapus).
/// 4. Mengelola filter periode pendataan.
class AdminFormController extends GetxController {
  /// Daftar seluruh formulir yang tersedia untuk dikelola.
  final RxList<FormItem> forms = <FormItem>[].obs;
  /// Menandakan status pemuatan data dari Firestore.
  final RxBool isLoading = true.obs;
  /// ID pengguna admin yang sedang aktif.
  final RxString currentUserId = ''.obs;
  /// Peran (role) admin untuk menentukan batasan akses data.
  final RxString userRole = ''.obs;
  /// ID Desa admin untuk filter formulir spesifik wilayah.
  final RxString userVillageId = ''.obs;
  /// Nama Desa admin.
  final RxString userVillageName = ''.obs; // Tambahan
  /// Filter periode pendataan yang dipilih (Default: 'Semua').
  final RxString selectedPeriodFilter = 'Semua'.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _formsSubscription;

  static const String _formsCollectionPath = 'adminForms';

  @override
  void onInit() {
    super.onInit();
    _initializeAndListen();
  }

  /// Mengambil informasi peran dan wilayah tugas admin.
  /// 
  /// Mencoba mengambil data dari [AdminController] jika sudah terdaftar untuk efisiensi,
  /// jika tidak, akan melakukan fetch langsung ke Firestore.
  Future<void> _fetchUserRole() async {
    try {
      // Prioritas: Ambil data dari AdminController jika sudah ada (Share State)
      if (Get.isRegistered<AdminController>()) {
        final adminCtrl = Get.find<AdminController>();
        if (adminCtrl.userRole.value.isNotEmpty) {
          userRole.value = adminCtrl.userRole.value;
          userVillageId.value = adminCtrl.villageId.value;
          userVillageName.value = adminCtrl.villageName.value;
          debugPrint("AdminFormController: Menggunakan data role dari AdminController (Cache)");
          return;
        }
      }

      final User? user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userRole.value = (userDoc.data()?['role'] as String? ?? 'user').toLowerCase().trim();
          userVillageId.value = (userDoc.data()?['villageId'] as String? ?? '').trim();
          userVillageName.value = (userDoc.data()?['villageName'] as String? ?? '').trim();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }

  /// Menginisialisasi identitas user dan mulai mendengarkan perubahan data formulir.
  void _initializeAndListen() {
    final User? user = _auth.currentUser;

    if (user != null) {
      currentUserId.value = user.uid;
      debugPrint(
        'DEBUG: AdminFormController - User terautentikasi: ${user.uid}',
      );
    } else {
      debugPrint(
        'DEBUG: AdminFormController - Tidak ada pengguna yang login.',
      );
    }

    _fetchUserRole().then((_) => _listenToForms());
  }

  /// Mendengarkan perubahan data koleksi `adminForms` secara real-time.
  /// 
  /// Menerapkan filter periode dan batasan akses (Role-Based Access Control).
  /// Admin Desa hanya dapat melihat formulir yang memiliki [villageId] yang sama.
  void _listenToForms() {
    _formsSubscription?.cancel();

    isLoading.value = true;

    Query<Map<String, dynamic>> query = _db.collection(_formsCollectionPath);

    if (selectedPeriodFilter.value != 'Semua') {
      query = query.where('period', isEqualTo: selectedPeriodFilter.value);
    }

    _formsSubscription = query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<FormItem> loadedForms = snapshot.docs.map((doc) {
          return FormItem.fromFirestoreSummary(doc);
        }).toList();

        // FILTER: Hanya tampilkan form yang relevan untuk Admin Desa & Admin Monitoring
        final userModel = UserModel(uid: '', role: userRole.value);
        final String vId = userVillageId.value.trim();
        
        List<FormItem> filteredForms = loadedForms;
        
        if (userModel.isRestrictedAdmin) {
          filteredForms = loadedForms.where((form) {
            // Perketat: Hanya tampilkan form yang villageId-nya cocok persis dengan desa admin
            // (Form umum/null atau form desa lain akan tersembunyi)
            return form.villageId == vId && vId.isNotEmpty;
          }).toList();
        }

        if (!isClosed) {
          forms.assignAll(filteredForms);
          isLoading.value = false;
        }
        
        debugPrint('AdminFormController: Role ${userRole.value} melihat ${filteredForms.length} form.');
      },
      onError: (error) {
        debugPrint(
          'Error fetching forms list from $_formsCollectionPath: $error',
        );

        if (!isClosed) {
          isLoading.value = false;
        }

        Get.snackbar(
          'Error Data Form',
          'Gagal mengambil daftar form: $error',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  /// Mengubah filter periode pendataan dan menyegarkan data.
  void changePeriodFilter(String period) {
    selectedPeriodFilter.value = period;
    _listenToForms();
  }

  /// Menyegarkan daftar formulir secara manual dari Firestore.
  Future<void> refreshFormsData() async {
    debugPrint('DEBUG: AdminFormController - refreshFormsData() dipanggil.');

    try {
      isLoading.value = true;

      Query<Map<String, dynamic>> query = _db.collection(_formsCollectionPath);

      if (selectedPeriodFilter.value != 'Semua') {
        query = query.where('period', isEqualTo: selectedPeriodFilter.value);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final List<FormItem> loadedForms = snapshot.docs.map((doc) {
        return FormItem.fromFirestoreSummary(doc);
      }).toList();

      // FILTER: Konsisten dengan _listenToForms
      final userModel = UserModel(uid: '', role: userRole.value);
      final String vId = userVillageId.value.trim();
      
      List<FormItem> filteredForms = loadedForms;
      
      if (userModel.isRestrictedAdmin) {
        filteredForms = loadedForms.where((form) {
          // Hanya tampilkan form yang villageId-nya cocok persis dengan desa admin
          // (Form umum/null atau form desa lain akan tersembunyi)
          return form.villageId == vId && vId.isNotEmpty;
        }).toList();
      }

      if (!isClosed) {
        forms.assignAll(filteredForms);
      }
    } catch (e) {
      debugPrint('Error refresh forms: $e');

      Get.snackbar(
        'Error Refresh',
        'Gagal memuat ulang data form: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Menambahkan formulir baru ke database Firestore.
  /// 
  /// Jika ditambahkan oleh Admin Desa, sistem secara otomatis akan memberikan 
  /// hak akses kepada seluruh petugas di desa tersebut.
  Future<void> addForm(
      String title,
      String description,
      List<FormSection> sections,
      ) async {
    if (title.trim().isEmpty) {
      Get.snackbar(
        'Input Error',
        'Judul form tidak boleh kosong.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      Get.snackbar(
        'Autentikasi Error',
        'Anda harus login untuk menambahkan form.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final String role = userRole.value.toLowerCase().trim();
      final String vId = userVillageId.value.trim();
      final String vName = userVillageName.value.trim();

      final FormItem newFormItem = FormItem(
        id: '',
        title: title.trim(),
        description: description.trim(),
        villageId: vId.isNotEmpty ? vId : null,
        villageName: vName.isNotEmpty ? vName : null,
        createdAt: DateTime.now(),
        createdByUserId: currentUser.uid,
        sections: sections,
      );

      final docRef = await _db.collection(_formsCollectionPath).add(
        newFormItem.toFirestore(),
      );

      // OTOMATIS TAMBAH AKSES: Jika admin desa membuat form, beri akses ke semua user di desa tersebut
      final userModel = UserModel(uid: '', role: role);
      if (userModel.isVillageAdmin) {
        if (vId.isNotEmpty) {
          await _autoAssignAccessToUsers(docRef.id, vId);
        }
      }

      Get.snackbar(
        'Berhasil',
        'Form "$title" berhasil ditambahkan!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error adding form: $e');

      Get.snackbar(
        'Error Tambah Form',
        'Gagal: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  /// Menduplikat formulir yang sudah ada beserta seluruh pertanyaannya.
  /// 
  /// Melakukan Deep Copy pada data formulir, termasuk konfigurasi kelompok usia.
  Future<void> duplicateForm(FormItem originalForm) async {
    try {
      isLoading.value = true;
      
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Ambil data lengkap form karena originalForm mungkin hanya summary
      final fullDoc = await _db.collection(_formsCollectionPath).doc(originalForm.id).get();
      if (!fullDoc.exists) {
        throw Exception("Form data asli tidak ditemukan.");
      }
      
      final fullOriginalForm = FormItem.fromFirestore(fullDoc);

      final FormItem newForm = FormItem(
        id: '', 
        title: '${fullOriginalForm.title} (Copy)',
        description: fullOriginalForm.description,
        period: fullOriginalForm.period,
        villageId: fullOriginalForm.villageId,
        villageName: fullOriginalForm.villageName,
        createdAt: DateTime.now(),
        createdByUserId: currentUser.uid,
        // Gunakan .map().toList() untuk Deep Copy data
        sections: fullOriginalForm.sections.map((s) => s.copyWith()).toList(),
        formVersion: '1.0',
        autoDuplicateMonthly: fullOriginalForm.autoDuplicateMonthly,
        lockPreviousPeriod: fullOriginalForm.lockPreviousPeriod,
        // Salin kategori usia secara otomatis di sini
        ageGroups: fullOriginalForm.ageGroups.map((ag) => ag.copyWith()).toList(),
      );

      final docRef = await _db.collection(_formsCollectionPath).add(newForm.toFirestore());

      // OTOMATIS TAMBAH AKSES: Jika admin desa menduplikat form
      final userModel = UserModel(uid: '', role: userRole.value);
      if (userModel.isVillageAdmin && newForm.villageId != null) {
        await _autoAssignAccessToUsers(docRef.id, newForm.villageId!);
      }

      Get.snackbar(
        'Berhasil Duplikat',
        'Form "${fullOriginalForm.title}" berhasil diduplikat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error Duplikat', 
        'Gagal menduplikat form: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Memberikan hak akses formulir secara otomatis kepada seluruh user di desa tertentu.
  /// 
  /// Menggunakan [WriteBatch] untuk efisiensi penulisan data massal ke subkoleksi `managedAccounts`.
  Future<void> _autoAssignAccessToUsers(String formId, String vId) async {
    try {
      debugPrint('AdminFormController: Menambahkan akses otomatis untuk villageId: $vId');
      
      final usersSnapshot = await _db.collection('users')
          .where('villageId', isEqualTo: vId)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        debugPrint('AdminFormController: Tidak ada user ditemukan di desa tersebut.');
        return;
      }

      final WriteBatch batch = _db.batch();
      final CollectionReference accessCol = _db.collection(_formsCollectionPath)
          .doc(formId)
          .collection('managedAccounts');

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        batch.set(accessCol.doc(userDoc.id), {
          'userId': userDoc.id,
          'userName': userData['username'] ?? userData['fullName'] ?? 'User',
          'role': userData['role'] ?? 'user',
          'addedAt': FieldValue.serverTimestamp(),
          'autoAssigned': true,
        });
      }

      await batch.commit();
      debugPrint('AdminFormController: Berhasil menambah akses untuk ${usersSnapshot.docs.length} user.');
    } catch (e) {
      debugPrint('Error auto-assigning access: $e');
    }
  }

  /// Menghapus formulir dari Firestore setelah konfirmasi pengguna.
  /// 
  /// Menampilkan dialog konfirmasi bahaya sebelum melakukan penghapusan permanen.
  Future<void> deleteForm(String formId, String formTitle) async {
    if (_auth.currentUser == null) {
      Get.snackbar(
        'Autentikasi Error',
        'Anda harus login untuk menghapus form.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Penghapusan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin menghapus form "$formTitle"?\nTindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (Get.isDialogOpen == true) {
                        Navigator.of(Get.overlayContext!).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                    label: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (Get.isDialogOpen == true) {
                        Navigator.of(Get.overlayContext!).pop();
                      }

                      try {
                        await _db
                            .collection(_formsCollectionPath)
                            .doc(formId)
                            .delete();

                        if (!isClosed) {
                          forms.removeWhere((form) {
                            return form.id == formId;
                          });
                        }

                        Get.snackbar(
                          'Berhasil',
                          'Form "$formTitle" berhasil dihapus!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        debugPrint('Error deleting form: $e');

                        Get.snackbar(
                          'Error Hapus Form',
                          'Gagal: ${e.toString()}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade400,
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    _formsSubscription?.cancel();
    super.onClose();
  }
}