// lib/presentation/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Make sure this is imported

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart';

// Import AppRoutes
import '../../../infrastructure/navigation/routes.dart'; // Adjust path if necessary
// Import FormItem model
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';


class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80); // A light orange
  static const Color accentHeaderColor = Color(0xFFFF9800); // A more vibrant orange
  static const Color iconColor = Color(0xFFF57C00); // A darker orange for icons
  static const Color cardBackgroundColor = Colors.white;
  static const Color bottomNavIconColor = Color(0xFFF57C00);
  static const Color titlePageColor = Colors.black87; // Added for consistent text color

  List<Widget> get _pages => [
    _DashboardContentOnly(controller: controller), // Our BI Dashboard
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
  static const Color filterChipColor = AdminScreen.primaryHeaderColor;


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isDashboardLoading.value) { // Use specific loading indicator for dashboard
        return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(), // Refresh all dashboard data
        color: AdminScreen.accentHeaderColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Date Filter Section ---
            _buildDateFilterSection(context),
            const SizedBox(height: 20),

            // --- Key Metrics Cards ---
            _buildMetricCards(),
            const SizedBox(height: 20),

            // --- Submission Trend Chart Placeholder ---
            Text(
              'Submission Trend (Daily)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: controller.submissionTrend.isEmpty
                  ? _buildDummyChartWithLabel() // Use the new dummy chart widget
                  : const Text(
                'Chart Placeholder (e.g., Bar Chart, Line Chart)',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            const SizedBox(height: 20),

            // --- Submissions Per Form Section ---
            Text(
              'Submissions per Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            controller.filteredFormSubmissions.isEmpty
                ? _buildNoDataMessage('No form submissions found for the selected filter.')
                : Column(
              children: controller.filteredFormSubmissions.map((entry) {
                return _buildFormSubmissionItem(entry);
              }).toList(),
            ),
            const SizedBox(height: 20),

            // --- Form Access Section ---
            _buildFormAccessSection(),
            const SizedBox(height: 20),

            // --- (Optional) User Activity Placeholder ---
            Text(
              'User Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: controller.totalActiveUsers.value == 0
                  ? _buildNoDataMessage('No user activity data available.')
                  : Text(
                'Total Active Users: ${controller.totalActiveUsers.value}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Builds the date range filter section for the dashboard.
  /// This provides a clean interface for selecting start and end dates,
  /// with an option to reset the filter.
  Widget _buildDateFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Tanggal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell( // Use InkWell for a custom tap effect and border
                onTap: () => controller.pickDateRange(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: AdminScreen.cardBackgroundColor, // White background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300), // Subtle border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    String startDate = controller.selectedStartDate.value != null
                        ? DateFormat('dd MMM yyyy').format(controller.selectedStartDate.value!) // More readable date format
                        : 'Pilih Tanggal Mulai';
                    String endDate = controller.selectedEndDate.value != null
                        ? DateFormat('dd MMM yyyy').format(controller.selectedEndDate.value!) // More readable date format
                        : 'Pilih Tanggal Akhir';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$startDate - $endDate',
                            style: TextStyle(
                              fontSize: 15,
                              color: controller.selectedStartDate.value != null
                                  ? AdminScreen.titlePageColor // Darker color when dates are selected
                                  : Colors.grey.shade600, // Hint color when no dates
                              fontWeight: controller.selectedStartDate.value != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AdminScreen.accentHeaderColor,
                          size: 20,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            if (controller.selectedStartDate.value != null) // Show reset button only if a date range is selected
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: InkWell(
                  onTap: controller.resetDateFilter,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close, // Use a close icon for reset
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Submissions',
            value: controller.totalSubmissions.value.toString(),
            icon: Icons.checklist_rtl_outlined,
            iconColor: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Active Users',
            value: controller.totalActiveUsers.value.toString(),
            icon: Icons.people_outline,
            iconColor: Colors.purple.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color iconColor}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subtitleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSubmissionItem(Map<String, dynamic> entry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AdminScreen.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submissions: ${entry['count']}',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form Access Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.formAccessCounts.isEmpty) {
            return _buildNoDataMessage('No forms found or no access data available.');
          }
          return Column(
            children: controller.formAccessCounts.map((entry) {
              return _buildFormAccessItem(entry);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildFormAccessItem(Map<String, dynamic> entry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.lock_open_outlined, color: AdminScreen.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Users with Access: ${entry['accessCount']}',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a placeholder for the chart when no real data is available,
  /// with a "Data Dummy" label.
  Widget _buildDummyChartWithLabel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dummy chart representation (e.g., a simple grey box or grid)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100, // Light grey background for dummy chart
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
          ),
          child: CustomPaint(
            painter: _DummyChartPainter(), // Simple lines to simulate a chart
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No trend data available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 5),
            Text(
              '(Data Dummy)', // Dummy data label
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple CustomPainter to draw some lines/grid for the dummy chart
// This class MUST be outside of _DashboardContentOnly or any other class.
class _DummyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(0, size.height / 4 * i), Offset(size.width, size.height / 4 * i), linePaint);
    }

    // Draw vertical lines
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(size.width / 5 * i, 0), Offset(size.width / 5 * i, size.height), linePaint);
    }

    // Draw a simple "trend" line (example only)
    final Paint trendPaint = Paint()
      ..color = Colors.blue.shade300 // Lighter blue for dummy line
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.6);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.55);
    path.lineTo(size.width, size.height * 0.3);
    canvas.drawPath(path, trendPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}