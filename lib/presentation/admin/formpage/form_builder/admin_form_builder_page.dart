import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/form_builder/admin_form_builder_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk konsistensi warna

class AdminFormBuilderPage extends GetView<AdminFormBuilderController> {
  const AdminFormBuilderPage({Key? key}) : super(key: key);

  static const Color appBarForegroundColor = Colors.white;
  static const Color accentThemeColor = AdminScreen.accentHeaderColor;
  static const Color neutralLabelColor = Colors.grey;
  static const Color defaultTextFieldBorderColor = Colors.black26;
  static const Color pageBgColor = AdminScreen.pageBackgroundColor;
  static const Color cardBgColor = Colors.white;

  // Helper function to convert integer to Roman numeral
  String _toRoman(int number) {
    if (number < 1 || number > 3999) {
      return number.toString(); // Fallback for numbers out of typical Roman numeral range
    }
    const List<String> romanNumerals = [
      "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"
    ];
    const List<int> values = [
      1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1
    ];
    String result = "";
    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        result += romanNumerals[i];
        number -= values[i];
      }
    }
    return result;
  }

  static InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
    bool isDense = false,
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
    // Widget? suffixIcon, // Pastikan parameter suffixIcon ada jika Anda menggunakannya di pemanggilan
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: neutralLabelColor.withOpacity(0.9), fontSize: isDense ? 14 : 15), // neutralLabelColor harus static
      floatingLabelStyle: const TextStyle(color: accentThemeColor, fontWeight: FontWeight.w500), // accentThemeColor harus static
      hintText: hintText ?? 'Masukkan $labelText...',
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)), // defaultTextFieldBorderColor harus static
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: accentThemeColor, width: 1.8),
      ),
      filled: true,
      fillColor: cardBgColor, // cardBgColor harus static
      contentPadding: contentPadding ?? (isDense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      // suffixIcon: suffixIcon, // Aktifkan jika Anda menambahkan parameter suffixIcon
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
        final bool showInitialLoaderForNewForm = controller.isBusy.value &&
            !controller.isEditMode &&
            controller.sections.isEmpty;
        final bool showLoaderForEditing = controller.isBusy.value && controller.isEditMode;

        if (showInitialLoaderForNewForm || showLoaderForEditing) {
          return const Center(child: CircularProgressIndicator(color: accentThemeColor));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),
            Obx(() => Column(
              children: controller.sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;
                return _buildSectionCard(controller.sections[sectionIndex].id, sectionIndex);
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

  // Ganti metode _buildSectionCard Anda yang ada dengan ini:
  Widget _buildSectionCard(String sectionIdFromList, int sectionIndex) {
    return Obx(() { // Bungkus dengan Obx untuk reaktivitas terhadap perubahan section
      final section = controller.sections.firstWhere(
            (s) => s.id == sectionIdFromList,
        // orElse: () => FormSection(id: 'error', title: 'Error Section Not Found', questions: []), // Fallback jika diperlukan
      );

      String romanNumeral = _toRoman(sectionIndex + 1);
      String displaySectionTitle = section.title.trim().isEmpty
          ? 'Bagian $romanNumeral'
          : '$romanNumeral ${section.title.trim()}';

      if (section.isRepeatable) { // Akses properti isRepeatable dari model FormSection
        displaySectionTitle += " (Berulang";
        if (section.repeatTriggerQuestionCode != null && section.repeatTriggerQuestionCode!.isNotEmpty) {
          displaySectionTitle += " - Pemicu: ${section.repeatTriggerQuestionCode}";
        } else if (section.repeatTriggerQuestionId != null) {
          FormQuestion? triggerQ = controller.findQuestionById(section.repeatTriggerQuestionId!);
          if (triggerQ?.code != null && triggerQ!.code!.isNotEmpty) {
            displaySectionTitle += " - Pemicu: ${triggerQ.code}";
          } else if (triggerQ != null) {
            displaySectionTitle += " - Pemicu: ID ${triggerQ.id.substring(0,5)}...";
          }
        }
        displaySectionTitle += ")";
      }
      String titleForDialog = section.title.trim().isEmpty ? "Bagian $romanNumeral" : section.title.trim();

      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: cardBgColor,
        child: ExpansionTile(
          key: ValueKey(section.id),
          initiallyExpanded: sectionIndex == 0 || section.questions.isNotEmpty || section.title.isNotEmpty || section.isRepeatable,
          backgroundColor: cardBgColor,
          collapsedBackgroundColor: cardBgColor,
          iconColor: accentThemeColor,
          collapsedIconColor: Colors.grey.shade700,
          title: Text(
            displaySectionTitle,
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
                                middleText: "Anda yakin ingin menghapus bagian '$titleForDialog'?",
                                textConfirm: "Hapus", textCancel: "Batal",
                                confirmTextColor: Colors.white, buttonColor: Colors.red.shade400,
                                cancelTextColor: Colors.grey.shade700,
                                onConfirm: () { controller.removeSection(section.id); Get.back(); }
                            );
                          },
                        ),
                    ],
                  ),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_title'),
                    initialValue: section.title,
                    onChanged: (text) => controller.updateSectionTitle(section.id, text),
                    decoration: _modernInputDecoration(labelText: 'Judul Bagian', hintText: 'Kosongkan untuk nomor Romawi', isDense: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_description'),
                    initialValue: section.description ?? '',
                    onChanged: (text) => controller.updateSectionDescription(section.id, text),
                    decoration: _modernInputDecoration(labelText: 'Deskripsi Bagian', hintText: 'Opsional', isDense: true),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // --- UI UNTUK PENGATURAN REPEATABLE SECTION ---
                  _buildExpansionTileForSettings(
                    "Pengaturan Pengulangan Bagian",
                    [
                      SwitchListTile(
                        title: const Text("Bagian ini dapat diulang?", style: TextStyle(fontSize: 14)),
                        value: section.isRepeatable, // Gunakan dari section terbaru
                        onChanged: (bool newValue) {
                          controller.updateSectionRepeatability( // Panggil metode controller
                            sectionId: section.id,
                            isRepeatable: newValue,
                            triggerQuestionId: newValue ? section.repeatTriggerQuestionId : null,
                            triggerQuestionCode: newValue ? section.repeatTriggerQuestionCode : null,
                            minRepeats: newValue ? (section.minRepeats ?? (section.repeatTriggerQuestionId != null ? 0 : 1)) : null,
                            maxRepeats: newValue ? section.maxRepeats : null,
                          );
                        },
                        activeColor: accentThemeColor, dense: true, contentPadding: EdgeInsets.zero,
                      ),
                      if (section.isRepeatable) ...[ // Gunakan dari section terbaru
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: DropdownButtonFormField<String?>(
                            value: section.repeatTriggerQuestionId, // Gunakan dari section terbaru
                            decoration: _modernInputDecoration(
                              labelText: 'Ulangi berdasarkan jawaban pertanyaan:',
                              hintText: 'Pilih pertanyaan pemicu (tipe angka)',
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text("(Tidak ada pemicu / Ulangi min. kali)", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13))),
                              ...controller.getAllQuestionsForLinking(numericOnly: true).map((qMap) => // Panggil metode controller
                              DropdownMenuItem<String?>(value: qMap['id'], child: Text("${qMap['code']} - ${qMap['text']}", style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))
                              ).toList(),
                            ],
                            onChanged: (String? selectedQId) {
                              FormQuestion? triggerQ = controller.findQuestionById(selectedQId ?? '');
                              controller.updateSectionRepeatability( // Panggil metode controller
                                sectionId: section.id, isRepeatable: true,
                                triggerQuestionId: selectedQId, triggerQuestionCode: triggerQ?.code,
                                minRepeats: section.minRepeats, maxRepeats: section.maxRepeats,
                              );
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _PersistentTextField(
                            fieldKey: ValueKey('${section.id}_min_repeats'),
                            initialValue: section.minRepeats?.toString() ?? (section.repeatTriggerQuestionId != null ? '0' : '1'),
                            decoration: _modernInputDecoration(labelText: 'Min Pengulangan', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => controller.updateSectionRepeatability( // Panggil metode controller
                                sectionId: section.id, isRepeatable: true, triggerQuestionId: section.repeatTriggerQuestionId, triggerQuestionCode: section.repeatTriggerQuestionCode,
                                minRepeats: int.tryParse(val), maxRepeats: section.maxRepeats),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _PersistentTextField(
                            fieldKey: ValueKey('${section.id}_max_repeats'),
                            initialValue: section.maxRepeats?.toString() ?? '',
                            decoration: _modernInputDecoration(labelText: 'Max Pengulangan (Opsional)', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => controller.updateSectionRepeatability( // Panggil metode controller
                                sectionId: section.id, isRepeatable: true, triggerQuestionId: section.repeatTriggerQuestionId, triggerQuestionCode: section.repeatTriggerQuestionCode,
                                minRepeats: section.minRepeats, maxRepeats: int.tryParse(val)),
                          )),
                        ]),
                      ],
                    ],
                    initiallyExpanded: section.isRepeatable, // Gunakan dari section terbaru
                  ),
                  // --- AKHIR UI UNTUK PENGATURAN REPEATABLE SECTION ---
                  const SizedBox(height: 20),
                  Text("Pertanyaan untuk Bagian Ini:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  if (section.questions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text("Belum ada pertanyaan di bagian ini.", style: TextStyle(color: Colors.grey.shade600))),
                    )
                  else
                    Column(
                      children: section.questions.asMap().entries.map((entry) {
                        final questionIndexInSection = entry.key;
                        final questionItem = entry.value;
                        // Kirim ID pertanyaan agar _buildQuestionCard bisa mengambil state terbaru
                        return _buildQuestionCard(section.id, sectionIndex, questionItem.id, questionIndexInSection);
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
    });
  }

  Widget _buildGridNumericSettings(String sectionId, FormQuestion question) {
    bool isGridConfigured = (question.gridRowLabels.isNotEmpty) ||
        (question.gridColumnLabels.isNotEmpty) ||
        (question.gridSubColumnLabels.isNotEmpty);
    return _buildExpansionTileForSettings(
      'Pengaturan Label Grid Numerik', // Judul ExpansionTile
      [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
          child: Text(
            "Masukkan label dipisahkan koma (,). Contoh: Senin,Selasa.\n"
                "- Label Baris: Opsional (misal: 'Sampah Basah,Sampah Kering'). Kosongkan jika grid hanya butuh 1 jenis baris.\n"
                "- Label Kolom: Wajib (misal: 'Senin,Selasa,dst' untuk hari).\n"
                "- Label Sub-Kolom: Wajib (misal: 'Kecil,Sedang,Besar' untuk ukuran).",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
          ),
        ),
        // Menggunakan _PersistentTextField untuk Label Baris
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridRowLabels_persistent'),
          initialValue: question.gridRowLabels.join(', '),
          onChanged: (text) => controller.updateGridRowLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Baris (Pisahkan dengan koma)', hintText: 'Contoh: Baris A,Baris B', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Menggunakan _PersistentTextField untuk Label Kolom
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridColLabels_persistent'),
          initialValue: question.gridColumnLabels.join(', '),
          onChanged: (text) => controller.updateGridColumnLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Kolom (Pisahkan dengan koma)', hintText: 'Contoh: Kolom 1,Kolom 2', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Menggunakan _PersistentTextField untuk Label Sub-Kolom
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridSubColLabels_persistent'),
          initialValue: question.gridSubColumnLabels.join(', '),
          onChanged: (text) => controller.updateGridSubColumnLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Sub-Kolom (Pisahkan dengan koma)', hintText: 'Contoh: Sub A,Sub B', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
      ],
      initiallyExpanded: isGridConfigured, // Buka jika sudah ada label yang dikonfigurasi
    );
  }

  // Ganti metode _buildQuestionCard Anda yang ada dengan ini:
  Widget _buildQuestionCard(String sectionId, int sectionIndexOverall, String questionIdFromList, int questionIndexInSection) {
    return Obx(() {
      final question = controller.sections
          .firstWhereOrNull((s) => s.id == sectionId)
          ?.questions
          .firstWhereOrNull((q) => q.id == questionIdFromList);

      if (question == null) {
        return const SizedBox.shrink(child: Text("Error: Pertanyaan tidak dapat dimuat"));
      }

      String displayCode = question.code != null && question.code!.isNotEmpty ? "(${question.code}) " : "";
      String questionTypeString = question.type.toShortString();
      if (questionTypeString.isNotEmpty) {
        questionTypeString = (questionTypeString[0].toUpperCase() + questionTypeString.substring(1));
        if (question.type == QuestionType.gridNumeric) {
          questionTypeString = "Grid Numerik";
        }
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey.shade200, width: 1.0),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade100, blurRadius: 3, offset: const Offset(0,1))
            ]
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
                    'Pertanyaan ${questionIndexInSection + 1} $displayCode($questionTypeString)',
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
                          middleText: "Anda yakin ingin menghapus pertanyaan '${question.questionText.isNotEmpty ? question.questionText : displayCode}'?",
                          textConfirm: "Hapus", textCancel: "Batal",
                          confirmTextColor: Colors.white, buttonColor: Colors.red.shade400,
                          cancelTextColor: Colors.grey.shade700,
                          onConfirm: () { controller.removeQuestion(sectionId, question.id); Get.back(); }
                      );
                    }
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PersistentTextField(
              fieldKey: ValueKey('${question.id}_code'),
              initialValue: question.code ?? '',
              onChanged: (text) => controller.updateQuestionCode(sectionId, question.id, text),
              decoration: _modernInputDecoration(
                  labelText: 'Kode Pertanyaan',
                  hintText: 'Otomatis: ${sectionIndexOverall + 1}${(questionIndexInSection + 1).toString().padLeft(2,'0')} atau sesuaikan',
                  isDense: true,
                  prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.tag, size: 18, color: Colors.grey.shade500))
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _PersistentTextField(
              fieldKey: ValueKey('${question.id}_text'),
              initialValue: question.questionText,
              onChanged: (text) => controller.updateQuestionText(sectionId, question.id, text),
              decoration: _modernInputDecoration(labelText: 'Teks Pertanyaan', isDense: true,
                  prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.help_outline_rounded, size: 18, color: Colors.grey.shade500))
              ),
              maxLines: null,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),

            if (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes || question.type == QuestionType.dropdown)
              _buildOptionsSection(sectionId, question), // 'question' di sini adalah state terbaru dari Obx

            if (question.type == QuestionType.gridNumeric)
              _buildGridNumericSettings(sectionId, question), // 'question' di sini adalah state terbaru

            // Validasi (pastikan urutannya logis)
            // Selalu tampilkan predefined rule dropdown
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildPredefinedRuleDropdown(sectionId, question), // 'question' di sini adalah state terbaru
            ),
            const SizedBox(height: 4), // Jarak sebelum expansion tile validasi lain

            if (question.type == QuestionType.number || question.type == QuestionType.gridNumeric) // Grid numeric juga bisa punya validasi angka
              _buildNumberValidationSection(sectionId, question), // 'question' di sini adalah state terbaru
            if (question.type == QuestionType.text || question.type == QuestionType.paragraph)
              _buildTextValidationSection(sectionId, question), // 'question' di sini adalah state terbaru
            if (question.type == QuestionType.date)
              _buildDateValidationSection(sectionId, question), // 'question' di sini adalah state terbaru

            const SizedBox(height: 12),
            Row( // Wajib diisi & Opsi Lainnya
              children: [
                const Text('Wajib diisi', style: TextStyle(fontSize: 14)),
                Switch(
                  value: question.isRequired, // 'question' dari Obx
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
                        const Flexible(
                          child: Text(
                            'Opsi "Lainnya"',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: question.hasOtherOption, // 'question' dari Obx
                          onChanged: (value) => controller.updateQuestionHasOtherOption(sectionId, question.id, value),
                          activeColor: accentThemeColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            _buildRepeatableSetting(sectionId, question), // 'question' dari Obx (untuk repeatable individual question)
            _buildRepeatableGroupSettings(sectionId, question), // 'question' dari Obx (untuk repeatable group question)
            _buildConditionalJumpSetting(sectionId, question), // 'question' dari Obx
            if (question.type == QuestionType.dropdown)
              _buildDependentOptionsConfigurator(sectionId, question), // 'question' dari Obx
          ],
        ),
      );
    });
  }

  Widget _buildRepeatableGroupSettings(String sectionId, FormQuestion question) {
    final String uniqueTagSuggestion = "grup_${question.id.substring(0, 5)}";

    return _buildExpansionTileForSettings(
      'Pengaturan Grup Pertanyaan Berulang',
      [
        // Opsi 1: Pertanyaan ini adalah PENGONTROL grup
        // Hanya boleh tipe Angka
        if (question.type == QuestionType.number)
          CheckboxListTile(
            title: Text("Jadikan Pengontrol Grup?", style: TextStyle(fontSize: 14, fontWeight: question.isRepeatableGroupController ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text("Jawaban pertanyaan ini (angka) akan menentukan berapa kali grup pertanyaan lain diulang.", style: const TextStyle(fontSize: 12)),
            value: question.isRepeatableGroupController,
            onChanged: (bool? value) {
              if (value == true) {
                // Jika belum ada tag, berikan sugesti
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, true, question.controlledGroupTag ?? uniqueTagSuggestion);
              } else {
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, false, null);
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        if (question.isRepeatableGroupController && question.type == QuestionType.number)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
            child: TextField(
              controller: TextEditingController(text: question.controlledGroupTag ?? uniqueTagSuggestion)
                ..selection = TextSelection.fromPosition(TextPosition(offset: (question.controlledGroupTag ?? uniqueTagSuggestion).length)),
              decoration: _modernInputDecoration(
                  labelText: 'ID Unik Grup yang Dikontrol',
                  hintText: 'Contoh: ${uniqueTagSuggestion}',
                  isDense: true),
              onChanged: (tag) {
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, true, tag.isNotEmpty ? tag : null);
              },
              style: const TextStyle(fontSize: 13),
            ),
          ),

        if (question.type == QuestionType.number && question.isRepeatableGroupController)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Divider(height: 12, color: Colors.grey.shade300),
          ),

        // Opsi 2: Pertanyaan ini adalah ANGGOTA grup
        // Tidak boleh jika pertanyaan ini adalah controller
        if (!question.isRepeatableGroupController) ...[
          CheckboxListTile(
            title: Text("Jadikan Anggota Grup Berulang?", style: TextStyle(fontSize: 14, fontWeight: (question.belongsToGroupTag !=null && question.belongsToGroupTag!.isNotEmpty) ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text("Pertanyaan ini akan diulang berdasarkan jawaban pertanyaan pengontrol.", style: const TextStyle(fontSize: 12)),
            value: (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty),
            onChanged: (bool? value) {
              if (value == true) {
                // Biarkan kosong dulu, user akan pilih dari dropdown
                controller.updateQuestionBelongsToGroupTag(sectionId, question.id, question.belongsToGroupTag); // Mungkin sudah ada nilai sebelumnya
              } else {
                controller.updateQuestionBelongsToGroupTag(sectionId, question.id, null);
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty || (question.isRepeatableGroupController == false && Get.find<AdminFormBuilderController>().getAvailableControlledGroupTags(sectionId, question.id).isNotEmpty)) // Tampilkan dropdown jika sudah jadi anggota ATAU ada tag yang bisa dipilih
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
              child: DropdownButtonFormField<String?>(
                value: question.belongsToGroupTag,
                decoration: _modernInputDecoration(labelText: 'Pilih ID Grup Induk', isDense: true),
                hint: const Text('Pilih grup...'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Tidak termasuk grup / Lepaskan", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                  ...controller.getAvailableControlledGroupTags(sectionId, question.id)
                      .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                      .toList(),
                ],
                onChanged: (String? selectedTag) {
                  controller.updateQuestionBelongsToGroupTag(sectionId, question.id, selectedTag);
                },
                isExpanded: true,
              ),
            ),
          if (controller.getAvailableControlledGroupTags(sectionId, question.id).isEmpty && !question.isRepeatableGroupController && (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) )
            Padding(
              padding: const EdgeInsets.only(left:16.0, top:0.0, bottom: 8.0),
              child: Text("Tidak ada grup pertanyaan yang tersedia. Buat pertanyaan pengontrol terlebih dahulu (tipe Angka).", style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
            ),
        ],

        // Info validasi silang (placeholder)
        if (question.isRepeatableGroupController && question.type == QuestionType.number)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Info Lanjutan (Validasi Silang):",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Untuk validasi seperti 'jawaban pertanyaan ini tidak boleh melebihi jawaban dari pertanyaan X (misal: 112)', akan memerlukan fitur validasi silang antar pertanyaan yang lebih canggih dan saat ini belum terimplementasi di UI builder ini. Namun, nilai min/max untuk pertanyaan ini sendiri dapat diatur di 'Pengaturan Validasi Angka'.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
      ],
      initiallyExpanded: question.isRepeatableGroupController || (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty),
    );
  }


  Widget _buildOptionsSection(String sectionId, FormQuestion question) {
    // Asumsi optionInputDecoration sudah didefinisikan di dalam kelas AdminFormBuilderPage
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
        // Gunakan Obx jika question.options adalah RxList atau jika daftar opsi bisa berubah drastis.
        // Jika question.options adalah List biasa yang diupdate melalui controller.sections.refresh(),
        // maka Obx di level atas (yang mengamati controller.sections) sudah cukup.
        // Namun, jika hanya ingin merebuild bagian ini saat opsi berubah, Obx di sini bisa berguna.
        // Untuk saat ini, kita asumsikan Obx di level atas sudah menangani rebuild.
        ...question.options.asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  question.type == QuestionType.multipleChoice ? Icons.radio_button_off_rounded :
                  question.type == QuestionType.checkboxes ? Icons.check_box_outline_blank_rounded :
                  Icons.arrow_right_rounded, // Untuk dropdown
                  color: Colors.grey.shade500, size: 18,
                ),
              ),
              Expanded(
                child: _PersistentTextField( // Menggunakan _PersistentTextField
                  fieldKey: ValueKey('${question.id}_option_${index}_persistent'),
                  initialValue: option,
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 0), // Remove default padding
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8), // Padding for children
      initiallyExpanded: initiallyExpanded,
      iconColor: accentThemeColor,
      collapsedIconColor: Colors.grey.shade600,
      shape: const Border(top: BorderSide.none, bottom: BorderSide.none), // No border when expanded
      collapsedShape: const Border(top: BorderSide.none, bottom: BorderSide.none), // No border when collapsed
      children: children,
    );
  }

  Widget _buildTextValidationSection(String sectionId, FormQuestion question) {
    bool isValidationNotEmpty = question.validation != null &&
        (question.validation!.minLength != null ||
            question.validation!.maxLength != null ||
            (question.validation!.regex != null && question.validation!.regex!.isNotEmpty));

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Teks/Paragraf',
      [
        TextField(
          controller: TextEditingController(text: question.validation?.minLength?.toString() ?? ''),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, (question.validation ?? ValidationRule()).copyWith(minLength: int.tryParse(value), setMinLengthNull: value.isEmpty)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.maxLength?.toString() ?? ''),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, (question.validation ?? ValidationRule()).copyWith(maxLength: int.tryParse(value), setMaxLengthNull: value.isEmpty)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.regex ?? ''),
          decoration: _modernInputDecoration(labelText: 'Pola Regex Kustom', hintText: 'Opsional, e.g. ^[A-Z]+\$', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, (question.validation ?? ValidationRule()).copyWith(regex: value.isEmpty ? null : value, setRegexNull: value.isEmpty)); },
        ),
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

  // Ganti metode _buildNumberValidationSection Anda dengan ini:
  Widget _buildNumberValidationSection(String sectionId, FormQuestion question) {
    // 'question' yang diterima di sini adalah state terbaru dari Obx di _buildQuestionCard
    final ValidationRule validationRule = question.validation;

    bool isBasicNumValidationNotEmpty = validationRule.minValue != null || validationRule.maxValue != null;
    // Cek apakah comparisonOperator ada dan bukan 'none'
    bool isComparisonRuleNotEmpty = (validationRule.comparisonOperator != null &&
        validationRule.comparisonOperator != ComparisonOperatorType.none.toShortString()) &&
        validationRule.compareToQuestionId != null &&
        validationRule.compareToQuestionId!.isNotEmpty;

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Angka & Perbandingan',
      [
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_minValue'),
          initialValue: validationRule.minValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id,
              validationRule.copyWith(minValue: num.tryParse(value), setMinValueNull: value.isEmpty));
          },
        ),
        const SizedBox(height: 8),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_maxValue'),
          initialValue: validationRule.maxValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id,
              validationRule.copyWith(maxValue: num.tryParse(value), setMaxValueNull: value.isEmpty));
          },
        ),
        const SizedBox(height: 16),
        Text("Validasi Perbandingan dengan Pertanyaan Lain:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: validationRule.comparisonOperator ?? ComparisonOperatorType.none.toShortString(),
          decoration: _modernInputDecoration(labelText: 'Operator Perbandingan', isDense: true),
          items: ComparisonOperatorType.values.map((op) {
            String displayText;
            switch(op){
              case ComparisonOperatorType.none: displayText = "Tidak ada perbandingan"; break;
              case ComparisonOperatorType.lessThan: displayText = "Kurang Dari (<)"; break;
              case ComparisonOperatorType.lessThanOrEqual: displayText = "Kurang Dari atau Sama Dengan (<=)"; break;
              case ComparisonOperatorType.equal: displayText = "Sama Dengan (==)"; break;
              case ComparisonOperatorType.notEqual: displayText = "Tidak Sama Dengan (!=)"; break;
              case ComparisonOperatorType.greaterThan: displayText = "Lebih Dari (>)"; break;
              case ComparisonOperatorType.greaterThanOrEqual: displayText = "Lebih Dari atau Sama Dengan (>=)"; break;
            }
            return DropdownMenuItem<String?>(
                value: op.toShortString(),
                child: Text(displayText, style: TextStyle(fontSize:14, fontStyle: op == ComparisonOperatorType.none ? FontStyle.italic : FontStyle.normal))
            );
          }).toList(),
          onChanged: (String? selectedOpString) {
            final selectedOperator = selectedOpString == ComparisonOperatorType.none.toShortString() ? null : selectedOpString;
            controller.updateValidation(
              sectionId, question.id,
              validationRule.copyWith(
                comparisonOperator: selectedOperator, setComparisonOperatorNull: selectedOperator == null,
                compareToQuestionId: selectedOperator == null ? null : validationRule.compareToQuestionId,
                setCompareToQuestionIdNull: selectedOperator == null,
                compareToQuestionCode: selectedOperator == null ? null : validationRule.compareToQuestionCode,
                setCompareToQuestionCodeNull: selectedOperator == null,
              ),
            );
          },
          isExpanded: true,
        ),
        // Dropdown untuk memilih pertanyaan pembanding hanya muncul jika operator dipilih
        if (validationRule.comparisonOperator != null && validationRule.comparisonOperator != ComparisonOperatorType.none.toShortString()) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: validationRule.compareToQuestionId,
            decoration: _modernInputDecoration(labelText: 'Bandingkan dengan Pertanyaan:', isDense: true),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text("Pilih pertanyaan...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))),
              ...controller.getAllQuestionsForLinking(currentQuestionIdToExclude: question.id, numericOnly: true) // Hanya pertanyaan numerik
                  .map((qMap) => DropdownMenuItem<String?>(value: qMap['id'], child: Text("${qMap['code']} - ${qMap['text']}", style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)))
                  .toList(),
            ],
            onChanged: (String? selectedTargetId) {
              FormQuestion? targetQ = controller.findQuestionById(selectedTargetId ?? '');
              controller.updateValidation(
                sectionId, question.id,
                validationRule.copyWith(
                    compareToQuestionId: selectedTargetId, setCompareToQuestionIdNull: selectedTargetId == null,
                    compareToQuestionCode: targetQ?.code, setCompareToQuestionCodeNull: selectedTargetId == null || targetQ?.code == null
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

  Widget _buildDateValidationSection(String sectionId, FormQuestion question) {
    // Add specific date validation fields here if needed in the future.
    // For now, it's mostly covered by predefined rules or general validation if any.
    bool isValidationNotEmpty = question.validation != null &&
        (question.validation!.predefinedRule == 'pastDateOnly' ||
            question.validation!.predefinedRule == 'futureDateOnly');
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Tanggal',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Gunakan "Pola Validasi Umum" di bawah untuk validasi tanggal (misal: Hanya Tanggal Lalu).', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
        )
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

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
      // Add more as needed
    };
    if (question.type == QuestionType.date) {
      predefinedRulesDisplay['pastDateOnly'] = 'Hanya Tanggal Lalu';
      predefinedRulesDisplay['futureDateOnly'] = 'Hanya Tanggal Akan Datang';
    }


    String? currentRule = question.validation?.predefinedRule;
    if (currentRule != null && !predefinedRulesDisplay.containsKey(currentRule)) {
      currentRule = 'none'; // Default if rule from db is not in our map
    }
    if (currentRule == null || currentRule.isEmpty) currentRule = 'none';


    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 8.0), // Reduced top padding
      child: DropdownButtonFormField<String>(
        value: currentRule,
        decoration: _modernInputDecoration(
          labelText: 'Pola Validasi Umum',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: predefinedRulesDisplay.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) {
          controller.updateValidation(
              sectionId,
              question.id,
              (question.validation ?? ValidationRule()).copyWith(
                  predefinedRule: (value == 'none' || value == null || value.isEmpty) ? null : value,
                  setPredefinedRuleNull: (value == 'none' || value == null || value.isEmpty)
              )
          );
        },
        isExpanded: true,
      ),
    );
  }


  Widget _buildRepeatableSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Ulang Pertanyaan',
      [
        CheckboxListTile(
          title: const Text("Dapat diulang?", style: TextStyle(fontSize: 14)),
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
              decoration: _modernInputDecoration(labelText: 'Jumlah Maks. Pengulangan', hintText: 'Kosongkan untuk tanpa batas', isDense: true),
              onChanged: (value) { controller.updateQuestionRepeatable(sectionId, question.id, true, count: int.tryParse(value)); },
            ),
          ),
      ],
      initiallyExpanded: question.repeatable,
    );
  }

  Widget _buildConditionalJumpSetting(String sectionId, FormQuestion question) {
    bool canHaveJumps = question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.checkboxes ||
        question.type == QuestionType.dropdown ||
        (question.options.isNotEmpty);

    if (!canHaveJumps) {
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
          else if (jump.jumpToQuestionId == 'END_OF_SECTION') {
            if (jump.jumpToSectionId != null) {
              final targetSection = controller.sections.firstWhereOrNull((s) => s.id == jump.jumpToSectionId);
              String targetSectionRoman = "";
              if (targetSection != null) {
                int targetSectionIndex = controller.sections.indexOf(targetSection);
                targetSectionRoman = _toRoman(targetSectionIndex + 1);
              }
              jumpToTargetText = targetSection != null ? 'Awal Bagian: $targetSectionRoman ${targetSection.title.isNotEmpty ? (targetSection.title.length > 15 ? targetSection.title.substring(0,12)+'...' : targetSection.title) : "Tanpa Judul"}' : 'Bagian Selanjutnya';
            } else {
              jumpToTargetText = 'Bagian Selanjutnya / Akhir Bagian Ini';
            }
          } else if (jump.jumpToQuestionId.isNotEmpty) {
            bool targetFound = false;
            for (var sec_idx = 0; sec_idx < controller.sections.length; sec_idx++) {
              var sec = controller.sections[sec_idx];
              for (var q_idx = 0; q_idx < sec.questions.length; q_idx++) {
                var q_item = sec.questions[q_idx];
                if (q_item.id == jump.jumpToQuestionId) {
                  String qCodeDisplay = q_item.code != null && q_item.code!.isNotEmpty ? q_item.code! : "${_toRoman(sec_idx + 1)}.${q_idx + 1}";
                  jumpToTargetText = 'P: $qCodeDisplay - ${q_item.questionText.length > 20 ? q_item.questionText.substring(0,17)+'...' : q_item.questionText}';
                  targetFound = true;
                  break;
                }
              }
              if (targetFound) break;
            }
            if (!targetFound) {
              jumpToTargetText = 'ID Pertanyaan: ${jump.jumpToQuestionId} (Mungkin terhapus)';
            }
          }

          return ListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: Text('Jika jawaban: "${jump.conditionValue}"', style: const TextStyle(fontSize: 14)),
            subtitle: Text('Lompat ke: $jumpToTargetText', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 20),
              onPressed: () {
                String idToRemove = jump.jumpToQuestionId;
                if (jump.jumpToQuestionId == 'END_OF_SECTION' && jump.jumpToSectionId != null) {
                  idToRemove = jump.jumpToSectionId!;
                }
                controller.removeConditionalJump(sectionId, question.id, idToRemove);
              },
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
    String? selectedTargetCompositeValue; // e.g., 'question_xyz', 'section_start_abc', 'end_of_form'


    List<DropdownMenuItem<String>> allJumpTargets = [
      const DropdownMenuItem(value: "HEADER_TARGET", enabled: false, child: Text('Pilih Tujuan Lompat:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
    ];

    for (int i = 0; i < controller.sections.length; i++) {
      final sec = controller.sections[i];
      String sectionRoman = _toRoman(i + 1);
      String sectionTitle = '$sectionRoman: ${sec.title.isNotEmpty ? (sec.title.length > 20 ? sec.title.substring(0, 17) + '...' : sec.title) : "Tanpa Judul"}';


      allJumpTargets.add(DropdownMenuItem(
        value: 'section_start_${sec.id}',
        child: Text("Lompat ke Awal Bagian $sectionTitle", style: const TextStyle(fontWeight: FontWeight.w500)),
      ));

      for (int j = 0; j < sec.questions.length; j++) {
        final q = sec.questions[j];
        String questionCodeDisplay = q.code != null && q.code!.isNotEmpty ? q.code! : "$sectionRoman.${j+1}";
        allJumpTargets.add(DropdownMenuItem(
          value: 'question_${q.id}',
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('  P $questionCodeDisplay: ${q.questionText.length > 25 ? q.questionText.substring(0, 22) + '...' : q.questionText}'),
          ),
        ));
      }
    }

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_current_section',
      child: Text('Akhir Bagian Ini (Lanjut Bagian Berikutnya)', style: TextStyle(fontStyle: FontStyle.italic)),
    ));

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_form',
      child: Text('Akhir Form (Selesai)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
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
              Text('Jika jawaban untuk "${question.questionText.length > 30 ? question.questionText.substring(0,27) + "..." : question.questionText}" adalah:', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),

              if (question.options.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: _modernInputDecoration(labelText: 'Nilai Jawaban Pemicu', isDense: true),
                  items: question.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                  onChanged: (val) => conditionController.text = val ?? '',
                  hint: const Text('Pilih dari opsi'),
                )
              else
                TextField(
                  controller: conditionController,
                  decoration: _modernInputDecoration(labelText: 'Nilai Jawaban Pemicu', hintText: 'Contoh: Ya, Tidak, >10', isDense: true),
                ),

              const SizedBox(height: 16),
              const Text('Maka lompat ke:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _modernInputDecoration(labelText: 'Pilih Tujuan', isDense: true)
                    .copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14)),
                value: selectedTargetCompositeValue,
                items: allJumpTargets.where((item) => item.value != "HEADER_TARGET").toList(),
                onChanged: (valueWithPrefix) {
                  selectedTargetCompositeValue = valueWithPrefix;
                },
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
              if (conditionValue.isNotEmpty && selectedTargetCompositeValue != null && selectedTargetCompositeValue != "HEADER_TARGET") {
                String jumpToQId = '';
                String? jumpToSId;

                List<String> parts = selectedTargetCompositeValue!.split('_');
                String type = parts.first;


                if (type == 'question' && parts.length > 1) {
                  jumpToQId = parts.sublist(1).join('_'); // Handle IDs that might contain underscores
                } else if (type == 'section' && parts.length > 2 && parts[1] == 'start') {
                  jumpToSId = parts.sublist(2).join('_'); // Handle IDs that might contain underscores
                  jumpToQId = 'END_OF_SECTION';
                } else if (selectedTargetCompositeValue == 'end_of_current_section') {
                  jumpToQId = 'END_OF_SECTION';
                } else if (selectedTargetCompositeValue == 'end_of_form') {
                  jumpToQId = 'END_OF_FORM';
                } else {
                  Get.snackbar('Peringatan', 'Tujuan lompat tidak valid atau format ID salah.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
                  return;
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

  Widget _buildDependentOptionsConfigurator(String sectionId, FormQuestion questionToList) {
    return Obx(() {
      final question = controller.sections
          .firstWhereOrNull((s) => s.id == sectionId)
          ?.questions
          .firstWhereOrNull((q) => q.id == questionToList.id) ?? questionToList;

      print("--- START _buildDependentOptionsConfigurator for child Q: ${question.id} ---");

      final potentialParents = controller.getPotentialParentQuestions(sectionId, question.id);
      print("Potential Parents count: ${potentialParents.length}");

      FormQuestion? selectedParentQuestionObj; // Variabel baru untuk kejelasan
      final String? storedParentIdInChild = question.dependentOptions?.parentQuestionId;
      print("Stored Parent ID in child's dependentOptions: $storedParentIdInChild");

      if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty) {
        selectedParentQuestionObj = controller.findQuestionById(storedParentIdInChild);
        if (selectedParentQuestionObj == null) {
          print("ERROR: Parent object for ID '$storedParentIdInChild' NOT FOUND by findQuestionById.");
        } else {
          print("SUCCESS: Parent object FOUND: ID='${selectedParentQuestionObj.id}', Text='${selectedParentQuestionObj.questionText}'");
          print("PARENT OBJECT OPTIONS (Length: ${selectedParentQuestionObj.options.length}): ${selectedParentQuestionObj.options}");
        }
      } else {
        print("No parent ID stored in child's dependentOptions.");
      }

      final validParentQuestionIdsInDropdown = potentialParents.map((pQ) => pQ.id).toList();
      String? effectiveParentIdForDropdownValue = storedParentIdInChild;
      if (effectiveParentIdForDropdownValue != null && !validParentQuestionIdsInDropdown.contains(effectiveParentIdForDropdownValue)) {
        print("Warning: Stored parent ID '$effectiveParentIdForDropdownValue' is not in current valid dropdown items. Resetting dropdown value to null.");
        effectiveParentIdForDropdownValue = null;
      }
      print("Effective Parent ID for Dropdown 'value' property: $effectiveParentIdForDropdownValue");

      // Kondisi utama untuk menampilkan UI mapping
      // Kita cek sekali lagi di sini dengan objek yang baru di-fetch
      bool showMappingInterface = selectedParentQuestionObj != null && selectedParentQuestionObj.options.isNotEmpty;
      print(">>> Condition to show mapping UI: showMappingInterface = $showMappingInterface");
      if (selectedParentQuestionObj == null) print("    Reason: selectedParentQuestionObj is NULL");
      if (selectedParentQuestionObj != null && selectedParentQuestionObj.options.isEmpty) print("    Reason: selectedParentQuestionObj.options IS EMPTY");
      if (selectedParentQuestionObj != null && selectedParentQuestionObj.options.isNotEmpty) print("    Reason: selectedParentQuestionObj IS NOT NULL and options IS NOT EMPTY");


      return _buildExpansionTileForSettings(
        'Opsi Bergantung (Cascading)',
        [
          Padding( // Selalu tampilkan dropdown pemilihan parent
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String?>(
              key: ValueKey('${question.id}_parent_dd_${effectiveParentIdForDropdownValue ?? "no_parent_selected"}'),
              value: effectiveParentIdForDropdownValue,
              decoration: _modernInputDecoration(
                  labelText: 'Bergantung pada Pertanyaan (Induk)',
                  isDense: true
              ),
              hint: const Text('Pilih Pertanyaan Induk'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text("Tidak Bergantung / Hapus", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
                if (potentialParents.isNotEmpty) // Hanya tampilkan jika ada calon induk
                  ...potentialParents.map((parentQ) {
                    String parentSectionTitle = "Lain Bagian";
                    String parentSectionRoman = "";
                    int parentSectionIndex = controller.sections.indexWhere((s) => s.questions.any((qInS) => qInS.id == parentQ.id));
                    if (parentSectionIndex != -1) {
                      final sec = controller.sections[parentSectionIndex];
                      parentSectionRoman = _toRoman(parentSectionIndex + 1);
                      parentSectionTitle = sec.title.isNotEmpty ? sec.title : "Bagian $parentSectionRoman";
                    }
                    String parentQCodeDisplay = parentQ.code != null && parentQ.code!.isNotEmpty ? parentQ.code! : "N/A";
                    return DropdownMenuItem<String?>(
                      value: parentQ.id,
                      child: Text(
                        '$parentQCodeDisplay - ${parentQ.questionText.length > 15 ? parentQ.questionText.substring(0, 12) + "..." : parentQ.questionText} (di: $parentSectionTitle)',
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList()
                else // Jika potentialParents kosong, tambahkan item ini
                  const DropdownMenuItem<String?>(
                    value: null, // atau nilai dummy yang tidak akan pernah terpilih
                    enabled: false, // Buat tidak bisa dipilih
                    child: Text("Tidak ada calon induk tersedia", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
              ],
              onChanged: (String? newParentId) {
                print("DROPDOWN PARENT CHANGED. New Parent ID selected: $newParentId");
                controller.setParentQuestionForDependency(sectionId, question.id, newParentId);
              },
              isExpanded: true,
            ),
          ),

          const SizedBox(height: 10), // Jarak sebelum pesan error atau UI mapping

          // Pesan error jika parent ID tersimpan tapi objeknya tidak ditemukan
          if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty && selectedParentQuestionObj == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Pesan Info: Pertanyaan Induk (ID: $storedParentIdInChild) yang sebelumnya dipilih tidak ditemukan. Mungkin telah dihapus atau ID berubah. Silakan pilih ulang dari daftar di atas.',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),

          // Tampilkan UI mapping opsi
          if (showMappingInterface) ...[
            // Jika showMappingInterface true, selectedParentQuestionObj dijamin tidak null.
            Text(
              'Atur opsi anak untuk pertanyaan "${question.questionText}" berdasarkan jawaban dari "${selectedParentQuestionObj!.code ?? "Induk"}" (${selectedParentQuestionObj.questionText}):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedParentQuestionObj.options.length,
              itemBuilder: (context, index) {
                final parentOption = selectedParentQuestionObj!.options[index];
                final currentChildOptions = question.dependentOptions?.optionMapping[parentOption] ?? [];
                return _buildParentOptionMappingTile(
                  sectionId,
                  question.id,
                  parentOption,
                  currentChildOptions,
                );
              },
            ),
          ]
          // Pesan jika parent ditemukan tapi tidak punya opsi
          else if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty && selectedParentQuestionObj != null && selectedParentQuestionObj.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                  'Info: Pertanyaan Induk "${selectedParentQuestionObj.questionText}" (${selectedParentQuestionObj.code ?? selectedParentQuestionObj.id}) TIDAK MEMILIKI OPSI. Harap tambahkan opsi pada pertanyaan induk tersebut agar bisa mengatur dependensi.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12.5, fontStyle: FontStyle.italic)
              ),
            )
        ],
        initiallyExpanded: question.dependentOptions != null && question.dependentOptions!.parentQuestionId.isNotEmpty,
      );
    });
  }

  Widget _buildParentOptionMappingTile(String sectionId, String questionId, String parentOptionValue, List<String> currentChildOptions) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jika jawaban Induk adalah: "$parentOptionValue"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            const SizedBox(height: 6),
            Text(
              'Opsi untuk pertanyaan ini: ${currentChildOptions.isEmpty ? "(Belum diatur - akan menggunakan opsi standar pertanyaan ini)" : currentChildOptions.join(", ")}',
              style: TextStyle(fontSize: 13, color: currentChildOptions.isEmpty ? Colors.grey.shade600 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.edit_note_rounded, size: 20, color: accentThemeColor.withOpacity(0.8)),
                label: Text('Atur Opsi Anak', style: TextStyle(fontSize: 13, color: accentThemeColor.withOpacity(0.9), fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap
                ),
                onPressed: () {
                  _showEditChildOptionsDialog(sectionId, questionId, parentOptionValue, List<String>.from(currentChildOptions));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Di dalam kelas AdminFormBuilderPage

// Metode ini sekarang hanya menampilkan StatefulWidget dialog kustom
  void _showEditChildOptionsDialog(
      String sectionId,
      String questionId,
      String parentOptionValue,
      List<String> initialChildOptions
      ) {
    Get.dialog(
      _EditChildOptionsDialog( // Panggil StatefulWidget dialog kustom Anda
        pageController: controller, // Teruskan AdminFormBuilderController utama
        sectionId: sectionId,
        questionId: questionId,
        parentOptionValue: parentOptionValue,
        initialChildOptions: initialChildOptions,
      ),
      barrierDismissible: false, // Pengguna harus menekan tombol Batal atau Simpan
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
                      childAspectRatio: 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
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
                          case QuestionType.gridNumeric: iconData = Icons.grid_on_outlined; typeName = "Grid Numerik"; break; // <-- OPSI BARU
                        }
                        return InkWell(
                          onTap: () {
                            controller.addQuestionToSection(sectionId, type);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                                color: accentThemeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentThemeColor.withOpacity(0.3))
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(iconData, color: accentThemeColor, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  typeName,
                                  style: TextStyle(fontSize: 10.5, color: accentThemeColor.withOpacity(0.95), fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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


// Di bagian atas file AdminFormBuilderPage.dart, setelah import
// atau di dalam kelas AdminFormBuilderPage sebagai nested class jika mau,
// tapi lebih umum sebagai helper class terpisah di file yang sama.

class _PersistentTextField extends StatefulWidget {
  final String initialValue;
  final ValueKey fieldKey; // Key unik untuk TextField ini berdasarkan data
  final InputDecoration decoration;
  final Function(String) onChanged;
  final TextStyle? style;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _PersistentTextField({
    required this.fieldKey, // Gunakan Key yang lebih spesifik dari pemanggil
    required this.initialValue,
    required this.decoration,
    required this.onChanged,
    this.style,
    this.maxLines = 1, // Default maxLines
    this.keyboardType,
  }) : super(key: fieldKey); // Teruskan fieldKey ke super constructor

  @override
  State<_PersistentTextField> createState() => _PersistentTextFieldState();
}


class _EditChildOptionsDialog extends StatefulWidget {
  final AdminFormBuilderController pageController; // Untuk memanggil updateMappingForParentOption
  final String sectionId;
  final String questionId;
  final String parentOptionValue;
  final List<String> initialChildOptions;

  const _EditChildOptionsDialog({
    // Key? key, // Tidak wajib untuk dialog via Get.dialog
    required this.pageController,
    required this.sectionId,
    required this.questionId,
    required this.parentOptionValue,
    required this.initialChildOptions,
  }); // : super(key: key);

  @override
  State<_EditChildOptionsDialog> createState() => _EditChildOptionsDialogState();
}

class _EditChildOptionsDialogState extends State<_EditChildOptionsDialog> {
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _optionControllers = widget.initialChildOptions
        .map((opt) => TextEditingController(text: opt))
        .toList();
    if (_optionControllers.isEmpty) {
      // Selalu mulai dengan satu field jika kosong
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Dispose semua controller saat dialog ini di-dispose
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    print("AdminFormBuilderPage: _EditChildOptionsDialog disposed ${_optionControllers.length} controllers.");
    super.dispose();
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    setState(() {
      FocusScope.of(context).unfocus();
      // Controller yang dihapus akan di-dispose secara otomatis oleh metode dispose() utama widget ini
      // ketika dialog ditutup, atau jika Anda ingin langsung dispose di sini:
      // _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      // Jika setelah dihapus menjadi kosong, tambahkan satu field lagi agar tidak pernah benar-benar kosong
      if (_optionControllers.isEmpty) {
        _optionControllers.add(TextEditingController());
      }
    });
  }

  void _saveOptions() {
    final newChildOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    widget.pageController.updateMappingForParentOption(
        widget.sectionId, widget.questionId, widget.parentOptionValue, newChildOptions);

    Get.back(); // Tutup dialog. dispose() akan dipanggil otomatis.
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Atur Opsi Anak untuk Induk: "${widget.parentOptionValue}"',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 0), // Sesuaikan padding
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // Lebar dialog responsif
        child: Column(
          mainAxisSize: MainAxisSize.min, // Agar tinggi dialog menyesuaikan konten
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Opsi anak yang akan muncul jika jawaban induk adalah \"${widget.parentOptionValue}\":",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 15),
            Flexible( // Membuat ListView scrollable jika kontennya melebihi tinggi dialog
              child: ListView.builder(
                shrinkWrap: true, // Penting di dalam Column MainAxisSize.min
                itemCount: _optionControllers.length,
                itemBuilder: (ctx, index) {
                  return Padding(
                    key: ObjectKey(_optionControllers[index]), // Gunakan ObjectKey untuk stabilitas
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: AdminFormBuilderPage._modernInputDecoration( // Akses helper static
                                labelText: 'Opsi Anak ${index + 1}',
                                isDense: true
                            ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                fillColor: Colors.grey.shade50
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 22),
                          onPressed: () => _removeOptionField(index),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add_circle_rounded, color: AdminFormBuilderPage.accentThemeColor, size: 20),
                label: Text('Tambah Opsi Anak', style: TextStyle(color: AdminFormBuilderPage.accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
                onPressed: _addOptionField,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0)),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12), // Sesuaikan padding
      actions: [
        OutlinedButton(
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          onPressed: () {
            Get.back(); // Menutup dialog akan memicu dispose() pada _EditChildOptionsDialogState
          },
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Simpan Opsi Ini'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminFormBuilderPage.accentThemeColor, foregroundColor: Colors.white),
          onPressed: _saveOptions,
        ),
      ],
    );
  }
}


class _PersistentTextFieldState extends State<_PersistentTextField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_PersistentTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hanya update controller jika nilai awal dari model benar-benar berubah
    // DAN controller saat ini tidak mencerminkan nilai baru tersebut.
    // Ini mencegah kursor melompat jika perubahan berasal dari input pengguna sendiri.
    if (widget.initialValue != oldWidget.initialValue) {
      if (_textController.text != widget.initialValue) {
        _textController.text = widget.initialValue;
        // Atur kursor ke akhir teks setelah pembaruan programatik
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      // Tidak perlu key di sini karena sudah ada di StatefulWidget
      controller: _textController,
      onChanged: widget.onChanged,
      decoration: widget.decoration,
      style: widget.style,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
    );
  }




  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}