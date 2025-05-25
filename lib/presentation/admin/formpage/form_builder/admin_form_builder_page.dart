// lib/presentation/admin/formpage/admin_form_builder_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/form_builder/admin_form_builder_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk konsistensi warna

class AdminFormBuilderPage extends GetView<AdminFormBuilderController> {
  const AdminFormBuilderPage({Key? key}) : super(key: key);

  // Warna dari AdminScreen untuk konsistensi
  static const Color appBarForegroundColor = Colors.white;
  // Warna aksen untuk elemen aktif seperti border fokus, switch, tombol utama
  static const Color accentThemeColor = AdminScreen.accentHeaderColor; // Color(0xFFFF9800)
  // Warna netral untuk label TextField saat tidak fokus
  static const Color neutralLabelColor = Colors.grey; // Atau Colors.grey.shade600
  // Warna border TextField saat tidak fokus
  static const Color defaultTextFieldBorderColor = Colors.black26; // Lebih lembut dari Colors.grey
  // Warna latar belakang utama halaman
  static const Color pageBgColor = AdminScreen.pageBackgroundColor; // Color(0xFFF2FAFF)
  // Warna latar belakang untuk Card
  static const Color cardBgColor = Colors.white;


  // Helper untuk InputDecoration yang modern dan elegan
  InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
    bool isDense = false,
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: neutralLabelColor.withOpacity(0.9), fontSize: isDense ? 14 : 15), // Label saat tidak fokus
      floatingLabelStyle: const TextStyle(color: accentThemeColor, fontWeight: FontWeight.w500), // Label saat fokus/terisi
      hintText: hintText ?? 'Masukkan $labelText...',
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: accentThemeColor, width: 1.8), // Border fokus
      ),
      filled: true,
      fillColor: cardBgColor, // Latar belakang TextField
      contentPadding: contentPadding ?? (isDense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get.put(AdminFormBuilderController()); // DIHAPUS - Sudah dihandle oleh binding

    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        toolbarHeight: 80.0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Management Form',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Obx(() => Text(
              controller.formTitle.value.isEmpty
                  ? 'Buat Form Baru'
                  : controller.formTitle.value,
              style: TextStyle(fontSize: 14, color: appBarForegroundColor.withOpacity(0.85)),
              overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
        actions: [
          Obx(() => controller.isBusy.value
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: appBarForegroundColor, strokeWidth: 2.5)),
          )
              : IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Simpan Form',
            onPressed: controller.saveForm,
          )),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AdminScreen.primaryHeaderColor, AdminScreen.accentHeaderColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(35.0)),
          ),
        ),
      ),
      body: Obx(() {
        // Kondisi loading awal: jika sedang sibuk, BUKAN mode edit (artinya form baru), dan belum ada section
        final bool showInitialLoaderForNewForm = controller.isBusy.value &&
            !controller.isEditMode && // Menggunakan getter isEditMode dari controller
            controller.sections.isEmpty;

        // Kondisi loading jika SEDANG mode edit dan isBusy true (artinya sedang memuat data form)
        final bool showLoaderForEditing = controller.isBusy.value && controller.isEditMode;

        if (showInitialLoaderForNewForm || showLoaderForEditing) {
          return const Center(child: CircularProgressIndicator(color: accentThemeColor));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),
            Obx(() => Column( // Bungkus dengan Obx jika sections adalah RxList
              children: controller.sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;
                return _buildSectionCard(section, sectionIndex);
              }).toList(),
            )),
            const SizedBox(height: 24),
            _buildAddSectionButton(),
            const SizedBox(height: 70),
          ],
        );
      }),
    );
  }

  Widget _buildFormHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Detail Form Utama",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: accentThemeColor),
              ),
            ),
            TextField(
              controller: controller.titleController,
              decoration: _modernInputDecoration(labelText: 'Judul Form'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: _modernInputDecoration(labelText: 'Deskripsi Form', hintText: 'Deskripsi Form (Opsional)'),
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.addSection,
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Tambah Bagian Baru',
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentThemeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(FormSection section, int sectionIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: ExpansionTile(
        key: ValueKey(section.id),
        initiallyExpanded: sectionIndex == 0 || section.questions.isNotEmpty,
        backgroundColor: cardBgColor,
        collapsedBackgroundColor: cardBgColor,
        iconColor: accentThemeColor,
        collapsedIconColor: Colors.grey.shade700,
        title: Text(
          'Bagian ${sectionIndex + 1}: ${section.title.isEmpty ? "Bagian Baru" : section.title}',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          overflow: TextOverflow.ellipsis,
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Detail Bagian', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    if (controller.sections.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
                        tooltip: 'Hapus Bagian Ini',
                        onPressed: () {
                          Get.defaultDialog(
                              title: "Konfirmasi Hapus Bagian",
                              middleText: "Anda yakin ingin menghapus bagian '${section.title.isEmpty ? "Tanpa Judul" : section.title}'?",
                              textConfirm: "Hapus",
                              textCancel: "Batal",
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red.shade400,
                              cancelTextColor: Colors.grey.shade700,
                              onConfirm: () { controller.removeSection(section.id); Get.back(); }
                          );
                        },
                      ),
                  ],
                ),
                TextField(
                  controller: TextEditingController(text: section.title)
                    ..selection = TextSelection.fromPosition(TextPosition(offset: section.title.length)),
                  onChanged: (text) => controller.updateSectionTitle(section.id, text),
                  decoration: _modernInputDecoration(labelText: 'Judul Bagian', isDense: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: section.description)
                    ..selection = TextSelection.fromPosition(TextPosition(offset: section.description?.length ?? 0)),
                  onChanged: (text) => controller.updateSectionDescription(section.id, text),
                  decoration: _modernInputDecoration(labelText: 'Deskripsi Bagian', hintText: 'Deskripsi Bagian (Opsional)', isDense: true),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Text("Pertanyaan untuk Bagian Ini:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                if (section.questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text("Belum ada pertanyaan di bagian ini.", style: TextStyle(color: Colors.grey.shade600))),
                  ),
                Column( // Pastikan ini Column jika ada banyak pertanyaan
                  children: section.questions.asMap().entries.map((entry) {
                    final questionIndex = entry.key;
                    final question = entry.value;
                    return _buildQuestionCard(section.id, sectionIndex, question, questionIndex);
                  }).toList(),
                ),
                const SizedBox(height: 15),
                _buildAddQuestionButton(section.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String sectionId, int currentSectionIndex, FormQuestion question, int questionIndexInThisSection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Pertanyaan ${questionIndexInThisSection + 1} (${question.type.toShortString().capitalizeFirst ?? question.type.toShortString()})',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                  icon: Icon(Icons.delete_forever_outlined, color: Colors.red.shade300, size: 20,),
                  tooltip: 'Hapus Pertanyaan',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: () {
                    Get.defaultDialog(
                        title: "Konfirmasi Hapus Pertanyaan",
                        middleText: "Anda yakin ingin menghapus pertanyaan ini?",
                        textConfirm: "Hapus", textCancel: "Batal",
                        confirmTextColor: Colors.white, buttonColor: Colors.red.shade400,
                        cancelTextColor: Colors.grey.shade700,
                        onConfirm: () { controller.removeQuestion(sectionId, question.id); Get.back(); }
                    );
                  }
              ),
            ],
          ),
          TextField(
            controller: TextEditingController(text: question.questionText)
              ..selection = TextSelection.fromPosition(TextPosition(offset: question.questionText.length)),
            onChanged: (text) => controller.updateQuestionText(sectionId, question.id, text),
            decoration: _modernInputDecoration(labelText: 'Teks Pertanyaan', isDense: true,
                prefixIcon: Padding(padding: const EdgeInsets.all(8.0), child: Icon(Icons.help_outline_rounded, size: 18, color: Colors.grey.shade500))
            ),
            maxLines: null,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes || question.type == QuestionType.dropdown)
            _buildOptionsSection(sectionId, question),
          if (question.type == QuestionType.number)
            _buildNumberValidationSection(sectionId, question),
          if (question.type == QuestionType.text || question.type == QuestionType.paragraph)
            _buildTextValidationSection(sectionId, question),
          if (question.type == QuestionType.date)
            _buildDateValidationSection(sectionId, question),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Wajib diisi', style: TextStyle(fontSize: 14)),
              Switch(
                value: question.isRequired,
                onChanged: (value) => controller.updateQuestionRequired(sectionId, question.id, value),
                activeColor: accentThemeColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Spacer(),
              if (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'Opsi "Lainnya"',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: question.hasOtherOption,
                        onChanged: (value) => controller.updateQuestionHasOtherOption(sectionId, question.id, value),
                        activeColor: accentThemeColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _buildRepeatableSetting(sectionId, question),
          _buildConditionalJumpSetting(sectionId, question),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(String sectionId, FormQuestion question) {
    InputDecoration optionInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: accentThemeColor)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        isDense: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
          child: Text('Opsi Pilihan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
        ),
        ...question.options.asMap().entries.map((entry) {
          int index = entry.key; String option = entry.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  question.type == QuestionType.multipleChoice ? Icons.radio_button_off_rounded :
                  question.type == QuestionType.checkboxes ? Icons.check_box_outline_blank_rounded :
                  Icons.arrow_right_rounded,
                  color: Colors.grey.shade500, size: 18,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: option)..selection = TextSelection.fromPosition(TextPosition(offset: option.length)),
                  onChanged: (text) => controller.updateOption(sectionId, question.id, index, text),
                  decoration: optionInputDecoration('Opsi ${index + 1}'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 20),
                onPressed: () => controller.removeOption(sectionId, question.id, index),
                splashRadius: 16, padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                visualDensity: VisualDensity.compact,
              ),
            ],
          );
        }).toList(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => controller.addOption(sectionId, question.id),
            icon: const Icon(Icons.add_circle_outline_rounded, color: accentThemeColor, size: 20),
            label: const Text('Tambah Opsi', style: TextStyle(color: accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
          ),
        ),
        const Divider(height: 16, thickness: 0.5),
      ],
    );
  }

  Widget _buildExpansionTileForSettings(String title, List<Widget> children, {bool initiallyExpanded = false}) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      initiallyExpanded: initiallyExpanded,
      iconColor: accentThemeColor,
      collapsedIconColor: Colors.grey.shade600,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      children: children,
    );
  }

  Widget _buildTextValidationSection(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Teks',
      [
        TextField(
          controller: TextEditingController(text: question.validation?.minLength?.toString()),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, ValidationRule(minLength: int.tryParse(value), maxLength: question.validation?.maxLength, regex: question.validation?.regex)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.maxLength?.toString()),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, ValidationRule(minLength: question.validation?.minLength, maxLength: int.tryParse(value), regex: question.validation?.regex)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.regex),
          decoration: _modernInputDecoration(labelText: 'Pola Regex', hintText: 'Opsional, e.g. ^[A-Z]+\$', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, ValidationRule(minLength: question.validation?.minLength, maxLength: question.validation?.maxLength, regex: value.isEmpty ? null : value)); },
        ),
      ],
      initiallyExpanded: question.validation != null && (question.validation!.minLength != null || question.validation!.maxLength != null || question.validation!.regex != null),
    );
  }

  Widget _buildNumberValidationSection(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Angka',
      [
        TextField(
          controller: TextEditingController(text: question.validation?.minValue?.toString()),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, ValidationRule(minValue: num.tryParse(value), maxValue: question.validation?.maxValue)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.maxValue?.toString()),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, ValidationRule(minValue: question.validation?.minValue, maxValue: num.tryParse(value))); },
        ),
      ],
      initiallyExpanded: question.validation != null && (question.validation!.minValue != null || question.validation!.maxValue != null),
    );
  }

  Widget _buildDateValidationSection(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Tanggal',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Fitur validasi tanggal (Min/Max) akan segera hadir.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
        )
      ],
    );
  }

  Widget _buildRepeatableSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Ulang Pertanyaan',
      [
        CheckboxListTile(
          title: const Text("Dapat diulang (misal, isian harian)?", style: TextStyle(fontSize: 14)),
          value: question.repeatable,
          onChanged: (bool? value) { controller.updateQuestionRepeatable(sectionId, question.id, value ?? false); },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: accentThemeColor,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (question.repeatable)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: TextField(
              controller: TextEditingController(text: question.repeatCount?.toString() ?? ''),
              keyboardType: TextInputType.number,
              decoration: _modernInputDecoration(labelText: 'Jumlah Maks. Pengulangan', hintText: 'Opsional', isDense: true),
              onChanged: (value) { controller.updateQuestionRepeatable(sectionId, question.id, true, count: int.tryParse(value)); },
            ),
          ),
      ],
      initiallyExpanded: question.repeatable,
    );
  }

  Widget _buildConditionalJumpSetting(String sectionId, FormQuestion question) {
    if (!(question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes || question.type == QuestionType.dropdown) && question.options.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildExpansionTileForSettings(
      'Logika Bersyarat (Lompat)',
      [
        if (question.conditionalJumps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Belum ada aturan lompat.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
        ...question.conditionalJumps.asMap().entries.map((entry) {
          final jump = entry.value; String jumpToTargetText = "...";
          if (jump.jumpToQuestionId == 'END_OF_FORM') jumpToTargetText = 'Akhir Form';
          else if (jump.jumpToQuestionId == 'END_OF_SECTION' || jump.jumpToSectionId != null) jumpToTargetText = 'Bagian Selanjutnya atau Akhir Bagian';
          else if (jump.jumpToQuestionId.isNotEmpty) {
            bool targetFound = false;
            for (var sec in controller.sections) {
              if (jump.jumpToSectionId == sec.id && jump.jumpToQuestionId == 'END_OF_SECTION') {
                jumpToTargetText = 'Bagian: ${sec.title.isNotEmpty ? sec.title : "Tanpa Judul"}';
                targetFound = true;
                break;
              }
              for (var q in sec.questions) {
                if (q.id == jump.jumpToQuestionId) {
                  jumpToTargetText = 'P: ${q.questionText.length > 20 ? q.questionText.substring(0,17)+'...' : q.questionText}';
                  targetFound = true;
                  break;
                }
              }
              if (targetFound) break;
            }
            if (!targetFound && jump.jumpToQuestionId.isNotEmpty) {
              jumpToTargetText = 'ID: ${jump.jumpToQuestionId}';
            }
          }


          return ListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: Text('Jika: "${jump.conditionValue}"', style: const TextStyle(fontSize: 14)),
            subtitle: Text('Lompat ke: $jumpToTargetText', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 20),
              onPressed: () => controller.removeConditionalJump(sectionId, question.id, jump.jumpToQuestionId.isNotEmpty ? jump.jumpToQuestionId : jump.jumpToSectionId!),
              splashRadius: 18, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showAddConditionalJumpDialog(sectionId, question),
            icon: const Icon(Icons.add_circle_outline_rounded, color: accentThemeColor, size: 20),
            label: const Text('Tambah Aturan', style: TextStyle(color: accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
          ),
        ),
      ],
      initiallyExpanded: question.conditionalJumps.isNotEmpty,
    );
  }

  void _showAddConditionalJumpDialog(String sectionId, FormQuestion question) {
    final TextEditingController conditionController = TextEditingController();
    String? selectedTargetId;

    List<DropdownMenuItem<String>> allJumpTargets = [
      const DropdownMenuItem(value: null, enabled: false, child: Text('Pilih Tujuan Lompat:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
    ];

    for (int i = 0; i < controller.sections.length; i++) {
      final sec = controller.sections[i];
      String sectionTitle = 'Bagian ${i + 1}: ${sec.title.isNotEmpty ? (sec.title.length > 25 ? sec.title.substring(0, 22) + '...' : sec.title) : "Tanpa Judul"}';
      allJumpTargets.add(DropdownMenuItem(
        value: 'section_${sec.id}',
        child: Text(sectionTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
      ));
      for (int j = 0; j < sec.questions.length; j++) {
        final q = sec.questions[j];
        if (q.id == question.id) continue;
        allJumpTargets.add(DropdownMenuItem(
          value: q.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('  P${i + 1}.${j + 1}: ${q.questionText.length > 25 ? q.questionText.substring(0, 22) + '...' : q.questionText}'),
          ),
        ));
      }
    }
    allJumpTargets.add(DropdownMenuItem(
      value: 'END_OF_FORM',
      child: Text('Akhir Form (Selesai)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green.shade700)),
    ));

    Get.dialog(
      AlertDialog(
        title: const Text('Tambah Aturan Lompat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jika jawaban untuk pertanyaan ini adalah:', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: conditionController,
                decoration: _modernInputDecoration(labelText: 'Nilai Jawaban Pemicu', hintText: 'Contoh: Ya, Tidak, >10', isDense: true),
              ),
              const SizedBox(height: 16),
              const Text('Maka lompat ke:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _modernInputDecoration(labelText: 'Pilih Pertanyaan/Bagian Tujuan', isDense: true)
                    .copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14)),
                value: selectedTargetId,
                items: allJumpTargets.where((item) => item.enabled).toList(),
                onChanged: (value) { selectedTargetId = value; },
                isExpanded: true,
                hint: const Text('Pilih tujuan...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentThemeColor, foregroundColor: Colors.white),
            onPressed: () {
              final conditionValue = conditionController.text.trim();
              if (conditionValue.isNotEmpty && selectedTargetId != null) {
                String jumpToQId = ''; String? jumpToSId;
                if (selectedTargetId!.startsWith('section_')) {
                  jumpToSId = selectedTargetId!.substring(8); jumpToQId = 'END_OF_SECTION';
                } else if (selectedTargetId == 'END_OF_FORM') {
                  jumpToQId = 'END_OF_FORM';
                } else {
                  jumpToQId = selectedTargetId!;
                }
                controller.addConditionalJump(sectionId, question.id, ConditionalJump(conditionValue: conditionValue, jumpToQuestionId: jumpToQId, jumpToSectionId: jumpToSId));
                Get.back();
              } else {
                Get.snackbar('Peringatan', 'Kondisi dan tujuan lompat harus diisi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }


  Widget _buildAddQuestionButton(String sectionId) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.bottomSheet(
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, -2))]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text("Pilih Tipe Pertanyaan", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      mainAxisSpacing: 10.0,
                      crossAxisSpacing: 10.0,
                      children: QuestionType.values.map((type) {
                        IconData iconData; String typeName;
                        switch(type) {
                          case QuestionType.text: iconData = Icons.short_text_rounded; typeName = "Teks"; break;
                          case QuestionType.paragraph: iconData = Icons.notes_rounded; typeName = "Paragraf"; break;
                          case QuestionType.number: iconData = Icons.pin_outlined; typeName = "Angka"; break;
                          case QuestionType.date: iconData = Icons.date_range_rounded; typeName = "Tanggal"; break;
                          case QuestionType.multipleChoice: iconData = Icons.radio_button_checked_rounded; typeName = "Pilihan Ganda"; break;
                          case QuestionType.checkboxes: iconData = Icons.check_box_rounded; typeName = "Kotak Centang"; break;
                          case QuestionType.dropdown: iconData = Icons.arrow_drop_down_circle_rounded; typeName = "Dropdown"; break;
                          default: iconData = Icons.help_rounded; typeName = "Lainnya";
                        }
                        return InkWell(
                          onTap: () {
                            controller.addQuestionToSection(sectionId, type);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                                color: accentThemeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentThemeColor.withOpacity(0.3))
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(iconData, color: accentThemeColor, size: 26),
                                const SizedBox(height: 5),
                                Text(typeName, style: TextStyle(fontSize: 11, color: accentThemeColor.withOpacity(0.9), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              isScrollControlled: true,
            );
          },
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Tambah Pertanyaan',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}