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
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                              shadows: [
                                Shadow(
                                    blurRadius: 2,
                                    color: Colors.black26,
                                    offset: Offset(1, 1))
                              ]),
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
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.selectedPageIndex.value,
        onTap: controller.onPageChanged,
        selectedItemColor: bottomNavIconColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
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
    return RefreshIndicator(
      onRefresh: () => controller.fetchDashboardData(),
      color: AdminScreen.accentHeaderColor,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
        children: [
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
                  color: Colors.grey.withOpacity(0.1),
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
                            child: Text(DateFormat('dd\nMMM', 'id_ID').format(date), style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500, fontSize: 9)),
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
                            child: Text(meta.formattedValue, style: TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.w500)),
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
                            AdminScreen.primaryHeaderColor.withOpacity(0.3),
                            AdminScreen.accentHeaderColor.withOpacity(0.1),
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
  /// **BAGIAN INI TELAH DIUBAH**
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
                                AdminScreen.primaryHeaderColor.withOpacity(0.8),
                                AdminScreen.accentHeaderColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: AdminScreen.accentHeaderColor.withOpacity(0.2),
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
                              color: titleColor.withOpacity(1.0),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Chip Jumlah Isian
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                            color: AdminScreen.accentHeaderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AdminScreen.accentHeaderColor.withOpacity(0.3),
                              width: 1.0,
                            )),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_list_bulleted_rounded, size: 18, color: AdminScreen.accentHeaderColor),
                            const SizedBox(width: 8),
                            Text(
                              '${count} Isian',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AdminScreen.accentHeaderColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Navigasi ke Halaman Detail
                      Material(
                        color: AdminScreen.accentHeaderColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.SUBMISSIONS_FORM,
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
                              size: 20,
                            ),
                          ),
                        ),
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

  Widget _buildDateFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Rentang Tanggal',
          style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AdminScreen.titlePageColor.withOpacity(0.85)),
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
                color: AdminScreen.accentHeaderColor.withOpacity(0.8),
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
                        color: titleColor.withOpacity(0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengguna dengan Akses: ${entry['accessCount']}',
                    style: TextStyle(
                        fontSize: 13, color: subtitleColor.withOpacity(0.9)),
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
}