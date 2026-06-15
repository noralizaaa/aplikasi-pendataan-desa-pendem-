import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'village_management_controller.dart';
import '../admin_screen.dart';

/// [VillageManagementPage] adalah halaman UI untuk mengelola entitas desa dalam sistem.
/// 
/// Halaman ini menampilkan daftar seluruh desa dan menyediakan akses untuk:
/// 1. Melihat informasi dasar desa (Nama, ID, Status).
/// 2. Menambah desa baru melalui tombol aksi terapung (FAB).
/// 3. Mengedit atau menghapus entitas desa.
class VillageManagementPage extends GetView<VillageManagementController> {
  const VillageManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      appBar: AppBar(
        title: const Text('Manajemen Desa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AdminScreen.primaryHeaderColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.villages.isEmpty) {
          return const Center(child: Text('Belum ada data desa.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.villages.length,
          itemBuilder: (context, index) {
            final village = controller.villages[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminScreen.accentHeaderColor.withValues(alpha: 0.2),
                  child: const Icon(Icons.holiday_village, color: AdminScreen.iconColor),
                ),
                title: Text(village.villageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${village.villageId} | Status: ${village.isActive ? 'Aktif' : 'Nonaktif'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => controller.addOrEditVillage(village: village),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => controller.deleteVillage(village.villageId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_village_management_add',
        onPressed: () => controller.addOrEditVillage(),
        backgroundColor: AdminScreen.accentHeaderColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
