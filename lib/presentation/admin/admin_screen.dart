// lib/presentation/admin/admin_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// CORRECTED IMPORTS:
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart'; // Import AdminController
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_model.dart'; // Import DashboardItem
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart'; // Import AdminFormPage
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart'; // Import AdminAccountPage (using your specified path)

// No need for AppRoutes import here for internal tab switching with IndexedStack

class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  // Definisi Warna (konsisten dengan desain Anda)
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80); // Oranye terang
  static const Color accentHeaderColor = Color(0xFFFF9800); // Oranye lebih gelap
  static const Color iconColor = Color(0xFFF57C00); // Warna ikon profil/search
  static const Color cardBackgroundColor = Colors.white; // Warna dasar card
  static const Color bottomNavIconColor = Color(0xFFF57C00); // Warna ikon bottom nav

  // List of widgets for the IndexedStack (bottom navigation tabs)
  // Each element here corresponds to a tab in the BottomNavigationBar
  List<Widget> get _pages => [
    _DashboardContent(controller: controller), // The actual dashboard UI
    const AdminFormPage(), // Dummy Form Page
    const AdminAccountPage(), // Dummy Account Page
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is put (usually handled by binding, but explicit for clarity)
    // Get.put(AdminController()); // This is typically handled by AdminBinding in app_routes.dart
    // No need to put it here if binding is set up correctly.

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      // >>> MAIN CHANGE: Use IndexedStack in the body <<<
      body: Obx(
            () => IndexedStack(
          index: controller.selectedPageIndex.value, // Controls which page is visible
          children: _pages, // The list of pages/widgets for each tab
        ),
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.selectedPageIndex.value,
        onTap: controller.onPageChanged, // Update the selectedPageIndex in controller
        selectedItemColor: bottomNavIconColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Ensures labels are always visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Form',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      )),
    );
  }
}

// Extracted Dashboard content into a separate StatelessWidget for clarity
// This widget contains the header, search bar, and dashboard cards.
class _DashboardContent extends StatelessWidget {
  final AdminController controller; // Pass the controller to access its data/methods
  const _DashboardContent({required this.controller});

  // Re-use color definitions from AdminScreen
  static const Color pageBackgroundColor = AdminScreen.pageBackgroundColor;
  static const Color primaryHeaderColor = AdminScreen.primaryHeaderColor;
  static const Color accentHeaderColor = AdminScreen.accentHeaderColor;
  static const Color iconColor = AdminScreen.iconColor;
  static const Color cardBackgroundColor = AdminScreen.cardBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        // Header Kustom (Area Orange Atas) - This part remains the same
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
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
                          'Hello, ${controller.adminName}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )),
                        InkWell(
                          onTap: () {
                            // Example: Navigate to Admin Profile or User Profile (if admin is also a user)
                            // Get.toNamed(AppRoutes.adminProfile); // Create this route if needed
                            Get.snackbar('Profil Admin', 'Aksi profil admin');
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: Icon(Icons.person, size: 30, color: iconColor),
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
                          hintText: 'Search Form',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: Icon(Icons.search, color: iconColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dashboard Items List - This part remains the same
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 20),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.dashboardItems.isEmpty) {
                return _buildNoFormsMessage();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: controller.dashboardItems.map((item) =>
                      _buildDashboardCard(item)
                  ).toList(),
                ),
              );
            }),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }

  // Helper method to build a dashboard card
  Widget _buildDashboardCard(DashboardItem item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Item Dipilih',
            'Anda memilih: ${item.title} (${item.programId})',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.article_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 5),
                        Text(
                          item.category,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          item.location,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentHeaderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Static message when no forms are available
  Widget _buildNoFormsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Tidak ada item dashboard yang tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            const Text(
              'Silakan hubungi administrator untuk konfigurasi dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}