import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './input_user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk QuestionType
import 'package:intl/intl.dart';

class InputUserScreen extends GetView<InputUserController> {
  const InputUserScreen({Key? key}) : super(key: key);

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color cardBackgroundColor = Colors.white;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(
            controller.loadedForm.value?.title ?? 'Mengisi Form',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))),
        backgroundColor: accentHeaderColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        actions: [
          Obx(() => controller.isLoading.value &&
              controller.loadedForm.value == null
              ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)))
              : IconButton(
            icon: const Icon(Icons.save_alt_rounded),
            tooltip: 'Kirim Form',
            onPressed: controller.isLoading.value
                ? null
                : () {
              Get.defaultDialog(
                  title: "Konfirmasi Pengiriman",
                  middleText:
                  "Anda yakin ingin mengirim jawaban form ini?",
                  textConfirm: "Ya, Kirim",
                  textCancel: "Batal",
                  confirmTextColor: Colors.white,
                  buttonColor: accentHeaderColor,
                  onConfirm: () {
                    Get.back();
                    controller.submitForm();
                  });
            },
          ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.loadedForm.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: accentHeaderColor));
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.loadedForm.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (controller.loadedForm.value == null) {
          return const Center(
              child: Text("Form tidak tersedia atau gagal dimuat."));
        }

        final form = controller.loadedForm.value!;

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: form.sections.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(form.title,
                              style: Get.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: accentHeaderColor)),
                          if (form.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(form.description,
                                style: Get.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade700)),
                          ],
                          const SizedBox(height: 10),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text(
                              "Harap isi semua pertanyaan dengan benar dan jujur. Pertanyaan dengan tanda (*) wajib diisi.",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                  fontStyle: FontStyle.italic)),
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
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displaySectionTitle,
                            style: Get.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        if (section.description != null &&
                            section.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(section.description!,
                              style: Get.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600)),
                        ],
                        const SizedBox(height: 16),
                        ...section.questions.map((question) {
                          return Obx(() {
                            final bool isVisible =
                                controller.questionVisibility[question.id] ??
                                    true;
                            if (!isVisible) return const SizedBox.shrink();

                            if (question.belongsToGroupTag != null &&
                                question.belongsToGroupTag!.isNotEmpty) {
                              final groupTag = question.belongsToGroupTag!;
                              final int repeatCount =
                                  controller.repeatableGroupCounts[groupTag] ?? 0;

                              if (repeatCount == 0 && !question.isRepeatableGroupController ) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(repeatCount, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0.0, top: 8.0, bottom: 8.0),
                                    child: Card(
                                      elevation: 0.5,
                                      color: Colors.grey.shade50,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: Colors.grey.shade200)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "[Data ke-${i + 1}] ${question.questionText}${question.isRequired ? '*' : ''}",
                                              style: Get.textTheme.titleMedium
                                                  ?.copyWith(
                                                  fontSize: 15,
                                                  fontWeight:
                                                  FontWeight.w500),
                                            ),
                                            if (question.code != null &&
                                                question.code!.isNotEmpty)
                                              Text("(${question.code})",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade500)),
                                            const SizedBox(height: 8),
                                            _buildQuestionInput(context, question, repeatIndex: i),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            } else {
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(
                                              "${question.questionText}${question.isRequired ? '*' : ''}",
                                              style: Get.textTheme.titleMedium
                                                  ?.copyWith(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w500))),
                                      if (question.code != null &&
                                          question.code!.isNotEmpty)
                                        Text(" (${question.code}) ",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600)),
                                    ]),
                                    const SizedBox(height: 8),
                                    _buildQuestionInput(context, question),
                                  ],
                                ),
                              );
                            }
                          });
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
            Obx(() {
              if (controller.isLoading.value &&
                  controller.loadedForm.value != null) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      }),
    );
  }

  Widget _buildQuestionInput(BuildContext context, FormQuestion question,
      {int? repeatIndex}) {
    return Obx(() {
      dynamic initialValue;
      Function(dynamic) onChangedCallback;

      if (repeatIndex != null) {
        if (!controller.repeatableGroupAnswers.containsKey(question.id)) {
          controller.repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.type == QuestionType.checkboxes &&
            controller.repeatableGroupAnswers[question.id]![repeatIndex] == null) {
          controller.repeatableGroupAnswers[question.id]![repeatIndex] = <String>[];
        }
        initialValue = controller.repeatableGroupAnswers[question.id]?[repeatIndex];
        onChangedCallback = (value) => controller.updateRepeatableGroupAnswer(question.id, repeatIndex, value);
      } else {
        if (question.type == QuestionType.checkboxes && controller.userAnswers[question.id] == null) {
          controller.userAnswers[question.id] = <String>[];
        }
        initialValue = controller.userAnswers[question.id];
        onChangedCallback = (value) => controller.updateUserAnswer(question.id, value);
      }

      InputDecoration modernInputDecoration(
          {String? labelText, String? hintText}) {
        return InputDecoration(
            labelText: labelText,
            hintText: hintText ?? "Masukkan jawaban...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accentHeaderColor, width: 1.5),
                borderRadius: BorderRadius.circular(8.0)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: cardBackgroundColor);
      }

      switch (question.type) {
        case QuestionType.text:
          return TextFormField(
            key: ValueKey("${question.id}${repeatIndex ?? ''}_text"),
            initialValue: initialValue as String?,
            decoration: modernInputDecoration(hintText: "Jawaban teks singkat"),
            onChanged: onChangedCallback,
          );
        case QuestionType.paragraph:
          return TextFormField(
            key: ValueKey("${question.id}${repeatIndex ?? ''}_paragraph"),
            initialValue: initialValue as String?,
            decoration: modernInputDecoration(hintText: "Jawaban teks panjang"),
            maxLines: 3,
            onChanged: onChangedCallback,
          );
        case QuestionType.number:
          return TextFormField(
            key: ValueKey("${question.id}${repeatIndex ?? ''}_number"),
            initialValue: initialValue?.toString() ?? '',
            decoration: modernInputDecoration(hintText: "Masukkan angka"),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              onChangedCallback(value);
            },
          );
        case QuestionType.date:
          String displayDate = '';
          if (initialValue is DateTime) {
            displayDate = DateFormat('dd/MM/yyyy').format(initialValue);
          } else if (initialValue is String) {
            displayDate = initialValue;
          }
          return TextFormField(
            key: ValueKey(
                "${question.id}${repeatIndex ?? ''}_date_$displayDate"),
            readOnly: true,
            controller: TextEditingController(text: displayDate),
            decoration: modernInputDecoration(hintText: "Pilih tanggal")
                .copyWith(
                suffixIcon:
                Icon(Icons.calendar_today, color: accentHeaderColor)),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime initialDatePickerDate = DateTime.now();
              if (initialValue is DateTime) {
                initialDatePickerDate = initialValue;
              } else if (initialValue is String && initialValue.isNotEmpty) {
                try {
                  initialDatePickerDate = DateFormat('dd/MM/yyyy').parse(initialValue);
                } catch (e) { /* fallback */ }
              }

              DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDatePickerDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: accentHeaderColor,
                              onPrimary: Colors.white,
                              onSurface: Colors.black),
                          textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                  foregroundColor: accentHeaderColor))),
                      child: child!,
                    );
                  });
              if (pickedDate != null) {
                onChangedCallback(DateFormat('dd/MM/yyyy').format(pickedDate));
              }
            },
          );
        case QuestionType.multipleChoice:
          String? currentGroupValue = initialValue as String?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: question.options.map((option) {
              return RadioListTile<String>(
                key: ValueKey(
                    "${question.id}${repeatIndex ?? ''}_${option}_radio"),
                title: Text(option),
                value: option,
                groupValue: currentGroupValue,
                onChanged: (String? value) {
                  if (value != null) onChangedCallback(value);
                },
                activeColor: accentHeaderColor,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          );
        case QuestionType.checkboxes:
          List<String> currentSelectedValues = List<String>.from(initialValue as List<dynamic>? ?? []);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: question.options.map((option) {
              return CheckboxListTile(
                key: ValueKey(
                    "${question.id}${repeatIndex ?? ''}_${option}_checkbox"),
                title: Text(option),
                value: currentSelectedValues.contains(option),
                onChanged: (bool? selected) {
                  final latestSelectedValues = List<String>.from(currentSelectedValues);
                  if (selected == true) {
                    if (!latestSelectedValues.contains(option)) {
                      latestSelectedValues.add(option);
                    }
                  } else {
                    latestSelectedValues.remove(option);
                  }
                  onChangedCallback(latestSelectedValues);
                },
                activeColor: accentHeaderColor,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          );
        case QuestionType.dropdown:
        // --- PERBAIKAN UNTUK DROPDOWN VALUE ---
          String? effectiveInitialValue;
          if (initialValue is String) { // Pastikan initialValue adalah String
            if (question.options.contains(initialValue)) { // Dan ada di dalam options
              effectiveInitialValue = initialValue;
            }
          }
          // --- AKHIR PERBAIKAN ---
          return DropdownButtonFormField<String>(
            key: ValueKey("${question.id}${repeatIndex ?? ''}_dropdown"),
            value: effectiveInitialValue, // Gunakan nilai yang sudah valid atau null
            decoration: modernInputDecoration(labelText: "Pilih salah satu"),
            items: question.options.map((option) {
              return DropdownMenuItem<String>(
                  value: option, child: Text(option));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onChangedCallback(newValue);
            },
            isExpanded: true,
          );
        default:
          return Text("Tipe pertanyaan tidak didukung: ${question.type}");
      }
    });
  }
}