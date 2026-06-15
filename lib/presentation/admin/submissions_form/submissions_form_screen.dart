// lib/presentation/admin/submissions_form/submissions_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/user_model.dart';
import './submissions_form_controller.dart';

/// [SubmissionsFormScreen] adalah antarmuka untuk melihat daftar hasil pendataan
/// (submissions) dari sebuah formulir spesifik.
/// 
/// Halaman ini menyediakan fitur:
/// 1. Pencarian data berdasarkan identitas responden atau pengisi.
/// 2. Filtering data berdasarkan periode, status, dan wilayah desa.
/// 3. Pengurutan data (sorting) secara dinamis.
/// 4. Akses untuk melihat detail, mengedit, dan menghapus data isian.
/// 5. Tombol aksi ekspor data ke format JSON, CSV, dan Excel.
class SubmissionsFormScreen extends GetView<SubmissionsFormController> {
  const SubmissionsFormScreen({super.key});

  /// Skema warna konsisten untuk antarmuka daftar submissions.
  static const Color pageBackgroundColor = Color(0xFFF0F4F8);
  static const Color primaryHeaderColor = Color(0xFFFFB74D);
  static const Color accentHeaderColor = Color(0xFFFB8C00);
  static const Color cardBackgroundColor = Colors.white;
  static const Color searchFieldColor = Colors.white;
  static const Color deleteButtonColor = Color(0xFFE53935);
  static const Color editButtonColor = Color(0xFF43A047);
  static const Color textColorPrimary = Color(0xFF263238);
  static const Color textColorSecondary = Color(0xFF455A64);
  static const Color iconColorGeneral = Color(0xFF78909C);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yy, HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          color: Colors.white,
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Obx(() => Text(
          controller.appBarTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 19),
          overflow: TextOverflow.ellipsis,
        )),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [accentHeaderColor, primaryHeaderColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 3.0,
        centerTitle: true,
        actions: [
          Obx(() => controller.isExporting.value
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          )
              : PopupMenuButton<String>(
            icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white),
            tooltip: "Export Data Form Ini",
            onSelected: (value) {
              if (value == 'json') {
                controller.exportSubmissionsAsJson();
              } else if (value == 'csv') {
                controller.exportSubmissionsAsCsv();
              } else if (value == 'xlsx') {
                controller.exportSubmissionsAsXlsx();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              _buildPopupMenuItem(value: 'json', text: 'JSON (.json)', icon: Icons.code_rounded, color: Colors.blueAccent.shade700),
              _buildPopupMenuItem(value: 'csv', text: 'CSV (.csv)', icon: Icons.description_rounded, color: Colors.green.shade700),
              _buildPopupMenuItem(value: 'xlsx', text: 'Excel (.xlsx)', icon: Icons.table_chart_rounded, color: Colors.teal.shade700),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.white,
          )),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(context, controller.searchController),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingStructure.value && controller.formStructure.value == null && controller.initialFormTitle.value.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
              }
              if (controller.errorMessage.value.isNotEmpty && controller.displayedSubmissions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
                );
              }
              if (controller.isLoadingSubmissions.value && controller.displayedSubmissions.isEmpty && controller.errorMessage.value.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
              }

              return RefreshIndicator(
                onRefresh: () => controller.refreshData(),
                color: accentHeaderColor,
                backgroundColor: Colors.white,
                child: Obx(() {
                  if (controller.displayedSubmissions.isEmpty && !controller.isLoadingSubmissions.value) {
                    return _buildNoSubmissionsMessage(
                      controller.searchQuery.value.isNotEmpty
                          ? 'Tidak ada data cocok dengan pencarian "${controller.searchQuery.value}".'
                          : 'Belum ada data isian untuk form ini.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: controller.displayedSubmissions.length,
                    itemBuilder: (context, index) {
                      final displayableSubmission = controller.displayedSubmissions[index];
                      return _buildSubmissionCard(displayableSubmission, dateFormat, context);
                    },
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Membangun item menu untuk pilihan ekspor data.
  PopupMenuEntry<String> _buildPopupMenuItem({
    required String value,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14.5, color: textColorPrimary)),
        ],
      ),
    );
  }

  /// Membangun komponen bar pencarian dan barisan filter (Periode, Status, Desa).
  Widget _buildSearchBarAndFilter(BuildContext context, TextEditingController searchCtrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: pageBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  elevation: 1.5,
                  borderRadius: BorderRadius.circular(10.0),
                  shadowColor: Colors.grey.withValues(alpha: 0.3),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (value) => controller.changeSearchQuery(value),
                    style: const TextStyle(color: textColorPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Cari KRT/NIK/Pengisi...',
                      hintStyle: TextStyle(color: textColorSecondary.withValues(alpha: 0.8), fontSize: 14.5),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.search_outlined, color: textColorSecondary.withValues(alpha: 0.7), size: 20),
                      ),
                      filled: true,
                      fillColor: searchFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.7),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: accentHeaderColor.withValues(alpha: 0.8), width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                elevation: 1.5,
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                shadowColor: Colors.grey.withValues(alpha: 0.3),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey.shade300, width: 0.7),
                  ),
                  child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.currentSortOrder.value,
                      icon: Icon(Icons.sort_rounded, color: accentHeaderColor.withValues(alpha: 0.9), size: 20),
                      style: TextStyle(color: textColorPrimary.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                      items: controller.sortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        controller.changeSortOrder(newValue);
                      },
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filter:',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 42,
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
                      items: controller.availablePeriods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 13)),
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
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedStatusFilter.value,
                      items: controller.statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.selectedStatusFilter.value = newValue;
                          controller.refreshData();
                        }
                      },
                    ),
                  )),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.userRole.value == 'global_admin' || controller.userRole.value == 'admin') {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_outlined, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    const Text('Desa:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(() => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: controller.selectedVillageFilter.value,
                            items: [
                              const DropdownMenuItem(value: 'Semua', child: Text('Semua Desa', style: TextStyle(fontSize: 13))),
                              ...controller.availableVillages.map((v) => DropdownMenuItem(
                                value: v['id'],
                                child: Text(v['name'] ?? '', style: const TextStyle(fontSize: 13)),
                              )),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedVillageFilter.value = val;
                                controller.refreshData();
                              }
                            },
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Membangun kartu informasi individu untuk satu data isian (submission).
  /// 
  /// Menampilkan judul (Nama KRT), status, nama petugas, wilayah, dan waktu pengisian.
  /// Juga menyediakan tombol aksi kontekstual berdasarkan peran admin yang login.
  Widget _buildSubmissionCard(DisplayableSubmission displayableSubmission, DateFormat dateFormat, BuildContext context) {
    final submission = displayableSubmission.originalSubmission;
    final String namaKRT = displayableSubmission.namaKepalaKeluarga;
    final String nikKRT = displayableSubmission.nikKepalaKeluarga;

    final String formattedSubmittedAt = dateFormat.format(submission.submittedAt.toDate().toLocal());
    final String? formattedUpdatedAt = submission.updatedAt != null
        ? dateFormat.format(submission.updatedAt!.toDate().toLocal())
        : null;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: cardBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => controller.editSubmission(submission),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayableSubmission.displayTitle.isNotEmpty
                                        ? displayableSubmission.displayTitle
                                        : "Data ${submission.formTitle}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: textColorPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (displayableSubmission.displayDescription.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        displayableSubmission.displayDescription,
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: textColorSecondary.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(submission.status),
                          ],
                        ),
                        if (submission.userName.isNotEmpty && !displayableSubmission.displayTitle.contains(submission.userName))
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Text(
                              "Pengisi: ${submission.userName}",
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: textColorSecondary.withValues(alpha: 0.9),
                                  fontStyle: FontStyle.italic
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final role = controller.userRole.value.toLowerCase().trim();
                    final userModel = UserModel(uid: '', role: role);
                    
                    // Admin RT hanya bisa LIHAT (Read-Only), tidak bisa hapus/edit
                    final bool isReadOnlyUser = userModel.isAdminRt;
                    final List<String> canModifyRoles = ['global_admin', 'admin', 'admin_desa', 'admindesa'];
                    final bool canModify = canModifyRoles.contains(role);
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        if (isReadOnlyUser)
                          _actionButtonSmall(
                            tooltip: 'Lihat Detail',
                            icon: Icons.visibility_rounded,
                            color: Colors.blue.shade600,
                            onPressed: () => controller.editSubmission(submission),
                          ),
                        if (canModify) ...[
                          _actionButtonSmall(
                            tooltip: 'Edit Isian',
                            icon: Icons.edit_rounded,
                            color: editButtonColor,
                            onPressed: () => controller.editSubmission(submission),
                          ),
                          _actionButtonSmall(
                            tooltip: 'Hapus Isian',
                            icon: Icons.delete_forever_rounded,
                            color: deleteButtonColor,
                            onPressed: () => controller.deleteSubmission(submission, displayableSubmission.displayTitle),
                          ),
                        ],
                      ],
                    );
                  })
                ],
              ),

              if (!(namaKRT.isNotEmpty && nikKRT.isNotEmpty && displayableSubmission.displayTitle == "$namaKRT - $nikKRT")) ...[
                if (namaKRT.isNotEmpty && displayableSubmission.displayTitle != namaKRT) Padding(
                  padding: const EdgeInsets.only(top:6.0),
                  child: _buildInfoRow(Icons.person_outline_rounded, "Nama KRT", namaKRT, isHighlight: true),
                ),
                if (nikKRT.isNotEmpty && !displayableSubmission.displayTitle.contains(nikKRT)) _buildInfoRow(Icons.perm_identity_rounded, "NIK KRT", nikKRT, isHighlight: true),
              ],

              if ((namaKRT.isNotEmpty || nikKRT.isNotEmpty) && submission.formTitle != displayableSubmission.displayTitle) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.ballot_outlined, "Jenis Form", submission.formTitle),
              ],

              if (namaKRT.isNotEmpty || nikKRT.isNotEmpty || !displayableSubmission.displayTitle.contains(submission.formTitle) ) const SizedBox(height: 10),
              
              if (submission.villageName != null) 
                _buildInfoRow(Icons.location_city, "Desa", submission.villageName!),
              _buildInfoRow(Icons.date_range, "Periode", submission.period ?? "N/A"),
              if (submission.isAutoGenerated)
                _buildInfoRow(Icons.auto_awesome, "Sumber", "Auto Duplicate dari ${submission.duplicatedFromPeriod}"),

              Divider(color: Colors.grey.shade200, thickness: 0.8),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildMetaInfo(
                    icon: Icons.calendar_today_rounded,
                    text: formattedSubmittedAt,
                    tooltip: "Waktu Pengisian",
                  ),
                  if (formattedUpdatedAt != null && formattedUpdatedAt != formattedSubmittedAt) ...[
                    const SizedBox(width: 6),
                    _buildMetaInfo(
                      icon: Icons.edit_calendar_outlined,
                      text: "Update: $formattedUpdatedAt",
                      tooltip: "Waktu Pembaruan",
                      isUpdate: true,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun baris informasi (Ikon + Label + Nilai) di dalam kartu submission.
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: isHighlight ? accentHeaderColor.withValues(alpha: 0.8) : iconColorGeneral),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              color: textColorSecondary,
              fontWeight: isHighlight ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: textColorPrimary,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun informasi metadata kecil (misal: Tanggal Isi/Update) dengan ikon.
  Widget _buildMetaInfo({required IconData icon, required String text, String? tooltip, bool isUpdate = false}) {
    return Tooltip(
      message: tooltip ?? text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isUpdate ? 11.5 : 12.5, color: isUpdate ? Colors.blueGrey.shade500 : Colors.grey.shade600),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isUpdate ? 10.5 : 11,
                color: isUpdate ? Colors.blueGrey.shade600 : Colors.grey.shade600,
                fontStyle: isUpdate ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol aksi kecil melingkar (Edit, Hapus, Lihat) dengan tooltip.
  Widget _actionButtonSmall({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  /// Membangun tampilan pesan saat tidak ada data isian yang ditemukan atau cocok dengan filter.
  Widget _buildNoSubmissionsMessage(String message) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.find_in_page_outlined, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColorPrimary.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 10),
                      if (controller.searchQuery.value.isNotEmpty)
                        const Text(
                          "Coba kata kunci lain atau bersihkan pencarian.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: textColorSecondary, height: 1.5),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  /// Membangun label (badge) status isian dengan warna yang sesuai (Draft, Submitted, Locked).
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'submitted':
        color = Colors.green;
        break;
      case 'locked':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
