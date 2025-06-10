// File: input_user_screen.dart

import 'package:aplikasi_pendataan_desa/presentation/user/ListSubmissionForm/list_submission_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:get/get.dart';
import '../../../infrastructure/navigation/routes.dart'; // Pastikan path ini benar
import 'input_user_controller.dart'; // Pastikan ini mengarah ke file controller yang benar
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk QuestionType, ValidationRule, ComparisonOperatorType
import 'package:intl/intl.dart';

// --- AWAL TAMBAHAN: Widget untuk Grup Berulang ---
class RepeatableGroupInstanceWidget extends StatelessWidget {
  final String groupTag;
  final List<FormQuestion> questionsInGroup;
  final InputUserController controller;
  final InputUserScreen screenInstance; // Untuk akses metode _buildQuestionLabel/Input

  const RepeatableGroupInstanceWidget({
    Key? key,
    required this.groupTag,
    required this.questionsInGroup,
    required this.controller,
    required this.screenInstance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int totalRepeatCount = controller.repeatableGroupCounts[groupTag] ?? 0;
      final int activeIndex = controller.activeRepeatIndexForGroup[groupTag] ?? 0;

      if (totalRepeatCount == 0 || activeIndex >= totalRepeatCount) {
        return const SizedBox.shrink();
      }

      List<Widget> itemWidgets = [];
      bool hasVisibleQuestionInInstance = false;

      for (int i = 0; i < questionsInGroup.length; i++) {
        final q = questionsInGroup[i];
        final bool isQuestionStructurallyVisible = controller.questionVisibility[q.id] ?? true;

        if (!isQuestionStructurallyVisible) {
          continue;
        }
        hasVisibleQuestionInInstance = true;

        String itemTitle = "[Data ${q.code != null && q.code!.isNotEmpty ? q.code : ''} ke-${activeIndex + 1} dari $totalRepeatCount] ${q.questionText}";

        itemWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                key: ValueKey("${q.id}_${groupTag}_${activeIndex}_col_ingroup_widget"),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  screenInstance._buildQuestionLabel(q, itemTitleOverride: itemTitle, isGroupedItem: true),
                  const SizedBox(height: 10),
                  screenInstance._buildQuestionInput(context, q,
                      repeatIndex: activeIndex,
                      keyPrefix: "${q.id}_${groupTag}_${activeIndex}"),
                ],
              ),
            )
        );
        if (i < questionsInGroup.length - 1) {
          if (i + 1 < questionsInGroup.length) {
            final nextQ = questionsInGroup[i+1];
            final bool isNextQVisible = controller.questionVisibility[nextQ.id] ?? true;
            if (isNextQVisible) {
              itemWidgets.add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Divider(height: 20, thickness: 0.5, color: Colors.blue.shade200.withOpacity(0.7)),
              ));
            }
          }
        }
      }

      if (!hasVisibleQuestionInInstance && questionsInGroup.isNotEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100, width: 0.8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...itemWidgets,
              if (itemWidgets.isNotEmpty) const SizedBox(height: 16), // Tambah spasi sedikit lebih banyak
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  (activeIndex > 0)
                      ? ElevatedButton.icon(
                    icon: const Icon(Icons.navigate_before_rounded, size: 18),
                    label: const Text("Data Sblmnya"),
                    onPressed: () => controller.goToPreviousRepeatableItem(groupTag),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13)),
                  )
                      : const SizedBox.shrink(),
                  const Spacer(),
                  Text(
                    "Data ${activeIndex + 1} dari $totalRepeatCount",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  (activeIndex < totalRepeatCount - 1)
                      ? ElevatedButton.icon(
                    icon: const Icon(Icons.navigate_next_rounded, size: 18),
                    label: const Text("Data Brktnya"),
                    onPressed: () => controller.goToNextRepeatableItem(groupTag),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: InputUserScreen.accentHeaderColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13)),
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
// --- AKHIR TAMBAHAN ---

