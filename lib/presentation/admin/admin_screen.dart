// lib/presentation/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart';

// Import AppRoutes
import '../../../infrastructure/navigation/routes.dart'; // Sesuaikan path jika perlu
// Import FormItem model
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';


class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color iconColor = Color(0xFFF57C00);
  static const Color cardBackgroundColor = Colors.white;
  static const Color bottomNavIconColor = Color(0xFFF57C00);

  List<Widget> get _pages => [
    _DashboardContentOnly(controller: controller),
    const AdminFormPage(),
    const AdminAccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Column(
        children: [
          Container(
            height: 200.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryHeaderColor, accentHeaderColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, left: 24.0, right: 24.0, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Text(
                        'Hello, ${controller.adminName.value.isNotEmpty ? controller.adminName.value : 'Admin'}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )),
                      InkWell(
                        onTap: () {
                          Get.toNamed(AppRoutes.adminProfil);
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(Icons.person, size: 30, color: AdminScreen.iconColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(
                  () => IndexedStack(
                index: controller.selectedPageIndex.value,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.selectedPageIndex.value,
        onTap: controller.onPageChanged,
        selectedItemColor: bottomNavIconColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Form'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Account'),
        ],
      )),
    );
  }
}


class _DashboardContentOnly extends StatelessWidget {
  final AdminController controller;
  const _DashboardContentOnly({required this.controller});

  static const Color cardBgColor = AdminScreen.cardBackgroundColor;
  static const Color titleColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;
  static const Color dateColor = Colors.grey;
  static const Color iconDetailColor = AdminScreen.iconColor;


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // PERBAIKAN DI SINI: Gunakan controller.isLoading.value
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
      }
      // Menggunakan controller.dashboardForms (nama ini sudah benar dari AdminController terakhir)
      if (controller.dashboardForms.isEmpty) {
        return _buildNoFormsAvailableMessage();
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchFormsForDashboard(),
        color: AdminScreen.accentHeaderColor,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          itemCount: controller.dashboardForms.length,
          itemBuilder: (context, index) {
            final formItem = controller.dashboardForms[index];
            return _buildFormItemCard(formItem, context);
          },
        ),
      );
    });
  }

  Widget _buildFormItemCard(FormItem item, BuildContext context) {
    int totalQuestions = item.sections.fold(0, (sum, section) => sum + section.questions.length);
    String formattedDate = "${item.createdAt.toLocal().day}/${item.createdAt.toLocal().month}/${item.createdAt.toLocal().year}";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBgColor,
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Form Dipilih',
            'Form: ${item.title}\nID: ${item.id}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: titleColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 14, color: subtitleColor),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dibuat: $formattedDate',
                        style: const TextStyle(fontSize: 11, color: dateColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Pertanyaan: $totalQuestions',
                        style: const TextStyle(fontSize: 11, color: dateColor),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: iconDetailColor.withOpacity(0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFormsAvailableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Belum ada form yang dibuat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan buat form baru pada tab "Form".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}