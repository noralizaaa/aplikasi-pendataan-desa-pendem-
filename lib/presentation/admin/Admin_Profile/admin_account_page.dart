// lib/presentation/admin/Admin_Profile/admin_account_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';
import 'admin_account_controller.dart'; // Menggunakan controller yang sudah dirombak
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk FormItem
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart'; // Untuk warna konsisten
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Untuk navigasi

/// [AdminAccountPage] adalah halaman UI untuk kategori Manajemen Akun pada sisi Admin.
/// 
/// Halaman ini menampilkan:
/// 1. Shortcut ke daftar semua akun dan manajemen desa (jika Admin Global).
/// 2. Daftar formulir aktif yang dapat dikelola hak akses akunnya secara spesifik.
class AdminAccountPage extends GetView<AdminAccountController> {
  const AdminAccountPage({super.key});

  /// Warna latar belakang halaman.
  static const Color pageBackgroundColor = Color(0xFFEBF4F8);
  /// Warna judul utama halaman.
  static const Color titlePageColor = Colors.black87;
  /// Warna latar belakang kartu item.
  static const Color cardBgColor = AdminTheme.cardBackgroundColor;
  
  /// Gradien warna untuk kartu "Daftar Akun" agar terlihat berbeda secara visual.
  static const Gradient allAccountsCardGradient = LinearGradient(
    colors: [Color(0xFFFFF9C4), Color(0xFFFFF176)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color titleColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;
  static const Color dateColor = Colors.grey;
  static const Color iconDetailColor = AdminTheme.iconColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Manajemen Akun', // Updated Title
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titlePageColor,
              ),
            ),
            const SizedBox(height: 20), // Jarak setelah judul utama
            // --- Row untuk Card Utama ---
            Obx(() {
              final userModel = UserModel(uid: '', role: controller.userRole.value);
              debugPrint('AdminAccountPage: Rendering cards for role: ${userModel.role}, isGlobal: ${userModel.isGlobalAdmin}');
              
              return Row(
                children: [
                  Expanded(child: _buildAllAccountsCard(context)),
                  if (userModel.isGlobalAdmin) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildVillagesCard(context)),
                  ],
                ],
              );
            }),
            const SizedBox(height: 24),
            // --- Daftar form lainnya ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.listedForms.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AdminTheme.accentHeaderColor));
                }
                if (controller.listedForms.isEmpty) {
                  return _buildNoFormsMessage(); // Pesan jika tidak ada form
                }
                return RefreshIndicator(
                  onRefresh: () => controller.refreshListedForms(),
                  color: AdminTheme.accentHeaderColor,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: controller.listedForms.length,
                    itemBuilder: (context, index) {
                      final formItem = controller.listedForms[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == controller.listedForms.length - 1 ? 0 : 16.0,
                        ),
                        child: _buildFormItemCardForAccountTab(formItem, context),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu navigasi untuk menuju ke manajemen seluruh akun pengguna.
  Widget _buildAllAccountsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: allAccountsCardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(AppRoutes.allAccountManagement);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: AdminTheme.accentHeaderColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daftar Akun',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun kartu navigasi untuk manajemen desa (Hanya muncul untuk Admin Global).
  Widget _buildVillagesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFF4DD0E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(AppRoutes.allVillageManagement);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.holiday_village_outlined,
                    color: Color(0xFF0097A7),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daftar Desa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun kartu item untuk setiap formulir.
  /// 
  /// Kartu ini mengarahkan admin ke halaman manajemen akun spesifik yang 
  /// memiliki akses ke formulir tersebut.
  Widget _buildFormItemCardForAccountTab(FormItem item, BuildContext context) {
    int totalQuestions = item.sections.fold(0, (sum, section) => sum + section.questions.length);
    String formattedDate =
        "${item.createdAt.toLocal().day.toString().padLeft(2, '0')}/"
        "${item.createdAt.toLocal().month.toString().padLeft(2, '0')}/"
        "${item.createdAt.toLocal().year}";

    IconData formIcon = Icons.description_outlined;
    if (item.title.toLowerCase().contains("penduduk")) {
      formIcon = Icons.people_alt_outlined;
    } else if (item.title.toLowerCase().contains("tps3r")) {
      formIcon = Icons.recycling_outlined;
    } else if (item.title.toLowerCase().contains("bank sampah")) {
      formIcon = Icons.savings_outlined;
    } else if (item.title.toLowerCase().contains("desa")) {
      formIcon = Icons.holiday_village_outlined;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.formAccountManagement,
            arguments: {
              'formId': item.id,
              'formTitle': item.title,
            },
          );
          debugPrint('Navigasi ke manajemen akun untuk form: ${item.title} (ID: ${item.id})');
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryHeaderColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(formIcon, color: AdminTheme.iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: titleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Dibuat: $formattedDate | Pertanyaan: $totalQuestions',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'delete_form_definition') {
                    controller.deleteForm(item.id, item.title);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete_form_definition',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Hapus Form Ini'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan pesan placeholder jika belum ada formulir yang dibuat.
  Widget _buildNoFormsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ballot_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Kategori Form',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Setiap form yang Anda buat akan muncul di sini sebagai kategori untuk manajemen akun terkait.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