class InputUserScreen extends GetView<InputUserController> {
  const InputUserScreen({Key? key}) : super(key: key);

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color cardBackgroundColor = Colors.white;
  static Color get titleTextColor => Colors.grey.shade800;
  static Color get subtitleTextColor => Colors.grey.shade600;
  static Color get mandatoryAsteriskColor => Colors.red.shade700;
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
      errorMaxLines: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool allowPop = false;
        await Get.defaultDialog<void>(
          title: "Konfirmasi Keluar",
          titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          middleText: "Apakah Anda yakin ingin keluar dari Form ini?\nData yang belum diisi atau disimpan akan hilang.",
          middleTextStyle: const TextStyle(fontSize: 15),
          textConfirm: "Ya, Keluar",
          textCancel: "Batal",
          confirmTextColor: Colors.white,
          buttonColor: accentHeaderColor,
          cancelTextColor: Colors.grey.shade700,
          onConfirm: () {
            allowPop = true;
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
          },
          onCancel: () {
            allowPop = false;
          },
          radius: 10,
          barrierDismissible: false,
        );
        return allowPop;
      },
      child: Scaffold(
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
                          formIdForNavigation = controller.loadedForm.value?.id;
                        } catch (e) {
                          Get.snackbar("Error Internal","Controller error saat mengambil formId.", snackPosition: SnackPosition.BOTTOM);
                          if (Get.isDialogOpen ?? false) Get.back(closeOverlays: true);
                          return;
                        }

                        if (Get.isDialogOpen ?? false) {
                          Get.back();
                        }

                        bool submissionSuccessful = false;
                        try {
                          submissionSuccessful = await controller.submitForm();
                          if (submissionSuccessful) {
                            if (!controller.isEditMode.value && formIdForNavigation != null) {
                              Get.offNamed(AppRoutes.LIST_SUBMISSION_FORM, arguments: formIdForNavigation);
                            } else if (controller.isEditMode.value && formIdForNavigation != null) {
                              Get.offNamed(AppRoutes.LIST_SUBMISSION_FORM, arguments: formIdForNavigation);
                            }
                          }
                        } catch (e) {
                          print("Error caught during submit confirmation: $e");
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
                        onPressed: () => controller.fetchFormAndPotentialSubmissionData(),
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
                          controller.expandedSectionId.value == section.id || controller.loadedForm.value!.sections.length == 1;
                      final bool hasAnswers = controller.isEditMode.value &&
                          controller.sectionHasAnswers(section.id);

                      return Card(
                        elevation: 1.8,
                        margin: const EdgeInsets.only(
                            bottom: 16, left: 4, right: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                                  if (controller.loadedForm.value!.sections.length > 1)
                                    IconButton(
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: accentHeaderColor,
                                      ),
                                      iconSize: 28,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => controller.toggleSectionExpansion(section.id),
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
                                ..._buildQuestionsForSection(context, section, this),
                              ],
                            ],
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
      ),
    );
  }

  List<Widget> _buildQuestionsForSection(BuildContext context, FormSection section, InputUserScreen screenInstance) {
    List<Widget> sectionWidgets = [];
    Set<String> processedGroupTagsThisSection = {};

    final List<FormQuestion> sortedQuestions = List.from(section.questions);
    sortedQuestions.sort((a, b) {
      final codeA = a.code;
      final codeB = b.code;

      // Pertanyaan tanpa 'code' atau dengan code kosong akan diletakkan di akhir.
      if (codeA == null || codeA.isEmpty) return 1;
      if (codeB == null || codeB.isEmpty) return -1;

      // Coba parse ke integer untuk melakukan sorting numerik yang benar (misal: "10" > "2")
      final numA = int.tryParse(codeA);
      final numB = int.tryParse(codeB);

      if (numA != null && numB != null) {
        return numA.compareTo(numB); // Lakukan perbandingan sebagai angka jika keduanya valid.
      }

      // Jika salah satu atau keduanya bukan angka, lakukan perbandingan sebagai string.
      return codeA.compareTo(codeB);
    });

    for (int i = 0; i < sortedQuestions.length; i++) {
      final question = sortedQuestions[i];
      Widget? widgetToAdd;
      final bool isQuestionStructurallyVisible = controller.questionVisibility[question.id] ?? true;

      if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
        if (isQuestionStructurallyVisible) {
          widgetToAdd = Padding(
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
        processedGroupTagsThisSection.remove(question.controlledGroupTag!);
      } else if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
        final groupTag = question.belongsToGroupTag!;
        if (!processedGroupTagsThisSection.contains(groupTag)) {
          List<FormQuestion> questionsInThisGroup = section.questions
              .where((q) => q.belongsToGroupTag == groupTag)
              .toList();

          final controllerQ = section.questions.firstWhereOrNull((q) => q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
          bool isOwningControllerVisible = true;
          if(controllerQ != null){
            isOwningControllerVisible = controller.questionVisibility[controllerQ.id] ?? true;
          }
          final bool groupHasItems = (controller.repeatableGroupCounts[groupTag] ?? 0) > 0;

          if (isOwningControllerVisible && groupHasItems) {
            widgetToAdd = RepeatableGroupInstanceWidget(
              key: ValueKey("group_instance_${groupTag}_${section.id}"),
              groupTag: groupTag,
              questionsInGroup: questionsInThisGroup,
              controller: controller,
              screenInstance: screenInstance,
            );
          }
          processedGroupTagsThisSection.add(groupTag);
        }
      } else {
        if (isQuestionStructurallyVisible) {
          widgetToAdd = Padding(
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
      }

      if (widgetToAdd != null) {
        if (widgetToAdd is RepeatableGroupInstanceWidget) {
          sectionWidgets.add(widgetToAdd);
        } else {
          sectionWidgets.add(Obx(() {
            final bool currentVisibility = controller.questionVisibility[question.id] ?? true;
            return currentVisibility ? widgetToAdd! : const SizedBox.shrink();
          }));
        }
      }
    }

    List<Widget> finalWidgets = [];
    for (int k = 0; k < sectionWidgets.length; k++) {
      finalWidgets.add(sectionWidgets[k]);
      if (k < sectionWidgets.length - 1) {
        bool nextWidgetIsEffectivelyShrink = false;
        if (sectionWidgets[k+1] is SizedBox && (sectionWidgets[k+1] as SizedBox).height == 0 && (sectionWidgets[k+1] as SizedBox).width == 0) {
          nextWidgetIsEffectivelyShrink = true;
        }
        if (!nextWidgetIsEffectivelyShrink) {
          finalWidgets.add(Divider(height: 32, thickness: 0.7, color: Colors.grey.shade300));
        }
      }
    }
    return finalWidgets;
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

  // Helper method untuk mendapatkan teks display operator perbandingan
  String _getComparisonOperatorDisplayText(String? operatorShortString) {
    if (operatorShortString == null) return "";
    switch (operatorShortString) {
      case 'lessThan': return 'kurang dari';
      case 'lessThanOrEqual': return 'kurang dari atau sama dengan';
      case 'equal': return 'sama dengan';
      case 'notEqual': return 'tidak sama dengan';
      case 'greaterThan': return 'lebih dari';
      case 'greaterThanOrEqual': return 'lebih dari atau sama dengan';
      default: return operatorShortString; // fallback
    }
  }


  Widget _buildQuestionInput(BuildContext context, FormQuestion question,
      {int? repeatIndex, required String keyPrefix}) {
    return Obx(() {
      dynamic initialValue;
      Function(dynamic) onChangedCallback;

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
          if (!controller.repeatableGroupOtherAnswers[question.id]!.containsKey(repeatIndex)) {
            controller.repeatableGroupOtherAnswers[question.id]![repeatIndex] = '';
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

      String? validatorFunction(dynamic val) {
        final FormQuestion currentQuestionState =
            controller.findQuestionById(question.id) ?? question;
        final ValidationRule? rule = currentQuestionState.validation;
        final String questionLabel =
        (itemTitleOverrideForValidation(currentQuestionState, repeatIndex) ?? currentQuestionState.questionText).isNotEmpty
            ? (itemTitleOverrideForValidation(currentQuestionState, repeatIndex) ?? currentQuestionState.questionText)
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
              return 'NIK untuk $questionLabel harus 16 digit angka.';
            }
            if (rule.predefinedRule == 'noKK' &&
                !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
              return 'No. KK untuk $questionLabel harus 16 digit angka.';
            }
            if (rule.predefinedRule == 'email' &&
                !GetUtils.isEmail(effectiveValueString)) {
              return 'Format email untuk $questionLabel tidak valid.';
            }
            if (rule.predefinedRule == 'numbersOnly' &&
                !GetUtils.isNumericOnly(effectiveValueString.replaceAll(',', '').replaceAll('.', ''))) {
              return '$questionLabel hanya boleh berisi angka.';
            }
          }

          // Validasi untuk Tipe Pertanyaan Angka
          if (currentQuestionState.type == QuestionType.number && val != null && val.toString().isNotEmpty) {
            num? numAnswer = num.tryParse(val.toString().replaceAll(',', '.'));

            if (numAnswer == null && val.toString().isNotEmpty) {
              return '$questionLabel harus berupa angka.';
            }

            if (numAnswer != null) {
              // Validasi Min/Max Value
              if (rule.minValue != null && numAnswer < rule.minValue!) {
                return '$questionLabel minimal ${rule.minValue}.';
              }
              if (rule.maxValue != null && numAnswer > rule.maxValue!) {
                return '$questionLabel maksimal ${rule.maxValue}.';
              }

              // ---- AWAL IMPLEMENTASI VALIDASI PERBANDINGAN ----
              if (rule.comparisonOperator != null &&
                  rule.comparisonOperator != ComparisonOperatorType.none.toShortString() &&
                  rule.compareToQuestionId != null &&
                  rule.compareToQuestionId!.isNotEmpty) {

                final String compareToQuestionId = rule.compareToQuestionId!;
                final FormQuestion? targetQuestion = controller.findQuestionById(compareToQuestionId);

                if (targetQuestion != null) {
                  dynamic targetAnswerDynamic;
                  // Cek apakah pertanyaan target berada dalam grup yang sama dan ada repeatIndex
                  if (targetQuestion.belongsToGroupTag != null &&
                      targetQuestion.belongsToGroupTag == currentQuestionState.belongsToGroupTag &&
                      repeatIndex != null &&
                      controller.repeatableGroupAnswers.containsKey(compareToQuestionId)) {
                    targetAnswerDynamic = controller.repeatableGroupAnswers[compareToQuestionId]![repeatIndex];
                  } else if (controller.userAnswers.containsKey(compareToQuestionId)) {
                    // Ambil dari userAnswers jika bukan kasus di atas atau tidak ditemukan di repeatableGroupAnswers
                    targetAnswerDynamic = controller.userAnswers[compareToQuestionId];
                  }


                  if (targetAnswerDynamic != null && targetAnswerDynamic.toString().isNotEmpty) {
                    num? targetNumAnswer = num.tryParse(targetAnswerDynamic.toString().replaceAll(',', '.'));

                    if (targetNumAnswer != null) {
                      String operatorText = _getComparisonOperatorDisplayText(rule.comparisonOperator);
                      String targetQuestionLabel = targetQuestion.code != null && targetQuestion.code!.isNotEmpty
                          ? "${targetQuestion.questionText} (${targetQuestion.code})"
                          : targetQuestion.questionText;

                      bool comparisonResult = false;
                      switch (rule.comparisonOperator) {
                        case 'lessThan': // ComparisonOperatorType.lessThan.toShortString()
                          comparisonResult = numAnswer < targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                        case 'lessThanOrEqual': // ComparisonOperatorType.lessThanOrEqual.toShortString()
                          comparisonResult = numAnswer <= targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                        case 'equal': // ComparisonOperatorType.equal.toShortString()
                          comparisonResult = numAnswer == targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                        case 'notEqual': // ComparisonOperatorType.notEqual.toShortString()
                          comparisonResult = numAnswer != targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                        case 'greaterThan': // ComparisonOperatorType.greaterThan.toShortString()
                          comparisonResult = numAnswer > targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                        case 'greaterThanOrEqual': // ComparisonOperatorType.greaterThanOrEqual.toShortString()
                          comparisonResult = numAnswer >= targetNumAnswer;
                          if (!comparisonResult) return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (nilai dari: $targetQuestionLabel).';
                          break;
                      }
                    } else {
                      // Nilai pertanyaan target tidak valid (bukan angka), mungkin tampilkan warning atau abaikan
                      // Untuk saat ini, kita bisa memilih untuk mengabaikan jika nilai target tidak bisa di-parse,
                      // karena validasi tipe data pertanyaan target seharusnya ditangani oleh validatornya sendiri.
                      // Atau bisa juga: return 'Nilai pertanyaan "${targetQuestion.questionText}" yang dibandingkan bukan angka.';
                    }
                  } else {
                    // Pertanyaan target belum diisi, mungkin tampilkan pesan agar user mengisinya terlebih dahulu
                    // atau abaikan validasi perbandingan ini.
                    // Untuk saat ini, validasi dilewati jika pertanyaan target kosong.
                    // Bisa juga: return 'Isi dulu pertanyaan "${targetQuestion.questionText}" untuk perbandingan.';
                  }
                } else {
                  // Seharusnya tidak terjadi jika konfigurasi benar
                  print("Peringatan: Pertanyaan dengan ID ${compareToQuestionId} untuk perbandingan tidak ditemukan.");
                }
              }
              // ---- AKHIR IMPLEMENTASI VALIDASI PERBANDINGAN ----


              // Contoh validasi custom spesifik yang sudah ada sebelumnya
              if (currentQuestionState.code == "203" ||
                  currentQuestionState.code == "204") {
                final artQuestion = controller.findQuestionByCode("112");
                if (artQuestion != null) {
                  dynamic artCountValueDynamic;
                  if (repeatIndex != null && artQuestion.belongsToGroupTag == currentQuestionState.belongsToGroupTag) {
                    artCountValueDynamic = controller.repeatableGroupAnswers[artQuestion.id]?[repeatIndex];
                  } else {
                    artCountValueDynamic = controller.userAnswers[artQuestion.id];
                  }

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
        return null; // Tidak ada error
      }


      switch (question.type) {
        case QuestionType.text:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            decoration:
            _modernInputDecoration(context, hintText: "Jawaban teks singkat"),
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: (question.validation?.predefinedRule == 'nik' || question.validation?.predefinedRule == 'noKK')
                ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ]
                : (question.validation?.predefinedRule == 'numbersOnly')
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            keyboardType: (question.validation?.predefinedRule == 'nik' || question.validation?.predefinedRule == 'noKK' || question.validation?.predefinedRule == 'numbersOnly')
                ? TextInputType.number
                : TextInputType.text,
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
        case QuestionType.number:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue != null ? initialValue.toString().replaceAll('.', ',') : '',
            decoration: _modernInputDecoration(context, hintText: "Masukkan angka"),
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))], // Memperbolehkan koma untuk desimal
            onChanged: (value) {
              onChangedCallback(value.replaceAll(',', '.')); // Simpan dengan titik sebagai desimal
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
                DateTime? parsedFromDisplay = DateFormat('dd/MM/yyyy').tryParse(initialValue);
                if (parsedFromDisplay != null) {
                  displayDate = initialValue;
                } else {
                  DateTime? parsedDate = DateTime.tryParse(initialValue);
                  if (parsedDate != null) {
                    displayDate = DateFormat('dd/MM/yyyy').format(parsedDate);
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
              if (initialValue is String && initialValue.isNotEmpty) {
                try {
                  initialDatePickerDate = DateFormat('dd/MM/yyyy').parseStrict(initialValue);
                } catch (e) {
                  try {
                    DateTime? parsedInternal = DateTime.tryParse(initialValue);
                    if (parsedInternal != null) initialDatePickerDate = parsedInternal;
                  } catch (e2) { /* biarkan default jika semua parse gagal */ }
                }
              } else if (initialValue is DateTime) {
                initialDatePickerDate = initialValue;
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
          String? currentGroupValue = initialValue as String?;
          return FormField<String>(
              key: ValueKey("${fieldKeyId}_mc_formfield"),
              initialValue: currentGroupValue,
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PERUBAHAN: Membaca List<QuestionOption> untuk membuat RadioListTile ---
                    ...question.options.map((option) { // option sekarang adalah QuestionOption
                      return RadioListTile<String>(
                        key: ValueKey("${fieldKeyId}_${option.value.hashCode}_radio"),
                        title: Text(option.value, style: const TextStyle(fontSize: 15.0)),
                        // Menampilkan deskripsi sebagai subtitle
                        subtitle: (option.description != null && option.description!.isNotEmpty)
                            ? Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                          child: Text(
                            option.description!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                          ),
                        )
                            : null,
                        value: option.value, // Nilai yang disimpan tetap String
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
                        activeColor: accentHeaderColor,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        // Penting agar subtitle dengan banyak baris tidak terpotong
                        isThreeLine: (option.description != null && option.description!.isNotEmpty),
                      );
                    }).toList(),
                    // --- AKHIR PERUBAHAN ---
                    if (question.hasOtherOption)
                      RadioListTile<String>(
                        key: ValueKey("${fieldKeyId}_other_radio"),
                        title: const Text("Lainnya...", style: TextStyle(fontSize: 15.0)),
                        value: _kOtherOptionValue,
                        groupValue: field.value,
                        onChanged: (String? value) {
                          if (value != null) {
                            onChangedCallback(value);
                            field.didChange(value);
                          }
                        },
                        activeColor: accentHeaderColor,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (question.hasOtherOption && field.value == _kOtherOptionValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                        child: TextFormField(
                          key: ValueKey("${fieldKeyId}_other_text_${repeatIndex ?? 'single'}"),
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
              });
        case QuestionType.checkboxes:
          return FormField<List<String>>(
            key: ValueKey("${fieldKeyId}_checkbox_formfield"),
            initialValue: List<String>.from(initialValue as List<dynamic>? ?? []),
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<List<String>> field) {
              bool isOtherCurrentlySelected = field.value?.contains(_kOtherOptionValue) ?? false;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PERUBAHAN: Membaca List<QuestionOption> untuk membuat CheckboxListTile ---
                  ...question.options.map((option) { // option adalah QuestionOption
                    return CheckboxListTile(
                      key: ValueKey("${fieldKeyId}_${option.value.hashCode}_checkbox"),
                      title: Text(option.value, style: const TextStyle(fontSize: 15.0)),
                      // Menampilkan deskripsi sebagai subtitle
                      subtitle: (option.description != null && option.description!.isNotEmpty)
                          ? Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                        child: Text(
                          option.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                        ),
                      )
                          : null,
                      value: field.value?.contains(option.value) ?? false,
                      onChanged: (bool? selected) {
                        final latestSelectedValues = List<String>.from(field.value ?? []);
                        if (selected == true) {
                          if (!latestSelectedValues.contains(option.value)) latestSelectedValues.add(option.value);
                        } else {
                          latestSelectedValues.remove(option.value);
                        }
                        onChangedCallback(latestSelectedValues);
                        field.didChange(latestSelectedValues);
                      },
                      activeColor: accentHeaderColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      // Penting agar subtitle dengan banyak baris tidak terpotong
                      isThreeLine: (option.description != null && option.description!.isNotEmpty),
                    );
                  }).toList(),
                  // --- AKHIR PERUBAHAN ---
                  if (question.hasOtherOption)
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
                  if (question.hasOtherOption && isOtherCurrentlySelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                      child: TextFormField(
                        key: ValueKey("${fieldKeyId}_other_text_checkbox_${repeatIndex ?? 'single'}"),
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
        // List terpadu untuk menampung opsi, baik dari opsi utama maupun dari opsi dependen.
        // Setiap item adalah Map yang berisi 'value' (wajib) dan 'description' (opsional).
          List<Map<String, String?>> unifiedOptions = [];
          bool isDependent = question.dependentOptions != null && question.dependentOptions!.parentQuestionId.isNotEmpty;
          String? parentAnswer;

          if (isDependent) {
            final parentQuestionId = question.dependentOptions!.parentQuestionId;
            // Mendapatkan jawaban dari pertanyaan induk...
            if (repeatIndex != null && controller.repeatableGroupAnswers.containsKey(parentQuestionId)) {
              parentAnswer = controller.repeatableGroupAnswers[parentQuestionId]![repeatIndex] as String?;
            } else {
              parentAnswer = controller.userAnswers[parentQuestionId] as String?;
            }

            // Jika ada jawaban induk, ambil opsi dependennya.
            if (parentAnswer != null && parentAnswer.isNotEmpty) {
              final List<String> dependentOptions = question.dependentOptions!.optionMapping[parentAnswer] ?? [];
              // Ubah List<String> menjadi List<Map> agar strukturnya sama. Deskripsi akan null.
              unifiedOptions = dependentOptions.map((opt) => {'value': opt, 'description': null}).toList();
            }
            // Jika tidak ada jawaban induk, unifiedOptions akan tetap kosong, dan dropdown akan dinonaktifkan.
          } else {
            // Jika bukan dropdown dependen, ambil dari opsi utama.
            unifiedOptions = question.options.map((opt) => {'value': opt.value, 'description': opt.description}).toList();
          }

          // Cek apakah nilai yang tersimpan saat ini masih valid dengan opsi yang ditampilkan.
          String? effectiveInitialValue = initialValue as String?;
          if (effectiveInitialValue != null && !unifiedOptions.any((opt) => opt['value'] == effectiveInitialValue)) {
            effectiveInitialValue = null; // Reset jika tidak valid.
          }

          // Tampilkan pesan jika dropdown dependen belum bisa ditampilkan
          if (isDependent && (parentAnswer == null || parentAnswer.isEmpty)) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pilih jawaban untuk pertanyaan induk terlebih dahulu.",
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }
          if (isDependent && parentAnswer != null && parentAnswer.isNotEmpty && unifiedOptions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Tidak ada opsi yang tersedia untuk pilihan '$parentAnswer'.",
                style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }

          String optionsKeyPart = unifiedOptions.map((e) => e['value']).join(',');
          Key dropdownKey = ValueKey("${fieldKeyId}_${effectiveInitialValue ?? 'null'}_$optionsKeyPart");

          return DropdownButtonFormField<String>(
            key: dropdownKey,
            value: effectiveInitialValue,
            decoration: _modernInputDecoration(context, labelText: "Pilih salah satu"),
            isExpanded: true,
            // --- PERUBAHAN: Membuat item dropdown dengan ListTile untuk mendukung deskripsi ---
            items: unifiedOptions.map((option) {
              final String value = option['value']!;
              final String? description = option['description'];
              return DropdownMenuItem<String>(
                value: value,
                // Menggunakan ListTile agar rapi saat ada deskripsi
                child: Tooltip(
                  message: description ?? '',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(value, style: const TextStyle(fontSize: 15)),
                    subtitle: (description != null && description.isNotEmpty)
                        ? Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, overflow: TextOverflow.ellipsis))
                        : null,
                  ),
                ),
              );
            }).toList(),
            onChanged: (unifiedOptions.isEmpty && isDependent)
                ? null // Nonaktifkan jika dependen dan tidak ada opsi
                : (String? newValue) {
              if (newValue != null) {
                onChangedCallback(newValue);
              }
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.gridNumeric:
          Map<String, Map<String, Map<String, num?>>> effectiveGridAnswers = {};

          if (initialValue is Map && (initialValue as Map).isNotEmpty) {
            final Map<dynamic, dynamic> rawInitialDataMap = initialValue as Map<dynamic, dynamic>;
            if (question.gridRowLabels.isEmpty) {
              if (rawInitialDataMap.entries.isNotEmpty) {
                MapEntry<dynamic, dynamic> targetEntry = rawInitialDataMap.entries.first;
                if (rawInitialDataMap.containsKey("")) { // Prefer empty string key if exists
                  for (final MapEntry<dynamic, dynamic> entryInLoop in rawInitialDataMap.entries) {
                    if (entryInLoop.key == "") {
                      targetEntry = entryInLoop;
                      break;
                    }
                  }
                }
                final rowDataMap = targetEntry.value;
                if (rowDataMap is Map) {
                  try {
                    effectiveGridAnswers[""] = Map<String, Map<String, num?>>.fromEntries(
                        (rowDataMap as Map<dynamic, dynamic>).entries.map((colEntry) {
                          var subColMapData = colEntry.value;
                          if (subColMapData is! Map) subColMapData = <String, dynamic>{}; // Ensure it's a map
                          return MapEntry(
                              colEntry.key.toString(),
                              Map<String, num?>.fromEntries(
                                  (subColMapData as Map<dynamic, dynamic>).entries.map((subColEntry) {
                                    num? cellValueNum;
                                    if (subColEntry.value == null) cellValueNum = null;
                                    else if (subColEntry.value is num) cellValueNum = subColEntry.value as num;
                                    else cellValueNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));
                                    return MapEntry(subColEntry.key.toString(), cellValueNum);
                                  })
                              )
                          );
                        })
                    );
                  } catch (e) {
                    print("Error casting single-row grid data for $fieldKeyId (dalam _buildQuestionInput): $e. rowDataMap: $rowDataMap");
                    effectiveGridAnswers[""] = {}; // Fallback to empty
                  }
                }
              }
            } else { // Multi-row grid
              try {
                effectiveGridAnswers = Map<String, Map<String, Map<String, num?>>>.fromEntries(
                    rawInitialDataMap.entries
                        .where((rowEntry) => question.gridRowLabels.contains(rowEntry.key.toString())) // Only include defined rows
                        .map((rowEntry) {
                      var colMapData = rowEntry.value;
                      if (colMapData is! Map) colMapData = <String, dynamic>{}; // Ensure it's a map
                      return MapEntry(
                          rowEntry.key.toString(),
                          Map<String, Map<String, num?>>.fromEntries(
                              (colMapData as Map<dynamic, dynamic>).entries.map((colEntry) {
                                var subColMapData = colEntry.value;
                                if (subColMapData is! Map) subColMapData = <String, dynamic>{}; // Ensure it's a map
                                return MapEntry(
                                    colEntry.key.toString(),
                                    Map<String, num?>.fromEntries(
                                        (subColMapData as Map<dynamic, dynamic>).entries.map((subColEntry) {
                                          num? valNum;
                                          if (subColEntry.value == null) valNum = null;
                                          else if (subColEntry.value is num) valNum = subColEntry.value as num;
                                          else valNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));
                                          return MapEntry(subColEntry.key.toString(), valNum);
                                        })
                                    )
                                );
                              })
                          )
                      );
                    })
                );
              } catch (e) {
                print("Error casting multi-row gridAnswers for $fieldKeyId: $e. InitialValue: $initialValue");
                // Fallback: initialize with defined rows and empty maps to prevent errors
                for (var rowLabel in question.gridRowLabels) {
                  effectiveGridAnswers[rowLabel] = {};
                }
              }
            }
          }


          if (question.gridColumnLabels.isEmpty || question.gridSubColumnLabels.isEmpty) {
            return Text("Grid Numerik: Konfigurasi label 'Kolom' atau 'Sub-Kolom' belum lengkap.", style: TextStyle(color: Colors.red.shade700));
          }

          List<String> superRowsToRender = question.gridRowLabels.isNotEmpty ? question.gridRowLabels : [""]; // "" for single unnamed super-row

          return FormField<Map<String, Map<String, Map<String, num?>>>>(
              key: ValueKey("${fieldKeyId}_grid_formfield_${superRowsToRender.join('_')}_${question.gridColumnLabels.join('_')}_${question.gridSubColumnLabels.join('_')}_modified"),
              initialValue: effectiveGridAnswers,
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (FormFieldState<Map<String, Map<String, Map<String, num?>>>> field) {
                num? getSafeCellValue(String superRowLabel, String originalGridColLabel, String originalGridSubColLabel) {
                  // Ensure all keys exist before accessing
                  return field.value?[superRowLabel]?[originalGridColLabel]?[originalGridSubColLabel];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: superRowsToRender.map((uiSuperRowLabel) { // uiSuperRowLabel is the "" or actual label
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (uiSuperRowLabel.isNotEmpty && question.gridRowLabels.isNotEmpty) // Display super-row label if not empty
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0, left: 2.0, top: 8.0),
                                    child: Text(uiSuperRowLabel, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: titleTextColor)),
                                  ),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                                  defaultColumnWidth: const MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(85)), // Min width to prevent squishing
                                  children: [
                                    TableRow( // Header Row for SubColumns
                                      decoration: BoxDecoration(color: Colors.grey.shade100),
                                      children: [
                                        const TableCell(child: Padding(padding: EdgeInsets.all(6.0), child: Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))), // Empty top-left cell
                                        ...question.gridSubColumnLabels.map((subColLabel) => TableCell(
                                          verticalAlignment: TableCellVerticalAlignment.middle,
                                          child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0), // Increased padding
                                              child: Text(subColLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        )).toList(),
                                      ],
                                    ),
                                    // Data Rows (one for each originalGridColLabel)
                                    ...question.gridColumnLabels.map((originalGridColLabel) {
                                      return TableRow(
                                        children: [
                                          TableCell( // Row Header (originalGridColLabel)
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0), // Increased padding
                                                  child: Text(originalGridColLabel, style: const TextStyle(fontSize: 12)))),
                                          // Data Cells (TextFormFields)
                                          ...question.gridSubColumnLabels.map((originalGridSubColLabel) {
                                            // Safely get the cell value for display
                                            num? cellValue = getSafeCellValue(uiSuperRowLabel, originalGridColLabel, originalGridSubColLabel);
                                            String cellKeyIdGrid = "${fieldKeyId}_grid_${uiSuperRowLabel}_${originalGridColLabel}_${originalGridSubColLabel}";

                                            return TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.all(2.0), // Padding around TextFormField
                                                child: TextFormField(
                                                  key: ValueKey(cellKeyIdGrid + (cellValue?.toString() ?? "")), // Key includes value for rebuild
                                                  initialValue: cellValue?.toString().replaceAll('.', ',') ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 13),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Padding inside TextFormField
                                                    isDense: true,
                                                    fillColor: Colors.white,
                                                    filled: true,
                                                    errorStyle: const TextStyle(height: 0, fontSize: 0), // Hide default error to prevent layout jump
                                                  ),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
                                                  onChanged: (value) {
                                                    // Update controller state
                                                    controller.updateGridAnswer(
                                                        question.id,
                                                        repeatIndex,
                                                        uiSuperRowLabel, // Pass the correct superRowLabel
                                                        originalGridColLabel,
                                                        originalGridSubColLabel,
                                                        value.replaceAll(',', '.')); // Store with '.'

                                                    // Get the updated grid state from the controller
                                                    var currentGridAnswerState;
                                                    if (repeatIndex != null) {
                                                      currentGridAnswerState = controller.repeatableGroupAnswers[question.id]?[repeatIndex];
                                                    } else {
                                                      currentGridAnswerState = controller.userAnswers[question.id];
                                                    }

                                                    // Update FormField state
                                                    if (currentGridAnswerState is Map<String, Map<String, Map<String, num?>>>) {
                                                      field.didChange(Map<String, Map<String, Map<String, num?>>>.from(currentGridAnswerState));
                                                    } else if (currentGridAnswerState is Map) {
                                                      // Attempt conversion if it's a map but not the exact type (e.g. from Firestore)
                                                      try {
                                                        Map<String, Map<String, Map<String, num?>>> convertedMap = controller.getGridMapForValidation(currentGridAnswerState);
                                                        field.didChange(convertedMap);
                                                      } catch (e) {
                                                        print("Error converting grid state for FormField (onChanged): $e");
                                                        field.didChange({}); // Fallback
                                                      }
                                                    } else {
                                                      field.didChange({}); // Fallback if not a map
                                                    }
                                                  },
                                                  validator: (cellValueString) {
                                                    // Basic validation: ensure it's a number if not empty
                                                    if (cellValueString != null &&
                                                        cellValueString.isNotEmpty &&
                                                        num.tryParse(cellValueString.replaceAll(',', '.')) == null) {
                                                      return 'X'; // Minimal error indicator, main validation by FormField
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
                        padding: const EdgeInsets.only(top: 8.0, left: 0.0), // Display error below the table
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

  String? itemTitleOverrideForValidation(FormQuestion question, int? repeatIndex) {
    if (repeatIndex != null && question.belongsToGroupTag != null) {
      final groupTag = question.belongsToGroupTag!;
      final totalRepeatCount = controller.repeatableGroupCounts[groupTag] ?? 0;
      // return "[Data ${question.code != null && question.code!.isNotEmpty ? question.code : ''} ke-${repeatIndex + 1} dari $totalRepeatCount] ${question.questionText}";
      // Disederhanakan agar tidak terlalu panjang di pesan error
      return "${question.questionText} (data ke-${repeatIndex + 1})";
    }
    return question.questionText;
  }
}


extension GridMapConversion on InputUserController {
  Map<String, Map<String, Map<String, num?>>> getGridMapForValidation(dynamic currentGridData) {
    if (currentGridData is Map<String, Map<String, Map<String, num?>>>) {
      return currentGridData;
    }
    if (currentGridData is Map) {
      try {
        return Map<String, Map<String, Map<String, num?>>>.fromEntries(
            (currentGridData as Map<dynamic, dynamic>).entries.map((rowEntry) {
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
                                  num? cellValueNum;
                                  if (subColEntry.value == null) {
                                    cellValueNum = null;
                                  } else if (subColEntry.value is num) {
                                    cellValueNum = subColEntry.value as num;
                                  } else {
                                    cellValueNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));
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
        print("Error in getGridMapForValidation: $e. Data: $currentGridData");
        return <String, Map<String, Map<String, num?>>>{};
      }
    }
    return <String, Map<String, Map<String, num?>>>{};
  }
}