import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_page.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/Admin_Profile/admin_account_page.dart';
import '../../../infrastructure/navigation/routes.dart';

class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color iconColor = Color(0xFFF57C00);
  static const Color cardBackgroundColor = Colors.white;
  static const Color bottomNavIconColor = Color(0xFFF57C00);
  static const Color titlePageColor = Colors.black87;

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
            padding: const EdgeInsets.only(
                top: 40.0, left: 24.0, right: 24.0, bottom: 20.0),
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentHeaderColor.withOpacity(0.9),
                    primaryHeaderColor.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                  )
                ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                        'Hello, ${controller.adminName.value.isNotEmpty ? controller.adminName.value : 'Admin'}',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))]
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                    InkWell(
                      onTap: () {
                        Get.toNamed(AppRoutes.adminProfil);
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(Icons.person_rounded,
                            size: 30, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      controller.updateGlobalSearchQuery(value);
                    },
                    decoration: InputDecoration(
                        hintText: 'Cari berdasarkan judul form...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                        suffixIcon: Obx(() =>
                        controller.globalSearchQuery.value.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500, size: 20),
                          onPressed: () {
                            controller.clearGlobalSearchQuery();
                            FocusScope.of(context).unfocus();
                          },
                        )
                            : const SizedBox.shrink()),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
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
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.file_copy_rounded), label: 'Form'),
          BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded), label: 'Account'),
        ],
      )),
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
    return Obx(() {
      if (controller.isDashboardLoading.value &&
          controller.filteredFormSubmissions.isEmpty &&
          controller.submissionTrend.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AdminScreen.accentHeaderColor));
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
            const SizedBox(height: 24),
            Text(
              'Progress Rumah Tangga yang Sudah Didata Harian', // Renamed
              style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600, color: titleColor),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 12),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                bool noOverallData = !controller.isDashboardLoading.value &&
                    controller.submissionTrend.isEmpty &&
                    controller.selectedStartDate.value == null;
                bool noFilteredData = !controller.isDashboardLoading.value &&
                    controller.submissionTrend.isEmpty &&
                    controller.selectedStartDate.value != null;

                if (controller.isDashboardLoading.value &&
                    controller.submissionTrend.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AdminScreen.accentHeaderColor, strokeWidth: 2.5));
                } else if (noOverallData) {
                  return _buildDummyChartWithLabel(
                      "Belum ada data progres rumah tangga yang sudah didata secara keseluruhan.", isEmpty: true); // Updated message
                } else if (noFilteredData) {
                  return _buildDummyChartWithLabel(
                      "Tidak ada data progres rumah tangga yang sudah didata untuk rentang tanggal yang dipilih.",
                      isEmpty: true); // Updated message
                } else if (controller.submissionTrend.isEmpty &&
                    !controller.isDashboardLoading.value) {
                  return _buildDummyChartWithLabel(
                      "Tidak ada poin data untuk diplot pada chart.", isEmpty: true);
                }

                List<FlSpot> spots = [];
                List<String> dateLabels = [];
                final trendEntries = controller.submissionTrend.entries.toList();

                double minY = 0;
                double maxY = 5;

                if (trendEntries.isNotEmpty) {
                  maxY = trendEntries
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble();
                  if (maxY < 5) maxY = 5;
                  if (maxY == 0) maxY = 1;
                }

                for (int i = 0; i < trendEntries.length; i++) {
                  spots.add(FlSpot(i.toDouble(), trendEntries[i].value.toDouble()));
                  dateLabels.add(trendEntries[i].key);
                }

                if (spots.isEmpty && !controller.isDashboardLoading.value) {
                  return _buildDummyChartWithLabel(
                      "Tidak ada poin data untuk diplot pada chart.", isEmpty: true);
                }

                return LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval:
                      (maxY / 4).roundToDouble() > 0 ? (maxY / 4).roundToDouble() : 1,
                      verticalInterval:
                      spots.length > 10 ? (spots.length / 7).ceilToDouble() : 1,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 0.8),
                      getDrawingVerticalLine: (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 0.8),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: spots.length > 7
                              ? (spots.length / (spots.length > 20 ? 6 : 4)).ceilToDouble()
                              : 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // Ensure index is valid
                            final int index = value.toInt();
                            if (index < 0 || index >= dateLabels.length) {
                              return const SizedBox.shrink();
                            }

                            // Parse and format date
                            try {
                              final DateTime date = DateFormat('yyyy-MM-dd').parse(dateLabels[index]);
                              final String formattedDate = DateFormat('dd\nMMM', 'id_ID').format(date);
                              return SideTitleWidget(
                                meta: meta, // Required parameter
                                space: 6.0,
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: subtitleColor ?? Colors.grey.shade600, // Fallback color, non-const
                                    fontWeight: FontWeight.w500,
                                    fontSize: 9,
                                  ),
                                ),
                                fitInside: SideTitleFitInsideData(
                                  enabled: spots.length > 10, // Enable only for dense data
                                  distanceFromEdge: 6.0,
                                  parentAxisSize: meta.parentAxisSize, axisPosition: meta.axisPosition,
                                ),
                              );
                            } catch (e) {
                              debugPrint('Error parsing date at index $index: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: (maxY / 4).roundToDouble() > 0 ? (maxY / 4).roundToDouble() : 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // Only show integer, non-negative values
                            if (value != value.toInt() || value < 0) {
                              return const SizedBox.shrink();
                            }

                            // Use formattedValue for consistency
                            String text;
                            if (value == meta.min || value == meta.max) {
                              text = meta.formattedValue;
                            } else if (meta.appliedInterval != null &&
                                meta.appliedInterval! > 0 &&
                                value % meta.appliedInterval! == 0) {
                              text = meta.formattedValue;
                            } else {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              meta: meta, // Required parameter
                              space: 4.0,
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: subtitleColor ?? Colors.grey.shade600, // Fallback color, non-const
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              fitInside: SideTitleFitInsideData(
                                enabled: maxY > 10, // Enable only for large Y-axis ranges
                                distanceFromEdge: 4.0,
                                parentAxisSize: meta.parentAxisSize, axisPosition: meta.axisPosition,
                              ),
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
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [AdminScreen.primaryHeaderColor, AdminScreen.accentHeaderColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: spots.length <= 15,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 3.5,
                            color: Colors.white,
                            strokeWidth: 1.5,
                            strokeColor: AdminScreen.accentHeaderColor,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AdminScreen.primaryHeaderColor.withOpacity(0.3),
                              AdminScreen.accentHeaderColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(8.0),
                        getTooltipColor: (LineBarSpot spot) => AdminScreen.accentHeaderColor,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final flSpot = barSpot;
                            if (flSpot.x.toInt() >= 0 && flSpot.x.toInt() < dateLabels.length) {
                              DateTime date = DateFormat('yyyy-MM-dd').parse(dateLabels[flSpot.x.toInt()]);
                              String formattedDate = DateFormat('EEE, dd MMM yy', 'id_ID').format(date);
                              return LineTooltipItem(
                                '$formattedDate\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: flSpot.y.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.yellowAccent[400],
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' isian',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                                textAlign: TextAlign.center,
                              );
                            }
                            return null;
                          }).where((item) => item != null).toList().cast<LineTooltipItem>();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              'Submissions per Form',
              style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
            ),
            const SizedBox(height: 12),
            Obx(() => controller.filteredFormSubmissions.isEmpty && !controller.isDashboardLoading.value
                ? _buildNoDataMessage(
                controller.globalSearchQuery.value.isNotEmpty
                    ? 'Tidak ada form cocok dengan "${controller.globalSearchQuery.value}".'
                    : controller.selectedStartDate.value != null
                    ? 'Tidak ada submission form untuk rentang tanggal yang dipilih.'
                    : 'Belum ada submission form.'
            )
                : Column(
              children: controller.filteredFormSubmissions.map((entry) {
                return _buildFormSubmissionItem(entry);
              }).toList(),
            )),
            const SizedBox(height: 24),
            _buildFormAccessSection(),
            const SizedBox(height: 24),
            // Removed "Aktivitas Pengguna" section as requested.
            // Text(
            //   'Aktivitas Pengguna',
            //   style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
            // ),
            // const SizedBox(height: 12),
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: cardBgColor,
            //     borderRadius: BorderRadius.circular(12),
            //     boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2)) ],
            //   ),
            //   child: Obx(() => controller.totalActiveUsers.value == 0 && !controller.isDashboardLoading.value
            //       ? _buildNoDataMessage('Tidak ada data aktivitas pengguna.')
            //       : Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Icon(Icons.supervised_user_circle_outlined, color: Colors.green.shade600, size: 28),
            //       const SizedBox(width: 10),
            //       Text(
            //         'Total Pengguna Aktif: ${controller.totalActiveUsers.value}',
            //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            //       ),
            //     ],
            //   )
            //   ),
            // ),
            const SizedBox(height: 30),
          ],
        ),
      );
    });
  }

  Widget _buildDateFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Rentang Tanggal',
          style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AdminScreen.titlePageColor.withOpacity(0.85)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => controller.openCustomDateRangePicker(context), // Memanggil dialog kustom
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AdminScreen.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                    boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)) ],
                  ),
                  child: Obx(() {
                    String startDateText = controller.selectedStartDate.value != null
                        ? DateFormat('dd MMM yy', 'id_ID').format(controller.selectedStartDate.value!)
                        : 'Mulai';
                    String endDateText = controller.selectedEndDate.value != null
                        ? DateFormat('dd MMM yy', 'id_ID').format(controller.selectedEndDate.value!)
                        : 'Akhir';

                    String displayText = 'Pilih Rentang Tanggal';
                    if (controller.selectedStartDate.value != null && controller.selectedEndDate.value != null) {
                      bool isSingleDay = isSameDay(controller.selectedStartDate.value, controller.selectedEndDate.value);
                      if (isSingleDay) {
                        displayText = startDateText;
                      } else {
                        displayText = '$startDateText - $endDateText';
                      }
                    } else if (controller.selectedStartDate.value != null) {
                      displayText = startDateText;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 14.5,
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
                        const Icon( // Ikon kalender tetap di sini untuk indikasi visual
                          Icons.calendar_today_outlined, // Menggunakan ikon yang lebih standar
                          color: AdminScreen.accentHeaderColor,
                          size: 20,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            Obx(() => (controller.selectedStartDate.value != null || controller.selectedEndDate.value != null)
                ? Padding( // Widget Padding LUAR untuk tombol reset
              padding: const EdgeInsets.only(left: 10.0), // PASTIKAN ADA PROPERTI PADDING INI
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: controller.resetDateFilter,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10.0), // Padding DALAM untuk konten tombol
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200, width: 1)
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink()
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Jumlah Rumah Tangga yang Sudah Didata', // Renamed
              value: controller.totalSubmissions.value.toString(),
              icon: Icons.home_work_rounded, // Changed icon for household data
              iconColor: Colors.blue.shade600,
            ),
          ),
          // Removed 'Pengguna Aktif' card as requested
          // const SizedBox(width: 16),
          // Expanded(
          //   child: _buildMetricCard(
          //     title: 'Pengguna Aktif',
          //     value: controller.totalActiveUsers.value.toString(),
          //     icon: Icons.group_rounded,
          //     iconColor: Colors.teal.shade600,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color iconColor}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: subtitleColor.withOpacity(0.9)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor.withOpacity(0.85)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.article_outlined, color: AdminScreen.accentHeaderColor.withOpacity(0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'] ?? 'Untitled Form',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor.withOpacity(0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jumlah Isian: ${entry['count']}',
                    style: TextStyle(fontSize: 13, color: subtitleColor.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            Icon(Icons.bar_chart_rounded, color: Colors.grey.shade400, size: 20)
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
          'Gambaran Akses Form',
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.filteredFormAccessCounts.isEmpty && !controller.isDashboardLoading.value) {
            return _buildNoDataMessage(
                controller.globalSearchQuery.value.isNotEmpty
                    ? 'Tidak ada form cocok dengan "${controller.globalSearchQuery.value}" pada gambaran akses.'
                    : 'Tidak ada data akses form.'
            );
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
            Icon(Icons.how_to_reg_outlined, color: AdminScreen.accentHeaderColor.withOpacity(0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['formTitle'] ?? 'Untitled Form',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor.withOpacity(0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengguna dengan Akses: ${entry['accessCount']}',
                    style: TextStyle(fontSize: 13, color: subtitleColor.withOpacity(0.9)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isEmpty ? Icons.info_outline_rounded : Icons.insert_chart_outlined_rounded, // Ikon diganti
              size: isEmpty ? 40 : 44,
              color: Colors.grey.shade400
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
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
    // Kosongkan karena pesan teks sudah cukup
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}