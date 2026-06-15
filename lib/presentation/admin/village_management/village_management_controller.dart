// lib/presentation/admin/village_management/village_management_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/village/village_model.dart';

/// [VillageManagementController] mengelola daftar desa yang terdaftar dalam sistem.
/// 
/// Controller ini menyediakan fitur:
/// 1. Sinkronisasi real-time daftar desa dari Firestore.
/// 2. Menambah desa baru atau mengedit konfigurasi desa yang sudah ada.
/// 3. Mengatur tipe server desa (Cloud Firebase atau Local API).
/// 4. Menghapus data desa dari sistem.
class VillageManagementController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Daftar desa yang diambil dari Firestore.
  final RxList<VillageModel> villages = <VillageModel>[].obs;
  /// Menandakan status pemuatan data.
  final RxBool isLoading = true.obs;

  StreamSubscription? _villagesSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToVillages();
  }

  /// Mendengarkan perubahan data desa di Firestore secara real-time.
  void _listenToVillages() {
    isLoading.value = true;
    _villagesSubscription?.cancel();
    _villagesSubscription = _db.collection('villages').snapshots().listen((snapshot) {
      villages.assignAll(snapshot.docs.map((doc) => VillageModel.fromFirestore(doc)).toList());
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      debugPrint("Error listening to villages: $error");
    });
  }

  /// Menampilkan dialog untuk menambah atau mengedit informasi desa.
  /// 
  /// Mencakup pengaturan infrastruktur IT desa seperti alamat IP lokal, port, 
  /// dan kebutuhan VPN untuk koneksi hybrid.
  Future<void> addOrEditVillage({VillageModel? village}) async {
    final nameController = TextEditingController(text: village?.villageName ?? '');
    final idController = TextEditingController(text: village?.villageId ?? '');
    final apiBaseUrlController = TextEditingController(text: village?.apiBaseUrl ?? '');
    final localIpAddressController = TextEditingController(text: village?.localIpAddress ?? '');
    final portController = TextEditingController(text: village?.port ?? '');
    
    final RxBool isActive = (village?.isActive ?? true).obs;
    final RxBool requiresVpn = (village?.requiresVpn ?? false).obs;
    final RxString selectedServerType = (village?.serverType ?? 'firebase_shared').obs;

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(village == null ? 'Tambah Desa Baru' : 'Edit Data Desa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (village == null)
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'ID Desa (Contoh: desa_001)',
                    hintText: 'desa_xxx',
                  ),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Desa'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedServerType.value,
                decoration: const InputDecoration(labelText: 'Tipe Server'),
                items: const [
                  DropdownMenuItem(value: 'firebase_shared', child: Text('Firebase Shared')),
                  DropdownMenuItem(value: 'local_api', child: Text('Local API')),
                ],
                onChanged: (val) {
                  if (val != null) selectedServerType.value = val;
                },
              ),
              Obx(() => selectedServerType.value == 'local_api' 
                ? Column(
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: apiBaseUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API Base URL',
                          hintText: 'http://192.168.1.x:8080',
                        ),
                      ),
                      TextField(
                        controller: localIpAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Local IP Address',
                          hintText: '192.168.x.x',
                        ),
                      ),
                      TextField(
                        controller: portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '8080',
                        ),
                      ),
                      Obx(() => SwitchListTile(
                        title: const Text('Membutuhkan VPN'),
                        value: requiresVpn.value,
                        onChanged: (val) => requiresVpn.value = val,
                        activeThumbColor: Colors.orange,
                      )),
                    ],
                  )
                : const SizedBox.shrink()),
              const SizedBox(height: 10),
              Obx(() => SwitchListTile(
                title: const Text('Status Aktif'),
                value: isActive.value,
                onChanged: (val) => isActive.value = val,
                activeThumbColor: Colors.orange,
              )),
            ],
          ),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final id = idController.text.trim();
              if (name.isEmpty || (village == null && id.isEmpty)) {
                Get.snackbar('Error', 'Nama dan ID Desa tidak boleh kosong');
                return;
              }

              final newVillage = VillageModel(
                villageId: village?.villageId ?? id,
                villageName: name,
                serverType: selectedServerType.value,
                apiBaseUrl: selectedServerType.value == 'local_api' ? apiBaseUrlController.text.trim() : null,
                localIpAddress: selectedServerType.value == 'local_api' ? localIpAddressController.text.trim() : null,
                port: selectedServerType.value == 'local_api' ? portController.text.trim() : null,
                requiresVpn: selectedServerType.value == 'local_api' ? requiresVpn.value : false,
                isActive: isActive.value,
              );

              try {
                if (village == null) {
                  await _db.collection('villages').doc(id).set(newVillage.toFirestore());
                } else {
                  await _db.collection('villages').doc(village.villageId).update(newVillage.toFirestore());
                }
                
                if (Get.isDialogOpen == true) {
                  Navigator.of(Get.overlayContext!).pop();
                }
                
                Get.snackbar('Sukses', 'Data desa berhasil disimpan', 
                    backgroundColor: Colors.green, 
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM);
              } catch (e) {
                Get.snackbar('Error', 'Gagal menyimpan data: $e',
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Menghapus data desa dari Firestore setelah konfirmasi pengguna.
  /// 
  /// Menampilkan peringatan mengenai dampak terhadap akun pengguna yang terkait.
  Future<void> deleteVillage(String id) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Desa'),
        content: const Text('Apakah Anda yakin ingin menghapus desa ini? Akun yang terkait mungkin tidak dapat diakses dengan benar.'),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Navigator.of(Get.overlayContext!).pop();
              }
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _db.collection('villages').doc(id).delete();
                if (Get.isDialogOpen == true) {
                  Navigator.of(Get.overlayContext!).pop();
                }
                Get.snackbar('Sukses', 'Desa telah dihapus',
                    snackPosition: SnackPosition.BOTTOM);
              } catch (e) {
                Get.snackbar('Error', 'Gagal menghapus desa: $e',
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _villagesSubscription?.cancel();
    super.onClose();
  }
}
