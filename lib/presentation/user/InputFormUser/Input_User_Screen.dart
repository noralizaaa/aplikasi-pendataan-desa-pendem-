import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:get/get.dart';
import '../../../infrastructure/navigation/routes.dart';
import 'input_user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk QuestionType, dll.
import 'package:intl/intl.dart';

class InputUserScreen extends GetView<InputUserController> {
  const InputUserScreen({Key? key}) : super(key: key);

  // Definisi Warna (Anda sudah punya ini)
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color cardBackgroundColor = Colors.white;
  static Color get titleTextColor => Colors.grey.shade800;
  static Color get subtitleTextColor => Colors.grey.shade600;
  static Color get mandatoryAsteriskColor => Colors.red.shade700;

  String _toRoman(int number) {
    if (number < 1 || number > 3999) return number.toString();
    const List<String> romanNumerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
    const List<int> values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    String result = "";
    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        result += romanNumerals[i];
        number -= values[i];
      }
    }
    return result;
  }

  InputDecoration _modernInputDecoration(BuildContext context, {
    String? hintText,
    String? labelText,
    Widget? suffixIcon,
    bool isDense = false, // isDense tidak digunakan lagi di sini, styling dari contentPadding
  }) {
    return InputDecoration(
      hintText: hintText ?? "Masukkan jawaban...",
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      floatingLabelStyle: const TextStyle(color: accentHeaderColor, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accentHeaderColor, width: 1.8), borderRadius: BorderRadius.circular(10.0)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400, width: 1.2), borderRadius: BorderRadius.circular(10.0)),
      focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade700, width: 1.8), borderRadius: BorderRadius.circular(10.0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Dibuat konsisten
      filled: true,
      fillColor: cardBackgroundColor,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.loadedForm.value?.title ?? 'Mengisi Form',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        )),
        backgroundColor: accentHeaderColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          Obx(() => (controller.isLoading.value && controller.loadedForm.value == null)
              ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Kirim Form',
            onPressed: controller.isLoading.value ? null : () {
              Get.defaultDialog(
                title: "Konfirmasi Pengiriman",
                titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                middleText: "Anda yakin ingin mengirim jawaban form ini?",
                middleTextStyle: const TextStyle(fontSize: 15),
                textConfirm: "Ya, Kirim",
                textCancel: "Batal",
                confirmTextColor: Colors.white,
                buttonColor: accentHeaderColor,
                cancelTextColor: Colors.grey.shade700,
                onConfirm: () {
                  Get.toNamed(AppRoutes.LIST_SUBMISSION_FORM); // Menutup dialog
                  print("AppBar Action: Tombol 'Ya, Kirim' ditekan. Akan memanggil controller.submitForm()"); // DEBUG
                  controller.submitForm();
                },
                radius: 10,
              );
            },
          ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.loadedForm.value == null) {
          return const Center(child: CircularProgressIndicator(color: accentHeaderColor));
        }
        if (controller.errorMessage.value.isNotEmpty && controller.loadedForm.value == null) {
          final currentErrorMessage = controller.errorMessage.value;
          // Cek apakah error disebabkan oleh masalah fundamental dengan argumen ID
          bool isFatalArgumentError = currentErrorMessage.contains("Argumen ID Form tidak ditemukan") ||
              currentErrorMessage.contains("Tipe argumen ID Form tidak valid") ||
              currentErrorMessage.contains("ID Form yang diterima kosong") ||
              currentErrorMessage.contains("ID Form kosong atau tidak valid"); // Termasuk pesan dari guard fetchFormStructure

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 50),
                  const SizedBox(height: 10),
                  Text(currentErrorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (!isFatalArgumentError) // Hanya tampilkan "Coba Lagi Memuat" jika errornya bukan karena ID form yang salah dari awal
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Coba Lagi Memuat Form"),
                      onPressed: () => controller.fetchFormStructure(),
                      style: ElevatedButton.styleFrom(backgroundColor: accentHeaderColor, foregroundColor: Colors.white),
                    )
                  else // Jika error karena ID, sarankan untuk kembali
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text("Kembali"),
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600, foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),
          );
        }
        if (controller.loadedForm.value == null) {
          return const Center(child: Text("Form tidak tersedia atau gagal dimuat."));
        }

        final form = controller.loadedForm.value!;

        return Form(
          key: controller.formKey,
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 70.0),
                itemCount: form.sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(form.title,
                                style: Get.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: accentHeaderColor,
                                    fontSize: 22
                                )),
                            if (form.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(form.description,
                                  style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700, height: 1.4)),
                            ],
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300, thickness: 0.8),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900, fontStyle: FontStyle.italic, height: 1.3),
                                children: <TextSpan>[
                                  const TextSpan(text: "Harap isi semua pertanyaan dengan benar dan jujur. Pertanyaan dengan tanda "),
                                  TextSpan(text: '*', style: TextStyle(color: mandatoryAsteriskColor, fontWeight: FontWeight.bold)),
                                  const TextSpan(text: " wajib diisi."),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final section = form.sections[index - 1];
                  final sectionIndex = index - 1;
                  String displaySectionTitle = section.title.trim().isEmpty
                      ? 'Bagian ${_toRoman(sectionIndex + 1)}'
                      : '${_toRoman(sectionIndex + 1)}: ${section.title.trim()}';

                  return Card(
                    elevation: 1.8,
                    margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displaySectionTitle,
                              style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: titleTextColor, fontSize: 19)),
                          if (section.description != null && section.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(section.description!,
                                style: Get.textTheme.bodySmall?.copyWith(color: subtitleTextColor, fontSize: 13, height: 1.4)),
                          ],
                          const SizedBox(height: 20),
                          ..._buildQuestionsForSection(context, section),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Obx(() {
                if (controller.isLoading.value && controller.loadedForm.value != null) {
                  return Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildQuestionsForSection(BuildContext context, FormSection section) {
    List<Widget> questionWidgets = [];
    for (int i = 0; i < section.questions.length; i++) {
      final question = section.questions[i];
      questionWidgets.add(
          Obx(() { // Obx untuk setiap pertanyaan agar visibilitasnya reaktif
            final bool isVisible = controller.questionVisibility[question.id] ?? true;
            if (!isVisible) return const SizedBox.shrink();

            if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionLabel(question),
                    const SizedBox(height: 10),
                    _buildQuestionInput(context, question, keyPrefix: question.id),
                  ],
                ),
              );
            } else if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
              final groupTag = question.belongsToGroupTag!;
              // Gunakan Obx di sini untuk mereaksikan perubahan repeatableGroupCounts
              final int repeatCount = controller.repeatableGroupCounts[groupTag] ?? 0;

              if (repeatCount == 0) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(repeatCount, (repeatIdx) {
                  String itemTitle = "[Data ${question.code != null && question.code!.isNotEmpty ? question.code : ''} ke-${repeatIdx + 1}] ${question.questionText}";
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100, width: 0.8)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuestionLabel(question, itemTitleOverride: itemTitle, isGroupedItem: true),
                          const SizedBox(height: 10),
                          _buildQuestionInput(context, question, repeatIndex: repeatIdx, keyPrefix: "${question.id}_${groupTag}_$repeatIdx"),
                        ],
                      ),
                    ),
                  );
                }),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionLabel(question),
                    const SizedBox(height: 10),
                    _buildQuestionInput(context, question, keyPrefix: question.id),
                  ],
                ),
              );
            }
          })
      );
      if (i < section.questions.length - 1) { // Cek jika bukan pertanyaan terakhir
        questionWidgets.add(Divider(height: 32, thickness: 0.7, color: Colors.grey.shade300));
      }
    }
    return questionWidgets;
  }

  Widget _buildQuestionLabel(FormQuestion question, {String? itemTitleOverride, bool isGroupedItem = false}) {
    final String labelText = itemTitleOverride ?? question.questionText;
    // Ambil deskripsi dari objek question
    final String? questionDescription = question.description;

    return Column( // Bungkus dengan Column agar bisa menambahkan deskripsi di bawahnya
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Get.textTheme.bodyLarge?.copyWith(
                      fontSize: isGroupedItem ? 14.5 : 15.5,
                      fontWeight: FontWeight.w500,
                      color: titleTextColor, // Pastikan titleTextColor terdefinisi
                      height: 1.4
                  ),
                  children: [
                    TextSpan(text: labelText),
                    if (question.isRequired)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: mandatoryAsteriskColor, fontSize: isGroupedItem ? 15 : 16, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            // Tampilkan kode hanya jika bukan item dalam grup (untuk menghindari duplikasi jika kode sudah ada di itemTitleOverride)
            if (question.code != null && question.code!.isNotEmpty && !isGroupedItem) ...[
              const SizedBox(width: 8),
              Text("(${question.code})", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
        // --- UNTUK MENAMPILKAN DESKRIPSI ---
        if (questionDescription != null && questionDescription.isNotEmpty) ...[
          const SizedBox(height: 4), // Spasi antara judul pertanyaan dan deskripsi
          Padding(
            // Anda bisa atur padding kiri jika ingin deskripsi sedikit menjorok
            // padding: const EdgeInsets.only(left: isGroupedItem ? 0 : 8.0),
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              questionDescription,
              style: TextStyle(
                fontSize: isGroupedItem ? 12.5 : 13.5, // Font lebih kecil untuk deskripsi
                color: subtitleTextColor?.withOpacity(0.9), // Warna lebih lembut, pastikan subtitleTextColor terdefinisi
                fontStyle: FontStyle.italic, // Gaya italic untuk membedakan
                height: 1.3,
              ),
            ),
          ),
        ],
        // --- AKHIR BLOK DESKRIPSI ---
      ],
    );
  }

  Widget _buildQuestionInput(BuildContext context, FormQuestion question, {int? repeatIndex, required String keyPrefix}) {
    // Obx di sini memastikan bahwa setiap input field individu (seperti Dropdown atau Checkbox)
    // dapat merefleksikan perubahan nilainya dari controller secara reaktif.
    return Obx(() {
      dynamic initialValue;
      Function(dynamic) onChangedCallback;
      // Key unik sangat penting untuk stateful widgets di dalam list/repeatable group
      // Menambahkan tipe pertanyaan ke key untuk lebih memastikan keunikan jika ID sama tapi tipe beda (jarang terjadi)
      String fieldKeyId = "${keyPrefix}_${question.type.toShortString()}";

      if (repeatIndex != null) { // Ini adalah pertanyaan di dalam grup yang berulang
        // Pastikan map untuk question.id ada di repeatableGroupAnswers
        if (!controller.repeatableGroupAnswers.containsKey(question.id)) {
          controller.repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        // Pastikan map untuk repeatIndex ada di dalam map pertanyaan
        if (!controller.repeatableGroupAnswers[question.id]!.containsKey(repeatIndex)) {
          // Inisialisasi nilai default berdasarkan tipe pertanyaan untuk slot baru ini
          if (question.type == QuestionType.checkboxes) {
            controller.repeatableGroupAnswers[question.id]![repeatIndex] = <String>[];
          } else if (question.type == QuestionType.gridNumeric) {
            controller.repeatableGroupAnswers[question.id]![repeatIndex] = <String, Map<String, Map<String, num?>>>{};
          } else if (question.type == QuestionType.dropdown) {
            controller.repeatableGroupAnswers[question.id]![repeatIndex] = null;
          } else { // text, paragraph, number, date
            controller.repeatableGroupAnswers[question.id]![repeatIndex] = '';
          }
        }
        initialValue = controller.repeatableGroupAnswers[question.id]![repeatIndex];
        onChangedCallback = (value) => controller.updateRepeatableGroupAnswer(question.id, repeatIndex, value);
      } else { // Ini adalah pertanyaan reguler (bukan bagian dari grup berulang yang dikontrol)
        // Pastikan entri ada di userAnswers dengan nilai default yang sesuai jika belum
        if (!controller.userAnswers.containsKey(question.id)) {
          if (question.type == QuestionType.checkboxes) {
            controller.userAnswers[question.id] = <String>[];
          } else if (question.type == QuestionType.gridNumeric) {
            controller.userAnswers[question.id] = <String, Map<String, Map<String, num?>>>{};
          } else if (question.type == QuestionType.dropdown) {
            controller.userAnswers[question.id] = null;
          } else { // text, paragraph, number, date
            controller.userAnswers[question.id] = '';
          }
        }
        initialValue = controller.userAnswers[question.id];
        onChangedCallback = (value) => controller.updateUserAnswer(question.id, value);
      }

      // --- VALIDATOR FUNCTION ---
      String? validatorFunction(dynamic val) {
        // Ambil definisi pertanyaan terbaru dari controller untuk validasi
        // Ini penting jika definisi pertanyaan (misal, isRequired) bisa berubah secara dinamis
        final FormQuestion currentQuestionState = controller.findQuestionById(question.id) ?? question;
        final ValidationRule? rule = currentQuestionState.validation; // Rule bisa null sesuai model Anda
        final String questionLabel = currentQuestionState.questionText.isNotEmpty ? currentQuestionState.questionText : "Isian ini";

        String effectiveValueString = "";
        bool isEmptyAnswer = true;

        if (val is String) {
          effectiveValueString = val.trim();
          isEmptyAnswer = effectiveValueString.isEmpty;
        } else if (val is List) {
          isEmptyAnswer = val.isEmpty;
        } else if (val == null) {
          isEmptyAnswer = true;
        } else if (val is Map) { // Untuk gridNumeric
          isEmptyAnswer = (val).values.every((colVal) => (colVal as Map).values.every((subColVal) => (subColVal as Map).values.every((cellVal) => cellVal == null || cellVal.toString().trim().isEmpty)));
        }

        if (currentQuestionState.isRequired && isEmptyAnswer) {
          return '$questionLabel wajib diisi.';
        }
        // Jika tidak wajib dan memang kosong, lolos validasi dasar ini.
        // Validasi lebih lanjut (min/max, regex, dll.) hanya jika ada isian.
        if (isEmptyAnswer && !currentQuestionState.isRequired) return null;

        if (rule != null) { // Hanya proses jika rule ada
          if (val is String && val.isNotEmpty) { // Validasi string hanya jika tidak kosong
            if (rule.minLength != null && effectiveValueString.length < rule.minLength!) return '$questionLabel minimal ${rule.minLength} karakter.';
            if (rule.maxLength != null && effectiveValueString.length > rule.maxLength!) return '$questionLabel maksimal ${rule.maxLength} karakter.';
            if (rule.regex != null && rule.regex!.isNotEmpty && !RegExp(rule.regex!).hasMatch(effectiveValueString)) return 'Format $questionLabel tidak sesuai.';
            if (rule.predefinedRule == 'nik' && !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) return 'NIK harus 16 digit angka.';
            if (rule.predefinedRule == 'email' && !GetUtils.isEmail(effectiveValueString)) return 'Format email tidak valid.';
            if (rule.predefinedRule == 'numbersOnly' && !GetUtils.isNumericOnly(effectiveValueString)) return '$questionLabel hanya boleh berisi angka.';
            // Tambahkan predefined rule lain jika perlu
          }

          if (currentQuestionState.type == QuestionType.number) {
            // Untuk TextFormField angka, 'val' akan selalu String.
            num? numAnswer = num.tryParse(effectiveValueString);
            if (numAnswer == null && effectiveValueString.isNotEmpty) return '$questionLabel harus berupa angka.';
            if (numAnswer != null) {
              if (rule.minValue != null && numAnswer < rule.minValue!) return '$questionLabel minimal ${rule.minValue}.';
              if (rule.maxValue != null && numAnswer > rule.maxValue!) return '$questionLabel maksimal ${rule.maxValue}.';

              // --- VALIDASI ANTAR PERTANYAAN (CONTOH HARDCODE) ---
              // Model ValidationRule Anda tidak mendukung comparisonOperator, jadi ini hardcode
              if (currentQuestionState.code == "203" || currentQuestionState.code == "204") { // Ganti dengan kode aktual
                final artQuestion = controller.findQuestionByCode("112"); // Ganti dengan kode aktual Jumlah ART
                if (artQuestion != null) {
                  final artCountValueDynamic = controller.getAnswerByQuestionId(artQuestion.id);
                  num? artCount;
                  if (artCountValueDynamic is num) artCount = artCountValueDynamic;
                  else if (artCountValueDynamic is String) artCount = num.tryParse(artCountValueDynamic);

                  if (artCount != null && numAnswer > artCount) {
                    return '$questionLabel (${numAnswer.toInt()}) tidak boleh melebihi ${artQuestion.questionText} ($artCount).';
                  }
                }
              }
              // --- AKHIR CONTOH HARDCODE ---
            }
          }
        }
        return null;
      }
      // --- AKHIR VALIDATOR ---

      switch (question.type) {
        case QuestionType.text:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            decoration: _modernInputDecoration(context, hintText: "Jawaban teks singkat"),
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.paragraph:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            decoration: _modernInputDecoration(context, hintText: "Jawaban teks panjang"),
            maxLines: 3, minLines: 2,
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.number:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue?.toString() ?? '',
            decoration: _modernInputDecoration(context, hintText: "Masukkan angka"),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.date:
          String displayDate = '';
          if (initialValue is DateTime) displayDate = DateFormat('dd/MM/yyyy').format(initialValue);
          else if (initialValue is String) displayDate = initialValue;

          return TextFormField(
            key: ValueKey(fieldKeyId + displayDate),
            readOnly: true,
            controller: TextEditingController(text: displayDate),
            decoration: _modernInputDecoration(context, hintText: "Pilih tanggal",
                suffixIcon: Icon(Icons.calendar_today_rounded, color: accentHeaderColor)
            ),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime initialDatePickerDate = DateTime.now();
              if (initialValue is DateTime) { initialDatePickerDate = initialValue; }
              else if (initialValue is String && initialValue.isNotEmpty) {
                try { initialDatePickerDate = DateFormat('dd/MM/yyyy').parse(initialValue); } catch (e) { /* biarkan default */ }
              }
              DateTime? pickedDate = await showDatePicker(
                  context: context, initialDate: initialDatePickerDate,
                  firstDate: DateTime(1900), lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: accentHeaderColor,
                              onPrimary: Colors.white,
                              onSurface: Colors.black87),
                          textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(foregroundColor: accentHeaderColor))),
                      child: child!,
                    );
                  });
              if (pickedDate != null) {
                onChangedCallback(DateFormat('dd/MM/yyyy').format(pickedDate));
              }
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.multipleChoice:
          String? currentGroupValue = initialValue as String?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: question.options.map((option) {
              return RadioListTile<String>(
                key: ValueKey("${fieldKeyId}_${option}_radio"),
                title: Text(option, style: const TextStyle(fontSize: 15.0)),
                value: option,
                groupValue: currentGroupValue,
                onChanged: (String? value) { if (value != null) onChangedCallback(value); },
                activeColor: accentHeaderColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          );
        case QuestionType.checkboxes:
          List<String> currentSelectedValues = List<String>.from(initialValue as List<dynamic>? ?? []);
          return FormField<List<String>>(
            key: ValueKey(fieldKeyId + "_checkbox_formfield"),
            initialValue: currentSelectedValues,
            validator: (value) {
              if (question.isRequired && (value == null || value.isEmpty)) {
                return '${question.questionText.isNotEmpty ? question.questionText : "Pilihan ini"} wajib dipilih (minimal satu).';
              }
              return validatorFunction(value);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<List<String>> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...question.options.map((option) {
                    return CheckboxListTile(
                      key: ValueKey("${fieldKeyId}_${option}_checkbox"),
                      title: Text(option, style: const TextStyle(fontSize: 15.0)),
                      value: field.value?.contains(option) ?? false,
                      onChanged: (bool? selected) {
                        final latestSelectedValues = List<String>.from(field.value ?? []);
                        if (selected == true) {
                          if (!latestSelectedValues.contains(option)) latestSelectedValues.add(option);
                        } else {
                          latestSelectedValues.remove(option);
                        }
                        onChangedCallback(latestSelectedValues);
                        field.didChange(latestSelectedValues);
                      },
                      activeColor: accentHeaderColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 0.0),
                      child: Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ),
                ],
              );
            },
          );
        case QuestionType.dropdown:
          List<String> optionsToDisplay = List<String>.from(question.options);
          bool isDependent = question.dependentOptions != null &&
              question.dependentOptions!.parentQuestionId.isNotEmpty;
          String? parentAnswer;

          if (isDependent) {
            final parentQuestionId = question.dependentOptions!.parentQuestionId;
            parentAnswer = controller.userAnswers[parentQuestionId] as String?;

            if (parentAnswer != null && parentAnswer.isNotEmpty) {
              optionsToDisplay = question.dependentOptions!.optionMapping[parentAnswer] ?? [];
            } else {
              optionsToDisplay = [];
            }
          }

          String? effectiveInitialValue = initialValue as String?;
          if (effectiveInitialValue != null && !optionsToDisplay.contains(effectiveInitialValue)) {
            effectiveInitialValue = null;
            // Jika nilai lama tidak valid lagi karena parent berubah, panggil onChangedCallback dengan null
            // agar controller bisa meresetnya. Ini penting untuk konsistensi data.
            // Lakukan ini setelah build jika diperlukan, atau biarkan controller yang handle saat parent berubah.
            // Untuk saat ini, kita set null untuk tampilan, controller akan mereset di _resetDependentChildrenAnswers
          }

          if (isDependent && parentAnswer == null && optionsToDisplay.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pilih jawaban untuk pertanyaan induk (${question.dependentOptions!.parentQuestionId}) terlebih dahulu.",
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }
          if (isDependent && parentAnswer != null && optionsToDisplay.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Tidak ada opsi RW yang tersedia untuk Dusun '$parentAnswer'.",
                style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }

          return DropdownButtonFormField<String>(
            key: ValueKey(fieldKeyId + (effectiveInitialValue ?? "_nullVal_") + optionsToDisplay.join('_')), // Key lebih unik
            value: effectiveInitialValue,
            decoration: _modernInputDecoration(context,
                labelText: (optionsToDisplay.isEmpty && !isDependent && question.options.isEmpty)
                    ? "Tidak ada opsi terdefinisi"
                    : "Pilih salah satu"),
            items: (optionsToDisplay.isEmpty && !isDependent && question.options.isEmpty)
                ? [ const DropdownMenuItem(value: null, enabled: false, child: Text("Tidak ada opsi", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))]
                : optionsToDisplay.map((option) {
              return DropdownMenuItem<String>(value: option, child: Text(option, style: const TextStyle(fontSize: 15)));
            }).toList(),
            onChanged: (optionsToDisplay.isEmpty && isDependent && parentAnswer != null)
                ? null // Nonaktifkan jika dependent, parent sudah dipilih, tapi tidak ada opsi anak
                : (String? newValue) {
              if (newValue != null) onChangedCallback(newValue);
            },
            isExpanded: true,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hint: (optionsToDisplay.isEmpty && isDependent && parentAnswer != null)
                ? const Text("Tidak ada opsi untuk pilihan induk ini")
                : null,
          );
        case QuestionType.gridNumeric:
          Map<String, Map<String, Map<String, num?>>> gridAnswers = {};
          if (initialValue is Map) {
            try {
              gridAnswers = Map<String, Map<String, Map<String, num?>>>.fromEntries(
                  (initialValue as Map<dynamic,dynamic>).entries.map((rowEntry) {
                    var colMap = rowEntry.value;
                    if (colMap is! Map) colMap = {};

                    return MapEntry(
                        rowEntry.key.toString(),
                        Map<String, Map<String, num?>>.fromEntries(
                            (colMap as Map<dynamic,dynamic>).entries.map((colEntry) {
                              var subColMap = colEntry.value;
                              if (subColMap is! Map) subColMap = {};

                              return MapEntry(
                                  colEntry.key.toString(),
                                  Map<String, num?>.fromEntries(
                                      (subColMap as Map<dynamic,dynamic>).entries.map((subColEntry) =>
                                          MapEntry(subColEntry.key.toString(), subColEntry.value as num?)
                                      )
                                  )
                              );
                            })
                        )
                    );
                  })
              );
            } catch(e) { print("Error casting gridAnswers for $fieldKeyId: $e. InitialValue: $initialValue"); }
          }

          if (question.gridColumnLabels.isEmpty || question.gridSubColumnLabels.isEmpty) {
            return Text("Grid Numerik: Konfigurasi label kolom/sub-kolom belum lengkap.", style: TextStyle(color: Colors.red.shade700));
          }
          List<String> rows = question.gridRowLabels.isNotEmpty ? question.gridRowLabels : [""];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows.map((rowLabel) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rowLabel.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(rowLabel, style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: titleTextColor)),
                      ),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                        defaultColumnWidth: const MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(65)),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              const TableCell(child: Padding(padding: EdgeInsets.all(6.0), child: Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                              ...question.gridColumnLabels.map((colLabel) => TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0), child: Text(colLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              )).toList(),
                            ],
                          ),
                          ...question.gridSubColumnLabels.map((subColLabel) {
                            return TableRow(
                              children: [
                                TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0), child: Text(subColLabel, style: const TextStyle(fontSize: 12)))),
                                ...question.gridColumnLabels.map((colLabel) {
                                  num? cellValue = gridAnswers[rowLabel]?[colLabel]?[subColLabel];
                                  String cellKeyIdGrid = "${fieldKeyId}_grid_${rowLabel}_${colLabel}_$subColLabel";
                                  return TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: TextFormField(
                                        key: ValueKey(cellKeyIdGrid),
                                        initialValue: cellValue?.toString() ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
                                          isDense: true,
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')), // Izinkan angka, titik, dan koma
                                        ],
                                        onChanged: (value) {
                                          // Kirim nilai dengan koma jika pengguna mengetik koma
                                          controller.updateGridAnswer(question.id, repeatIndex, rowLabel, colLabel, subColLabel, value);
                                        },
                                        validator: (cellValueString) {
                                          if (question.isRequired && (cellValueString == null || cellValueString.isEmpty)) {
                                            // return 'Wajib'; // Terlalu kecil untuk pesan error
                                          }
                                          if (cellValueString != null && cellValueString.isNotEmpty && num.tryParse(cellValueString) == null) {
                                            return 'X'; // Error singkat
                                          }
                                          return null;
                                        },
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        default:
          return Text("Tipe pertanyaan tidak didukung: ${question.type}");
      }
    });
  }
}