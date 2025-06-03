// File: input_user_controller.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Pastikan path ini benar
import './input_user_model.dart'; // Pastikan path ini benar

class InputUserController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _kOtherOptionValue = '__other_option_value__';

  final RxBool isLoading = false.obs;
  final RxString formId = ''.obs;
  final Rx<FormItem?> loadedForm = Rx<FormItem?>(null);
  final RxString errorMessage = ''.obs;

  final RxString submissionId = ''.obs;
  RxBool get isEditMode => RxBool(submissionId.value.isNotEmpty);
  final Rx<FormSubmission?> loadedSubmission = Rx<FormSubmission?>(null);

  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  final RxMap<String, RxMap<int, dynamic>> repeatableGroupAnswers = <String, RxMap<int, dynamic>>{}.obs;

  final RxMap<String, String> userOtherAnswers = <String, String>{}.obs;
  final RxMap<String, RxMap<int, String>> repeatableGroupOtherAnswers = <String, RxMap<int, String>>{}.obs;

  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

  final RxMap<String, int> activeRepeatIndexForGroup = <String, int>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<String> _allQuestionIdsInOrder = [];

  final RxString expandedSectionId = ''.obs;

  void toggleSectionExpansion(String sectionId) {
    if (expandedSectionId.value == sectionId) {
      expandedSectionId.value = ''; // Tutup jika sudah terbuka
    } else {
      expandedSectionId.value = sectionId; // Buka jika tertutup
    }
  }

  bool sectionHasAnswers(String sectionId) {
    final section =
    loadedForm.value?.sections.firstWhereOrNull((s) => s.id == sectionId);
    if (section == null) return false;

    for (var question in section.questions) {
      bool hasMainAnswer = false;
      bool hasOtherTextForSelectedOther = false;

      if (question.belongsToGroupTag == null ||
          question.belongsToGroupTag!.isEmpty) {
        hasMainAnswer = userAnswers.containsKey(question.id) &&
            !_isAnswerEmpty(userAnswers[question.id], question.type);
        if (question.hasOtherOption && userAnswers[question.id] == _kOtherOptionValue) {
          hasOtherTextForSelectedOther = userOtherAnswers[question.id]?.isNotEmpty ?? false;
          if (hasMainAnswer && hasOtherTextForSelectedOther) return true;
        } else if (hasMainAnswer) {
          return true;
        }
      } else {
        final groupTag = question.belongsToGroupTag!;
        final count = repeatableGroupCounts[groupTag] ?? 0;
        if (repeatableGroupAnswers.containsKey(question.id)) {
          for (int i = 0; i < count; i++) {
            hasMainAnswer = repeatableGroupAnswers[question.id]!.containsKey(i) &&
                !_isAnswerEmpty(
                    repeatableGroupAnswers[question.id]![i], question.type);

            if (question.hasOtherOption && repeatableGroupAnswers[question.id]![i] == _kOtherOptionValue) {
              hasOtherTextForSelectedOther = repeatableGroupOtherAnswers[question.id]?[i]?.isNotEmpty ?? false;
              if (hasMainAnswer && hasOtherTextForSelectedOther) return true;
            } else if (hasMainAnswer) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }


  @override
  void onInit() {
    super.onInit();
    // print("[InputUserController] onInit triggered.");
    isLoading.value = true;
    final dynamic arguments = Get.arguments;
    String? extractedFormId;
    String? extractedSubmissionId;

    if (arguments != null) {
      if (arguments is String) {
        extractedFormId = arguments;
      } else if (arguments is Map) {
        if (arguments.containsKey('formId') &&
            arguments['formId'] is String &&
            (arguments['formId'] as String).isNotEmpty) {
          extractedFormId = arguments['formId'] as String;
        } else {
          errorMessage.value =
          "Argumen Map tidak berisi 'formId' String yang valid dan tidak kosong. Isi Map: $arguments";
          isLoading.value = false;
          return;
        }
        if (arguments.containsKey('submissionId') &&
            arguments['submissionId'] is String &&
            (arguments['submissionId'] as String).isNotEmpty) {
          extractedSubmissionId = arguments['submissionId'] as String;
          submissionId.value = extractedSubmissionId;
        }
      } else {
        errorMessage.value =
        "Tipe argumen ID Form tidak valid (diterima: ${arguments.runtimeType}).";
        isLoading.value = false;
        return;
      }

      if (extractedFormId != null && extractedFormId.isNotEmpty) {
        formId.value = extractedFormId;
        fetchFormAndPotentialSubmissionData();
      } else {
        errorMessage.value =
        "ID Form kosong atau null setelah ekstraksi dari argumen.";
        isLoading.value = false;
      }
    } else {
      errorMessage.value = "Argumen ID Form tidak ditemukan (null).";
      isLoading.value = false;
    }
  }

  Future<void> fetchFormAndPotentialSubmissionData() async {
    // print("[InputUserController] fetchFormAndPotentialSubmissionData started.");
    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    loadedSubmission.value = null;
    _allQuestionIdsInOrder.clear();
    activeRepeatIndexForGroup.clear();

    expandedSectionId.value = '';

    if (formId.value.isEmpty) {
      errorMessage.value = "ID Form kosong, tidak dapat melanjutkan.";
      isLoading.value = false;
      Get.snackbar('Error Kritis', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return;
    }

    try {
      final formDocSnapshot =
      await _db.collection('adminForms').doc(formId.value).get();
      if (formDocSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(formDocSnapshot);
        if (loadedForm.value != null) {
          _allQuestionIdsInOrder.clear();
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
            }
          }
          if (loadedForm.value!.sections.isNotEmpty) {
            if (loadedForm.value!.sections.length == 1) {
              expandedSectionId.value = loadedForm.value!.sections.first.id;
              // print("[InputUserController] Initial expandedSectionId set to: ${expandedSectionId.value} (Only one section)");
            } else {
              // print("[InputUserController] Multiple sections found, all initially closed. expandedSectionId is empty.");
            }
          } else {
            // print("[InputUserController] No sections found, expandedSectionId is empty.");
          }

        } else {
          errorMessage.value =
          "Gagal memproses struktur form dari Firestore.";
          isLoading.value = false;
          return;
        }
      } else {
        errorMessage.value =
        "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        isLoading.value = false;
        return;
      }

      if (isEditMode.value) {
        final submissionDocSnapshot = await _db
            .collection('formSubmissions')
            .doc(submissionId.value)
            .get();
        if (submissionDocSnapshot.exists) {
          loadedSubmission.value = FormSubmission.fromFirestore(
              submissionDocSnapshot as DocumentSnapshot<Map<String, dynamic>>);
          if (loadedSubmission.value == null) {
            errorMessage.value =
            "Gagal memproses data submission yang ada (ID: ${submissionId.value}). Menampilkan form kosong.";
            Get.snackbar("Peringatan", errorMessage.value,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 4));
          }
        } else {
          errorMessage.value =
          "Data submission dengan ID '${submissionId.value}' tidak ditemukan. Menampilkan form sebagai isian baru.";
          submissionId.value = '';
          Get.snackbar("Info", errorMessage.value,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4));
        }
      }
      _initializeStatesBasedOnMode();
    } catch (e, s) {
      // print("[InputUserController] Error saat fetchFormAndPotentialSubmissionData: $e\n$s");
      errorMessage.value = "Gagal memuat data: ${e.toString()}";
    } finally {
      isLoading.value = false;
      // print("[InputUserController] fetchFormAndPotentialSubmissionData finished. isLoading: ${isLoading.value}");
    }
  }

  dynamic _getDefaultAnswerForQuestionType(QuestionType type) {
    switch (type) {
      case QuestionType.checkboxes:
        return <String>[];
      case QuestionType.gridNumeric:
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
        return null;
      default:
        return '';
    }
  }

  void _initializeStatesBasedOnMode() {
    // print("[InputUserController] _initializeStatesBasedOnMode started.");
    if (loadedForm.value == null) {
      // print("[InputUserController] _initializeStatesBasedOnMode aborted: loadedForm is null.");
      return;
    }

    userAnswers.clear();
    repeatableGroupAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupAnswers.clear();
    userOtherAnswers.clear();
    repeatableGroupOtherAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupOtherAnswers.clear();
    repeatableGroupCounts.clear();
    questionVisibility.clear();
    activeRepeatIndexForGroup.clear();

    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null) continue;

      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        userAnswers[question.id] = _getDefaultAnswerForQuestionType(question.type);
        if (question.hasOtherOption) {
          userOtherAnswers[question.id] = '';
        }
      }
      else if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
        if (!repeatableGroupAnswers.containsKey(question.id)) {
          repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.hasOtherOption && !repeatableGroupOtherAnswers.containsKey(question.id)) {
          repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
        }
      }
    }

    if (isEditMode.value && loadedSubmission.value != null) {
      // print("[InputUserController] Populating answers from submission.");
      _populateAnswersFromSubmission();
    } else {
      // print("[InputUserController] Initializing answers for new form / no submission.");
      for (var qId in _allQuestionIdsInOrder) {
        final question = findQuestionById(qId);
        if (question == null) continue;
        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          dynamic controllerAnswer = userAnswers[question.id];
          int count = 0;
          if (controllerAnswer is String && controllerAnswer.isNotEmpty) count = int.tryParse(controllerAnswer) ?? 0;
          else if (controllerAnswer is num) count = controllerAnswer.toInt();

          repeatableGroupCounts[question.controlledGroupTag!] = count;
          if (count > 0) {
            activeRepeatIndexForGroup.putIfAbsent(question.controlledGroupTag!, () => 0);
          }
          _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
        }
      }
    }

    userAnswers.refresh();
    userOtherAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
    repeatableGroupCounts.refresh();
    activeRepeatIndexForGroup.refresh();

    _initializeAndEvaluateInitialVisibility();
    // print("[InputUserController] _initializeStatesBasedOnMode finished.");
  }

  Future<void> fetchFormStructure() async {
    // print("[InputUserController] fetchFormStructure started.");
    if (formId.value.isEmpty) {
      errorMessage.value =
      "ID Form kosong atau tidak valid. Tidak dapat memuat form.";
      isLoading.value = false;
      loadedForm.value = null;
      Get.snackbar('Error Kritis', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    _allQuestionIdsInOrder.clear();

    expandedSectionId.value = '';

    try {
      final docSnapshot =
      await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        if (loadedForm.value != null) {
          _allQuestionIdsInOrder.clear();
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
            }
          }
          if (loadedForm.value!.sections.isNotEmpty) {
            if (loadedForm.value!.sections.length == 1) {
              expandedSectionId.value = loadedForm.value!.sections.first.id;
              // print("[InputUserController] fetchFormStructure - Initial expandedSectionId set to: ${expandedSectionId.value} (Only one section)");
            } else {
              // print("[InputUserController] fetchFormStructure - Multiple sections found, all initially closed. expandedSectionId is empty.");
            }
          } else {
            // print("[InputUserController] fetchFormStructure - No sections, expandedSectionId is empty.");
          }
          _initializeStatesBasedOnMode();
        } else {
          errorMessage.value = "Gagal memproses struktur form dari Firestore.";
        }
      } else {
        errorMessage.value =
        "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        loadedForm.value = null;
      }
    } catch (e, s) {
      // print("[InputUserController] Error saat fetchFormStructure: $e\n$s");
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      loadedForm.value = null;
      Get.snackbar('Error Memuat', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
      // print("[InputUserController] fetchFormStructure finished.");
    }
  }

  void _populateAnswersFromSubmission() {
    if (loadedSubmission.value == null || loadedForm.value == null) return;

    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null) continue;
      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        userAnswers[question.id] = _getDefaultAnswerForQuestionType(question.type);
        if (question.hasOtherOption) {
          userOtherAnswers[question.id] = '';
        }
      }
    }

    Map<String, int> tempGroupCounts = {};

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      bool isRepeatableMemberInstance = false;
      int? potentialRepeatIndex;

      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        potentialRepeatIndex = int.tryParse(parts.last);
        if (potentialRepeatIndex != null) {
          originalQuestionId = parts.sublist(0, parts.length - 1).join('_');
          isRepeatableMemberInstance = true;
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null) continue;

      dynamic mappedMainAnswer;
      String? otherText;

      if (questionDef.hasOtherOption) {
        if (savedAnswer.answer is String) {
          bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
          if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
            mappedMainAnswer = _kOtherOptionValue;
            otherText = savedAnswer.answer as String;
          } else {
            mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else if (savedAnswer.answer is List && questionDef.type == QuestionType.checkboxes) {
          List<String> tempCheckboxAnswers = [];
          List<String> otherTextsFound = [];
          for (var item in (savedAnswer.answer as List)) {
            if (questionDef.options.contains(item.toString())) {
              tempCheckboxAnswers.add(item.toString());
            } else if (item.toString().isNotEmpty) {
              otherTextsFound.add(item.toString());
            }
          }
          if (otherTextsFound.isNotEmpty) {
            tempCheckboxAnswers.add(_kOtherOptionValue);
            otherText = otherTextsFound.join(', ');
          }
          mappedMainAnswer = tempCheckboxAnswers;
        } else {
          mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }
      } else {
        mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
      }

      if (!isRepeatableMemberInstance) {
        userAnswers[originalQuestionId] = mappedMainAnswer;
        if (otherText != null) {
          userOtherAnswers[originalQuestionId] = otherText;
        }
        if (questionDef.isRepeatableGroupController && questionDef.controlledGroupTag != null) {
          int count = 0;
          if (mappedMainAnswer is String && mappedMainAnswer.isNotEmpty) count = int.tryParse(mappedMainAnswer) ?? 0;
          else if (mappedMainAnswer is num) count = mappedMainAnswer.toInt();
          tempGroupCounts[questionDef.controlledGroupTag!] = count;
        }
      }
    }

    tempGroupCounts.forEach((tag, count) {
      repeatableGroupCounts[tag] = count;
      if (count > 0) {
        activeRepeatIndexForGroup.putIfAbsent(tag, () => 0);
      } else {
        activeRepeatIndexForGroup.remove(tag);
      }
      _adjustRepeatableGroupAnswers(tag, count);
    });

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      int? repeatIndex;

      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        final potentialIndex = int.tryParse(parts.last);
        if (potentialIndex != null) {
          originalQuestionId = parts.sublist(0, parts.length - 1).join('_');
          repeatIndex = potentialIndex;
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null || questionDef.belongsToGroupTag == null || questionDef.belongsToGroupTag!.isEmpty || repeatIndex == null) {
        continue;
      }

      if (repeatableGroupAnswers.containsKey(originalQuestionId) &&
          repeatIndex < (repeatableGroupCounts[questionDef.belongsToGroupTag!] ?? 0) ) {

        dynamic mappedMainAnswerRepeat;
        String? otherTextRepeat;

        if (questionDef.hasOtherOption) {
          if (savedAnswer.answer is String) {
            bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
            if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
              mappedMainAnswerRepeat = _kOtherOptionValue;
              otherTextRepeat = savedAnswer.answer as String;
            } else {
              mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
            }
          } else if (savedAnswer.answer is List && questionDef.type == QuestionType.checkboxes) {
            List<String> tempCheckboxAnswers = [];
            List<String> otherTextsFound = [];
            for (var item in (savedAnswer.answer as List)) {
              if (questionDef.options.contains(item.toString())) {
                tempCheckboxAnswers.add(item.toString());
              } else if (item.toString().isNotEmpty){
                otherTextsFound.add(item.toString());
              }
            }
            if(otherTextsFound.isNotEmpty){
              tempCheckboxAnswers.add(_kOtherOptionValue);
              otherTextRepeat = otherTextsFound.join(', ');
            }
            mappedMainAnswerRepeat = tempCheckboxAnswers;
          } else {
            mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else {
          mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }

        repeatableGroupAnswers[originalQuestionId]![repeatIndex] = mappedMainAnswerRepeat;
        if (otherTextRepeat != null && repeatableGroupOtherAnswers.containsKey(originalQuestionId)) {
          if(!repeatableGroupOtherAnswers[originalQuestionId]!.containsKey(repeatIndex)){
            repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = '';
          }
          repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = otherTextRepeat;
        }
      }
    }
  }

  bool questionShouldBeVisible(String groupTag) {
    final controllerQ = loadedForm.value?.sections
        .expand((s) => s.questions)
        .firstWhereOrNull((q) => q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
    if (controllerQ != null) {
      return questionVisibility[controllerQ.id] ?? true;
    }
    return true;
  }

  dynamic _mapAnswerToCorrectType(dynamic rawAnswer, FormQuestion questionDef) {
    if (rawAnswer == null) {
      return _getDefaultAnswerForQuestionType(questionDef.type);
    }
    switch (questionDef.type) {
      case QuestionType.checkboxes:
        if (rawAnswer is List) {
          return List<String>.from(rawAnswer.map((item) => item.toString()));
        }
        return <String>[];
      case QuestionType.number:
        if (rawAnswer is num) return rawAnswer.toString().replaceAll('.', ',');
        if (rawAnswer is String) {
          return rawAnswer;
        }
        return (num.tryParse(rawAnswer.toString().replaceAll(',', '.'))?.toString().replaceAll('.', ',') ?? '');
      case QuestionType.date:
        if (rawAnswer is Timestamp) {
          return DateFormat('dd/MM/yyyy').format(rawAnswer.toDate());
        }
        if (rawAnswer is String) {
          try {
            DateFormat('dd/MM/yyyy').parseStrict(rawAnswer);
            return rawAnswer;
          } catch (_) {
            try {
              return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawAnswer));
            } catch (e) {
              // print("[InputUserController] Peringatan: Gagal mem-parse string tanggal '$rawAnswer' di _mapAnswerToCorrectType.");
              return rawAnswer;
            }
          }
        }
        return rawAnswer.toString();
      case QuestionType.gridNumeric:
        if (rawAnswer is Map) {
          try {
            return Map<String, Map<String, Map<String, num?>>>.fromEntries(
                (rawAnswer as Map<dynamic,dynamic>).entries.map((rowEntry) {
                  String effectiveRowKey = rowEntry.key.toString();
                  if ((questionDef.gridRowLabels.isEmpty) && effectiveRowKey == "default_row") {
                    effectiveRowKey = "";
                  }

                  var colMap = rowEntry.value;
                  if (colMap is! Map) colMap = <String, dynamic>{};

                  return MapEntry(
                      effectiveRowKey,
                      Map<String, Map<String, num?>>.fromEntries(
                          (colMap as Map<dynamic,dynamic>).entries.map((colEntry) {
                            var subColMap = colEntry.value;
                            if (subColMap is! Map) subColMap = <String, dynamic>{};
                            return MapEntry(
                                colEntry.key.toString(),
                                Map<String, num?>.fromEntries(
                                    (subColMap as Map<dynamic,dynamic>).entries.map((subColEntry) {
                                      num? valNum;
                                      if (subColEntry.value == null) {
                                        valNum = null;
                                      } else if (subColEntry.value is num) {
                                        valNum = subColEntry.value as num?;
                                      } else {
                                        valNum = num.tryParse((subColEntry.value.toString())
                                            .replaceAll(',', '.'));
                                      }
                                      return MapEntry(subColEntry.key.toString(), valNum);
                                    })));
                          })));
                }));
          } catch (e) {
            // print("[InputUserController] Error casting grid data in _mapAnswerToCorrectType (QID: ${questionDef.id}): $e. Data: $rawAnswer");
            return <String, Map<String, Map<String, num?>>>{};
          }
        }
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
      case QuestionType.multipleChoice:
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString() ?? _getDefaultAnswerForQuestionType(questionDef.type);
      default:
        return rawAnswer.toString();
    }
  }

  void _initializeAndEvaluateInitialVisibility() {
    // print("[InputUserController] _initializeAndEvaluateInitialVisibility started.");
    if (_allQuestionIdsInOrder.isEmpty || loadedForm.value == null) {
      questionVisibility.clear();
      questionVisibility.refresh();
      // print("[InputUserController] _initializeAndEvaluateInitialVisibility aborted: No questions or form not loaded.");
      return;
    }

    for (String qId in _allQuestionIdsInOrder) {
      questionVisibility[qId] = false;
    }

    String? firstQuestionIdInForm = _allQuestionIdsInOrder.firstOrNull;
    if (firstQuestionIdInForm != null) {
      final firstQuestion = findQuestionById(firstQuestionIdInForm);
      if (firstQuestion != null) {
        // print("[InputUserController] First question to make visible: ${firstQuestion.id}");
        questionVisibility[firstQuestionIdInForm] = true;

        if (firstQuestion.belongsToGroupTag != null &&
            (repeatableGroupCounts[firstQuestion.belongsToGroupTag!] ?? 0) > 0) {
          activeRepeatIndexForGroup.putIfAbsent(firstQuestion.belongsToGroupTag!, () => 0);
        }

        dynamic firstAnswer = _getAnswerForEvaluation(firstQuestion);
        // print("[InputUserController] Evaluating jumps for first question: ${firstQuestion.id} with answer: $firstAnswer");
        evaluateAndExecuteJumps(firstQuestionIdInForm, firstAnswer);
      } else {
        // print("[InputUserController] _initializeAndEvaluateInitialVisibility: First question definition not found for ID $firstQuestionIdInForm.");
      }
    } else {
      // print("[InputUserController] _initializeAndEvaluateInitialVisibility: No questions in _allQuestionIdsInOrder.");
    }
    questionVisibility.refresh();
    activeRepeatIndexForGroup.refresh();
    // print("[InputUserController] _initializeAndEvaluateInitialVisibility finished. Current expandedSectionId: ${expandedSectionId.value}");
  }

  dynamic _getAnswerForEvaluation(FormQuestion question, {int? specificRepeatIndex}) {
    if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
      final groupTag = question.belongsToGroupTag!;
      final int indexToUse = specificRepeatIndex ?? activeRepeatIndexForGroup[groupTag] ?? 0;
      final count = repeatableGroupCounts[groupTag] ?? 0;

      if (indexToUse >= 0 && indexToUse < count &&
          repeatableGroupAnswers.containsKey(question.id) &&
          repeatableGroupAnswers[question.id]!.containsKey(indexToUse)) {
        return repeatableGroupAnswers[question.id]![indexToUse];
      }
      return _getDefaultAnswerForQuestionType(question.type);
    }
    return userAnswers[question.id] ?? _getDefaultAnswerForQuestionType(question.type);
  }

  FormQuestion? findQuestionById(String questionId) {
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (q.id == questionId) return q;
      }
    }
    return null;
  }

  FormQuestion? findQuestionByCode(String questionCode) {
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (q.code == questionCode) return q;
      }
    }
    return null;
  }

  String? getOtherAnswer(String questionId, {int? repeatIndex}) {
    if (repeatIndex != null && repeatableGroupOtherAnswers.containsKey(questionId)) {
      return repeatableGroupOtherAnswers[questionId]![repeatIndex];
    } else if (userOtherAnswers.containsKey(questionId)){
      return userOtherAnswers[questionId];
    }
    return null;
  }

  void updateOtherAnswer(String questionId, String value, {int? repeatIndex}) {
    final question = findQuestionById(questionId);
    if (question == null) return;

    if (repeatIndex != null && question.belongsToGroupTag != null) {
      if (!repeatableGroupOtherAnswers.containsKey(questionId)) {
        repeatableGroupOtherAnswers[questionId] = RxMap<int, String>();
      }
      final groupTag = question.belongsToGroupTag!;
      final count = repeatableGroupCounts[groupTag] ?? 0;
      if (repeatIndex < count) {
        if(!repeatableGroupOtherAnswers[questionId]!.containsKey(repeatIndex)){
          repeatableGroupOtherAnswers[questionId]![repeatIndex] = '';
        }
        repeatableGroupOtherAnswers[questionId]![repeatIndex] = value;
      } else {
        // print("[InputUserController] Peringatan: updateOtherAnswer untuk repeatIndex $repeatIndex (QID: $questionId) di luar batas count $count.");
        return;
      }
    } else {
      userOtherAnswers[questionId] = value;
    }
  }

  String? _getSectionIdForQuestion(String? questionId) {
    if (loadedForm.value == null || questionId == null) return null;
    for (var section in loadedForm.value!.sections) {
      if (section.questions.any((q) => q.id == questionId)) {
        return section.id;
      }
    }
    // print("[InputUserController] Peringatan: _getSectionIdForQuestion tidak menemukan section untuk questionId '$questionId'.");
    return null;
  }

  String? _getFirstQuestionIdOfSection(String? sectionId) {
    if (loadedForm.value == null || sectionId == null) return null;
    final section =
    loadedForm.value!.sections.firstWhereOrNull((s) => s.id == sectionId);
    return section?.questions.isNotEmpty == true
        ? section!.questions.first.id
        : null;
  }

  void _resetDependentChildrenAnswers(String parentQuestionId, {bool calledFromJumpClear = false}) {
    if (loadedForm.value == null) return;
    for (var qId in _allQuestionIdsInOrder) {
      final qChild = findQuestionById(qId);
      if (qChild == null || qChild.dependentOptions?.parentQuestionId != parentQuestionId) continue;

      if (questionVisibility[qChild.id] == true || calledFromJumpClear) {
        dynamic defaultValue = _getDefaultAnswerForQuestionType(qChild.type);

        if (qChild.belongsToGroupTag == null || qChild.belongsToGroupTag!.isEmpty) {
          if (userAnswers[qChild.id] != defaultValue) {
            userAnswers[qChild.id] = defaultValue;
            if (qChild.hasOtherOption) userOtherAnswers[qChild.id] = '';
            _resetDependentChildrenAnswers(qChild.id, calledFromJumpClear: true);
          }
        } else {
          final groupTag = qChild.belongsToGroupTag!;
          final parentQuestion = findQuestionById(parentQuestionId);
          final count = repeatableGroupCounts[groupTag] ?? 0;

          for (int i = 0; i < count; i++) {
            bool shouldResetThisInstance = false;
            if (parentQuestion?.belongsToGroupTag == qChild.belongsToGroupTag) {
              shouldResetThisInstance = true;
            } else if (parentQuestion?.belongsToGroupTag == null) {
              shouldResetThisInstance = true;
            }
            else if (parentQuestion?.isRepeatableGroupController == true && parentQuestion?.controlledGroupTag == qChild.belongsToGroupTag) {
              shouldResetThisInstance = true;
            }

            if (shouldResetThisInstance &&
                repeatableGroupAnswers.containsKey(qChild.id) &&
                repeatableGroupAnswers[qChild.id]!.containsKey(i) &&
                repeatableGroupAnswers[qChild.id]![i] != defaultValue) {
              repeatableGroupAnswers[qChild.id]![i] = defaultValue;
              if (qChild.hasOtherOption && repeatableGroupOtherAnswers.containsKey(qChild.id)) {
                if (repeatableGroupOtherAnswers[qChild.id]!.containsKey(i)){
                  repeatableGroupOtherAnswers[qChild.id]![i] = '';
                }
              }
            }
          }
        }
      }
    }
  }

  void _clearAnswersForSkippedQuestions(List<String> skippedQuestionIds) {
    if (skippedQuestionIds.isEmpty) return;
    for (String qId in skippedQuestionIds) {
      final question = findQuestionById(qId);
      if (question == null) continue;
      dynamic defaultValue = _getDefaultAnswerForQuestionType(question.type);

      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        if (userAnswers.containsKey(qId) && userAnswers[qId] != defaultValue) {
          userAnswers[qId] = defaultValue;
        }
        if (question.hasOtherOption && userOtherAnswers.containsKey(qId) && userOtherAnswers[qId]!.isNotEmpty) {
          userOtherAnswers[qId] = '';
        }
        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          final groupTag = question.controlledGroupTag!;
          if ((repeatableGroupCounts[groupTag] ?? 0) > 0 || (userAnswers[qId]?.toString() ?? '0') != '0') {
            userAnswers[qId] = '0';
            repeatableGroupCounts[groupTag] = 0;
            _adjustRepeatableGroupAnswers(groupTag, 0);
          }
        }
      } else {
        final groupTag = question.belongsToGroupTag!;
        final count = repeatableGroupCounts[groupTag] ?? 0;
        if (repeatableGroupAnswers.containsKey(qId)) {
          final answerMap = repeatableGroupAnswers[qId]!;
          for (int i = 0; i < count; i++) {
            if (answerMap.containsKey(i) && answerMap[i] != defaultValue) {
              answerMap[i] = defaultValue;
            }
            if (question.hasOtherOption && repeatableGroupOtherAnswers.containsKey(qId)) {
              final otherAnswerMap = repeatableGroupOtherAnswers[qId]!;
              if (otherAnswerMap.containsKey(i) && otherAnswerMap[i]!.isNotEmpty) {
                otherAnswerMap[i] = '';
              }
            }
          }
        }
      }
      _resetDependentChildrenAnswers(qId, calledFromJumpClear: true);
    }
  }

  void evaluateAndExecuteJumps(String currentQuestionId, dynamic answerValue) {
    // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId, Answer: '$answerValue', Visibility: ${questionVisibility[currentQuestionId]}");

    final question = findQuestionById(currentQuestionId);
    if (question == null || loadedForm.value == null) {
      // print("[evaluateAndExecuteJumps] Aborted: Question or Form not loaded for Q_ID: $currentQuestionId");
      return;
    }

    bool isCurrentlyVisible = questionVisibility[currentQuestionId] ?? false;
    if (!isCurrentlyVisible && !isLoading.value) {
      // print("[evaluateAndExecuteJumps] Aborted: Q_ID: $currentQuestionId not visible and not initial loading phase.");
      return;
    }

    String? jumpToTargetCompositeValue;
    dynamic effectiveAnswerForJump = answerValue;

    if (question.hasOtherOption && answerValue == _kOtherOptionValue) {
      int? currentRepeatIndexForEval;
      if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
        final groupTag = question.belongsToGroupTag!;
        currentRepeatIndexForEval = activeRepeatIndexForGroup[groupTag] ?? 0;
        if (currentRepeatIndexForEval >= (repeatableGroupCounts[groupTag] ?? 0)) {
          currentRepeatIndexForEval = null;
        }
      }
      effectiveAnswerForJump = getOtherAnswer(currentQuestionId, repeatIndex: currentRepeatIndexForEval) ?? "";
    }

    if (question.unconditionalJumpTarget != null &&
        question.unconditionalJumpTarget!.isNotEmpty) {
      jumpToTargetCompositeValue = question.unconditionalJumpTarget;
      // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - Unconditional jump to: $jumpToTargetCompositeValue");
    } else if (question.conditionalJumps.isNotEmpty) {
      String currentAnswerString = effectiveAnswerForJump?.toString() ?? "";
      for (var jumpRule in question.conditionalJumps) {
        if (jumpRule.conditionValue == currentAnswerString) {
          if (jumpRule.jumpToQuestionId == 'END_OF_FORM') {
            jumpToTargetCompositeValue = 'end_of_form';
          } else if (jumpRule.jumpToQuestionId == 'END_OF_SECTION') {
            jumpToTargetCompositeValue =
            (jumpRule.jumpToSectionId != null &&
                jumpRule.jumpToSectionId!.isNotEmpty)
                ? 'section_start_${jumpRule.jumpToSectionId}'
                : 'end_of_current_section';
          } else if (jumpRule.jumpToQuestionId.isNotEmpty) {
            jumpToTargetCompositeValue =
            'question_${jumpRule.jumpToQuestionId}';
          }
          if (jumpToTargetCompositeValue != null) {
            // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - Conditional jump to: $jumpToTargetCompositeValue based on answer: '$currentAnswerString'");
            break;
          }
        }
      }
    }

    if (jumpToTargetCompositeValue != null) {
      _performJump(currentQuestionId, jumpToTargetCompositeValue);
    } else {
      // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - No jump rule met. Proceeding sequentially.");
      int currentIndex = _allQuestionIdsInOrder.indexOf(currentQuestionId);
      bool localVisibilityChanged = false;
      bool localGroupIndexChanged = false;

      if (currentIndex != -1 &&
          currentIndex + 1 < _allQuestionIdsInOrder.length) {
        String nextQuestionInSequenceId =
        _allQuestionIdsInOrder[currentIndex + 1];
        // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - Next sequential Q_ID: $nextQuestionInSequenceId");

        final nextQDef = findQuestionById(nextQuestionInSequenceId);
        if (nextQDef == null) {
          // print("[evaluateAndExecuteJumps] Aborted sequential: Next Q_ID def $nextQuestionInSequenceId not found.");
          return;
        }

        if (questionVisibility[nextQuestionInSequenceId] != true) {
          questionVisibility[nextQuestionInSequenceId] = true;
          localVisibilityChanged = true;
        }

        if (nextQDef.belongsToGroupTag != null && (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) > 0) {
          if (!activeRepeatIndexForGroup.containsKey(nextQDef.belongsToGroupTag!)) {
            activeRepeatIndexForGroup.putIfAbsent(nextQDef.belongsToGroupTag!, () => 0);
            localGroupIndexChanged = true;
          } else if (activeRepeatIndexForGroup[nextQDef.belongsToGroupTag!]! >= (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) &&
              (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) > 0) {
            activeRepeatIndexForGroup[nextQDef.belongsToGroupTag!] = 0;
            localGroupIndexChanged = true;
          }
        }

        if(localVisibilityChanged){
          questionVisibility.refresh();
        }
        if(localGroupIndexChanged){
          activeRepeatIndexForGroup.refresh();
        }

        dynamic nextAnswer = _getAnswerForEvaluation(nextQDef);
        evaluateAndExecuteJumps(nextQuestionInSequenceId, nextAnswer);
      } else {
        // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - No next sequential question (end of form or list).");
      }
    }
  }

  void _performJump(String currentQuestionId, String targetCompositeValue) {
    // print("[_performJump] currentQ: $currentQuestionId, targetComposite: $targetCompositeValue, currentExpandedSection: ${expandedSectionId.value}");

    if (loadedForm.value == null) return;
    final currentIndexInOrder = _allQuestionIdsInOrder.indexOf(currentQuestionId);
    if (currentIndexInOrder == -1) {
      // print("[_performJump] Peringatan: currentQuestionId '$currentQuestionId' tidak ada dalam _allQuestionIdsInOrder.");
      return;
    }

    bool visibilityChangedInPerformJump = false;
    String? effectiveNextVisibleQId;

    List<String> parts = targetCompositeValue.split('_');
    String type = parts.first;
    String? targetEntityId;

    if (type == 'question' && parts.length > 1) {
      targetEntityId = parts.sublist(1).join('_');
      effectiveNextVisibleQId = targetEntityId;
    } else if (type == 'section' && parts.length > 2 && parts[1] == 'start') {
      targetEntityId = parts.sublist(2).join('_');
      effectiveNextVisibleQId = _getFirstQuestionIdOfSection(targetEntityId);
    } else if (targetCompositeValue == 'end_of_current_section') {
      final currentSectionId = _getSectionIdForQuestion(currentQuestionId);
      if (currentSectionId != null) {
        int currentSecIdx = loadedForm.value!.sections.indexWhere((s) => s.id == currentSectionId);
        if (currentSecIdx != -1 && currentSecIdx + 1 < loadedForm.value!.sections.length) {
          effectiveNextVisibleQId = _getFirstQuestionIdOfSection(loadedForm.value!.sections[currentSecIdx + 1].id);
        } else {
          effectiveNextVisibleQId = null;
        }
      } else {
        effectiveNextVisibleQId = null;
      }
    } else if (targetCompositeValue == 'end_of_form') {
      effectiveNextVisibleQId = null;
    }

    // final String? initialEffectiveNextVisibleQIdForLog = effectiveNextVisibleQId; // Digunakan untuk logging sebelumnya

    if (effectiveNextVisibleQId != null && !_allQuestionIdsInOrder.contains(effectiveNextVisibleQId)) {
      // print("[_performJump] Peringatan: Target lompatan '$effectiveNextVisibleQId' dari '$initialEffectiveNextVisibleQIdForLog' tidak ditemukan dalam _allQuestionIdsInOrder. Dibatalkan menjadi null (lompat ke akhir).");
      effectiveNextVisibleQId = null;
    }

    List<String> idsToActuallyHideAndClear = [];
    for (int i = currentIndexInOrder + 1; i < _allQuestionIdsInOrder.length; i++) {
      String qIdToProcess = _allQuestionIdsInOrder[i];
      if (qIdToProcess == effectiveNextVisibleQId) continue;

      idsToActuallyHideAndClear.add(qIdToProcess);
      if (questionVisibility[qIdToProcess] != false) {
        questionVisibility[qIdToProcess] = false;
        visibilityChangedInPerformJump = true;
      }
    }

    if (idsToActuallyHideAndClear.isNotEmpty) {
      _clearAnswersForSkippedQuestions(idsToActuallyHideAndClear);
    }

    bool groupIndexChangedInPerformJump = false;
    if (effectiveNextVisibleQId != null) {
      final targetQuestionDef = findQuestionById(effectiveNextVisibleQId);
      if (targetQuestionDef != null) {
        if (questionVisibility[effectiveNextVisibleQId] != true) {
          questionVisibility[effectiveNextVisibleQId] = true;
          visibilityChangedInPerformJump = true;
        }
        if (targetQuestionDef.belongsToGroupTag != null &&
            (repeatableGroupCounts[targetQuestionDef.belongsToGroupTag!] ?? 0) > 0) {
          if (!activeRepeatIndexForGroup.containsKey(targetQuestionDef.belongsToGroupTag!) || activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] != 0 ) {
            activeRepeatIndexForGroup.putIfAbsent(targetQuestionDef.belongsToGroupTag!, () => 0);
            if(activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] != 0) groupIndexChangedInPerformJump = true;
            activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] = 0;
          }
        }
      } else {
        // print("[_performJump] Peringatan: Definisi pertanyaan untuk target lompatan '$effectiveNextVisibleQId' tidak ditemukan. Lompatan dibatalkan menjadi null.");
        effectiveNextVisibleQId = null;
      }
    }

    /*
    final targetSectionIdActual = _getSectionIdForQuestion(effectiveNextVisibleQId);
    // print("[_performJump] effectiveNextQ_final: $effectiveNextVisibleQId, targetSectionActual: $targetSectionIdActual, initialEffectiveQ: $initialEffectiveNextVisibleQIdForLog");
    if (targetSectionIdActual != null &&
        expandedSectionId.value != targetSectionIdActual &&
        (loadedForm.value?.sections.length ?? 0) > 1) {
      // print("[_performJump] Mengubah expandedSectionId dari '${expandedSectionId.value}' ke '$targetSectionIdActual'");
      // expandedSectionId.value = targetSectionIdActual; // DIKOMENTARI
    } else if (targetSectionIdActual == null && effectiveNextVisibleQId == null) {
      // print("[_performJump] Lompat ke akhir form/section. expandedSectionId tidak diubah dari '${expandedSectionId.value}'.");
    } else if (targetSectionIdActual != null && expandedSectionId.value == targetSectionIdActual) {
      // print("[_performJump] Target lompatan berada di section yang sama (${targetSectionIdActual}). expandedSectionId tidak diubah.");
    }
    else {
      // print("[_performJump] Kondisi untuk mengubah expandedSectionId tidak terpenuhi. targetSectionActual: $targetSectionIdActual, currentExpanded: ${expandedSectionId.value}");
    }
    */

    if (visibilityChangedInPerformJump) {
      questionVisibility.refresh();
    }
    if(groupIndexChangedInPerformJump || (effectiveNextVisibleQId != null && findQuestionById(effectiveNextVisibleQId)?.belongsToGroupTag != null)){
      activeRepeatIndexForGroup.refresh();
    }

    if (effectiveNextVisibleQId != null && (questionVisibility[effectiveNextVisibleQId] == true)) {
      final targetQuestionDef = findQuestionById(effectiveNextVisibleQId);
      if (targetQuestionDef != null) {
        dynamic targetAnswer = _getAnswerForEvaluation(targetQuestionDef);
        // print("[_performJump] Melakukan evaluasi rekursif untuk Q_ID: $effectiveNextVisibleQId");
        evaluateAndExecuteJumps(effectiveNextVisibleQId, targetAnswer);
      } else {
        // print("[_performJump] Tidak ada evaluasi rekursif karena target question def null untuk Q_ID: $effectiveNextVisibleQId");
      }
    } else {
      // print("[_performJump] Tidak ada evaluasi rekursif. effectiveNextQ: $effectiveNextVisibleQId, visibility: ${effectiveNextVisibleQId != null ? questionVisibility[effectiveNextVisibleQId] : 'N/A'}");
    }
    // print("[_performJump] Selesai untuk currentQ: $currentQuestionId. Final expandedSectionId: ${expandedSectionId.value}");
  }

  void updateUserAnswer(String questionId, dynamic value) {
    final question = findQuestionById(questionId);
    if (question == null) return;

    dynamic actualUpdatedValue = value;
    dynamic valueBeforeUpdate = userAnswers[questionId];

    if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
      int count = 0;
      if (value is String && value.isNotEmpty) {
        count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (value is num) {
        count = value.toInt();
      }

      final ValidationRule? qValidation = question.validation;
      if (qValidation != null) {
        if (qValidation.minValue != null && count < qValidation.minValue!) count = qValidation.minValue!.toInt();
        if (qValidation.maxValue != null && count > qValidation.maxValue!) count = qValidation.maxValue!.toInt();
      }
      if (question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = _getAnswerForEvaluation(artQuestion);
          num? artCount = (artCountValueDynamic is String && artCountValueDynamic.isNotEmpty)
              ? num.tryParse(artCountValueDynamic.replaceAll(',', '.'))
              : (artCountValueDynamic is num ? artCountValueDynamic : null);
          if (artCount != null && count > artCount) {
            count = artCount.toInt();
            Get.snackbar("Info Validasi", "Jumlah ${question.questionText} tidak boleh melebihi ${artQuestion.questionText} ($artCount). Dibatasi menjadi $count.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
          }
        }
      }
      actualUpdatedValue = count.toString();

      if ((repeatableGroupCounts[question.controlledGroupTag!] ?? 0) != count ||
          (userAnswers[questionId]?.toString() ?? '0') != actualUpdatedValue) {
        userAnswers[questionId] = actualUpdatedValue;
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
        activeRepeatIndexForGroup.refresh();
      } else {
        userAnswers[questionId] = actualUpdatedValue;
      }
    } else {
      userAnswers[questionId] = actualUpdatedValue;
    }

    if (question.hasOtherOption && actualUpdatedValue != _kOtherOptionValue && valueBeforeUpdate == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '');
    }

    if (valueBeforeUpdate != actualUpdatedValue) {
      bool isParent = loadedForm.value?.sections.any((s) =>
          s.questions.any((qChild) =>
          qChild.dependentOptions?.parentQuestionId == questionId)) ?? false;
      if (isParent) {
        _resetDependentChildrenAnswers(questionId);
      }
    }

    evaluateAndExecuteJumps(questionId, userAnswers[questionId]);
  }

  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    final question = findQuestionById(questionId);
    if (question == null || question.belongsToGroupTag == null) return;

    final groupTag = question.belongsToGroupTag!;
    final count = repeatableGroupCounts[groupTag] ?? 0;

    if (repeatIndex >= count) {
      // print("[InputUserController] Peringatan: updateRepeatableGroupAnswer untuk index $repeatIndex di luar batas count $count (QID: $questionId).");
      return;
    }

    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }
    if (!repeatableGroupAnswers[questionId]!.containsKey(repeatIndex)){
      repeatableGroupAnswers[questionId]![repeatIndex] = _getDefaultAnswerForQuestionType(question.type);
    }

    dynamic oldValue = repeatableGroupAnswers[questionId]![repeatIndex];
    repeatableGroupAnswers[questionId]![repeatIndex] = value;

    if (question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '', repeatIndex: repeatIndex);
    }

    if (oldValue != value) {
      bool isParent = loadedForm.value?.sections.any((s) =>
          s.questions.any((qChild) =>
          qChild.dependentOptions?.parentQuestionId == questionId)) ?? false;
      if (isParent) {
        _resetDependentChildrenAnswers(questionId);
      }
    }

    dynamic answerForEval = _getAnswerForEvaluation(question, specificRepeatIndex: repeatIndex);
    evaluateAndExecuteJumps(questionId, answerForEval);
  }

  void _adjustRepeatableGroupAnswers(String groupTag, int newCount) {
    if (loadedForm.value == null) return;

    for (var section in loadedForm.value!.sections) {
      for (var qInGroup in section.questions) {
        if (qInGroup.belongsToGroupTag == groupTag) {
          if (!repeatableGroupAnswers.containsKey(qInGroup.id)) {
            repeatableGroupAnswers[qInGroup.id] = RxMap<int, dynamic>();
          }
          final answerMap = repeatableGroupAnswers[qInGroup.id]!;
          answerMap.removeWhere((key, _) => key >= newCount);
          for (int i = 0; i < newCount; i++) {
            if (!answerMap.containsKey(i)) {
              answerMap[i] = _getDefaultAnswerForQuestionType(qInGroup.type);
            }
          }

          if (qInGroup.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(qInGroup.id)) {
              repeatableGroupOtherAnswers[qInGroup.id] = RxMap<int, String>();
            }
            final otherAnswerMap = repeatableGroupOtherAnswers[qInGroup.id]!;
            otherAnswerMap.removeWhere((key, _) => key >= newCount);
            for (int i = 0; i < newCount; i++) {
              if (!otherAnswerMap.containsKey(i)) {
                otherAnswerMap[i] = '';
              }
            }
          }
        }
      }
    }

    if (newCount == 0) {
      activeRepeatIndexForGroup.remove(groupTag);
    } else {
      if (!activeRepeatIndexForGroup.containsKey(groupTag) || activeRepeatIndexForGroup[groupTag]! >= newCount) {
        activeRepeatIndexForGroup[groupTag] = 0;
      }
      if (newCount > 0 && activeRepeatIndexForGroup[groupTag]! >= newCount) {
        activeRepeatIndexForGroup[groupTag] = newCount -1;
      }
    }
  }

  void goToNextRepeatableItem(String groupTag) {
    if (repeatableGroupCounts.containsKey(groupTag) &&
        activeRepeatIndexForGroup.containsKey(groupTag) &&
        repeatableGroupCounts[groupTag]! > 0) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      int maxIdx = repeatableGroupCounts[groupTag]! - 1;
      if (currentIdx < maxIdx) {
        activeRepeatIndexForGroup[groupTag] = currentIdx + 1;
      }
    }
  }

  void goToPreviousRepeatableItem(String groupTag) {
    if (activeRepeatIndexForGroup.containsKey(groupTag)) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      if (currentIdx > 0) {
        activeRepeatIndexForGroup[groupTag] = currentIdx - 1;
      }
    }
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel,
      String colLabel, String subColLabel, String? value) {
    String? parseableValue = value?.replaceAll(',', '.');
    num? numericValue = parseableValue != null && parseableValue.isNotEmpty
        ? num.tryParse(parseableValue)
        : null;

    Map<String, Map<String, Map<String, num?>>> getGridMap(dynamic currentGridData) {
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
                                    if (subColEntry.value == null) {cellValueNum = null;}
                                    else if (subColEntry.value is num) {cellValueNum = subColEntry.value as num;}
                                    else {cellValueNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));}
                                    return MapEntry(subColEntry.key.toString(),cellValueNum);
                                  })
                              )
                          );
                        })
                    )
                );
              })
          );
        } catch (e) {
          // print("[InputUserController] Error dalam getGridMap saat konversi: $e. Data: $currentGridData");
          return <String, Map<String, Map<String, num?>>>{};
        }
      }
      return <String, Map<String, Map<String, num?>>>{};
    }

    if (repeatIndex != null) {
      if (!repeatableGroupAnswers.containsKey(questionId)) {
        repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      }
      if (!repeatableGroupAnswers[questionId]!.containsKey(repeatIndex)) {
        repeatableGroupAnswers[questionId]![repeatIndex] = <String, Map<String, Map<String, num?>>>{};
      }

      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(repeatableGroupAnswers[questionId]![repeatIndex]);

      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      if (!userAnswers.containsKey(questionId) || userAnswers[questionId] == null || userAnswers[questionId] is! Map ) {
        userAnswers[questionId] = <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(userAnswers[questionId]);

      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
  }

  String? _performLocalValidation(
      FormQuestion question, dynamic answer, String questionDisplayName, {int? repeatIndex}) {
    if (questionVisibility[question.id] != true) {
      return null;
    }

    bool isEmpty = _isAnswerEmpty(answer, question.type);
    String? otherText;

    if (question.hasOtherOption) {
      if (repeatIndex != null) {
        otherText = repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        otherText = userOtherAnswers[question.id];
      }
      if (answer == _kOtherOptionValue && (otherText == null || otherText.trim().isEmpty)) {
        if (question.isRequired) return 'Isian "Lainnya" pada "$questionDisplayName" wajib diisi.';
        isEmpty = true;
      }
      else if (answer == _kOtherOptionValue && (otherText != null && otherText.trim().isNotEmpty)) {
        isEmpty = false;
      }
    }

    if (question.isRequired && isEmpty) {
      return 'Pertanyaan "$questionDisplayName" wajib diisi.';
    }

    if (isEmpty && !question.isRequired) {
      return null;
    }

    final ValidationRule? rule = question.validation;
    if (rule == null) {
      return null;
    }

    String effectiveStringValue = "";
    if (answer == _kOtherOptionValue && otherText != null) {
      effectiveStringValue = otherText.trim();
    } else if (answer is String) {
      effectiveStringValue = answer.trim();
    }

    if (effectiveStringValue.isNotEmpty || (answer is String && answer.isNotEmpty && question.type != QuestionType.number)) {
      if (rule.minLength != null && effectiveStringValue.length < rule.minLength!) {
        return 'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.';
      }
      if (rule.maxLength != null && effectiveStringValue.length > rule.maxLength!) {
        return 'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.';
      }
      if (rule.regex != null && rule.regex!.isNotEmpty && !RegExp(rule.regex!).hasMatch(effectiveStringValue)) {
        return 'Format "$questionDisplayName" tidak sesuai (${rule.regex}).';
      }
      if (rule.predefinedRule == 'nik' && !RegExp(r'^\d{16}$').hasMatch(effectiveStringValue)) {
        return 'NIK untuk "$questionDisplayName" harus 16 digit angka.';
      }
      if (rule.predefinedRule == 'noKK' && !RegExp(r'^\d{16}$').hasMatch(effectiveStringValue)) {
        return 'No. KK untuk "$questionDisplayName" harus 16 digit angka.';
      }
      if (rule.predefinedRule == 'email' && !GetUtils.isEmail(effectiveStringValue)) {
        return 'Format email untuk "$questionDisplayName" tidak valid.';
      }
      if (rule.predefinedRule == 'numbersOnly' && !GetUtils.isNumericOnly(effectiveStringValue.replaceAll(',', '').replaceAll('.', ''))) {
        return '"$questionDisplayName" hanya boleh angka.';
      }
    }

    if (question.type == QuestionType.number && answer != null && answer.toString().isNotEmpty) {
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.'));
      if (numAnswer == null && answer.toString().isNotEmpty) {
        return '"$questionDisplayName" harus berupa angka.';
      }
      if(numAnswer == null) return null;

      if (rule.minValue != null && numAnswer < rule.minValue!) {
        return '"$questionDisplayName" minimal ${rule.minValue}.';
      }
      if (rule.maxValue != null && numAnswer > rule.maxValue!) {
        return '"$questionDisplayName" maksimal ${rule.maxValue}.';
      }

      if (question.code == "203" || question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          dynamic artCountValueDynamic;
          if (repeatIndex != null && artQuestion.belongsToGroupTag == question.belongsToGroupTag) {
            artCountValueDynamic = repeatableGroupAnswers[artQuestion.id]?[repeatIndex];
          } else {
            artCountValueDynamic = userAnswers[artQuestion.id];
          }

          num? artCount;
          if (artCountValueDynamic is String && artCountValueDynamic.isNotEmpty) {
            artCount = num.tryParse(artCountValueDynamic.replaceAll(',', '.'));
          } else if (artCountValueDynamic is num) {
            artCount = artCountValueDynamic;
          }

          if (artCount != null && numAnswer > artCount) {
            return '$questionDisplayName (${numAnswer.toInt()}) tidak boleh melebihi ${artQuestion.questionText} (${artCount.toInt()}).';
          }
        }
      }
    }
    return null;
  }

  Future<bool> submitForm() async {
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isLoading.value = true;
    formKey.currentState?.save();
    bool formKeyValidationPassed = formKey.currentState?.validate() ?? true;

    String? firstInvalidSectionIdToFocus;
    bool allCustomValidationsPassed = true;
    List<String> validationErrors = [];

    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        if (questionVisibility[question.id] != true) {
          continue;
        }

        dynamic answerToValidate;
        String questionDisplayName = question.questionText;

        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          answerToValidate = userAnswers[question.id];
          String? localValidationError = _performLocalValidation(
              question, answerToValidate, questionDisplayName, repeatIndex: null);
          if (localValidationError != null) {
            allCustomValidationsPassed = false;
            if (!validationErrors.contains(localValidationError)) {
              validationErrors.add(localValidationError);
            }
            if (firstInvalidSectionIdToFocus == null) {
              firstInvalidSectionIdToFocus = section.id;
            }
          }
        } else {
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          for (int i = 0; i < count; i++) {
            answerToValidate = repeatableGroupAnswers[question.id]?[i];
            String displayNameForGroupItem = "[Data ke-${i + 1}] ${question.questionText}";

            String? localValidationError = _performLocalValidation(
                question, answerToValidate, displayNameForGroupItem, repeatIndex: i);
            if (localValidationError != null) {
              allCustomValidationsPassed = false;
              if (!validationErrors.contains(localValidationError)) {
                validationErrors.add(localValidationError);
              }
              if (firstInvalidSectionIdToFocus == null) {
                firstInvalidSectionIdToFocus = section.id;
              }
            }
          }
        }
      }
    }

    if (!formKeyValidationPassed || !allCustomValidationsPassed) {
      isLoading.value = false;
      if (firstInvalidSectionIdToFocus != null && expandedSectionId.value != firstInvalidSectionIdToFocus) {
        if ((loadedForm.value?.sections.length ?? 0) > 1) {
          expandedSectionId.value = firstInvalidSectionIdToFocus;
        }
      }

      final uniqueErrors = validationErrors.toSet().toList();
      String notificationMessage = uniqueErrors.join('\n');
      if (uniqueErrors.isEmpty && !formKeyValidationPassed) {
        notificationMessage = "Beberapa pertanyaan wajib belum diisi atau formatnya salah. Silakan periksa kembali.";
      }

      Get.snackbar(
        'Validasi Form Gagal',
        '',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        isDismissible: true,
        messageText: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: Get.height * 0.25),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              notificationMessage.isNotEmpty ? notificationMessage : "Terjadi kesalahan validasi. Harap periksa semua isian.",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
      return false;
    }

    List<QuestionAnswer> answersToSubmit = [];
    loadedForm.value!.sections.forEach((section) {
      section.questions.forEach((question) {
        if (questionVisibility[question.id] == true) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            dynamic answer = userAnswers[question.id];
            String? otherText = userOtherAnswers[question.id];
            dynamic finalAnswer = (question.hasOtherOption && answer == _kOtherOptionValue) ? (otherText ?? '') : answer;

            if (!_isAnswerEmpty(finalAnswer, question.type) || !question.isRequired) {
              answersToSubmit.add(QuestionAnswer(
                  questionId: question.id,
                  questionCode: question.code ?? '',
                  questionText: question.questionText,
                  answer: _prepareAnswerForFirestore(finalAnswer, question.type),
                  questionType: question.type.toShortString()));
            }
          } else {
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) {
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              String? otherText = repeatableGroupOtherAnswers[question.id]?[i];
              dynamic finalAnswer = (question.hasOtherOption && answer == _kOtherOptionValue) ? (otherText ?? '') : answer;

              if (!_isAnswerEmpty(finalAnswer, question.type) || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                    questionId: "${question.id}_$i",
                    questionCode: "${question.code ?? ''}_${i + 1}",
                    questionText: "[Data ke-${i + 1}] ${question.questionText}",
                    answer: _prepareAnswerForFirestore(finalAnswer, question.type),
                    questionType: question.type.toShortString()));
              }
            }
          }
        }
      });
    });

    final submissionData = FormSubmission(
      id: isEditMode.value ? submissionId.value : null,
      formId: loadedForm.value!.id,
      formTitle: loadedForm.value!.title,
      userId: _auth.currentUser!.uid,
      userName: _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? 'Anonim',
      submittedAt: (isEditMode.value && loadedSubmission.value?.submittedAt != null)
          ? loadedSubmission.value!.submittedAt!
          : Timestamp.now(),
      answers: answersToSubmit,
    );

    Map<String, dynamic> firestoreData = submissionData.toFirestore();
    if (isEditMode.value) {
      firestoreData['updatedAt'] = Timestamp.now();
    }

    try {
      if (isEditMode.value) {
        await _db.collection('formSubmissions').doc(submissionId.value).set(firestoreData, SetOptions(merge: true));
        Get.snackbar('Berhasil', 'Perubahan berhasil disimpan!',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        await _db.collection('formSubmissions').add(firestoreData);
        Get.snackbar('Berhasil', 'Form berhasil dikirim!',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      }
      isLoading.value = false;
      return true;
    } catch (e) {
      Get.snackbar('Error Simpan/Kirim', 'Gagal menyimpan data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white, duration: const Duration(seconds: 5));
      isLoading.value = false;
      return false;
    }
  }

  bool _isAnswerEmpty(dynamic answer, QuestionType type) {
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty;
    if (answer is Map) {
      if (type == QuestionType.gridNumeric) {
        if (answer.isEmpty) return true;
        return !(answer as Map<String, Map<String, Map<String, num?>>>).values.any((colMap) =>
            colMap.values.any((subColMap) =>
                subColMap.values.any((cellVal) => cellVal != null && cellVal.toString().trim().isNotEmpty)
            )
        );
      }
      return answer.isEmpty;
    }
    return false;
  }

  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type) {
    if (answer == null && (type == QuestionType.number || type == QuestionType.date || type == QuestionType.gridNumeric)) {
      return null;
    }
    if (answer == null) {
      return (type == QuestionType.checkboxes) ? <String>[] : "";
    }

    switch (type) {
      case QuestionType.number:
        if (answer is String) {
          if (answer.trim().isEmpty) return null;
          return num.tryParse(answer.replaceAll(',', '.'));
        }
        if (answer is num) return answer;
        return null;
      case QuestionType.date:
        if (answer is String) {
          if (answer.trim().isEmpty) return null;
          try {
            final date = DateFormat('dd/MM/yyyy').parseStrict(answer);
            return Timestamp.fromDate(date);
          } catch (e) {
            try {
              final date = DateTime.parse(answer);
              return Timestamp.fromDate(date);
            } catch (e2) {
              // print("[InputUserController] Peringatan: Gagal mem-parse string tanggal '$answer' untuk Firestore. Menyimpan string mentah.");
              return answer;
            }
          }
        }
        if (answer is DateTime) return Timestamp.fromDate(answer);
        if (answer is Timestamp) return answer;
        return null;
      case QuestionType.gridNumeric:
        if (answer is Map<String, Map<String, Map<String, num?>>>) {
          Map<String, dynamic> firestoreGrid = {};
          answer.forEach((rowKey, colMap) {
            String effectiveRowKey = rowKey.toString().isEmpty ? "default_row" : rowKey.toString();
            Map<String, dynamic> currentCols = {};
            colMap.forEach((colKey, subColMap) {
              Map<String, num?> currentSubCols = {};
              subColMap.forEach((subColKey, cellValue) {
                currentSubCols[subColKey.toString()] = cellValue;
              });
              currentCols[colKey.toString()] = currentSubCols;
            });
            firestoreGrid[effectiveRowKey] = currentCols;
          });
          return firestoreGrid;
        }
        return {};
      case QuestionType.checkboxes:
        if (answer is List) return List<String>.from(answer.map((e) => e.toString()));
        return <String>[];
      default:
        return answer.toString();
    }
  }
}