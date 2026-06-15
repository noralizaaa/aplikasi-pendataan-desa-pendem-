// lib/presentation/admin/formpage/admin_form_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import '../../../infrastructure/navigation/routes.dart';

/// [AdminFormPage] adalah halaman UI untuk menampilkan daftar seluruh formulir pendataan.
/// 
/// Halaman ini menyediakan fitur:
/// 1. Tampilan daftar formulir dalam bentuk kartu (cards).
/// 2. Filter periode pendataan (bulan-tahun).
/// 3. Tombol aksi terapung (FAB) untuk membuat formulir baru (hanya untuk role tertentu).
/// 4. Operasi cepat per formulir (Duplikat, Hapus, Edit).
class AdminFormPage extends GetView<AdminFormController> {
  const AdminFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.pageBackgroundColor,
      floatingActionButton: Obx(() {
        final userModel = UserModel(uid: '', role: controller.userRole.value);
        
        // Sembunyikan tombol buat form jika user bukan Admin atau hanya Admin RT (Monitoring)
        if (!userModel.isAdmin || userModel.isAdminRt) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: 'fab_admin_form_create',
          onPressed: () {
            Get.toNamed(AppRoutes.adminFormBuilder);
          },
          label: const Text(
            'Buat Form Baru',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded),
          backgroundColor: AdminTheme.accentHeaderColor,
          foregroundColor: Colors.white,
          elevation: 4.0,
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filter Periode:',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Obx(() => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: controller.selectedPeriodFilter.value,
                        items: ['Semua', ..._generatePeriods()].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            controller.changePeriodFilter(newValue);
                          }
                        },
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
                left: 16.0,
                right: 16.0,
                bottom: 80.0,
              ),
              child: Obx(() {
                if (controller.isLoading.value && controller.forms.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AdminTheme.accentHeaderColor,
                    ),
                  );
                }

                if (controller.forms.isEmpty) {
                  return _buildNoFormsMessage(context);
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshFormsData,
                  color: AdminTheme.accentHeaderColor,
                  child: ListView.builder(
                    itemCount: controller.forms.length,
                    itemBuilder: (context, index) {
                      final FormItem form = controller.forms[index];
                      return _buildFormCard(form);
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Menghasilkan daftar periode (YYYY-MM) untuk 24 bulan terakhir sebagai opsi filter.
  List<String> _generatePeriods() {
    final now = DateTime.now();
    final List<String> periods = [];
    for (int i = 0; i < 24; i++) {
      final date = DateTime(now.year, now.month - i);
      periods.add(DateFormat('yyyy-MM').format(date));
    }
    return periods;
  }

  /// Membangun kartu item (Card) untuk satu formulir pendataan.
  /// 
  /// Menampilkan status formulir (Umum/Khusus Desa), periode, deskripsi, dan info pembuatan.
  /// Juga menangani logika perizinan untuk akses edit dan hapus.
  Widget _buildFormCard(FormItem form) {
    final DateTime createdAt = form.createdAt.toLocal();

    final String formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}';

    final bool isGeneralForm = form.villageId == null;
    final userModel = UserModel(uid: '', role: controller.userRole.value);
    final String vId = controller.userVillageId.value.trim();
    
    // Logika Edit: Admin RT tidak bisa edit. Admin lain hanya bisa edit form milik desanya atau form Global.
    final bool canEdit = !userModel.isAdminRt &&
                         (userModel.isGlobalAdmin || (!isGeneralForm && form.villageId == vId));

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AdminTheme.cardBackgroundColor,
      child: InkWell(
        onTap: () {
          if (canEdit) {
            Get.toNamed(
              AppRoutes.adminFormBuilder,
              arguments: form.id,
            );
          } else {
            Get.snackbar(
              'Akses Terbatas',
              'Anda tidak diperbolehkan mengubah Form Umum. Silakan gunakan fitur "Duplikat" untuk membuat versi desa Anda.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade700,
              colorText: Colors.white,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 2.0),
                child: Icon(
                  isGeneralForm ? Icons.public_rounded : Icons.holiday_village_rounded,
                  color: isGeneralForm ? Colors.blue.shade700 : AdminTheme.accentHeaderColor,
                  size: 38,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            form.title + (isGeneralForm ? " (Form Umum)" : ""),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (form.period != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminTheme.accentHeaderColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              form.period!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.accentHeaderColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (form.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        form.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (form.villageName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Desa: ${form.villageName}",
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Dibuat: $formattedDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      'Bagian: ${form.sections.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey.shade600,
                  ),
                  tooltip: 'Opsi Lainnya',
                  onSelected: (value) {
                    if (value == 'delete') {
                      if (canEdit) {
                        controller.deleteForm(form.id, form.title);
                      } else {
                         Get.snackbar('Gagal', 'Anda tidak punya izin menghapus form ini.');
                      }
                    } else if (value == 'duplicate') {
                      controller.duplicateForm(form);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Duplikat Form'),
                          ],
                        ),
                      ),
                      if (canEdit)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text('Hapus Form'),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan pesan placeholder jika tidak ada formulir yang ditemukan di database.
  Widget _buildNoFormsMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada form yang dibuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tekan tombol "Buat Form Baru" di bawah untuk menambahkan form pertama Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
