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

  InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
    bool isDense = false,
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: neutralLabelColor.withOpacity(0.9), fontSize: isDense ? 14 : 15),
      floatingLabelStyle: const TextStyle(color: accentThemeColor, fontWeight: FontWeight.w500),
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
        borderSide: const BorderSide(color: accentThemeColor, width: 1.8),
      ),
      filled: true,
      fillColor: cardBgColor,
      contentPadding: contentPadding ?? (isDense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
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
    // sectionIndex adalah 0-based
    String romanNumeral = _toRoman(sectionIndex + 1);
    String displaySectionTitle;

    if (section.title.trim().isEmpty) {
      displaySectionTitle = 'Bagian $romanNumeral';
    } else {
      displaySectionTitle = '$romanNumeral ${section.title.trim()}';
    }

    String titleForDialog = section.title.trim().isEmpty ? "Bagian $romanNumeral" : section.title.trim();


    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: ExpansionTile(
        key: ValueKey(section.id), // Use section.id for stable key
        initiallyExpanded: sectionIndex == 0 || section.questions.isNotEmpty || section.title.isNotEmpty,
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
                  decoration: _modernInputDecoration(labelText: 'Judul Bagian (Contoh: Keterangan Rumah Tangga)', hintText: 'Kosongkan untuk hanya menampilkan nomor Romawi', isDense: true),
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
                Column(
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

  Widget _buildQuestionCard(String sectionId, int sectionIndexOverall, FormQuestion question, int questionIndexInSection) {
    // sectionIndexOverall adalah 0-based index dari section
    // questionIndexInSection adalah 0-based index dari pertanyaan di dalam section tersebut
    String displayCode = question.code != null && question.code!.isNotEmpty ? "(${question.code}) " : "";
    String questionTypeString = question.type.toShortString();
    if (questionTypeString.isNotEmpty) {
      questionTypeString = (questionTypeString[0].toUpperCase() + questionTypeString.substring(1));
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
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: question.code ?? '')
              ..selection = TextSelection.fromPosition(TextPosition(offset: (question.code ?? '').length)),
            onChanged: (text) => controller.updateQuestionCode(sectionId, question.id, text),
            decoration: _modernInputDecoration(
                labelText: 'Kode Pertanyaan',
                hintText: 'Otomatis: ${sectionIndexOverall + 1}XX atau sesuaikan',
                isDense: true,
                prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.tag, size: 18, color: Colors.grey.shade500))
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: question.questionText)
              ..selection = TextSelection.fromPosition(TextPosition(offset: question.questionText.length)),
            onChanged: (text) => controller.updateQuestionText(sectionId, question.id, text),
            decoration: _modernInputDecoration(labelText: 'Teks Pertanyaan', isDense: true,
                prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.help_outline_rounded, size: 18, color: Colors.grey.shade500))
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

          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildPredefinedRuleDropdown(sectionId, question),
          ),
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
          if (question.type == QuestionType.dropdown)
            _buildDependentOptionsConfigurator(sectionId, question),
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

  Widget _buildNumberValidationSection(String sectionId, FormQuestion question) {
    bool isValidationNotEmpty = question.validation != null &&
        (question.validation!.minValue != null ||
            question.validation!.maxValue != null);
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Angka',
      [
        TextField(
          controller: TextEditingController(text: question.validation?.minValue?.toString() ?? ''),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, (question.validation ?? ValidationRule()).copyWith(minValue: num.tryParse(value), setMinValueNull: value.isEmpty)); },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.validation?.maxValue?.toString() ?? ''),
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, (question.validation ?? ValidationRule()).copyWith(maxValue: num.tryParse(value), setMaxValueNull: value.isEmpty)); },
        ),
      ],
      initiallyExpanded: isValidationNotEmpty,
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


  Widget _buildDependentOptionsConfigurator(String sectionId, FormQuestion question) {
    final potentialParents = controller.getPotentialParentQuestions(sectionId, question.id);
    FormQuestion? selectedParentQuestion;

    if (question.dependentOptions?.parentQuestionId != null &&
        question.dependentOptions!.parentQuestionId.isNotEmpty) {
      selectedParentQuestion = controller.findQuestionById(question.dependentOptions!.parentQuestionId);
    }

    return _buildExpansionTileForSettings(
      'Opsi Bergantung (Cascading)',
      [
        if (potentialParents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String?>(
              value: question.dependentOptions?.parentQuestionId,
              decoration: _modernInputDecoration(labelText: 'Bergantung pada Pertanyaan (Induk)', isDense: true),
              hint: const Text('Pilih Pertanyaan Induk'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text("Tidak Bergantung / Hapus Ketergantungan", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
              onChanged: (String? newParentId) {
                controller.setParentQuestionForDependency(sectionId, question.id, newParentId);
              },
              isExpanded: true,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Tidak ada pertanyaan lain dengan opsi yang bisa dijadikan induk dalam form ini.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        if (selectedParentQuestion != null && selectedParentQuestion.options.isNotEmpty) ...[
          Text(
            'Atur opsi untuk pertanyaan ini berdasarkan jawaban dari "${selectedParentQuestion.code != null && selectedParentQuestion.code!.isNotEmpty ? selectedParentQuestion.code! + " - " : ""}${selectedParentQuestion.questionText}":',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          if (selectedParentQuestion.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Pertanyaan Induk yang dipilih tidak memiliki opsi yang telah ditentukan.', style: TextStyle(color: Colors.orange.shade700)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedParentQuestion.options.length,
              itemBuilder: (context, index) {
                final parentOption = selectedParentQuestion!.options[index];
                final currentChildOptions = question.dependentOptions?.optionMapping[parentOption] ?? [];
                return _buildParentOptionMappingTile(
                  sectionId,
                  question.id,
                  parentOption,
                  currentChildOptions,
                );
              },
            ),
        ] else if (question.dependentOptions?.parentQuestionId != null && question.dependentOptions!.parentQuestionId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                (selectedParentQuestion == null)
                    ? 'Pertanyaan Induk yang dipilih (ID: ${question.dependentOptions!.parentQuestionId}) tidak ditemukan.'
                    : 'Pertanyaan Induk "${selectedParentQuestion.questionText}" tidak memiliki opsi yang ditentukan.',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 13)
            ),
          )
      ],
      initiallyExpanded: question.dependentOptions != null && question.dependentOptions!.parentQuestionId.isNotEmpty,
    );
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

  void _showEditChildOptionsDialog(
      String sectionId,
      String questionId,
      String parentOptionValue,
      List<String> initialChildOptions
      ) {
    final List<TextEditingController> optionControllers =
    initialChildOptions.map((opt) => TextEditingController(text: opt)).toList();
    final List<TextEditingController> removedControllersForDisposal = [];

    if (optionControllers.isEmpty) {
      optionControllers.add(TextEditingController());
    }

    Get.dialog(
      AlertDialog(
        title: Text('Atur Opsi Anak untuk Induk: "$parentOptionValue"', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: StatefulBuilder(builder: (BuildContext dialogContext, StateSetter setStateDialog) {
          return SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.8,
            height: MediaQuery.of(dialogContext).size.height * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Daftar opsi yang akan muncul jika jawaban pertanyaan induk adalah \"$parentOptionValue\":", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: optionControllers.length,
                    itemBuilder: (ctx, index) {
                      final currentItemController = optionControllers[index];
                      return Padding(
                        key: ValueKey(currentItemController),
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: currentItemController,
                                decoration: _modernInputDecoration(labelText: 'Opsi Anak ${index + 1}', isDense: true)
                                    .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    fillColor: Colors.grey.shade50
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 22),
                              // Di dalam IconButton onPressed untuk menghapus opsi anak:
                              onPressed: () {
                                setStateDialog(() {
                                  FocusScope.of(dialogContext).unfocus();
                                  final removedController = optionControllers.removeAt(index);

                                  // !! PERUBAHAN DI SINI !!
                                  // Coba reset value controller secara eksplisit untuk "memutus" koneksi
                                  // dengan text input service sebelum dipindahkan.
                                  // dispose() seharusnya melakukan ini, tapi kita coba lebih awal.
                                  try {
                                    removedController.value = TextEditingValue.empty; // Mengosongkan teks, seleksi, dan composing region
                                  } catch (e) {
                                    // Tangani jika controller sudah terlanjur disposed karena suatu hal (seharusnya tidak terjadi di sini)
                                    print("Error saat mencoba reset value controller yang akan dihapus: $e");
                                  }

                                  removedControllersForDisposal.add(removedController);
                                });
                              },
                              splashRadius: 18,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: Icon(Icons.add_circle_rounded, color: AdminFormBuilderPage.accentThemeColor, size: 20),
                    label: Text('Tambah Opsi Anak Lagi', style: TextStyle(color: AdminFormBuilderPage.accentThemeColor, fontSize: 14)),
                    onPressed: () {
                      setStateDialog(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Get.back();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                for (var c in optionControllers) { c.dispose(); }
                for (var c in removedControllersForDisposal) { c.dispose(); }
              });
            },
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Simpan Opsi Ini'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminFormBuilderPage.accentThemeColor, foregroundColor: Colors.white),
            // Ini adalah bagian onPressed untuk ElevatedButton.icon (Tombol "Simpan Opsi Ini")
// di dalam _showEditChildOptionsDialog

            onPressed: () {
              // 1. Ambil data opsi anak yang baru dari controller yang masih aktif
              final newChildOptions = optionControllers
                  .map((c) => c.text.trim())
                  .where((text) => text.isNotEmpty) // Filter opsi yang kosong setelah di-trim
                  .toList();

              // 2. Panggil method pada controller utama Anda untuk menyimpan/memperbarui mapping opsi
              // Pastikan 'controller' di sini adalah instance AdminFormBuilderController yang benar
              controller.updateMappingForParentOption(sectionId, questionId, parentOptionValue, newChildOptions);

              // 3. Dispose SEMUA TextEditingController (baik yang masih di optionControllers
              //    maupun yang sudah dipindahkan ke removedControllersForDisposal)
              //    SECARA LANGSUNG sebelum memanggil Get.back().
              try {
                // Dispose controller yang masih terkait dengan TextField yang mungkin masih ada di UI
                // (meskipun akan segera ditutup)
                for (var c in optionControllers) {
                  c.dispose();
                }

                // Dispose controller yang TextField-nya sudah dihapus dari UI sebelumnya
                for (var c in removedControllersForDisposal) {
                  c.dispose();
                }
              } catch (e) {
                // Tambahkan logging jika ada error saat proses dispose, meskipun jarang terjadi
                // jika controller belum di-dispose sebelumnya.
                print("Error saat melakukan dispose pada TextEditingControllers di tombol Simpan: $e");
              }

              // 4. (Opsional tapi disarankan) Bersihkan list untuk menghindari referensi gantung,
              //    meskipun dialog akan ditutup dan variabel lokal ini akan hilang.
              optionControllers.clear();
              removedControllersForDisposal.clear();

              // 5. Tutup dialog
              Get.back();

              // Tidak ada lagi WidgetsBinding.instance.addPostFrameCallback untuk disposal di sini
              // karena sudah dilakukan secara langsung di atas.
            },
          ),
        ],
      ),
      barrierDismissible: false,
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
                        // default: iconData = Icons.help_rounded; typeName = "Lainnya"; // Should not happen with enum
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