// lib/presentation/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Make sure this is imported

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart';

// Import AppRoutes
import '../../../infrastructure/navigation/routes.dart'; // Adjust path if necessary
// Import FormItem model (jika masih diperlukan di file ini, jika tidak bisa dihapus)
// import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';


class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80); // A light orange
  static const Color accentHeaderColor = Color(0xFFFF9800); // A more vibrant orange
  static const Color iconColor = Color(0xFFF57C00); // A darker orange for icons
  static const Color cardBackgroundColor = Colors.white;
  static const Color bottomNavIconColor = Color(0xFFF57C00);
  static const Color titlePageColor = Colors.black87;

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
            // Tinggi header bisa disesuaikan jika perlu untuk mengakomodasi konten
            padding: const EdgeInsets.only(top: 80.0, left: 24.0, right: 24.0, bottom: 80.0), // Tambah padding bottom
            width: double.infinity, // Pastikan container mengambil lebar penuh
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentHeaderColor.withOpacity(1.0), // Kurangi opasitas dari 1.0 ke 0.8
                  primaryHeaderColor.withOpacity(0.5), // Sama untuk warna terang
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(80),
                // bottomRight: Radius.circular(30), // Opsional, jika ingin simetris
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten vertikal jika tinggi tetap
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      'Hello, ${controller.adminName.value.isNotEmpty ? controller.adminName.value : 'Admin'}',
                      style: const TextStyle(
                        fontSize: 28, // Sedikit lebih kecil agar pas
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
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: const Icon(Icons.person, size: 40, color: AdminScreen.iconColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40), // Sesuaikan spacing
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
                    // Hubungkan dengan controller untuk update query pencarian
                    onChanged: (value) {
                      controller.updateGlobalSearchQuery(value);
                    },
                    // Anda bisa juga menggunakan TextEditingController jika perlu mengontrol teks dari controller
                    // controller: controller.searchBarTextController, // Jika Anda membuatnya di AdminController
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan judul form...', // Updated hint text
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey[600]),
                      // Tambahkan tombol clear (X) pada search bar
                      suffixIcon: Obx(() => controller.globalSearchQuery.value.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          controller.clearGlobalSearchQuery();
                          // Jika menggunakan TextEditingController di AdminScreen:
                          // _searchFocusNode.unfocus(); // Untuk menutup keyboard
                          // _localSearchController.clear(); // Jika ada controller lokal di UI
                        },
                      )
                          : const SizedBox.shrink()), // Kosong jika tidak ada query
                    ),
                  ),
                ),
              ],
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
      if (controller.isDashboardLoading.value && controller.filteredFormSubmissions.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(),
        color: AdminScreen.accentHeaderColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDateFilterSection(context),
            const SizedBox(height: 20),

            _buildMetricCards(),
            const SizedBox(height: 20),

            Text(
              'Submission Trend (Daily)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8), // Tambahkan padding agar chart tidak terlalu mepet
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
              // Cek jika _fullSubmissionTrend (data master sebelum filter tanggal) kosong
              // atau submissionTrend (setelah filter tanggal) kosong
              child: controller.submissionTrend.isEmpty && controller.selectedStartDate.value == null
                  ? _buildDummyChartWithLabel("No trend data available overall.")
                  : controller.submissionTrend.isEmpty && controller.selectedStartDate.value != null
                  ? _buildDummyChartWithLabel("No trend data for selected date range.")
                  : const Text( // Ganti ini dengan implementasi chart Anda
                'Chart Placeholder (Implement with charts_flutter or fl_chart)',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Submissions per Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            // Gunakan controller.filteredFormSubmissions untuk menampilkan daftar form yang sudah difilter
            controller.filteredFormSubmissions.isEmpty
                ? _buildNoDataMessage(
                controller.globalSearchQuery.value.isNotEmpty
                    ? 'No forms found matching "${controller.globalSearchQuery.value}".'
                    : controller.selectedStartDate.value != null
                    ? 'No form submissions found for the selected date range.'
                    : 'No form submissions available.'
            )
                : Column(
              children: controller.filteredFormSubmissions.map((entry) {
                return _buildFormSubmissionItem(entry);
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildFormAccessSection(), // Widget ini sudah menggunakan controller.filteredFormAccessCounts
            const SizedBox(height: 20),

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
              child: InkWell(
                onTap: () => controller.pickDateRange(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: AdminScreen.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
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
                        ? DateFormat('dd MMM yyyy', 'id_ID').format(controller.selectedStartDate.value!)
                        : 'Pilih Tanggal Mulai';
                    String endDate = controller.selectedEndDate.value != null
                        ? DateFormat('dd MMM yyyy', 'id_ID').format(controller.selectedEndDate.value!)
                        : 'Pilih Tanggal Akhir';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            (controller.selectedStartDate.value != null && controller.selectedEndDate.value != null)
                                ? '$startDate - $endDate'
                                : (controller.selectedStartDate.value != null ? startDate : 'Pilih Rentang Tanggal'),
                            style: TextStyle(
                              fontSize: 15,
                              color: controller.selectedStartDate.value != null
                                  ? AdminScreen.titlePageColor
                                  : Colors.grey.shade600,
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
            Obx(() => controller.selectedStartDate.value != null
                ? Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: InkWell(
                onTap: controller.resetDateFilter,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400, // Warna lebih soft
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22, // Sesuaikan ukuran ikon
                  ),
                ),
              ),
            )
                : const SizedBox.shrink() // Kosong jika tidak ada tanggal dipilih
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
            // Gunakan totalSubmissions yang sudah difilter oleh tanggal dan search
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
      elevation: 2, // Kurangi elevasi agar lebih soft
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sesuaikan radius
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 26), // Sesuaikan ukuran ikon
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subtitleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Sesuaikan spacing
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: titleColor), // Sesuaikan ukuran font
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSubmissionItem(Map<String, dynamic> entry) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Sesuaikan padding
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AdminScreen.accentHeaderColor, size: 22), // Sesuaikan warna dan ukuran
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'] ?? 'Untitled Form', // Fallback jika null
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
          // Gunakan controller.filteredFormAccessCounts yang sudah difilter oleh search
          if (controller.filteredFormAccessCounts.isEmpty) {
            return _buildNoDataMessage(
                controller.globalSearchQuery.value.isNotEmpty
                    ? 'No forms found matching "${controller.globalSearchQuery.value}" in access overview.'
                    : 'No forms found or no access data available.'
            );
          }
          return Column(
            children: controller.filteredFormAccessCounts.map((entry) { // Gunakan filtered list
              return _buildFormAccessItem(entry);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildFormAccessItem(Map<String, dynamic> entry) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.lock_open_outlined, color: AdminScreen.accentHeaderColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'] ?? 'Untitled Form',
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

  Widget _buildDummyChartWithLabel(String message) { // Terima pesan sebagai argumen
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
          ),
          child: CustomPaint(
            painter: _DummyChartPainter(),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_nodata_rounded, size: 40, color: Colors.grey.shade400), // Ikon yang lebih relevan
            const SizedBox(height: 10),
            Text(
              message, // Gunakan pesan dari argumen
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            // Hilangkan "(Data Dummy)" karena pesan sudah lebih deskriptif
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0), // Tambah padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 50, color: Colors.grey.shade400), // Ikon yang lebih modern
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.4), // Tambah line height
            ),
          ],
        ),
      ),
    );
  }
}

class _DummyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8; // Garis lebih tipis

    // Draw horizontal lines
    for (int i = 1; i <= 4; i++) { // Ubah agar garis tidak di tepi
      final y = size.height / 5 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw vertical lines
    for (int i = 1; i <= 4; i++) { // Ubah agar garis tidak di tepi
      final x = size.width / 5 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw a simple "trend" line (example only)
    final Paint trendPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.5) // Warna lebih soft
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.7); // Mulai sedikit dari tepi
    path.cubicTo(
      size.width * 0.25, size.height * 0.5, // Kontrol poin 1
      size.width * 0.35, size.height * 0.6, // Kontrol poin 2
      size.width * 0.5, size.height * 0.4,  // Titik tengah
    );
    path.cubicTo(
      size.width * 0.65, size.height * 0.2, // Kontrol poin 3
      size.width * 0.75, size.height * 0.55,// Kontrol poin 4
      size.width * 0.95, size.height * 0.3, // Akhir sedikit dari tepi
    );
    canvas.drawPath(path, trendPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}