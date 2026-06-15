import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';
import '../../../infrastructure/navigation/routes.dart';

/// [AdminScreen] adalah halaman utama untuk antarmuka Admin.
/// 
/// Layar ini bertindak sebagai wadah (container) utama yang mengelola:
/// 1. **Sistem Navigasi**: Menggunakan [IndexedStack] untuk beralih antara Dashboard, Form, dan Account.
/// 2. **Header Dinamis**: Menampilkan sapaan nama admin, akses profil, dan bar pencarian global.
/// 3. **Role-Based UI**: Menyesuaikan jumlah tab dan konten berdasarkan peran pengguna (Global, Desa, RW, RT).
/// 4. **Dashboard Terpadu**: Menampilkan statistik real-time, tren grafik, dan status server desa.
class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  /// Warna latar belakang halaman.
  static const Color pageBackgroundColor = AdminTheme.pageBackgroundColor;
  /// Warna primer untuk bagian header.
  static const Color primaryHeaderColor = AdminTheme.primaryHeaderColor;
  /// Warna aksen oranye untuk elemen yang disorot.
  static const Color accentHeaderColor = AdminTheme.accentHeaderColor;
  /// Warna standar untuk ikon.
  static const Color iconColor = AdminTheme.iconColor;
  /// Warna latar belakang kartu informasi.
  static const Color cardBackgroundColor = AdminTheme.cardBackgroundColor;
  /// Warna ikon pada bar navigasi bawah.
  static const Color bottomNavIconColor = AdminTheme.bottomNavIconColor;
  /// Warna teks judul utama.
  static const Color titlePageColor = AdminTheme.titlePageColor;

  /// Daftar halaman (tab) yang tersedia berdasarkan peran pengguna.
  List<Widget> get _pages {
    final userModel = UserModel(uid: '', role: controller.userRole.value);
    
    // Jika role masih kosong (sedang dimuat), tampilkan loading sementara
    if (controller.userRole.value.isEmpty) {
      return [
        const Center(child: CircularProgressIndicator(color: accentHeaderColor)),
        const Center(child: CircularProgressIndicator(color: accentHeaderColor)),
      ];
    }

    if (userModel.isAdminRt) {
      return [
        _DashboardContentOnly(controller: controller),
      ];
    }

    if (userModel.isVillageAdmin) {
      return [
        _DashboardContentOnly(controller: controller),
        const AdminFormPage(),
      ];
    }
    return [
      _DashboardContentOnly(controller: controller),
      const AdminFormPage(),
      const AdminAccountPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Jika sedang di tab Form atau Account, balik ke Dashboard dulu
        if (controller.selectedPageIndex.value != 0) {
          controller.selectedPageIndex.value = 0;
          return;
        }

        // Jika sudah di Dashboard, tampilkan konfirmasi keluar
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentHeaderColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: pageBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                    top: 20.0, left: 24.0, right: 24.0, bottom: 20.0),
                width: double.infinity,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentHeaderColor.withValues(alpha: 0.9),
                        primaryHeaderColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(60),
                      bottomLeft: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (controller.selectedPageIndex.value > 0) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                controller.selectedPageIndex.value = 0,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            'Hello, ${controller.adminName.value.isNotEmpty ? controller.adminName.value : 'Admin'}',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      blurRadius: 2,
                                      color: Colors.black26,
                                      offset: Offset(1, 1))
                                ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.toNamed(AppRoutes.adminProfil);
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            child: const Icon(Icons.person_rounded,
                                size: 30, color: Colors.white),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: TextEditingController(text: controller.globalSearchQuery.value)
                          ..selection = TextSelection.fromPosition(TextPosition(offset: controller.globalSearchQuery.value.length)),
                        onChanged: (value) {
                          controller.updateGlobalSearchQuery(value);
                        },
                        decoration: InputDecoration(
                            hintText: 'Cari berdasarkan judul form...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade500, fontSize: 15),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey.shade600, size: 22),
                            suffixIcon: Obx(() => controller
                                .globalSearchQuery.value.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.grey.shade500, size: 20),
                              onPressed: () {
                                controller.clearGlobalSearchQuery();
                                FocusScope.of(context).unfocus();
                              },
                            )
                                : const SizedBox.shrink()),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14)),
                        style:
                        const TextStyle(fontSize: 15, color: Colors.black87),
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
        ),
        bottomNavigationBar: Obx(() {
          final userModel = UserModel(uid: '', role: controller.userRole.value);

          // Jika hanya Dashboard (Admin Monitoring), sembunyikan BottomNav untuk menghindari error/UX aneh
          if (userModel.isAdminRt) return const SizedBox.shrink();

          return BottomNavigationBar(
            currentIndex: controller.selectedPageIndex.value,
            onTap: (index) {
              // Proteksi agar tidak pindah ke index yang tidak ada
              if (userModel.isVillageAdmin && index > 1) return;
              controller.onPageChanged(index);
            },
            selectedItemColor: bottomNavIconColor,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8.0,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.file_copy_rounded), label: 'Form'),
              if (userModel.isGlobalAdmin)
                const BottomNavigationBarItem(
                    icon: Icon(Icons.manage_accounts_rounded), label: 'Account'),
            ],
          );
        }),
        floatingActionButton: Obx(() {
          if (controller.selectedPageIndex.value == 2) {
            return FloatingActionButton(
              heroTag: 'fab_admin_screen_refresh',
              onPressed: () => controller.fetchDashboardData(), // Temporary use to re-trigger role fetch if needed
              child: const Icon(Icons.refresh),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}

class _DashboardContentOnly extends StatelessWidget {
  final AdminController controller;
  const _DashboardContentOnly({required this.controller});

  static const Color cardBgColor = AdminScreen.cardBackgroundColor;
  static const Color titleColor = AdminScreen.titlePageColor;
  static const Color subtitleColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchDashboardData(),
      color: AdminScreen.accentHeaderColor,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
        children: [
          // Header Status Server Lokal
          Obx(() {
            if (controller.villageId.value.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: controller.isLocalServerOnline.value 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.isLocalServerOnline.value 
                      ? Colors.green.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isLocalServerOnline.value 
                        ? Icons.cloud_done_rounded 
                        : Icons.cloud_off_rounded,
                    color: controller.isLocalServerOnline.value 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.isLocalServerOnline.value 
                          ? 'Server Desa Online (${controller.villageName.value})' 
                          : 'Server Desa Offline / Tidak Terdeteksi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: controller.isLocalServerOnline.value 
                            ? Colors.green.shade800 
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildDateFilterSection(context),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Obx(() => Text(
              controller.selectedFormForChart.value == null
                  ? 'Progress Pendataan Harian'
                  : 'Progress Harian: ${controller.selectedFormForChart.value!['formTitle']}',
              style: Get.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
            )),
          ),
          const SizedBox(height: 12),

          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 12),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              if (controller.selectedFormForChart.value == null) {
                return _buildDummyChartWithLabel(
                    "Pilih salah satu form di bawah untuk melihat progress harian.",
                    isEmpty: true);
              }

              if (controller.isDashboardLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor, strokeWidth: 2.5));
              }
              if (controller.submissionTrend.isEmpty) {
                return _buildDummyChartWithLabel(
                    "Tidak ada data isian untuk form ini pada rentang tanggal yang dipilih.",
                    isEmpty: true);
              }

              List<FlSpot> spots = [];
              List<String> dateLabels = [];
              final trendEntries = controller.submissionTrend.entries.toList();
              double maxY = 5;

              if (trendEntries.isNotEmpty) {
                maxY = trendEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
                if (maxY < 5) maxY = 5;
              }

              for (int i = 0; i < trendEntries.length; i++) {
                spots.add(FlSpot(i.toDouble(), trendEntries[i].value.toDouble()));
                dateLabels.add(trendEntries[i].key);
              }

              return LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY / 4).roundToDouble() > 0 ? (maxY / 4).roundToDouble() : 1,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.8),
                    getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.8),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: spots.length > 7 ? (spots.length / 5).ceilToDouble() : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.toInt();
                          if (index < 0 || index >= dateLabels.length) return const SizedBox.shrink();
                          final DateTime date = DateFormat('yyyy-MM-dd').parse(dateLabels[index]);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6.0,
                            child: Text(DateFormat('dd\nMMM', 'id_ID').format(date), style: const TextStyle(color: subtitleColor, fontWeight: FontWeight.w500, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: (maxY / 4).roundToDouble() > 0 ? (maxY / 4).roundToDouble() : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value != value.toInt()) return const SizedBox.shrink();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4.0,
                            child: Text(meta.formattedValue, style: const TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.w500)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                      left: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(colors: [AdminScreen.primaryHeaderColor, AdminScreen.accentHeaderColor]),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: spots.length <= 15),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AdminScreen.primaryHeaderColor.withValues(alpha: 0.3),
                            AdminScreen.accentHeaderColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Ikhtisar Pendataan per Form',
              style: Get.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
            ),
          ),
          const SizedBox(height: 12),

          Obx(() {
            if (controller.isDashboardLoading.value && controller.filteredFormSubmissions.isEmpty) {
              return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor)));
            }
            if (controller.filteredFormSubmissions.isEmpty && !controller.isDashboardLoading.value) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildNoDataMessage(
                    controller.globalSearchQuery.value.isNotEmpty
                        ? 'Tidak ada form cocok dengan "${controller.globalSearchQuery.value}".'
                        : controller.selectedStartDate.value != null
                        ? 'Tidak ada submission form untuk rentang tanggal yang dipilih.'
                        : 'Belum ada submission form.'),
              );
            }
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: controller.filteredFormSubmissions.length,
                itemBuilder: (context, index) {
                  final entry = controller.filteredFormSubmissions[index];
                  bool isLastItem =
                      index == controller.filteredFormSubmissions.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(right: isLastItem ? 0 : 12.0),
                    child: _buildFormSubmissionSliderItem(entry, context),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildFormAccessSection(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Membangun setiap kartu dalam slider formulir.
  /// Membangun setiap kartu (slider item) pada daftar formulir di dashboard.
  /// 
  /// Menampilkan judul formulir, jumlah isian, dan menyediakan akses cepat 
  /// untuk ekspor data serta navigasi ke detail isian.
  Widget _buildFormSubmissionSliderItem(
      Map<String, dynamic> entry, BuildContext context) {
    final String formTitle = entry['formTitle'] ?? 'Untitled Form';
    final String formId = entry['formId'] ?? '';
    final int count = entry['count'] ?? 0;

    double cardWidth = MediaQuery.of(context).size.width * 0.75;
    if (cardWidth < 300) cardWidth = 300;

    return Obx(() {
      final bool isSelected =
          controller.selectedFormForChart.value?['formId'] == formId;
      return SizedBox(
        width: cardWidth,
        child: Card(
          elevation: isSelected ? 6.0 : 4.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected
                ? const BorderSide(color: AdminScreen.accentHeaderColor, width: 2.5)
                : BorderSide.none,
          ),
          color: cardBgColor,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            // Aksi klik utama: memilih kartu untuk menampilkan grafik
            onTap: () => controller.updateChartForForm(entry),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bagian Atas: Ikon dan Judul
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AdminScreen.primaryHeaderColor.withValues(alpha: 0.8),
                                AdminScreen.accentHeaderColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: AdminScreen.accentHeaderColor.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2))
                            ]),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            formTitle,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: titleColor.withValues(alpha: 1.0),
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bagian Bawah: Jumlah Isian dan Tombol Navigasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Export
                      Material(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            debugPrint('AdminScreen: Tombol Export diklik untuk $formTitle ($formId)');
                            _showExportDialog(context, formId, formTitle);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.download_rounded, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Export', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chip Jumlah Isian
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AdminScreen.accentHeaderColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AdminScreen.accentHeaderColor.withValues(alpha: 0.3),
                                  width: 1.0,
                                )),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AdminScreen.accentHeaderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tombol Navigasi ke Halaman Detail
                          Material(
                            color: AdminScreen.accentHeaderColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.submissionsForm,
                                  arguments: {
                                    'formId': formId,
                                    'formTitle': formTitle,
                                  },
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Membangun komponen pemilih rentang tanggal untuk filter data dashboard.
  Widget _buildDateFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Rentang Tanggal',
          style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AdminScreen.titlePageColor.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => controller.openCustomDateRangePicker(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AdminScreen.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: Obx(() {
                    String startDateText = controller.selectedStartDate.value != null ? DateFormat('dd MMM yy', 'id_ID').format(controller.selectedStartDate.value!) : 'Mulai';
                    String endDateText = controller.selectedEndDate.value != null ? DateFormat('dd MMM yy', 'id_ID').format(controller.selectedEndDate.value!) : 'Akhir';
                    String displayText = 'Pilih Rentang Tanggal';
                    if (controller.selectedStartDate.value != null) {
                      displayText = isSameDay(controller.selectedStartDate.value, controller.selectedEndDate.value)
                          ? startDateText
                          : '$startDateText - $endDateText';
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: controller.selectedStartDate.value != null ? AdminScreen.titlePageColor : Colors.grey.shade600,
                              fontWeight: controller.selectedStartDate.value != null ? FontWeight.w500 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, color: AdminScreen.accentHeaderColor, size: 20),
                      ],
                    );
                  }),
                ),
              ),
            ),
            Obx(() => (controller.selectedStartDate.value != null)
                ? Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: controller.resetDateFilter,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200, width: 1)),
                    child: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 20),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  /// Membangun bagian ringkasan akses akun untuk setiap formulir.
  Widget _buildFormAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambaran Akses Form',
          style: Get.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.isDashboardLoading.value &&
              controller.filteredFormAccessCounts.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor, strokeWidth: 2.0),
            ));
          }
          if (controller.filteredFormAccessCounts.isEmpty &&
              !controller.isDashboardLoading.value) {
            return _buildNoDataMessage(
                controller.globalSearchQuery.value.isNotEmpty
                    ? 'Tidak ada form cocok dengan "${controller.globalSearchQuery.value}" pada gambaran akses.'
                    : 'Tidak ada data akses form.');
          }
          return Column(
            children: controller.filteredFormAccessCounts.map((entry) {
              return _buildFormAccessItem(entry);
            }).toList(),
          );
        }),
      ],
    );
  }

  /// Membangun item baris dalam daftar ringkasan akses formulir.
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
            Icon(Icons.how_to_reg_outlined,
                color: AdminScreen.accentHeaderColor.withValues(alpha: 0.8),
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'] ?? 'Untitled Form',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor.withValues(alpha: 0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengguna dengan Akses: ${entry['accessCount']}',
                    style: TextStyle(
                        fontSize: 13, color: subtitleColor.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            Icon(Icons.people_alt_outlined, color: Colors.grey.shade400, size: 20)
          ],
        ),
      ),
    );
  }

  Widget _buildDummyChartWithLabel(String message, {bool isEmpty = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isEmpty
                    ? Icons.touch_app_rounded
                    : Icons.insert_chart_outlined_rounded,
                size: 44,
                color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog konfigurasi untuk ekspor data formulir ke file (CSV/JSON).
  void _showExportDialog(BuildContext context, String formId, String formTitle) {
    debugPrint('AdminScreen: Membuka dialog ekspor untuk form $formId');
    final TextEditingController periodController = TextEditingController(
      text: DateFormat('yyyy-MM').format(DateTime.now())
    );
    String selectedFormat = 'csv';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.file_download_outlined, color: AdminScreen.accentHeaderColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Export Data $formTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Masukkan Periode (Bulan)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: periodController,
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM (Contoh: 2024-05)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('2. Pilih Format File', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Excel (CSV)')),
                          selected: selectedFormat == 'csv',
                          onSelected: (bool selected) { if (selected) setState(() => selectedFormat = 'csv'); },
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: selectedFormat == 'csv' ? Colors.green.shade800 : Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('JSON')),
                          selected: selectedFormat == 'json',
                          onSelected: (bool selected) { if (selected) setState(() => selectedFormat = 'json'); },
                          selectedColor: Colors.orange.shade100,
                          labelStyle: TextStyle(color: selectedFormat == 'json' ? Colors.orange.shade800 : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminScreen.accentHeaderColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Simpan data yang dibutuhkan sebelum pop
                    final String fId = formId;
                    final String format = selectedFormat;
                    final String period = periodController.text.trim();

                    // Tutup dialog terlebih dahulu
                    Navigator.of(context).pop();
                    
                    // Gunakan Future.delayed untuk memastikan dialog sudah benar-benar tertutup 
                    // dan Overlay kembali stabil sebelum memanggil FilePicker
                    Future.delayed(const Duration(milliseconds: 300), () {
                       controller.exportFormSubmissions(
                        formId: fId, 
                        format: format,
                        period: period
                      );
                    });
                  },
                  child: const Text('Ekspor Sekarang', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
