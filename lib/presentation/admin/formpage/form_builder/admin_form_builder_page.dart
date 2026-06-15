import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/admin_constants.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/form_builder/admin_form_builder_controller.dart';

/// [AdminFormBuilderPage] adalah halaman UI untuk membangun dan mengedit formulir secara dinamis.
/// 
/// Halaman ini memungkinkan Admin untuk:
/// 1. Mengatur identitas formulir (Judul, Deskripsi, Periode).
/// 2. Menentukan target wilayah desa dan konfigurasi kelompok usia penduduk.
/// 3. Menambah, mengurutkan, dan mengelola seksi (sections) serta berbagai tipe pertanyaan.
/// 4. Mengatur logika kompleks seperti lompatan bersyarat, dependensi opsi, dan rekap otomatis.
class AdminFormBuilderPage extends GetView<AdminFormBuilderController> {
  const AdminFormBuilderPage({super.key});

  /// Warna teks pada AppBar.
  static const Color appBarForegroundColor = Colors.white;
  /// Warna aksen utama tema.
  static const Color accentThemeColor = AdminTheme.accentHeaderColor;
  /// Warna label netral.
  static const Color neutralLabelColor = Colors.grey;
  /// Warna default border kolom input.
  static const Color defaultTextFieldBorderColor = Colors.black26;
  /// Warna latar belakang halaman.
  static const Color pageBgColor = AdminTheme.pageBackgroundColor;
  /// Warna latar belakang kartu.
  static const Color cardBgColor = Colors.white;

  /// Mengonversi angka integer menjadi format Romawi untuk penomoran seksi.
  String _toRoman(int number) {
    if (number < 1 || number > 3999) {
      return number.toString();
    }

    const List<String> romanNumerals = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I',
    ];

    const List<int> values = [
      1000,
      900,
      500,
      400,
      100,
      90,
      50,
      40,
      10,
      9,
      5,
      4,
      1,
    ];

