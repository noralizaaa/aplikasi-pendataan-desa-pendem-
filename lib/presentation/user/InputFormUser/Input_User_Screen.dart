// File: input_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:get/get.dart';
import '../../../infrastructure/navigation/routes.dart'; // Pastikan path ini benar
import 'input_user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk QuestionType, dll.
import 'package:intl/intl.dart';

class InputUserScreen extends GetView<InputUserController> {
  const InputUserScreen({Key? key}) : super(key: key);

  // Definisi Warna
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80); // Lighter Orange
  static const Color accentHeaderColor = Color(0xFFFF9800);  // Darker Orange
  static const Color cardBackgroundColor = Colors.white;
  static Color get titleTextColor => Colors.grey.shade800;
  static Color get subtitleTextColor => Colors.grey.shade600;
  static Color get mandatoryAsteriskColor => Colors.red.shade700;

  // Konstanta untuk nilai opsi "Lainnya"
  static const String _kOtherOptionValue = '__other_option_value__';


  String _toRoman(int number) {
    if (number < 1 || number > 3999) return number.toString();
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

  InputDecoration _modernInputDecoration(
      BuildContext context, {
        String? hintText,
        String? labelText,
        Widget? suffixIcon,
        bool isDense = false,
      }) {
    return InputDecoration(
      hintText: hintText ?? "Masukkan jawaban...",
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      floatingLabelStyle:
      const TextStyle(color: accentHeaderColor, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accentHeaderColor, width: 1.8),
          borderRadius: BorderRadius.circular(10.0)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
          borderRadius: BorderRadius.circular(10.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.8),
          borderRadius: BorderRadius.circular(10.0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: cardBackgroundColor,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Build method tetap sama, tidak ada perubahan di sini) ...
    // Kode build() Anda sudah cukup panjang, jadi saya tidak akan mengulanginya di sini.
    // Pastikan sisanya tetap sama.
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        elevation: 3.0,
        shadowColor: Colors.black.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentHeaderColor,
                primaryHeaderColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.3, 0.9],
            ),
          ),
        ),
        title: Obx(() => Text(
          controller.loadedForm.value?.title ?? 'Mengisi Form',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5),
          overflow: TextOverflow.ellipsis,
        )),
        actions: [
          Obx(() {
            if (controller.isLoading.value &&
                controller.loadedForm.value == null) {
              return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)));
            }

            bool isEditing = controller.isEditMode.value;
            String buttonText = isEditing ? "SIMPAN" : "KIRIM";
            IconData buttonIcon = isEditing ? Icons.save_alt_rounded : Icons.send_rounded;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: Icon(buttonIcon, color: Colors.white, size: 20),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5)
                  ),
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                  Get.defaultDialog(
                    title: "Konfirmasi",
                    titleStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    middleText:
                    "Anda yakin ingin ${isEditing ? 'menyimpan perubahan' : 'mengirim jawaban'} form ini?",
                    middleTextStyle: const TextStyle(fontSize: 15),
                    textConfirm: isEditing ? "Ya, Simpan" : "Ya, Kirim",
                    textCancel: "Batal",
                    confirmTextColor: Colors.white,
                    buttonColor: accentHeaderColor,
                    cancelTextColor: Colors.grey.shade700,
                    onConfirm: () async {
                      String? formIdForNavigation;
                      try {
                        formIdForNavigation =
                            controller.loadedForm.value?.id;
                      } catch (e) {
                        Get.snackbar("Error Internal","Controller error saat mengambil formId.", snackPosition: SnackPosition.BOTTOM);
                        if (Get.isDialogOpen ?? false) Get.back(closeOverlays: true);
                        return;
                      }

                      if (Get.isDialogOpen ?? false) {
                        Get.back(closeOverlays: true);
                      }

                      try {
                        await controller.submitForm();
                        if (formIdForNavigation != null &&
                            formIdForNavigation.isNotEmpty) {
                          Get.offNamed(AppRoutes.LIST_SUBMISSION_FORM,
                              arguments: formIdForNavigation);
                        } else {
                          Get.snackbar("Navigasi Gagal", "ID Form tidak ditemukan.", snackPosition: SnackPosition.BOTTOM);
                        }
                      } catch (e) {
                        // Error sudah dihandle di controller atau di sini jika perlu
                      }
                    },
                    radius: 10,
                  );
                },
              ),
            );
          }),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.loadedForm.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: accentHeaderColor));
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.loadedForm.value == null) {
          final currentErrorMessage = controller.errorMessage.value;
          bool isFatalArgumentError = currentErrorMessage
              .contains("Argumen ID Form tidak ditemukan") ||
              currentErrorMessage.contains("Tipe argumen ID Form tidak valid") ||
              currentErrorMessage.contains("ID Form yang diterima kosong") ||
              currentErrorMessage
                  .contains("ID Form kosong atau tidak valid");

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red.shade400, size: 50),
                  const SizedBox(height: 10),
                  Text(currentErrorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (!isFatalArgumentError)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Coba Lagi Memuat Form"),
                      onPressed: () => controller.fetchFormStructure(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accentHeaderColor,
                          foregroundColor: Colors.white),
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text("Kembali"),
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),
          );
        }
        if (controller.loadedForm.value == null) {
          return const Center(
              child: Text("Form tidak tersedia atau gagal dimuat."));
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
                      elevation: 2.5,
                      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4, top: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                      color: cardBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.assignment_ind_outlined,
                                  color: accentHeaderColor.withOpacity(0.9),
                                  size: 38.0,
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        form.title,
                                        style: Get.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: accentHeaderColor,
                                          fontSize: 21,
                                        ),
                                      ),
                                      if (form.description.isNotEmpty) ...[
                                        const SizedBox(height: 6.0),
                                        Text(
                                          form.description,
                                          style: Get.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.shade700,
                                            height: 1.45,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                  color: primaryHeaderColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: primaryHeaderColor.withOpacity(0.3), width: 0.8)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline_rounded, color: accentHeaderColor.withOpacity(0.85), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.orange.shade900.withOpacity(0.95),
                                          height: 1.4,
                                        ),
                                        children: <TextSpan>[
                                          const TextSpan(text: "Petunjuk: Isi semua pertanyaan dengan data yang benar. Pertanyaan dengan tanda "),
                                          TextSpan(text: '*', style: TextStyle(color: mandatoryAsteriskColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                          const TextSpan(text: " wajib diisi."),
                                        ],
                                      ),
                                    ),
                                  ),
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

                  return Obx(() {
                    final bool isExpanded =
                        controller.expandedSectionId.value == section.id;
                    final bool hasAnswers = controller.isEditMode.value &&
                        controller.sectionHasAnswers(section.id);

                    return Card(
                      elevation: 1.8,
                      margin: const EdgeInsets.only(
                          bottom: 16, left: 4, right: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () =>
                            controller.toggleSectionExpansion(section.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      displaySectionTitle,
                                      style: Get.textTheme.titleLarge
                                          ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: titleTextColor,
                                          fontSize: 18),
                                    ),
                                  ),
                                  if (hasAnswers && !isExpanded)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.green.shade600,
                                          size: 20),
                                    ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: accentHeaderColor,
                                    size: 28,
                                  ),
                                ],
                              ),
                              if (section.description != null &&
                                  section.description!.isNotEmpty &&
                                  !isExpanded) ...[
                                const SizedBox(height: 8),
                                Text(
                                  section.description!,
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: subtitleTextColor,
                                    fontSize: 13,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (isExpanded) ...[
                                Divider(
                                    height: 24,
                                    thickness: 0.7,
                                    color: Colors.grey.shade300),
                                if (section.description != null &&
                                    section.description!.isNotEmpty) ...[
                                  Text(section.description!,
                                      style: Get.textTheme.bodySmall
                                          ?.copyWith(
                                          color: subtitleTextColor,
                                          fontSize: 13,
                                          height: 1.4)),
                                  const SizedBox(height: 16),
                                ],
                                ..._buildQuestionsForSection(context, section),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
              Obx(() {
                if (controller.isLoading.value &&
                    controller.loadedForm.value != null) {
                  return Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                        child:
                        CircularProgressIndicator(color: Colors.white)),
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


  List<Widget> _buildQuestionsForSection(
      BuildContext context, FormSection section) {
    List<Widget> questionWidgets = [];
    for (int i = 0; i < section.questions.length; i++) {
      final question = section.questions[i];
      questionWidgets.add(Obx(() {
        final bool isVisible =
            controller.questionVisibility[question.id] ?? true;
        if (!isVisible) return const SizedBox.shrink();

        if (question.isRepeatableGroupController &&
            question.controlledGroupTag != null) {
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
        } else if (question.belongsToGroupTag != null &&
            question.belongsToGroupTag!.isNotEmpty) {
          final groupTag = question.belongsToGroupTag!;
          final int repeatCount =
              controller.repeatableGroupCounts[groupTag] ?? 0;

          if (repeatCount == 0) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(repeatCount, (repeatIdx) {
              String itemTitle =
                  "[Data ${question.code != null && question.code!.isNotEmpty ? question.code : ''} ke-${repeatIdx + 1}] ${question.questionText}";
              return Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: Colors.blue.shade100, width: 0.8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionLabel(question,
                          itemTitleOverride: itemTitle, isGroupedItem: true),
                      const SizedBox(height: 10),
                      _buildQuestionInput(context, question,
                          repeatIndex: repeatIdx,
                          keyPrefix: "${question.id}_${groupTag}_$repeatIdx"),
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
      }));
      if (i < section.questions.length - 1) {
        questionWidgets.add(Divider(
            height: 32, thickness: 0.7, color: Colors.grey.shade300));
      }
    }
    return questionWidgets;
  }

  Widget _buildQuestionLabel(FormQuestion question,
      {String? itemTitleOverride, bool isGroupedItem = false}) {
    final String labelText = itemTitleOverride ?? question.questionText;
    final String? questionDescription = question.description;

    return Column(
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
                      color: titleTextColor,
                      height: 1.4),
                  children: [
                    TextSpan(text: labelText),
                    if (question.isRequired)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: mandatoryAsteriskColor,
                            fontSize: isGroupedItem ? 15 : 16,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            if (question.code != null &&
                question.code!.isNotEmpty &&
                !isGroupedItem) ...[
              const SizedBox(width: 8),
              Text("(${question.code})",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic)),
            ]
          ],
        ),
        if (questionDescription != null && questionDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              questionDescription,
              style: TextStyle(
                fontSize: isGroupedItem ? 12.5 : 13.5,
                color: subtitleTextColor?.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- AWAL PERUBAHAN PADA _buildQuestionInput ---
  // File: Input_User_Screen.dart
// ... (kode lainnya tetap sama)

  Widget _buildQuestionInput(BuildContext context, FormQuestion question,
      {int? repeatIndex, required String keyPrefix}) {
    return Obx(() {
      dynamic initialValue;
      Function(dynamic) onChangedCallback;
      // ... (definisi initialOtherText, onOtherTextChangedCallback, fieldKeyId,
      //     dan logika untuk mengambil initialValue & onChangedCallback tetap sama seperti sebelumnya)

      // Bagian ini tetap sama untuk mengambil initialValue dan onChangedCallback
      // --- AWAL BAGIAN YANG SAMA ---
      String? initialOtherText;
      if (repeatIndex != null) {
        initialOtherText = controller.repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        initialOtherText = controller.userOtherAnswers[question.id];
      }

      Function(String) onOtherTextChangedCallback = (text) {
        if (repeatIndex != null) {
          if (!controller.repeatableGroupOtherAnswers.containsKey(question.id)) {
            controller.repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
          }
          controller.repeatableGroupOtherAnswers[question.id]![repeatIndex] = text;
        } else {
          controller.userOtherAnswers[question.id] = text;
        }
      };

      String fieldKeyId = "${keyPrefix}_${question.type.toShortString()}";

      if (repeatIndex != null) {
        if (!controller.repeatableGroupAnswers.containsKey(question.id)) {
          controller.repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (!controller.repeatableGroupAnswers[question.id]!.containsKey(repeatIndex)) {
          dynamic defaultVal;
          if (question.type == QuestionType.checkboxes) defaultVal = <String>[];
          else if (question.type == QuestionType.gridNumeric) defaultVal = <String, Map<String, Map<String, num?>>>{};
          else if (question.type == QuestionType.dropdown) defaultVal = null;
          else defaultVal = '';
          controller.repeatableGroupAnswers[question.id]![repeatIndex] = defaultVal;
        }
        initialValue = controller.repeatableGroupAnswers[question.id]![repeatIndex];
        onChangedCallback = (value) => controller.updateRepeatableGroupAnswer(question.id, repeatIndex, value);
      } else {
        if (!controller.userAnswers.containsKey(question.id)) {
          dynamic defaultVal;
          if (question.type == QuestionType.checkboxes) defaultVal = <String>[];
          else if (question.type == QuestionType.gridNumeric) defaultVal = <String, Map<String, Map<String, num?>>>{};
          else if (question.type == QuestionType.dropdown) defaultVal = null;
          else defaultVal = '';
          controller.userAnswers[question.id] = defaultVal;
        }
        initialValue = controller.userAnswers[question.id];
        onChangedCallback = (value) => controller.updateUserAnswer(question.id, value);
      }
      // --- AKHIR BAGIAN YANG SAMA ---

      String? validatorFunction(dynamic val) {
        final FormQuestion currentQuestionState =
            controller.findQuestionById(question.id) ?? question;
        final ValidationRule? rule = currentQuestionState.validation;
        final String questionLabel =
        currentQuestionState.questionText.isNotEmpty
            ? currentQuestionState.questionText
            : "Isian ini";

        String effectiveValueString = "";
        bool isEmptyAnswer = true;

        if (val is String) {
          effectiveValueString = val.trim();
          isEmptyAnswer = effectiveValueString.isEmpty;
        } else if (val is List) {
          isEmptyAnswer = val.isEmpty;
        } else if (val == null) {
          isEmptyAnswer = true;
        } else if (val is Map && question.type == QuestionType.gridNumeric) {
          if (val.isEmpty) {
            isEmptyAnswer = true;
          } else {
            isEmptyAnswer = (val as Map<String, Map<String, Map<String, num?>>>)
                .values
                .every((colMap) => colMap.values.every(
                    (subColMap) => subColMap.values.every(
                        (cellVal) => cellVal == null || cellVal.toString().trim().isEmpty
                )
            ));
          }
        } else if (val is Map) {
          isEmptyAnswer = val.isEmpty;
        }

        if (currentQuestionState.isRequired && isEmptyAnswer) {
          bool isOtherSelected = false;
          if (currentQuestionState.type == QuestionType.multipleChoice && val == _kOtherOptionValue) {
            isOtherSelected = true;
          } else if (currentQuestionState.type == QuestionType.checkboxes && (val as List?)?.contains(_kOtherOptionValue) == true) {
            isOtherSelected = true;
          }

          if (isOtherSelected) {
            String? otherTextValue;
            if (repeatIndex != null) {
              otherTextValue = controller.repeatableGroupOtherAnswers[question.id]?[repeatIndex];
            } else {
              otherTextValue = controller.userOtherAnswers[question.id];
            }
            if (otherTextValue == null || otherTextValue.trim().isEmpty) {
              return 'Isian "Lainnya" untuk $questionLabel wajib diisi.';
            }
          } else {
            return '$questionLabel wajib diisi.';
          }
        }

        if (isEmptyAnswer && !currentQuestionState.isRequired) return null;

        if (rule != null) {
          if (val is String && val.isNotEmpty) {
            // ... (validasi string lainnya tetap sama)
            if (rule.minLength != null &&
                effectiveValueString.length < rule.minLength!) {
              return '$questionLabel minimal ${rule.minLength} karakter.';
            }
            if (rule.maxLength != null &&
                effectiveValueString.length > rule.maxLength!) {
              return '$questionLabel maksimal ${rule.maxLength} karakter.';
            }
            if (rule.regex != null &&
                rule.regex!.isNotEmpty &&
                !RegExp(rule.regex!).hasMatch(effectiveValueString)) {
              return 'Format $questionLabel tidak sesuai.';
            }
            if (rule.predefinedRule == 'nik' &&
                !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
              return 'NIK harus 16 digit angka.';
            }
            if (rule.predefinedRule == 'email' &&
                !GetUtils.isEmail(effectiveValueString)) {
              return 'Format email tidak valid.';
            }
            if (rule.predefinedRule == 'numbersOnly' &&
                !GetUtils.isNumericOnly(effectiveValueString)) {
              return '$questionLabel hanya boleh berisi angka.';
            }
          }

          if (currentQuestionState.type == QuestionType.number) {
            num? numAnswer = num.tryParse(effectiveValueString.replaceAll(',', '.'));
            if (numAnswer == null && effectiveValueString.isNotEmpty) {
              return '$questionLabel harus berupa angka.';
            }
            if (numAnswer != null) {
              if (rule.minValue != null && numAnswer < rule.minValue!) {
                return '$questionLabel minimal ${rule.minValue}.';
              }
              if (rule.maxValue != null && numAnswer > rule.maxValue!) {
                return '$questionLabel maksimal ${rule.maxValue}.';
              }
              if (currentQuestionState.code == "203" ||
                  currentQuestionState.code == "204") {
                final artQuestion = controller.findQuestionByCode("112");
                if (artQuestion != null) {
                  // --- AWAL PERUBAHAN UNTUK MENGAMBIL JAWABAN ART ---
                  dynamic artCountValueDynamic;
                  // `repeatIndex` berasal dari parameter _buildQuestionInput
                  if (repeatIndex != null) {
                    artCountValueDynamic = controller.repeatableGroupAnswers[artQuestion.id]?[repeatIndex];
                  } else {
                    artCountValueDynamic = controller.userAnswers[artQuestion.id];
                  }
                  // --- AKHIR PERUBAHAN UNTUK MENGAMBIL JAWABAN ART ---
                  num? artCount;
                  if (artCountValueDynamic is num) {
                    artCount = artCountValueDynamic;
                  } else if (artCountValueDynamic is String) {
                    artCount = num.tryParse(artCountValueDynamic.replaceAll(',', '.'));
                  }

                  if (artCount != null && numAnswer > artCount) {
                    return '$questionLabel (${numAnswer.toInt()}) tidak boleh melebihi ${artQuestion.questionText} (${artCount.toInt()}).';
                  }
                }
              }
            }
          }
        }
        return null;
      }


      switch (question.type) {
      // ... (kasus QuestionType.text, paragraph, number, date, multipleChoice, checkboxes tetap sama seperti sebelumnya)
        case QuestionType.text:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            decoration:
            _modernInputDecoration(context, hintText: "Jawaban teks singkat"),
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.paragraph:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            decoration:
            _modernInputDecoration(context, hintText: "Jawaban teks panjang"),
            maxLines: 3,
            minLines: 2,
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.number: // Pastikan ini tidak bentrok dengan validasi di validatorFunction
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue != null ? initialValue.toString().replaceAll('.', ',') : '',
            decoration: _modernInputDecoration(context, hintText: "Masukkan angka"),
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
            onChanged: (value) {
              onChangedCallback(value.replaceAll(',', '.'));
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.date:
          String displayDate = '';
          if (initialValue is DateTime) {
            displayDate = DateFormat('dd/MM/yyyy').format(initialValue);
          } else if (initialValue is String) {
            try {
              if (initialValue.isNotEmpty) {
                DateTime? parsedDate = DateTime.tryParse(initialValue);
                if (parsedDate != null) {
                  displayDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                } else {
                  parsedDate = DateFormat('dd/MM/yyyy').tryParse(initialValue);
                  if (parsedDate != null) {
                    displayDate = initialValue;
                  } else {
                    displayDate = initialValue;
                  }
                }
              }
            } catch (e) {
              displayDate = initialValue;
            }
          }

          return TextFormField(
            key: ValueKey(fieldKeyId + displayDate),
            readOnly: true,
            controller: TextEditingController(text: displayDate),
            decoration: _modernInputDecoration(context,
                hintText: "Pilih tanggal",
                suffixIcon: Icon(Icons.calendar_today_rounded,
                    color: accentHeaderColor)),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime initialDatePickerDate = DateTime.now();
              if (initialValue is DateTime) {
                initialDatePickerDate = initialValue;
              } else if (initialValue is String && initialValue.isNotEmpty) {
                try {
                  DateTime? parsedInternal = DateTime.tryParse(initialValue);
                  if (parsedInternal != null) {
                    initialDatePickerDate = parsedInternal;
                  } else {
                    initialDatePickerDate = DateFormat('dd/MM/yyyy').parse(initialValue);
                  }
                } catch (e) {/* biarkan default jika parse gagal */}
              }
              DateTime? pickedDate = await showDatePicker(
                // ... (showDatePicker tetap sama)
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
                              onSurface: Colors.black87),
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
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.multipleChoice:
        // ... (kode multipleChoice tetap sama seperti yang Anda berikan sebelumnya, dibungkus FormField)
          String? currentGroupValue = initialValue as String?;
          List<Widget> radioTiles = question.options.map((option) {
            return RadioListTile<String>(
              key: ValueKey("${fieldKeyId}_${option}_radio"),
              title: Text(option, style: const TextStyle(fontSize: 15.0)),
              value: option,
              groupValue: currentGroupValue, // Akan diupdate oleh FormField builder
              onChanged: (String? value) {
                // onChangedCallback dan field.didChange akan dipanggil di dalam builder FormField
              },
              activeColor: accentHeaderColor,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }).toList();

          if (question.hasOtherOption) {
            radioTiles.add(
              RadioListTile<String>(
                key: ValueKey("${fieldKeyId}_other_radio"),
                title: const Text("Lainnya...", style: TextStyle(fontSize: 15.0)),
                value: _kOtherOptionValue,
                groupValue: currentGroupValue, // Akan diupdate oleh FormField builder
                onChanged: (String? value) {
                  // onChangedCallback dan field.didChange akan dipanggil di dalam builder FormField
                },
                activeColor: accentHeaderColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            );
          }

          return FormField<String>(
              key: ValueKey("${fieldKeyId}_mc_formfield"),
              initialValue: currentGroupValue,
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...radioTiles.map((tile){
                      if (tile is RadioListTile<String>) {
                        return RadioListTile<String>(
                          key: tile.key,
                          title: tile.title,
                          value: tile.value,
                          groupValue: field.value,
                          onChanged: (String? value) {
                            if (value != null) {
                              onChangedCallback(value);
                              field.didChange(value);
                              if (value != _kOtherOptionValue) {
                                onOtherTextChangedCallback('');
                              }
                            }
                          },
                          activeColor: tile.activeColor,
                          contentPadding: tile.contentPadding,
                          visualDensity: tile.visualDensity,
                        );
                      }
                      return tile;
                    }).toList(),
                    if (question.hasOtherOption && field.value == _kOtherOptionValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                        child: TextFormField(
                          key: ValueKey("${fieldKeyId}_other_text"),
                          initialValue: initialOtherText ?? '',
                          decoration: _modernInputDecoration(context, hintText: "Sebutkan lainnya", isDense: true)
                              .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          onChanged: (text) {
                            onOtherTextChangedCallback(text);
                            field.didChange(field.value);
                          },
                          validator: (text) {
                            if (field.value == _kOtherOptionValue && question.isRequired && (text == null || text.trim().isEmpty)) {
                              return 'Isian "Lainnya" tidak boleh kosong.';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                );
              }
          );
        case QuestionType.checkboxes:
        // ... (kode checkboxes tetap sama seperti yang Anda berikan sebelumnya, dibungkus FormField)
          List<String> currentSelectedValues = List<String>.from(initialValue as List<dynamic>? ?? []);
          bool isOtherOptionSelectedInitially = currentSelectedValues.contains(_kOtherOptionValue);

          return FormField<List<String>>(
            key: ValueKey("${fieldKeyId}_checkbox_formfield"),
            initialValue: currentSelectedValues,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<List<String>> field) {
              bool isOtherCurrentlySelected = field.value?.contains(_kOtherOptionValue) ?? false;

              List<Widget> checkboxTiles = question.options.map((option) {
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
              }).toList();

              if (question.hasOtherOption) {
                checkboxTiles.add(
                  CheckboxListTile(
                    key: ValueKey("${fieldKeyId}_other_checkbox"),
                    title: const Text("Lainnya...", style: TextStyle(fontSize: 15.0)),
                    value: isOtherCurrentlySelected,
                    onChanged: (bool? selected) {
                      final latestSelectedValues = List<String>.from(field.value ?? []);
                      if (selected == true) {
                        if (!latestSelectedValues.contains(_kOtherOptionValue)) {
                          latestSelectedValues.add(_kOtherOptionValue);
                        }
                      } else {
                        latestSelectedValues.remove(_kOtherOptionValue);
                        onOtherTextChangedCallback('');
                      }
                      onChangedCallback(latestSelectedValues);
                      field.didChange(latestSelectedValues);
                    },
                    activeColor: accentHeaderColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...checkboxTiles,
                  if (question.hasOtherOption && isOtherCurrentlySelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                      child: TextFormField(
                        key: ValueKey("${fieldKeyId}_other_text"),
                        initialValue: initialOtherText ?? '',
                        decoration: _modernInputDecoration(context, hintText: "Sebutkan lainnya", isDense: true)
                            .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        onChanged: (text) {
                          onOtherTextChangedCallback(text);
                          field.didChange(field.value);
                        },
                        validator: (text) {
                          if (isOtherCurrentlySelected && question.isRequired && (text == null || text.trim().isEmpty)) {
                            return 'Isian "Lainnya" tidak boleh kosong.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
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
            if (repeatIndex != null && controller.repeatableGroupAnswers.containsKey(parentQuestionId)) {
              parentAnswer = controller.repeatableGroupAnswers[parentQuestionId]![repeatIndex] as String?;
            } else {
              parentAnswer = controller.userAnswers[parentQuestionId] as String?;
            }

            if (parentAnswer != null && parentAnswer.isNotEmpty) {
              optionsToDisplay =
                  question.dependentOptions!.optionMapping[parentAnswer] ?? [];
            } else {
              optionsToDisplay = [];
            }
          }

          String? effectiveInitialValue = initialValue as String?;
          if (effectiveInitialValue != null &&
              !optionsToDisplay.contains(effectiveInitialValue) &&
              optionsToDisplay.isNotEmpty) {
            effectiveInitialValue = null;
          } else if (optionsToDisplay.isEmpty && effectiveInitialValue != null) {
            effectiveInitialValue = null;
          }

          if (isDependent && (parentAnswer == null || parentAnswer.isEmpty) && optionsToDisplay.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pilih jawaban untuk pertanyaan induk (${controller.findQuestionById(question.dependentOptions!.parentQuestionId)?.questionText ?? 'sebelumnya'}) terlebih dahulu.",
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 14),
              ),
            );
          }
          if (isDependent && parentAnswer != null && parentAnswer.isNotEmpty && optionsToDisplay.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Tidak ada opsi yang tersedia untuk pilihan '$parentAnswer'.",
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                    fontSize: 14),
              ),
            );
          }

          return DropdownButtonFormField<String>(
            key: ValueKey(fieldKeyId + (effectiveInitialValue ?? "_nullVal_") + optionsToDisplay.join('_') + (parentAnswer ?? "")),
            value: effectiveInitialValue,
            decoration: _modernInputDecoration(
                context,
                labelText: (optionsToDisplay.isEmpty &&
                    (!isDependent || (isDependent && parentAnswer != null && parentAnswer.isNotEmpty)))
                    ? "Tidak ada opsi tersedia"
                    : "Pilih salah satu"),
            items: optionsToDisplay.map((option) {
              return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 15)));
            }).toList(),
            onChanged: (optionsToDisplay.isEmpty && (!isDependent || (isDependent && parentAnswer != null && parentAnswer.isNotEmpty)))
                ? null
                : (String? newValue) {
              if (newValue != null) {
                onChangedCallback(newValue);
                // --- MENGOMENTARI PEMANGGILAN triggerDependentQuestionUpdates ---
                // controller.triggerDependentQuestionUpdates(question.id, newValue, repeatIndex);
              }
            },
            isExpanded: true,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hint: (optionsToDisplay.isEmpty && isDependent && parentAnswer != null && parentAnswer.isNotEmpty)
                ? const Text("Tidak ada opsi untuk pilihan induk ini")
                : null,
          );

        case QuestionType.gridNumeric:
        // ... (kode gridNumeric yang sudah diperbaiki dari respons sebelumnya tetap sama)
          Map<String, Map<String, Map<String, num?>>> effectiveGridAnswers = {};

          if (initialValue is Map && (initialValue as Map).isNotEmpty) {
            final Map<dynamic, dynamic> rawInitialDataMap = initialValue as Map<dynamic, dynamic>;

            if (question.gridRowLabels.isEmpty) {
              if (rawInitialDataMap.entries.isNotEmpty) {
                MapEntry<dynamic, dynamic>? targetEntry;
                if (rawInitialDataMap.containsKey("")) {
                  targetEntry = rawInitialDataMap.entries.firstWhere((e) => e.key == "", orElse: () => rawInitialDataMap.entries.first);
                } else {
                  targetEntry = rawInitialDataMap.entries.first;
                }

                final rowDataMap = targetEntry.value;

                if (rowDataMap is Map) {
                  try {
                    effectiveGridAnswers[""] = Map<String, Map<String, num?>>.fromEntries(
                        (rowDataMap as Map<dynamic, dynamic>).entries.map((colEntry) {
                          var subColMapData = colEntry.value;
                          if (subColMapData is! Map) subColMapData = <String, dynamic>{};
                          return MapEntry(
                              colEntry.key.toString(),
                              Map<String, num?>.fromEntries(
                                  (subColMapData as Map<dynamic, dynamic>).entries.map((subColEntry) => MapEntry(
                                      subColEntry.key.toString(),
                                      subColEntry.value as num?
                                  ))
                              )
                          );
                        })
                    );
                  } catch (e) {
                    print("Error casting single-row grid data for $fieldKeyId: $e. InitialValue: $initialValue");
                  }
                }
              }
            } else {
              try {
                effectiveGridAnswers = Map<String, Map<String, Map<String, num?>>>.fromEntries(
                    rawInitialDataMap.entries
                        .where((rowEntry) => question.gridRowLabels.contains(rowEntry.key.toString()))
                        .map((rowEntry) {
                      var colMapData = rowEntry.value;
                      if (colMapData is! Map) colMapData = <String, dynamic>{};
                      return MapEntry(
                          rowEntry.key.toString(),
                          Map<String, Map<String, num?>>.fromEntries(
                              (colMapData as Map<dynamic, dynamic>).entries.map((colEntry) {
                                var subColMapData = colEntry.value;
                                if (subColMapData is! Map) subColMapData = <String, dynamic>{};
                                return MapEntry(
                                    colEntry.key.toString(),
                                    Map<String, num?>.fromEntries(
                                        (subColMapData as Map<dynamic, dynamic>).entries.map((subColEntry) => MapEntry(
                                            subColEntry.key.toString(),
                                            subColEntry.value as num?
                                        ))
                                    )
                                );
                              })
                          )
                      );
                    })
                );
              } catch (e) {
                print("Error casting multi-row gridAnswers for $fieldKeyId: $e. InitialValue: $initialValue");
              }
            }
          }


          if (question.gridColumnLabels.isEmpty || question.gridSubColumnLabels.isEmpty) {
            return Text("Grid Numerik: Konfigurasi label kolom/sub-kolom belum lengkap.", style: TextStyle(color: Colors.red.shade700));
          }

          List<String> rowsToRender = question.gridRowLabels.isNotEmpty ? question.gridRowLabels : [""];

          return FormField<Map<String, Map<String, Map<String, num?>>>>(
              key: ValueKey("${fieldKeyId}_grid_formfield"),
              initialValue: effectiveGridAnswers,
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (FormFieldState<Map<String, Map<String, Map<String, num?>>>> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rowsToRender.map((uiRowLabel) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (uiRowLabel.isNotEmpty && question.gridRowLabels.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(uiRowLabel, style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: titleTextColor)),
                                  ),
                                Table(
                                  // ... (definisi Table tetap sama)
                                  border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                                  defaultColumnWidth: const MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(65)),
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: Colors.grey.shade100),
                                      children: [
                                        const TableCell(child: Padding(padding: EdgeInsets.all(6.0), child: Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                        ...question.gridColumnLabels.map((colLabel) => TableCell(
                                          verticalAlignment: TableCellVerticalAlignment.middle,
                                          child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                              child: Text(colLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        )).toList(),
                                      ],
                                    ),
                                    ...question.gridSubColumnLabels.map((subColLabel) {
                                      return TableRow(
                                        children: [
                                          TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                                                  child: Text(subColLabel, style: const TextStyle(fontSize: 12)))),
                                          ...question.gridColumnLabels.map((colLabel) {
                                            num? cellValue = effectiveGridAnswers[uiRowLabel]?[colLabel]?[subColLabel];
                                            String cellKeyIdGrid = "${fieldKeyId}_grid_${uiRowLabel}_${colLabel}_$subColLabel";

                                            return TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.all(1.0),
                                                child: TextFormField(
                                                  key: ValueKey(cellKeyIdGrid),
                                                  initialValue: cellValue?.toString().replaceAll('.', ',') ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 13),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
                                                    isDense: true,
                                                    fillColor: Colors.white,
                                                    filled: true,
                                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                                  ),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
                                                  onChanged: (value) {
                                                    controller.updateGridAnswer(
                                                        question.id,
                                                        repeatIndex,
                                                        uiRowLabel,
                                                        colLabel,
                                                        subColLabel,
                                                        value.replaceAll(',', '.'));

                                                    // Ambil state terbaru untuk validasi FormField
                                                    var currentGridAnswerState;
                                                    if (repeatIndex != null) {
                                                      currentGridAnswerState = controller.repeatableGroupAnswers[question.id]?[repeatIndex];
                                                    } else {
                                                      currentGridAnswerState = controller.userAnswers[question.id];
                                                    }

                                                    if (currentGridAnswerState != null) {
                                                      // --- AWAL LOGIKA getGridMap YANG DI-INLINE (MENGGANTIKAN controller.getGridMap) ---
                                                      Map<String, Map<String, Map<String, num?>>> convertedMap;
                                                      if (currentGridAnswerState is Map<String, Map<String, Map<String, num?>>>) {
                                                        convertedMap = currentGridAnswerState;
                                                      } else if (currentGridAnswerState is Map) {
                                                        try {
                                                          convertedMap = Map<String, Map<String, Map<String, num?>>>.fromEntries(
                                                              (currentGridAnswerState as Map<dynamic, dynamic>).entries.map((rowEntry) {
                                                                var colMap = rowEntry.value;
                                                                if (colMap is! Map) colMap = <String, dynamic>{};

                                                                return MapEntry(
                                                                    rowEntry.key.toString(),
                                                                    Map<String, Map<String, num?>>.fromEntries(
                                                                        (colMap as Map<dynamic, dynamic>).entries.map((colEntry) {
                                                                          var subColMap = colEntry.value;
                                                                          if (subColMap is! Map) subColMap = <String, dynamic>{};

                                                                          return MapEntry(
                                                                              colEntry.key.toString(),
                                                                              Map<String, num?>.fromEntries(
                                                                                  (subColMap as Map<dynamic, dynamic>).entries.map((subColEntry) {
                                                                                    num? cellValueNum; // Ganti nama variabel agar tidak bentrok
                                                                                    if (subColEntry.value == null) {
                                                                                      cellValueNum = null;
                                                                                    } else if (subColEntry.value is num) {
                                                                                      cellValueNum = subColEntry.value as num;
                                                                                    } else {
                                                                                      cellValueNum = num.tryParse(subColEntry.value.toString());
                                                                                    }
                                                                                    return MapEntry(
                                                                                        subColEntry.key.toString(),
                                                                                        cellValueNum
                                                                                    );
                                                                                  })
                                                                              )
                                                                          );
                                                                        })
                                                                    )
                                                                );
                                                              })
                                                          );
                                                        } catch (e) {
                                                          print("Error in inlined getGridMap casting within InputUserScreen: $e. Data: $currentGridAnswerState");
                                                          convertedMap = <String, Map<String, Map<String, num?>>>{};
                                                        }
                                                      } else {
                                                        convertedMap = <String, Map<String, Map<String, num?>>>{};
                                                      }
                                                      // --- AKHIR LOGIKA getGridMap YANG DI-INLINE ---
                                                      field.didChange(convertedMap);
                                                    } else {
                                                      field.didChange(<String, Map<String, Map<String, num?>>>{});
                                                    }
                                                  },
                                                  validator: (cellValueString) {
                                                    if (cellValueString != null &&
                                                        cellValueString.isNotEmpty &&
                                                        num.tryParse(cellValueString.replaceAll(',', '.')) == null) {
                                                      return 'X';
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
                    ),
                    if (field.hasError && field.errorText != null && field.errorText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 0.0),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                );
              }
          );

        default:
          return Text("Tipe pertanyaan tidak didukung: ${question.type}");
      }
    });
  }

// ... (sisa kode Input_User_Screen.dart)
// --- AKHIR PERUBAHAN PADA _buildQuestionInput ---

}