    String result = '';

    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        result += romanNumerals[i];
        number -= values[i];
      }
    }

    return result;
  }

  /// Mendapatkan label teks bahasa Indonesia untuk tipe pertanyaan tertentu.
  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.text:
        return 'Teks Singkat';
      case QuestionType.paragraph:
        return 'Paragraf';
      case QuestionType.number:
        return 'Angka';
      case QuestionType.date:
        return 'Tanggal';
      case QuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case QuestionType.checkboxes:
        return 'Checkbox';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.gridNumeric:
        return 'Grid Numerik';
      case QuestionType.imageUpload:
        return 'Upload Gambar';
      case QuestionType.location:
        return 'Lokasi GPS';
    }
  }

  /// Mendapatkan deskripsi singkat mengenai fungsi dari setiap tipe pertanyaan.
  String _questionTypeSubtitle(QuestionType type) {
    switch (type) {
      case QuestionType.text:
        return 'Jawaban teks pendek';
      case QuestionType.paragraph:
        return 'Jawaban teks panjang';
      case QuestionType.number:
        return 'Jawaban berupa angka';
      case QuestionType.date:
        return 'Jawaban berupa tanggal';
      case QuestionType.multipleChoice:
        return 'User memilih satu jawaban';
      case QuestionType.checkboxes:
        return 'User bisa memilih lebih dari satu jawaban';
      case QuestionType.dropdown:
        return 'User memilih jawaban dari dropdown';
      case QuestionType.gridNumeric:
        return 'Input angka dalam bentuk tabel/grid';
      case QuestionType.imageUpload:
        return 'User upload foto dari kamera atau galeri';
      case QuestionType.location:
        return 'User mengambil koordinat GPS saat ini';
    }
  }

  /// Mendapatkan ikon representatif untuk setiap tipe pertanyaan di UI.
  IconData _questionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.text:
        return Icons.short_text_rounded;
      case QuestionType.paragraph:
        return Icons.notes_rounded;
      case QuestionType.number:
        return Icons.pin_rounded;
      case QuestionType.date:
        return Icons.date_range_rounded;
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked_rounded;
      case QuestionType.checkboxes:
        return Icons.check_box_rounded;
      case QuestionType.dropdown:
        return Icons.arrow_drop_down_circle_rounded;
      case QuestionType.gridNumeric:
        return Icons.grid_on_rounded;
      case QuestionType.imageUpload:
        return Icons.image_rounded;
      case QuestionType.location:
        return Icons.my_location_rounded;
    }
  }

  /// Menghasilkan dekorasi input teks yang seragam (modern look) untuk seluruh form builder.
  static InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
    bool isDense = false,
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: neutralLabelColor.withValues(alpha: 0.9),
        fontSize: isDense ? 14 : 15,
      ),
      floatingLabelStyle: const TextStyle(
        color: accentThemeColor,
        fontWeight: FontWeight.w500,
      ),
      hintText: hintText ?? 'Masukkan $labelText...',
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: defaultTextFieldBorderColor.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: defaultTextFieldBorderColor.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: accentThemeColor,
          width: 1.8,
        ),
      ),
      filled: true,
      fillColor: cardBgColor,
      contentPadding: contentPadding ??
          (isDense
              ? const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          )
              : const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Batal / Kembali',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        toolbarHeight: 80.0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Management Form',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Obx(() {
              return Text(
                controller.formTitle.value.isEmpty
                    ? 'Buat Form Baru'
                    : controller.formTitle.value,
                style: TextStyle(
                  fontSize: 14,
                  color: appBarForegroundColor.withValues(alpha: 0.85),
                ),
                overflow: TextOverflow.ellipsis,
              );
            }),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.isBusy.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: appBarForegroundColor,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            return IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Simpan Form',
              onPressed: controller.saveForm,
            );
          }),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminTheme.primaryHeaderColor,
                AdminTheme.accentHeaderColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(35.0),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildSectionsList(),
          Obx(() {
            if (controller.isBusy.value) {
              return Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: accentThemeColor,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Membangun daftar seksi formulir menggunakan [CustomScrollView] untuk performa scrolling yang baik.
  Widget _buildSectionsList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _buildFormHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _buildVillageSelectionCard(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _buildAgeGroupSettings(),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final int sectionCount = controller.sections.length;

              if (sectionCount == 0) {
                return Card(
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Belum ada bagian. Tambahkan bagian baru.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sectionCount,
                onReorder: (oldIndex, newIndex) {
                  controller.reorderSections(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final FormSection section = controller.sections[index];

                  return _buildSectionCard(
                    section.id,
                    index,
                  );
                },
              );
            }),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _buildAddSectionButton(),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 90),
        ),
      ],
    );
  }

  /// Membangun kartu informasi utama formulir (Judul, Deskripsi, Periode, dan Auto-Refresh).
  Widget _buildFormHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Detail Form Utama',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentThemeColor,
                ),
              ),
            ),
            TextField(
              controller: controller.titleController,
              decoration: _modernInputDecoration(
                labelText: 'Judul Form',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: _modernInputDecoration(
                labelText: 'Deskripsi Form',
                hintText: 'Deskripsi Form (Opsional)',
              ),
              maxLines: 3,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Periode Pendataan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: Get.context!,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  helpText: 'Pilih Bulan & Tahun Periode',
                );
                if (picked != null) {
                  controller.selectedPeriod.value = DateFormat('yyyy-MM').format(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: defaultTextFieldBorderColor.withValues(alpha: 0.5)),
                  color: cardBgColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                        controller.selectedPeriod.value,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: accentThemeColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Fitur Duplikasi & Kunci Otomatis',
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 4),
            Obx(() => SwitchListTile(
              title: const Text('Auto Duplicate Bulanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Salin data periode sebelumnya otomatis saat masuk bulan baru.', style: TextStyle(fontSize: 12)),
              value: controller.autoDuplicateMonthly.value,
              onChanged: (val) => controller.autoDuplicateMonthly.value = val,
              activeThumbColor: accentThemeColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            Obx(() => SwitchListTile(
              title: const Text('Kunci Periode Sebelumnya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Otomatis kunci data bulan lalu agar tidak bisa diedit user.', style: TextStyle(fontSize: 12)),
              value: controller.lockPreviousPeriod.value,
              onChanged: (val) => controller.lockPreviousPeriod.value = val,
              activeThumbColor: accentThemeColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu pemilihan desa target untuk formulir ini (Tampilan berbeda berdasarkan Role).
  Widget _buildVillageSelectionCard() {
    return Obx(() {
      final role = controller.userRole.value;
      if (role == 'user' || role == '') return const SizedBox.shrink();

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cardBgColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Target Desa',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accentThemeColor,
                  ),
                ),
              ),
              if (role == 'global_admin' || role == 'admin')
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedVillageIdForForm.value.isEmpty ? null : controller.selectedVillageIdForForm.value,
                  decoration: _modernInputDecoration(
                    labelText: 'Pilih Desa (Kosongkan untuk Form Umum)',
                    prefixIcon: const Icon(Icons.holiday_village_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Form Umum (Semua Desa)'),
                    ),
                    ...controller.allVillages.map((village) => DropdownMenuItem<String>(
                          value: village.villageId,
                          child: Text(village.villageName),
                        )),
                  ],
                  onChanged: (val) {
                    controller.selectedVillageIdForForm.value = val ?? '';
                    if (val != null) {
                      controller.selectedVillageNameForForm.value = controller.allVillages.firstWhere((v) => v.villageId == val).villageName;
                    } else {
                      controller.selectedVillageNameForForm.value = '';
                    }
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.holiday_village_outlined, color: accentThemeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Form Desa:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              controller.selectedVillageNameForForm.value.isNotEmpty ? controller.selectedVillageNameForForm.value : 'Memuat...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Membangun kartu pengaturan kelompok usia untuk klasifikasi otomatis data kependudukan.
  Widget _buildAgeGroupSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBgColor,
      child: ExpansionTile(
        title: Text(
          'Konfigurasi Kelompok Usia Otomatis',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: accentThemeColor,
          ),
        ),
        subtitle: const Text('Tentukan kriteria kelompok usia untuk rekap otomatis.', style: TextStyle(fontSize: 12)),
        leading: const Icon(Icons.manage_accounts_rounded, color: accentThemeColor),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Obx(() => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.ageGroups.length,
                      itemBuilder: (context, index) {
                        final group = controller.ageGroups[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _PersistentTextField(
                                      fieldKey: ValueKey('age_group_label_${group.id}'),
                                      initialValue: group.label,
                                      onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(label: val)),
                                      decoration: _modernInputDecoration(labelText: 'Nama Kelompok', isDense: true),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => controller.removeAgeGroup(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PersistentTextField(
                                      fieldKey: ValueKey('age_group_key_${group.id}'),
                                      initialValue: group.key,
                                      onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(key: val)),
                                      decoration: _modernInputDecoration(labelText: 'Unique Key', isDense: true, hintText: 'cth: wus'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: group.gender,
                                      decoration: _modernInputDecoration(labelText: 'Jenis Kelamin', isDense: true),
                                      items: ['Semua', 'Laki-laki', 'Perempuan'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                                      onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(gender: val ?? 'Semua')),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PersistentTextField(
                                      fieldKey: ValueKey('age_group_min_${group.id}'),
                                      initialValue: group.minAge.toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(minAge: int.tryParse(val) ?? 0)),
                                      decoration: _modernInputDecoration(labelText: 'Min Usia', isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PersistentTextField(
                                      fieldKey: ValueKey('age_group_max_${group.id}'),
                                      initialValue: group.maxAge.toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(maxAge: int.tryParse(val) ?? 100)),
                                      decoration: _modernInputDecoration(labelText: 'Max Usia', isDense: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 16),
                              const Text(
                                'Aturan Jawaban Pemicu (Kustom)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                isExpanded: true,
                                initialValue: group.triggerQuestionId,
                                decoration: _modernInputDecoration(
                                  labelText: 'Jika Pertanyaan Berikut Dijawab:', 
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Tidak ada pemicu (Hanya Umur & Gender)')),
                                  ...controller.getAllQuestionsForLinking().map((q) => DropdownMenuItem(
                                    value: q['id'], 
                                    child: Text(q['text'] ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                  ))
                                ],
                                onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(triggerQuestionId: val, setTriggerQuestionIdNull: val == null)),
                              ),
                              const SizedBox(height: 10),
                              _PersistentTextField(
                                fieldKey: ValueKey('age_group_trigger_val_${group.id}'),
                                initialValue: group.triggerAnswerValue ?? '',
                                onChanged: (val) => controller.updateAgeGroup(index, group.copyWith(triggerAnswerValue: val, setTriggerAnswerValueNull: val.isEmpty)),
                                decoration: _modernInputDecoration(
                                  labelText: 'Maka Jawaban Harus Berupa:', 
                                  isDense: true, 
                                  hintText: 'Misal: Ya / Sering / 1'
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: controller.addAgeGroup,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Tambah Aturan Usia Baru'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentThemeColor,
                    side: const BorderSide(color: accentThemeColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol aksi untuk menambahkan seksi baru ke dalam formulir.
  Widget _buildAddSectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.addSection,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'Tambah Bagian Baru',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentThemeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  /// Membangun kartu individu untuk satu seksi (Section) yang mencakup pengaturan pengulangan dan daftar pertanyaan.
  Widget _buildSectionCard(String sectionIdFromList, int sectionIndex) {
    return Obx(
      key: ValueKey('section_obx_$sectionIdFromList'),
      () {
      final FormSection? section = controller.sections.firstWhereOrNull(
            (item) => item.id == sectionIdFromList,
      );

      if (section == null) {
        return Card(
          key: ValueKey('section_error_$sectionIdFromList'),
          child: const ListTile(
            title: Text('Bagian tidak ditemukan.'),
          ),
        );
      }

      final ExpansibleController? tileController =
      controller.sectionExpansionControllers[section.id];

      final String romanNumeral = _toRoman(sectionIndex + 1);

      String displaySectionTitle = section.title.trim().isEmpty
          ? 'Bagian $romanNumeral'
          : '$romanNumeral ${section.title.trim()}';

      if (section.isRepeatable) {
        displaySectionTitle += ' (Berulang)';
      }

      final String titleForDialog = section.title.trim().isEmpty
          ? 'Bagian $romanNumeral'
          : section.title.trim();

      final bool shouldBeInitiallyExpandedIfNoController =
          !controller.isEditMode && sectionIndex == 0;

      return Card(
        key: ValueKey('section_card_${section.id}'),
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: cardBgColor,
        child: ExpansionTile(
          key: ValueKey(section.id),
          controller: tileController,
          initiallyExpanded: tileController != null
              ? false
              : shouldBeInitiallyExpandedIfNoController,
          backgroundColor: cardBgColor,
          collapsedBackgroundColor: cardBgColor,
          iconColor: accentThemeColor,
          collapsedIconColor: Colors.grey.shade700,
          leading: const Icon(
            Icons.drag_handle_rounded,
            color: Colors.grey,
          ),
          title: Text(
            displaySectionTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Detail Bagian',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (controller.sections.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade300,
                          ),
                          tooltip: 'Hapus Bagian Ini',
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text('Konfirmasi Hapus Bagian'),
                                content: Text('Anda yakin ingin menghapus bagian "$titleForDialog"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Tutup dialog konfirmasi dengan Navigator standar agar lebih pasti
                                      Navigator.of(Get.context!).pop();
                                    },
                                    child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                                    onPressed: () {
                                      // Tutup dialog terlebih dahulu dengan Navigator standar agar lebih pasti
                                      Navigator.of(Get.context!).pop();
                                      // Beri jeda agar state update tidak mengganggu penutupan dialog
                                      Future.microtask(() => controller.removeSection(section.id));
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_title'),
                    initialValue: section.title,
                    onChanged: (text) {
                      controller.updateSectionTitle(section.id, text);
                    },
                    decoration: _modernInputDecoration(
                      labelText: 'Judul Bagian',
                      hintText: 'Misal: Data Penduduk',
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_description'),
                    initialValue: section.description ?? '',
                    onChanged: (text) {
                      controller.updateSectionDescription(section.id, text);
                    },
                    decoration: _modernInputDecoration(
                      labelText: 'Deskripsi Bagian',
                      hintText: 'Opsional',
                      isDense: true,
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionRepeatabilitySettings(section),
                  const SizedBox(height: 20),
                  Text(
                    'Pertanyaan untuk Bagian Ini:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildQuestionsList(
                    section.id,
                    sectionIndex,
                    section.questions,
                  ),
                  const SizedBox(height: 15),
                  _buildAddQuestionButton(section.id),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.unfold_less_rounded,
                        color: accentThemeColor.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      label: Text(
                        'Tutup Bagian Ini',
                        style: TextStyle(
                          color: accentThemeColor.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        tileController?.collapse();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Membangun pengaturan pengulangan (Repeatability) untuk suatu seksi.
  Widget _buildSectionRepeatabilitySettings(FormSection section) {
    return _buildExpansionTileForSettings(
      'Pengaturan Pengulangan Bagian',
      [
        SwitchListTile(
          title: const Text(
            'Bagian ini dapat diulang?',
            style: TextStyle(fontSize: 14),
          ),
          value: section.isRepeatable,
          onChanged: (bool newValue) {
            controller.updateSectionRepeatability(
              sectionId: section.id,
              isRepeatable: newValue,
              triggerQuestionId: newValue ? section.repeatTriggerQuestionId : null,
              minRepeats: newValue
                  ? (section.minRepeats ??
                  (section.repeatTriggerQuestionId != null ? 0 : 1))
                  : null,
              maxRepeats: newValue ? section.maxRepeats : null,
            );
          },
          activeThumbColor: accentThemeColor,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (section.isRepeatable) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: DropdownButtonFormField<String?>(
              initialValue: section.repeatTriggerQuestionId,
              decoration: _modernInputDecoration(
                labelText: 'Ulangi berdasarkan jawaban pertanyaan:',
                hintText: 'Pilih pertanyaan pemicu tipe angka',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    '(Tidak ada pemicu / Ulangi min. kali)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...controller.getAllQuestionsForLinking(numericOnly: true).map(
                      (qMap) {
                    return DropdownMenuItem<String?>(
                      value: qMap['id'],
                      child: Text(
                        qMap['text'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ],
              onChanged: (String? selectedQuestionId) {
                controller.updateSectionRepeatability(
                  sectionId: section.id,
                  isRepeatable: true,
                  triggerQuestionId: selectedQuestionId,
                  minRepeats: section.minRepeats,
                  maxRepeats: section.maxRepeats,
                );
              },
              isExpanded: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PersistentTextField(
                  fieldKey: ValueKey('${section.id}_min_repeats'),
                  initialValue: section.minRepeats?.toString() ??
                      (section.repeatTriggerQuestionId != null ? '0' : '1'),
                  decoration: _modernInputDecoration(
                    labelText: 'Min Pengulangan',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    controller.updateSectionRepeatability(
                      sectionId: section.id,
                      isRepeatable: true,
                      triggerQuestionId: section.repeatTriggerQuestionId,
                      minRepeats: int.tryParse(value),
                      maxRepeats: section.maxRepeats,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PersistentTextField(
                  fieldKey: ValueKey('${section.id}_max_repeats'),
                  initialValue: section.maxRepeats?.toString() ?? '',
                  decoration: _modernInputDecoration(
                    labelText: 'Max Pengulangan',
                    hintText: 'Opsional',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    controller.updateSectionRepeatability(
                      sectionId: section.id,
                      isRepeatable: true,
                      triggerQuestionId: section.repeatTriggerQuestionId,
                      minRepeats: section.minRepeats,
                      maxRepeats: int.tryParse(value),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
      initiallyExpanded: section.isRepeatable,
    );
  }

  /// Membangun daftar pertanyaan di dalam suatu seksi dengan fitur urutkan ulang (Reorderable).
  Widget _buildQuestionsList(
      String sectionId,
      int sectionIndex,
      List<FormQuestion> questions,
      ) {
    if (questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'Belum ada pertanyaan di bagian ini.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      onReorder: (oldIndex, newIndex) {
        controller.reorderQuestions(sectionId, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final FormQuestion question = questions[index];

        return _buildQuestionCard(
          sectionId,
          sectionIndex,
          question.id,
          index,
        );
      },
    );
  }

  /// Membangun kartu detail untuk setiap pertanyaan, mencakup teks, validasi, dan logika kustom.
  Widget _buildQuestionCard(
      String sectionId,
      int sectionIndexOverall,
      String questionIdFromList,
      int questionIndexInSection,
      ) {
    return Obx(
      key: ValueKey('q_obx_$questionIdFromList'),
      () {
      final FormQuestion? question = controller.sections
          .firstWhereOrNull((section) => section.id == sectionId)
          ?.questions
          .firstWhereOrNull((item) => item.id == questionIdFromList);

      if (question == null) {
        return Card(
          key: ValueKey('q_error_$questionIdFromList'),
          margin: const EdgeInsets.only(
            bottom: 16,
            top: 8,
          ),
          child: ListTile(
            title: Text(
              'Error: Pertanyaan ID $questionIdFromList tidak dapat dimuat.',
            ),
          ),
        );
      }

      final String questionTypeString = _questionTypeLabel(question.type);

      final Widget questionTileTitle = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.drag_indicator_rounded,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pertanyaan ${questionIndexInSection + 1} - ${question.questionText.trim().isNotEmpty ? question.questionText.trim() : questionTypeString}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey.shade800,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_forever_outlined,
              color: Colors.red.shade300,
              size: 22,
            ),
            tooltip: 'Hapus Pertanyaan',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Konfirmasi Hapus Pertanyaan'),
                  content: Text('Anda yakin ingin menghapus pertanyaan "${question.questionText.isNotEmpty ? question.questionText : "ini"}"?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Tutup dialog konfirmasi dengan Navigator standar agar lebih pasti
                        Navigator.of(Get.context!).pop();
                      },
                      child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                      onPressed: () {
                        // Tutup dialog terlebih dahulu dengan Navigator standar agar lebih pasti
                        Navigator.of(Get.context!).pop();
                        // Beri jeda agar state update tidak mengganggu penutupan dialog
                        Future.microtask(() => controller.removeQuestion(sectionId, question.id));
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );

      final List<Widget> questionTileChildren = [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _PersistentTextField(
                fieldKey: ValueKey('${question.id}_text'),
                initialValue: question.questionText,
                onChanged: (text) {
                  controller.updateQuestionText(sectionId, question.id, text);
                },
                decoration: _modernInputDecoration(
                  labelText: 'Teks Pertanyaan',
                  isDense: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                maxLines: null,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              _PersistentTextField(
                fieldKey: ValueKey('${question.id}_description'),
                initialValue: question.description ?? '',
                onChanged: (text) {
                  controller.updateQuestionDescription(sectionId, question.id, text);
                },
                decoration: _modernInputDecoration(
                  labelText: 'Deskripsi Tambahan (Opsional)',
                  hintText: 'Jelaskan lebih lanjut...',
                  isDense: true,
                ),
                maxLines: null,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              if (question.type == QuestionType.multipleChoice ||
                  question.type == QuestionType.checkboxes ||
                  question.type == QuestionType.dropdown)
                _buildOptionsSection(sectionId, question),
              if (question.type == QuestionType.gridNumeric)
                _buildGridNumericSettings(sectionId, question),
              if (question.type == QuestionType.imageUpload)
                _buildImageUploadQuestionInfo(),
              if (question.type == QuestionType.location)
                _buildLocationQuestionInfo(),
              if (question.type != QuestionType.imageUpload &&
                  question.type != QuestionType.location) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildPredefinedRuleDropdown(sectionId, question),
                ),
                const SizedBox(height: 4),
              ],
              if (question.type == QuestionType.number ||
                  question.type == QuestionType.gridNumeric)
                _buildNumberValidationSection(sectionId, question),
              if (question.type == QuestionType.text ||
                  question.type == QuestionType.paragraph)
                _buildTextValidationSection(sectionId, question),
              if (question.type == QuestionType.date)
                _buildDateValidationSection(sectionId, question),
              if (question.type == QuestionType.date)
                _buildAgeCalculationSetting(sectionId, question),
              _buildComputedSummarySetting(sectionId, question),
              _buildConditionalAgeGroupSetting(sectionId, question),
              const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Wajib diisi',
                            style: TextStyle(fontSize: 14),
                          ),
                          Switch(
                            value: question.isRequired,
                            onChanged: (value) {
                              controller.updateQuestionRequired(
                                sectionId,
                                question.id,
                                value,
                              );
                            },
                            activeThumbColor: accentThemeColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Hanya Baca (Read Only)',
                            style: TextStyle(fontSize: 14),
                          ),
                          Switch(
                            value: question.isReadOnly,
                            onChanged: (value) {
                              controller.updateQuestionIsReadOnly(
                                sectionId,
                                question.id,
                                value,
                              );
                            },
                            activeThumbColor: Colors.purple,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gunakan Sebagai Deskripsi',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: question.useAsDescription,
                        onChanged: (value) {
                          controller.updateQuestionUseAsDescription(
                            sectionId,
                            question.id,
                            value,
                          );
                        },
                        activeThumbColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gunakan Sebagai Judul',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: question.useAsTitle,
                        onChanged: (value) {
                          controller.updateQuestionUseAsTitle(
                            sectionId,
                            question.id,
                            value,
                          );
                        },
                        activeThumbColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  if (question.type == QuestionType.multipleChoice ||
                      question.type == QuestionType.checkboxes)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Opsi "Lainnya"',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: question.hasOtherOption,
                          onChanged: (value) {
                            controller.updateQuestionHasOtherOption(
                              sectionId,
                              question.id,
                              value,
                            );
                          },
                          activeThumbColor: accentThemeColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                ],
              ),
              if (question.type != QuestionType.imageUpload &&
                  question.type != QuestionType.location)
                _buildRepeatableSetting(sectionId, question),
              if (question.type != QuestionType.imageUpload &&
                  question.type != QuestionType.location)
                _buildRepeatableGroupSettings(sectionId, question),
              _buildConditionalJumpSetting(sectionId, question),
              _buildUnconditionalJumpSetting(sectionId, question),
              if (question.type == QuestionType.dropdown)
                _buildDependentOptionsConfigurator(sectionId, question),
            ],
          ),
        ),
      ];

      return Container(
        key: ValueKey('q_card_${question.id}'),
        margin: const EdgeInsets.only(
          bottom: 16.0,
          top: 8.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100.withValues(alpha: 0.8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ExpansionTile(
          key: ValueKey(question.id),
          title: questionTileTitle,
          initiallyExpanded: question.questionText.trim().isEmpty,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          childrenPadding: EdgeInsets.zero,
          iconColor: accentThemeColor,
          collapsedIconColor: Colors.grey.shade700,
          shape: const Border(
            top: BorderSide.none,
            bottom: BorderSide.none,
          ),
          collapsedShape: const Border(
            top: BorderSide.none,
            bottom: BorderSide.none,
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          children: questionTileChildren,
        ),
      );
    });
  }

  /// Menampilkan informasi panduan untuk pertanyaan tipe Upload Gambar.
  Widget _buildImageUploadQuestionInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.image_rounded,
            color: accentThemeColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tipe ini akan menampilkan tombol Kamera dan Galeri di halaman user. '
                  'Jawaban user akan disimpan sebagai URL gambar di Firebase Storage.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan informasi panduan untuk pertanyaan tipe Lokasi GPS.
  Widget _buildLocationQuestionInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.my_location_rounded,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tipe ini akan menampilkan tombol Gunakan Lokasi Saat Ini di halaman user. '
                  'Jawaban user akan disimpan sebagai latitude, longitude, akurasi, dan source GPS.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun pengaturan label baris/kolom untuk pertanyaan tipe Grid Numerik.
  Widget _buildGridNumericSettings(String sectionId, FormQuestion question) {
    final bool isGridConfigured = question.gridRowLabels.isNotEmpty ||
        question.gridColumnLabels.isNotEmpty ||
        question.gridSubColumnLabels.isNotEmpty;

    return _buildExpansionTileForSettings(
      'Pengaturan Label Grid Numerik',
      [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 10.0,
            top: 4.0,
          ),
          child: Text(
            'Masukkan label dipisahkan koma (,). Contoh: Senin,Selasa.\n'
                '- Label Baris: Opsional.\n'
                '- Label Kolom: Wajib.\n'
                '- Label Sub-Kolom: Wajib.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridRowLabels_persistent'),
          initialValue: question.gridRowLabels.join(', '),
          onChanged: (text) {
            controller.updateGridRowLabelsFromString(
              sectionId,
              question.id,
              text,
            );
          },
          decoration: _modernInputDecoration(
            labelText: 'Label Baris',
            hintText: 'Contoh: Baris A, Baris B',
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridColLabels_persistent'),
          initialValue: question.gridColumnLabels.join(', '),
          onChanged: (text) {
            controller.updateGridColumnLabelsFromString(
              sectionId,
              question.id,
              text,
            );
          },
          decoration: _modernInputDecoration(
            labelText: 'Label Kolom',
            hintText: 'Contoh: Kolom 1, Kolom 2',
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridSubColLabels_persistent'),
          initialValue: question.gridSubColumnLabels.join(', '),
          onChanged: (text) {
            controller.updateGridSubColumnLabelsFromString(
              sectionId,
              question.id,
              text,
            );
          },
          decoration: _modernInputDecoration(
            labelText: 'Label Sub-Kolom',
            hintText: 'Contoh: Sub A, Sub B',
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
      initiallyExpanded: isGridConfigured,
    );
  }

  /// Membangun daftar opsi jawaban untuk tipe pilihan (Dropdown, Checkbox, Multiple Choice).
  Widget _buildOptionsSection(String sectionId, FormQuestion question) {
    InputDecoration optionInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade500,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: accentThemeColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 0,
        ),
        isDense: true,
      );
    }

    InputDecoration optionDescriptionInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        isDense: true,
      );
    }

    final List<Widget> children = [
      Padding(
        padding: const EdgeInsets.only(
          bottom: 6.0,
          top: 4.0,
        ),
        child: Text(
          'Opsi Pilihan:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    ];

    children.addAll(
      question.options.asMap().entries.map((entry) {
        final int index = entry.key;
        final QuestionOption option = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(
                      question.type == QuestionType.multipleChoice
                          ? Icons.radio_button_off_rounded
                          : question.type == QuestionType.checkboxes
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.arrow_right_rounded,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: _PersistentTextField(
                      fieldKey: ValueKey('${question.id}_option_value_$index'),
                      initialValue: option.value,
                      onChanged: (text) {
                        controller.updateOptionValue(
                          sectionId,
                          question.id,
                          index,
                          text,
                        );
                      },
                      decoration: optionInputDecoration(
                        'Nilai Opsi ${index + 1}',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red.shade300,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.removeOption(
                        sectionId,
                        question.id,
                        index,
                      );
                    },
                    splashRadius: 16,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 44,
                ),
                child: _PersistentTextField(
                  fieldKey: ValueKey('${question.id}_option_desc_$index'),
                  initialValue: option.description ?? '',
                  onChanged: (text) {
                    controller.updateOptionDescription(
                      sectionId,
                      question.id,
                      index,
                      text,
                    );
                  },
                  decoration: optionDescriptionInputDecoration(
                    'Deskripsi untuk opsi ini (opsional)',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (index < question.options.length - 1)
                Divider(
                  height: 16,
                  thickness: 0.5,
                  color: Colors.grey.shade200,
                  indent: 24,
                  endIndent: 44,
                ),
            ],
          ),
        );
      }),
    );

    if (question.hasOtherOption &&
        (question.type == QuestionType.multipleChoice ||
            question.type == QuestionType.checkboxes)) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            bottom: 4.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  question.type == QuestionType.multipleChoice
                      ? Icons.radio_button_checked_rounded
                      : Icons.check_box_rounded,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
              ),
              Expanded(
                child: AbsorbPointer(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Lainnya...',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      hintText: 'Kolom input teks akan muncul untuk responden',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 0,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      );
    }

    children.add(
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            controller.addOption(sectionId, question.id);
          },
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: accentThemeColor,
            size: 20,
          ),
          label: const Text(
            'Tambah Opsi',
            style: TextStyle(
              color: accentThemeColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 4,
            ),
          ),
        ),
      ),
    );

    children.add(
      const Divider(
        height: 16,
        thickness: 0.5,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Helper untuk membangun [ExpansionTile] yang digunakan pada berbagai bagian pengaturan.
  Widget _buildExpansionTileForSettings(
      String title,
      List<Widget> children, {
        bool initiallyExpanded = false,
      }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      initiallyExpanded: initiallyExpanded,
      iconColor: accentThemeColor,
      collapsedIconColor: Colors.grey.shade600,
      shape: const Border(
        top: BorderSide.none,
        bottom: BorderSide.none,
      ),
      collapsedShape: const Border(
        top: BorderSide.none,
        bottom: BorderSide.none,
      ),
      children: children,
    );
  }

  /// Membangun pengaturan validasi teks (min/max length, regex).
  Widget _buildTextValidationSection(String sectionId, FormQuestion question) {
    final bool isValidationNotEmpty = question.validation.minLength != null ||
        question.validation.maxLength != null ||
        (question.validation.regex != null &&
            question.validation.regex!.isNotEmpty);

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Teks/Paragraf',
      [
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_minLength_persistent'),
          initialValue: question.validation.minLength?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(
            labelText: 'Panjang Min.',
            hintText: 'Opsional',
            isDense: true,
          ),
          onChanged: (value) {
            controller.updateValidation(
              sectionId,
              question.id,
              question.validation.copyWith(
                minLength: int.tryParse(value),
                setMinLengthNull: value.isEmpty,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_maxLength_persistent'),
          initialValue: question.validation.maxLength?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(
            labelText: 'Panjang Max.',
            hintText: 'Opsional',
            isDense: true,
          ),
          onChanged: (value) {
            controller.updateValidation(
              sectionId,
              question.id,
              question.validation.copyWith(
                maxLength: int.tryParse(value),
                setMaxLengthNull: value.isEmpty,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_regex_persistent'),
          initialValue: question.validation.regex ?? '',
          decoration: _modernInputDecoration(
            labelText: 'Pola Regex Kustom',
            hintText: 'Opsional, e.g. ^[A-Z]+\$',
            isDense: true,
          ),
          onChanged: (value) {
            controller.updateValidation(
              sectionId,
              question.id,
              question.validation.copyWith(
                regex: value.isEmpty ? null : value,
                setRegexNull: value.isEmpty,
              ),
            );
          },
        ),
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

  /// Membangun pengaturan validasi angka (min/max value) dan perbandingan antar pertanyaan.
  Widget _buildNumberValidationSection(String sectionId, FormQuestion question) {
    final ValidationRule validationRule = question.validation;

    final bool isBasicNumValidationNotEmpty =
        validationRule.minValue != null || validationRule.maxValue != null;

    final bool isComparisonRuleNotEmpty =
        validationRule.comparisonOperator != null &&
            validationRule.comparisonOperator !=
                ComparisonOperatorType.none.toShortString() &&
            validationRule.compareToQuestionId != null &&
            validationRule.compareToQuestionId!.isNotEmpty;

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Angka & Perbandingan',
      [
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_minValue'),
          initialValue: validationRule.minValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(
            labelText: 'Nilai Min.',
            hintText: 'Opsional',
            isDense: true,
          ),
          onChanged: (value) {
            controller.updateValidation(
              sectionId,
              question.id,
              validationRule.copyWith(
                minValue: num.tryParse(value),
                setMinValueNull: value.isEmpty,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_maxValue'),
          initialValue: validationRule.maxValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(
            labelText: 'Nilai Max.',
            hintText: 'Opsional',
            isDense: true,
          ),
          onChanged: (value) {
            controller.updateValidation(
              sectionId,
              question.id,
              validationRule.copyWith(
                maxValue: num.tryParse(value),
                setMaxValueNull: value.isEmpty,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Validasi Perbandingan dengan Pertanyaan Lain:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey.shade700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          initialValue: validationRule.comparisonOperator ??
              ComparisonOperatorType.none.toShortString(),
          decoration: _modernInputDecoration(
            labelText: 'Operator Perbandingan',
            isDense: true,
          ),
          items: ComparisonOperatorType.values.map((operatorType) {
            String displayText;

            switch (operatorType) {
              case ComparisonOperatorType.none:
                displayText = 'Tidak ada perbandingan';
                break;
              case ComparisonOperatorType.lessThan:
                displayText = 'Kurang Dari (<)';
                break;
              case ComparisonOperatorType.lessThanOrEqual:
                displayText = 'Kurang Dari atau Sama Dengan (<=)';
                break;
              case ComparisonOperatorType.equal:
                displayText = 'Sama Dengan (==)';
                break;
              case ComparisonOperatorType.notEqual:
                displayText = 'Tidak Sama Dengan (!=)';
                break;
              case ComparisonOperatorType.greaterThan:
                displayText = 'Lebih Dari (>)';
                break;
              case ComparisonOperatorType.greaterThanOrEqual:
                displayText = 'Lebih Dari atau Sama Dengan (>=)';
                break;
            }

            return DropdownMenuItem<String?>(
              value: operatorType.toShortString(),
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: operatorType == ComparisonOperatorType.none
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? selectedOperatorString) {
            final String? selectedOperator =
            selectedOperatorString == ComparisonOperatorType.none.toShortString()
                ? null
                : selectedOperatorString;

            controller.updateValidation(
              sectionId,
              question.id,
              validationRule.copyWith(
                comparisonOperator: selectedOperator,
                setComparisonOperatorNull: selectedOperator == null,
                compareToQuestionId:
                selectedOperator == null ? null : validationRule.compareToQuestionId,
                setCompareToQuestionIdNull: selectedOperator == null,
              ),
            );
          },
          isExpanded: true,
        ),
        if (validationRule.comparisonOperator != null &&
            validationRule.comparisonOperator !=
                ComparisonOperatorType.none.toShortString()) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: validationRule.compareToQuestionId,
            decoration: _modernInputDecoration(
              labelText: 'Bandingkan dengan Pertanyaan:',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Pilih pertanyaan...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
              ...controller
                  .getAllQuestionsForLinking(
                currentQuestionIdToExclude: question.id,
                numericOnly: true,
              )
                  .map(
                    (qMap) {
                  return DropdownMenuItem<String?>(
                    value: qMap['id'],
                    child: Text(
                      qMap['text'] ?? '',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ],
            onChanged: (String? selectedTargetId) {
              controller.updateValidation(
                sectionId,
                question.id,
                validationRule.copyWith(
                  compareToQuestionId: selectedTargetId,
                  setCompareToQuestionIdNull: selectedTargetId == null,
                ),
              );
            },
            isExpanded: true,
          ),
        ],
      ],
      initiallyExpanded: isBasicNumValidationNotEmpty || isComparisonRuleNotEmpty,
    );
  }

  /// Membangun pengaturan validasi tanggal (past/future date).
  Widget _buildDateValidationSection(String sectionId, FormQuestion question) {
    final bool isValidationNotEmpty =
        question.validation.predefinedRule == 'pastDateOnly' ||
            question.validation.predefinedRule == 'futureDateOnly';

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Tanggal',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Gunakan Pola Validasi Umum untuk validasi tanggal.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

  /// Membangun fitur perhitungan umur otomatis berdasarkan input tanggal lahir.
  Widget _buildAgeCalculationSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Fitur Hitung Umur & Klasifikasi Otomatis',
      [
        SwitchListTile(
          title: const Text(
            'Hitung umur otomatis dari tanggal ini?',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Jika aktif, tanggal ini dianggap sebagai Tanggal Lahir.',
            style: TextStyle(fontSize: 12),
          ),
          value: question.autoCalculateAge,
          onChanged: (bool newValue) {
            controller.updateQuestionAutoCalculateAge(
              sectionId,
              question.id,
              newValue,
            );
          },
          activeThumbColor: accentThemeColor,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (question.autoCalculateAge) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            key: ValueKey('${question.id}_ageTargetQuestionId_${question.ageTargetQuestionId}'),
            initialValue: question.ageTargetQuestionId,
            decoration: _modernInputDecoration(
              labelText: 'Masukkan hasil umur ke pertanyaan:',
              hintText: 'Pilih pertanyaan tipe angka/teks',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Pilih pertanyaan tujuan...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
              ...controller
                  .getAllQuestionsForLinking(
                currentQuestionIdToExclude: question.id,
                textOrNumericOnly: true,
              )
                  .map(
                    (qMap) {
                  return DropdownMenuItem<String?>(
                    value: qMap['id'],
                    child: Text(
                      '${qMap['code']} - ${qMap['text']}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ],
            onChanged: (String? selectedTargetId) {
              controller.updateQuestionAgeTargetQuestionId(
                sectionId,
                question.id,
                selectedTargetId,
              );
            },
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text(
              'Gunakan untuk rekap kelompok penduduk?',
              style: TextStyle(fontSize: 14),
            ),
            value: question.autoClassifyAgeGroup,
            onChanged: (bool newValue) {
              controller.updateQuestionAutoClassifyAgeGroup(
                sectionId,
                question.id,
                newValue,
              );
            },
            activeThumbColor: accentThemeColor,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (question.autoClassifyAgeGroup) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: question.genderSourceQuestionId,
              decoration: _modernInputDecoration(
                labelText: 'Pilih pertanyaan Jenis Kelamin:',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Pilih pertanyaan...'),
                ),
                ...controller.getAllQuestionsForLinking(
                  currentQuestionIdToExclude: question.id,
                ).map((qMap) => DropdownMenuItem<String?>(
                  value: qMap['id'],
                  child: Text('${qMap['code']} - ${qMap['text']}', overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (val) => controller.updateQuestionGenderSourceQuestionId(sectionId, question.id, val),
            ),
            const SizedBox(height: 8),
            _PersistentTextField(
              fieldKey: ValueKey('${question.id}_summaryGroupKey'),
              initialValue: question.summaryGroupKey ?? '',
              decoration: _modernInputDecoration(
                labelText: 'Summary Group Key (misal: anggota_keluarga)',
                isDense: true,
              ),
              onChanged: (val) => controller.updateQuestionSummaryGroupKey(sectionId, question.id, val),
            ),
          ],
        ],
      ],
      initiallyExpanded: question.autoCalculateAge,
    );
  }

  /// Membangun fitur rekap otomatis (Aggregation) untuk pertanyaan tertentu.
  Widget _buildComputedSummarySetting(String sectionId, FormQuestion question) {
    if (question.type != QuestionType.number && question.type != QuestionType.text) {
      return const SizedBox.shrink();
    }

    return _buildExpansionTileForSettings(
      'Fitur Rekap Otomatis',
      [
        SwitchListTile(
          title: const Text('Jadikan field rekap otomatis?', style: TextStyle(fontSize: 14)),
          value: question.isComputedSummary,
          onChanged: (val) => controller.updateQuestionIsComputedSummary(sectionId, question.id, val),
          activeThumbColor: accentThemeColor,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (question.isComputedSummary) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: question.summaryType,
            decoration: _modernInputDecoration(labelText: 'Pilih Kategori Rekap:', isDense: true),
            items: [
              if (controller.ageGroups.isEmpty)
                const DropdownMenuItem(value: null, child: Text('Buat kategori di kartu atas dulu', style: TextStyle(fontSize: 12, color: Colors.red))),
              ...controller.ageGroups.map((group) => DropdownMenuItem(
                value: group.key,
                child: Text(group.label, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (val) => controller.updateQuestionSummaryType(sectionId, question.id, val),
          ),
          const SizedBox(height: 8),
          _PersistentTextField(
            fieldKey: ValueKey('${question.id}_summaryGroupKey_rekap'),
            initialValue: question.summaryGroupKey ?? '',
            decoration: _modernInputDecoration(labelText: 'Summary Group Key', isDense: true),
            onChanged: (val) => controller.updateQuestionSummaryGroupKey(sectionId, question.id, val),
          ),
        ],
      ],
      initiallyExpanded: question.isComputedSummary,
    );
  }

  /// Membangun pengaturan visibilitas pertanyaan berdasarkan klasifikasi kelompok umur.
  Widget _buildConditionalAgeGroupSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Tampilkan Berdasarkan Kelompok Umur',
      [
        SwitchListTile(
          title: const Text('Aktifkan filter kelompok umur?', style: TextStyle(fontSize: 14)),
          value: question.isConditionalByAgeGroup,
          onChanged: (val) => controller.updateQuestionIsConditionalByAgeGroup(sectionId, question.id, val),
          activeThumbColor: accentThemeColor,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (question.isConditionalByAgeGroup) ...[
          const SizedBox(height: 8),
          const Text('Tampilkan jika ada anggota kelompok:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              if (controller.ageGroups.isEmpty)
                const Text('Daftarkan kategori usia di atas terlebih dahulu.', style: TextStyle(fontSize: 11, color: Colors.orange)),
              ...controller.ageGroups.map((group) {
                final isSelected = question.visibleWhenAgeGroups.contains(group.key);
                return FilterChip(
                  label: Text(group.label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: accentThemeColor,
                  onSelected: (selected) {
                    final current = List<String>.from(question.visibleWhenAgeGroups);
                    if (selected) {
                      current.add(group.key);
                    } else {
                      current.remove(group.key);
                    }
                    controller.updateQuestionVisibleWhenAgeGroups(sectionId, question.id, current);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          _PersistentTextField(
            fieldKey: ValueKey('${question.id}_condGroupKey'),
            initialValue: question.summaryGroupKey ?? '',
            decoration: _modernInputDecoration(labelText: 'Summary Group Key Sumber', isDense: true),
            onChanged: (val) => controller.updateQuestionSummaryGroupKey(sectionId, question.id, val),
          ),
        ],
      ],
      initiallyExpanded: question.isConditionalByAgeGroup,
    );
  }

  /// Membangun dropdown untuk memilih pola validasi yang sudah didefinisikan (NIK, Email, dll).
  Widget _buildPredefinedRuleDropdown(String sectionId, FormQuestion question) {
    final Map<String, String> predefinedRulesDisplay = {
      'none': 'Tidak Ada Pola Khusus',
      'lettersOnly': 'Hanya Huruf',
      'numbersOnly': 'Hanya Angka',
      'alphanumeric': 'Huruf & Angka',
      'email': 'Format Email',
      'url': 'Format URL',
      'phone': 'Nomor Telepon (ID)',
      'nik': 'NIK (16 Digit Angka)',
      'noKK': 'No. KK (16 Digit Angka)',
    };

    if (question.type == QuestionType.number) {
      predefinedRulesDisplay['numberSteppersOnly'] = 'Input Via Tombol (+/-) Saja';
    }

    if (question.type == QuestionType.gridNumeric) {
      predefinedRulesDisplay['gridAllCellsRequired'] =
      'Wajib Isi Semua Sel Grid (Angka)';
    }

    if (question.type == QuestionType.date) {
      predefinedRulesDisplay['pastDateOnly'] = 'Hanya Tanggal Lalu';
      predefinedRulesDisplay['futureDateOnly'] = 'Hanya Tanggal Akan Datang';
    }

    String? currentRule = question.validation.predefinedRule;

    if (currentRule != null && !predefinedRulesDisplay.containsKey(currentRule)) {
      currentRule = 'none';
    }

    if (currentRule == null || currentRule.isEmpty) {
      currentRule = 'none';
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 0.0,
        bottom: 8.0,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: currentRule,
        decoration: _modernInputDecoration(
          labelText: 'Pola Validasi Umum',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: predefinedRulesDisplay.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (value) {
          controller.updateValidation(
            sectionId,
            question.id,
            question.validation.copyWith(
              predefinedRule: value == 'none' || value == null || value.isEmpty
                  ? null
                  : value,
              setPredefinedRuleNull:
              value == 'none' || value == null || value.isEmpty,
            ),
          );
        },
        isExpanded: true,
      ),
    );
  }

  /// Membangun pengaturan pengulangan (Repeatable) pada level pertanyaan individu.
  Widget _buildRepeatableSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Ulang Pertanyaan',
      [
        CheckboxListTile(
          title: const Text(
            'Dapat diulang?',
            style: TextStyle(fontSize: 14),
          ),
          value: question.repeatable,
          onChanged: (bool? value) {
            controller.updateQuestionRepeatable(
              sectionId,
              question.id,
              value ?? false,
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: accentThemeColor,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (question.repeatable)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: _PersistentTextField(
              fieldKey: ValueKey('${question.id}_repeatCount_persistent'),
              initialValue: question.repeatCount?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: _modernInputDecoration(
                labelText: 'Jumlah Maks. Pengulangan',
                hintText: 'Kosongkan untuk tanpa batas',
                isDense: true,
              ),
              onChanged: (value) {
                controller.updateQuestionRepeatable(
                  sectionId,
                  question.id,
                  true,
                  count: int.tryParse(value),
                );
              },
            ),
          ),
      ],
      initiallyExpanded: question.repeatable,
    );
  }

  /// Membangun pengaturan grup berulang (Repeatable Group) berdasarkan input angka pengontrol.
  Widget _buildRepeatableGroupSettings(String sectionId, FormQuestion question) {
    final String uniqueTagSuggestion = 'grup_${question.id.substring(0, 5)}';
    final List<String> availableTags = controller.getAvailableControlledGroupTags(
      sectionId,
      question.id,
    );

    return _buildExpansionTileForSettings(
      'Pengaturan Grup Pertanyaan Berulang',
      [
        if (question.type == QuestionType.number)
          CheckboxListTile(
            title: Text(
              'Jadikan Pengontrol Grup?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: question.isRepeatableGroupController
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: const Text(
              'Jawaban angka akan menentukan berapa kali grup pertanyaan lain diulang.',
              style: TextStyle(fontSize: 12),
            ),
            value: question.isRepeatableGroupController,
            onChanged: (bool? value) {
              if (value == true) {
                controller.updateQuestionAsRepeatableGroupController(
                  sectionId,
                  question.id,
                  true,
                  question.controlledGroupTag ?? uniqueTagSuggestion,
                );
              } else {
                controller.updateQuestionAsRepeatableGroupController(
                  sectionId,
                  question.id,
                  false,
                  null,
                );
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        if (question.isRepeatableGroupController &&
            question.type == QuestionType.number)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              top: 4.0,
              bottom: 8.0,
            ),
            child: _PersistentTextField(
              fieldKey: ValueKey('${question.id}_controlledGroupTag_persistent'),
              initialValue: question.controlledGroupTag ?? uniqueTagSuggestion,
              decoration: _modernInputDecoration(
                labelText: 'ID Unik Grup yang Dikontrol',
                hintText: 'Contoh: $uniqueTagSuggestion',
                isDense: true,
              ),
              onChanged: (tag) {
                controller.updateQuestionAsRepeatableGroupController(
                  sectionId,
                  question.id,
                  true,
                  tag.isNotEmpty ? tag : null,
                );
              },
              style: const TextStyle(fontSize: 13),
            ),
          ),
        if (!question.isRepeatableGroupController) ...[
          CheckboxListTile(
            title: Text(
              'Jadikan Anggota Grup Berulang?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: question.belongsToGroupTag != null &&
                    question.belongsToGroupTag!.isNotEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: const Text(
              'Pertanyaan ini diulang berdasarkan jawaban pertanyaan pengontrol.',
              style: TextStyle(fontSize: 12),
            ),
            value: question.belongsToGroupTag != null &&
                question.belongsToGroupTag!.isNotEmpty,
            onChanged: (bool? value) {
              if (value == true) {
                if (availableTags.isNotEmpty) {
                  controller.updateQuestionBelongsToGroupTag(
                    sectionId,
                    question.id,
                    question.belongsToGroupTag ?? availableTags.first,
                  );
                }
              } else {
                controller.updateQuestionBelongsToGroupTag(
                  sectionId,
                  question.id,
                  null,
                );
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (availableTags.isNotEmpty ||
              (question.belongsToGroupTag != null &&
                  question.belongsToGroupTag!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 4.0,
                bottom: 8.0,
              ),
              child: DropdownButtonFormField<String?>(
                initialValue: question.belongsToGroupTag,
                decoration: _modernInputDecoration(
                  labelText: 'Pilih ID Grup Induk',
                  isDense: true,
                ),
                hint: const Text('Pilih grup...'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Tidak termasuk grup / Lepaskan',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...availableTags.map(
                        (tag) => DropdownMenuItem<String?>(
                      value: tag,
                      child: Text(tag),
                    ),
                  ),
                ],
                onChanged: (String? selectedTag) {
                  controller.updateQuestionBelongsToGroupTag(
                    sectionId,
                    question.id,
                    selectedTag,
                  );
                },
                isExpanded: true,
              ),
            ),
          if (availableTags.isEmpty &&
              !question.isRepeatableGroupController &&
              (question.belongsToGroupTag == null ||
                  question.belongsToGroupTag!.isEmpty))
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Tidak ada grup tersedia. Buat pertanyaan pengontrol tipe Angka terlebih dahulu.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ],
      initiallyExpanded: question.isRepeatableGroupController ||
          (question.belongsToGroupTag != null &&
              question.belongsToGroupTag!.isNotEmpty),
    );
  }

  /// Membangun pengaturan logika lompatan (Jump Logic) berdasarkan jawaban yang dipilih.
  Widget _buildConditionalJumpSetting(String sectionId, FormQuestion question) {
    final bool canHaveJumps = question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.checkboxes ||
        question.type == QuestionType.dropdown ||
        question.options.isNotEmpty;

    if (!canHaveJumps) {
      return const SizedBox.shrink();
    }

    return _buildExpansionTileForSettings(
      'Logika Bersyarat (Lompat per Jawaban)',
      [
        if (question.conditionalJumps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Belum ada aturan lompat bersyarat.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ...question.conditionalJumps.map((jump) {
          String targetDisplay = jump.jumpToQuestionId;
          if (jump.jumpToQuestionId == 'END_OF_FORM') {
            targetDisplay = 'Akhir Form';
          } else if (jump.jumpToQuestionId == 'END_OF_SECTION') {
            if (jump.jumpToSectionId != null && jump.jumpToSectionId!.isNotEmpty) {
              final targetSec = controller.sections.firstWhereOrNull((s) => s.id == jump.jumpToSectionId);
              targetDisplay = 'Mulai Bagian: ${targetSec?.title ?? jump.jumpToSectionId}';
            } else {
              targetDisplay = 'Akhir Bagian Ini';
            }
          } else {
            final targetQ = controller.findQuestionById(jump.jumpToQuestionId);
            if (targetQ != null) {
              targetDisplay = targetQ.questionText.length > 20 ? "${targetQ.questionText.substring(0, 17)}..." : targetQ.questionText;
            }
          }

          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Jika jawaban: "${jump.conditionValue}"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Maka: $targetDisplay',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.red.shade300,
                size: 20,
              ),
              onPressed: () {
                controller.removeConditionalJump(
                  sectionId,
                  question.id,
                  jump.jumpToQuestionId,
                );
              },
            ),
          );
        }),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              _showAddConditionalJumpDialog(sectionId, question);
            },
            icon: const Icon(Icons.alt_route_rounded),
            label: const Text('Tambah Aturan Lompat'),
          ),
        ),
      ],
      initiallyExpanded: question.conditionalJumps.isNotEmpty,
    );
  }

  /// Menampilkan dialog untuk menambahkan aturan lompatan bersyarat baru.
  void _showAddConditionalJumpDialog(String sectionId, FormQuestion question) {
    final TextEditingController conditionController = TextEditingController();
    String? selectedTarget;

    showDialog(
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<DropdownMenuItem<String?>> allJumpTargets = [
            const DropdownMenuItem<String?>(
              value: 'END_OF_FORM',
              child: Text('Akhir Form', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const DropdownMenuItem<String?>(
              value: 'END_OF_SECTION',
              child: Text('Akhir Bagian Ini', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          ];

          for (int i = 0; i < controller.sections.length; i++) {
            final sec = controller.sections[i];
            final String roman = _toRoman(i + 1);
            final String title = sec.title.isNotEmpty ? sec.title : 'Bagian $roman';
            
            allJumpTargets.add(
              DropdownMenuItem<String?>(
                value: 'section_start_${sec.id}',
                child: Text('Mulai $title', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
              ),
            );
          }

          allJumpTargets.addAll(
            controller.getAllQuestionsForLinking(currentQuestionIdToExclude: question.id).map((qMap) {
              return DropdownMenuItem<String?>(
                value: qMap['id'],
                child: Text(qMap['text'] ?? '', overflow: TextOverflow.ellipsis),
              );
            }),
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tambah Logika Bersyarat'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Jika Jawaban Adalah:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _modernInputDecoration(labelText: 'Pilih Opsi', isDense: true),
                    items: question.options.map((opt) => DropdownMenuItem(value: opt.value, child: Text(opt.value))).toList(),
                    onChanged: (value) {
                      setState(() {
                        conditionController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Maka Lompat Ke:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTarget,
                    isExpanded: true,
                    decoration: _modernInputDecoration(labelText: 'Pilih Tujuan', isDense: true),
                    items: allJumpTargets,
                    onChanged: (value) {
                      setState(() {
                        selectedTarget = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accentHeaderColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final String val = conditionController.text.trim();
                  if (val.isEmpty || selectedTarget == null) {
                    Get.snackbar('Input Belum Lengkap', 'Silakan pilih jawaban dan tujuan lompatan.',
                        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }

                  String jumpToQId = '';
                  String? jumpToSecId;

                  if (selectedTarget == 'END_OF_FORM') {
                    jumpToQId = 'END_OF_FORM';
                  } else if (selectedTarget == 'END_OF_SECTION') {
                    jumpToQId = 'END_OF_SECTION';
                  } else if (selectedTarget!.startsWith('section_start_')) {
                    jumpToSecId = selectedTarget!.replaceFirst('section_start_', '');
                    jumpToQId = 'END_OF_SECTION';
                  } else {
                    // Jika target adalah pertanyaan, simpan ID-nya saja
                    // Controller di sisi user akan membungkusnya dengan 'question_' jika perlu
                    jumpToQId = selectedTarget!;
                  }

                  // Tutup dialog terlebih dahulu
                  Navigator.pop(context);

                  // Update state setelah dialog tertutup
                  Future.microtask(() => controller.addConditionalJump(
                    sectionId,
                    question.id, 
                    ConditionalJump(
                      conditionValue: val, 
                      jumpToQuestionId: jumpToQId, 
                      jumpToSectionId: jumpToSecId
                    ),
                  ));
                },
                child: const Text('Tambah Aturan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    ).then((_) => conditionController.dispose());
  }

  /// Membangun pengaturan lompatan otomatis (Unconditional Jump) setelah pertanyaan dijawab.
  Widget _buildUnconditionalJumpSetting(String sectionId, FormQuestion question) {
    final List<DropdownMenuItem<String?>> allJumpTargets = [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text(
          'Tidak Ada Lompatan Otomatis',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    ];

    for (int i = 0; i < controller.sections.length; i++) {
      final FormSection section = controller.sections[i];
      final String sectionRoman = _toRoman(i + 1);
      final String sectionTitle = section.title.isNotEmpty
          ? section.title.length > 20
          ? '${section.title.substring(0, 17)}...'
          : section.title
          : 'Tanpa Judul';

      allJumpTargets.add(
        DropdownMenuItem<String?>(
          value: 'section_start_${section.id}',
          child: Text(
            'Lompat ke Awal Bagian $sectionRoman: $sectionTitle',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      );

      for (int j = 0; j < section.questions.length; j++) {
        final FormQuestion targetQuestion = section.questions[j];

        if (targetQuestion.id == question.id) {
          continue;
        }

        allJumpTargets.add(
          DropdownMenuItem<String?>(
            value: 'question_${targetQuestion.id}',
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                targetQuestion.questionText.length > 25 ? '${targetQuestion.questionText.substring(0, 22)}...' : targetQuestion.questionText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        );
      }
    }

    allJumpTargets.addAll(
      const [
        DropdownMenuItem<String?>(
          value: 'end_of_current_section',
          child: Text(
            'Akhir Bagian Ini',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ),
        DropdownMenuItem<String?>(
          value: 'end_of_form',
          child: Text(
            'Akhir Form',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

    String? currentTarget = question.unconditionalJumpTarget;

    final bool isCurrentTargetValid = currentTarget == null ||
        allJumpTargets.any((item) => item.value == currentTarget);

    if (!isCurrentTargetValid) {
      currentTarget = null;
    }

    return _buildExpansionTileForSettings(
      'Lompatan Otomatis (Setelah Pertanyaan Ini)',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Jika diatur, setelah pertanyaan ini dijawab, form akan otomatis melompat ke tujuan yang dipilih.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ),
        DropdownButtonFormField<String?>(
          key: ValueKey(
            '${question.id}_unconditional_jump_dd_${currentTarget ?? 'null'}',
          ),
          decoration: _modernInputDecoration(
            labelText: 'Lompat Otomatis Ke:',
            isDense: true,
          ).copyWith(
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          ),
          initialValue: currentTarget,
          items: allJumpTargets,
          onChanged: (String? selectedValue) {
            controller.updateUnconditionalJump(
              sectionId,
              question.id,
              selectedValue,
            );
          },
          isExpanded: true,
          hint: const Text('Pilih tujuan...'),
        ),
      ],
      initiallyExpanded: question.unconditionalJumpTarget != null &&
          question.unconditionalJumpTarget!.isNotEmpty,
    );
  }

  /// Membangun konfigurasi dependensi opsi (Opsi anak yang berubah berdasarkan pilihan induk).
  Widget _buildDependentOptionsConfigurator(
      String sectionId,
      FormQuestion question,
      ) {
    return Obx(() {
      final List<FormQuestion> potentialParents = controller
          .getPotentialParentQuestions(
        sectionId,
        question.id,
      )
          .where((item) => item.id != question.id)
          .toList();

      final String? storedParentId = question.dependentOptions?.parentQuestionId;
      final FormQuestion? selectedParentQuestion =
      controller.findQuestionById(storedParentId);

      final bool showMappingInterface = selectedParentQuestion != null &&
          selectedParentQuestion.options.isNotEmpty;

      return _buildExpansionTileForSettings(
        'Opsi Bergantung pada Jawaban Induk',
        [
          DropdownButtonFormField<String?>(
            initialValue: storedParentId != null &&
                potentialParents.any((parent) => parent.id == storedParentId)
                ? storedParentId
                : null,
            decoration: _modernInputDecoration(
              labelText: 'Pertanyaan Induk',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Tidak menggunakan dependensi',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...potentialParents.map((parent) {
                return DropdownMenuItem<String?>(
                  value: parent.id,
                  child: Text(
                    parent.questionText,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (String? selectedParentId) {
              controller.setParentQuestionForDependency(
                sectionId,
                question.id,
                selectedParentId,
              );
            },
            isExpanded: true,
          ),
          if (showMappingInterface) ...[
            const SizedBox(height: 12),
            Text(
              'Atur opsi anak berdasarkan jawaban induk:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedParentQuestion.options.length,
              itemBuilder: (context, index) {
                final QuestionOption parentOptionObj =
                selectedParentQuestion.options[index];
                final String parentOptionValue = parentOptionObj.value;
                final List<String> currentChildOptions = question
                    .dependentOptions?.optionMapping[parentOptionValue] ??
                    [];

                return _buildParentOptionMappingTile(
                  sectionId,
                  question.id,
                  parentOptionValue,
                  currentChildOptions,
                );
              },
            ),
          ],
        ],
        initiallyExpanded: question.dependentOptions != null &&
            question.dependentOptions!.parentQuestionId.isNotEmpty,
      );
    });
  }

  /// Membangun kartu pemetaan (mapping) untuk satu nilai opsi induk pada fitur dependensi.
  Widget _buildParentOptionMappingTile(
      String sectionId,
      String questionId,
      String parentOptionValue,
      List<String> currentChildOptions,
      ) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jika jawaban Induk adalah: "$parentOptionValue"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 8),
            _PersistentTextField(
              fieldKey: ValueKey('dep_opt_${questionId}_$parentOptionValue'),
              initialValue: currentChildOptions.join(', '),
              decoration: _modernInputDecoration(
                labelText: 'Opsi Anak',
                hintText: 'Pisahkan dengan koma, contoh: A, B, C',
                isDense: true,
              ),
              onChanged: (value) {
                final List<String> childOptions = value
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList();

                controller.updateMappingForParentOption(
                  sectionId,
                  questionId,
                  parentOptionValue,
                  childOptions,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.removeMappingForParentOption(
                      sectionId,
                      questionId,
                      parentOptionValue,
                    );
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun tombol untuk memicu bottom sheet pemilihan tipe pertanyaan baru.
  Widget _buildAddQuestionButton(String sectionId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showQuestionTypePicker(sectionId);
        },
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'Tambah Pertanyaan',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade700,
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  /// Menampilkan bottom sheet yang berisi daftar seluruh tipe pertanyaan yang didukung sistem.
  void _showQuestionTypePicker(String sectionId) {
    final List<QuestionType> questionTypes = [
      QuestionType.text,
      QuestionType.paragraph,
      QuestionType.number,
      QuestionType.date,
      QuestionType.multipleChoice,
      QuestionType.checkboxes,
      QuestionType.dropdown,
      QuestionType.gridNumeric,
      QuestionType.imageUpload,
      QuestionType.location,
    ];

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Tipe Pertanyaan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: questionTypes.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      );
                    },
                    itemBuilder: (context, index) {
                      final QuestionType type = questionTypes[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accentThemeColor.withValues(alpha: 0.12),
                          child: Icon(
                            _questionTypeIcon(type),
                            color: accentThemeColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          _questionTypeLabel(type),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _questionTypeSubtitle(type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () {
                          // Gunakan Navigator.pop untuk menutup overlay secara eksplisit
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                          
                          // Gunakan delay minimal agar animasi tutup tidak bertabrakan dengan rebuild berat
                          Future.delayed(const Duration(milliseconds: 100), () {
                             controller.addQuestionToSection(sectionId, type);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// [_PersistentTextField] adalah wrapper [TextField] khusus yang menjaga status input 
/// agar tidak hilang saat UI mengalami rebuild atau reorder.
class _PersistentTextField extends StatefulWidget {
  final Key fieldKey;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextStyle? style;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _PersistentTextField({
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
    required this.decoration,
    this.style,
    this.maxLines = 1,
    this.keyboardType,
  }) : super(key: fieldKey);

  @override
  State<_PersistentTextField> createState() {
    return _PersistentTextFieldState();
  }
}

class _PersistentTextFieldState extends State<_PersistentTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _PersistentTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      
      // Jika sedang fokus, jangan update text secara paksa untuk menghindari keyboard tertutup
      // atau kursor melompat, kecuali perubahannya signifikan.
      if (!_focusNode.hasFocus) {
        _controller.text = widget.initialValue;
      } else {
        // Jika sedang fokus tapi value di model berubah (misal rekap otomatis),
        // kita tetap update kursornya dengan hati-hati.
        final TextSelection oldSelection = _controller.selection;
        _controller.text = widget.initialValue;

        final int offset = oldSelection.baseOffset.clamp(
          0,
          _controller.text.length,
        );

        _controller.selection = TextSelection.collapsed(offset: offset);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: (value) {
        if (mounted) {
          widget.onChanged(value);
        }
      },
      decoration: widget.decoration,
      style: widget.style,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
    );
  }
}
