// File: input_user_controller.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import './input_user_model.dart';

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
      expandedSectionId.value = '';
    } else {
      expandedSectionId.value = sectionId;
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
            final int currentActiveRepeatIndex = activeRepeatIndexForGroup[groupTag] ?? 0;
            if (i == currentActiveRepeatIndex) {
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
    }
    return false;
  }


  @override
  void onInit() {
    super.onInit();
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
    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    loadedSubmission.value = null;
    _allQuestionIdsInOrder.clear();
    activeRepeatIndexForGroup.clear();

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
      print("Error saat fetchFormAndPotentialSubmissionData: $e\n$s");
      errorMessage.value = "Gagal memuat data: ${e.toString()}";
    } finally {
      isLoading.value = false;
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
    if (loadedForm.value == null) return;

    userAnswers.clear();
    repeatableGroupAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupAnswers.clear();
    userOtherAnswers.clear();
    repeatableGroupOtherAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupOtherAnswers.clear();
    repeatableGroupCounts.clear();
    questionVisibility.clear();
    activeRepeatIndexForGroup.clear();

    if (isEditMode.value && loadedSubmission.value != null) {
      _populateAnswersFromSubmission();
    } else {
      for (var qId in _allQuestionIdsInOrder) {
        final question = findQuestionById(qId);
        if (question == null) continue;

        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          if (!userAnswers.containsKey(question.id)) {
            userAnswers[question.id] = _getDefaultAnswerForQuestionType(question.type);
          }
        }
        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          if (!repeatableGroupCounts.containsKey(question.controlledGroupTag!)) {
            dynamic controllerAnswer = userAnswers[question.id];
            int count = 0;
            if (controllerAnswer is String) count = int.tryParse(controllerAnswer) ?? 0;
            else if (controllerAnswer is num) count = controllerAnswer.toInt();
            repeatableGroupCounts[question.controlledGroupTag!] = count;
            if (count > 0) {
              activeRepeatIndexForGroup.putIfAbsent(question.controlledGroupTag!, () => 0);
            } else {
              activeRepeatIndexForGroup.remove(question.controlledGroupTag!);
            }
          }
        }
        if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
          if (!repeatableGroupAnswers.containsKey(question.id)) {
            repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
          }
          if (question.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(question.id)) {
              repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
            }
          }
        }
      }
      repeatableGroupCounts.forEach((groupTag, count) {
        _adjustRepeatableGroupAnswers(groupTag, count);
      });
    }
    activeRepeatIndexForGroup.refresh();
    _initializeAndEvaluateInitialVisibility();
  }

  Future<void> fetchFormStructure() async {
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
          _initializeStatesBasedOnMode();
        }
      } else {
        errorMessage.value =
        "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        loadedForm.value = null;
      }
    } catch (e, s) {
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      loadedForm.value = null;
      Get.snackbar('Error Memuat', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void _populateAnswersFromSubmission() {
    if (loadedSubmission.value == null || loadedForm.value == null) return;

    Map<String, int> tempGroupCounts = {};
    activeRepeatIndexForGroup.clear();

    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null) continue;
      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        userAnswers[question.id] = _getDefaultAnswerForQuestionType(question.type);
        if (question.hasOtherOption) {
          userOtherAnswers[question.id] = '';
        }
      } else if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
        if (!repeatableGroupAnswers.containsKey(question.id)) {
          repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.hasOtherOption && !repeatableGroupOtherAnswers.containsKey(question.id)) {
          repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
        }
      }
    }

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      bool isRepeatableMemberInstance = false;
      int? potentialRepeatIndex;

      if (savedAnswer.questionId.contains('_')) {
        final parts = savedAnswer.questionId.split('_');
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

      // MODIFIED: Pass questionDef to _mapAnswerToCorrectType
      if (questionDef.hasOtherOption && savedAnswer.answer is String) {
        bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
        if (questionDef.type == QuestionType.multipleChoice) {
          if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
            mappedMainAnswer = _kOtherOptionValue;
            otherText = savedAnswer.answer as String;
          } else {
            mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else if (questionDef.type == QuestionType.checkboxes && savedAnswer.answer is List) {
          List<String> tempCheckboxAnswers = [];
          bool otherFound = false;
          for(var item in (savedAnswer.answer as List)){
            if(questionDef.options.contains(item.toString())){
              tempCheckboxAnswers.add(item.toString());
            } else if (item.toString().isNotEmpty) {
              if(!otherFound){
                tempCheckboxAnswers.add(_kOtherOptionValue);
                otherText = item.toString(); // This will be the 'other' text
                otherFound = true;
              } else {
                print("Warning: Multiple non-predefined options found for checkbox ${questionDef.id}, using first as 'Other'.");
              }
            }
          }
          mappedMainAnswer = tempCheckboxAnswers;
        } else {
          mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }
      } else if (questionDef.hasOtherOption && questionDef.type == QuestionType.checkboxes && savedAnswer.answer is List) {
        List<String> tempCheckboxAnswers = [];
        bool otherFound = false;
        for(var item in (savedAnswer.answer as List)){
          if(questionDef.options.contains(item.toString())){
            tempCheckboxAnswers.add(item.toString());
          } else if (item.toString().isNotEmpty) {
            if(!otherFound){
              tempCheckboxAnswers.add(_kOtherOptionValue);
              otherText = item.toString();
              otherFound = true;
            }
          }
        }
        mappedMainAnswer = tempCheckboxAnswers;
      }
      else {
        mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
      }

      if (!isRepeatableMemberInstance) {
        userAnswers[originalQuestionId] = mappedMainAnswer;
        if (otherText != null) {
          userOtherAnswers[originalQuestionId] = otherText;
        }

        if (questionDef.isRepeatableGroupController && questionDef.controlledGroupTag != null) {
          int count = 0;
          if (mappedMainAnswer is String) count = int.tryParse(mappedMainAnswer) ?? 0;
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
    });

    repeatableGroupCounts.forEach((groupTag, count) {
      _adjustRepeatableGroupAnswers(groupTag, count);
      if (questionShouldBeVisible(groupTag)) {
        activeRepeatIndexForGroup.putIfAbsent(groupTag, () => 0);
      }
      loadedForm.value?.sections.forEach((section) {
        section.questions.forEach((qInGroup) {
          if (qInGroup.belongsToGroupTag == groupTag && qInGroup.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(qInGroup.id)) {
              repeatableGroupOtherAnswers[qInGroup.id] = RxMap<int, String>();
            }
            final otherAnswerMap = repeatableGroupOtherAnswers[qInGroup.id]!;
            for (int i = 0; i < count; i++) {
              if (!otherAnswerMap.containsKey(i)) {
                otherAnswerMap[i] = '';
              }
            }
          }
        });
      });
    });

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      int? repeatIndex;

      if (savedAnswer.questionId.contains('_')) {
        final parts = savedAnswer.questionId.split('_');
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
          (repeatableGroupAnswers[originalQuestionId]?.length ?? 0) > repeatIndex) {

        dynamic mappedMainAnswerRepeat;
        String? otherTextRepeat;

        // MODIFIED: Pass questionDef to _mapAnswerToCorrectType
        if (questionDef.hasOtherOption && savedAnswer.answer is String) {
          bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
          if (questionDef.type == QuestionType.multipleChoice) {
            if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
              mappedMainAnswerRepeat = _kOtherOptionValue;
              otherTextRepeat = savedAnswer.answer as String;
            } else {
              mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
            }
          }  else { // For other types like text, paragraph if they somehow have hasOtherOption
            mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else if (questionDef.hasOtherOption && questionDef.type == QuestionType.checkboxes && savedAnswer.answer is List) {
          List<String> tempCheckboxAnswers = [];
          bool otherFound = false;
          for(var item in (savedAnswer.answer as List)){
            if(questionDef.options.contains(item.toString())){
              tempCheckboxAnswers.add(item.toString());
            } else if (item.toString().isNotEmpty) {
              if(!otherFound){
                tempCheckboxAnswers.add(_kOtherOptionValue);
                otherTextRepeat = item.toString();
                otherFound = true;
              }
            }
          }
          mappedMainAnswerRepeat = tempCheckboxAnswers;
        }
        else {
          mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }

        repeatableGroupAnswers[originalQuestionId]![repeatIndex] = mappedMainAnswerRepeat;
        if (otherTextRepeat != null && repeatableGroupOtherAnswers.containsKey(originalQuestionId)) {
          if (!repeatableGroupOtherAnswers[originalQuestionId]!.containsKey(repeatIndex)) {
            repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = '';
          }
          repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = otherTextRepeat;
        }
      }
    }

    userAnswers.refresh();
    userOtherAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
    repeatableGroupCounts.refresh();
    activeRepeatIndexForGroup.refresh();
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

  // MODIFIED: Signature changed to accept FormQuestion questionDef
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
        if (rawAnswer is num) return rawAnswer.toString();
        if (rawAnswer is String) return rawAnswer; // Already a string, might be "1,23"
        // If it's not num or string, try to parse. If fails, return empty string or keep as is.
        return (num.tryParse(rawAnswer.toString().replaceAll(',', '.')) ?? '')
            .toString();
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
              // Fallback for unparseable strings
            }
          }
        }
        return rawAnswer.toString(); // Fallback
      case QuestionType.gridNumeric:
        if (rawAnswer is Map) {
          try {
            return Map<String, Map<String, Map<String, num?>>>.fromEntries(
                (rawAnswer).entries.map((rowEntry) {
                  String effectiveRowKey = rowEntry.key.toString();
                  // CORE FIX: Convert "default_row" back to "" for single grids
                  if ((questionDef.gridRowLabels.isEmpty) && effectiveRowKey == "default_row") {
                    effectiveRowKey = "";
                  }

                  var colMap = rowEntry.value;
                  if (colMap is! Map) colMap = <String, dynamic>{};

                  return MapEntry(
                      effectiveRowKey, // Use the potentially modified key
                      Map<String, Map<String, num?>>.fromEntries(
                          (colMap as Map).entries.map((colEntry) {
                            var subColMap = colEntry.value;
                            if (subColMap is! Map) subColMap = <String, dynamic>{};
                            return MapEntry(
                                colEntry.key.toString(),
                                Map<String, num?>.fromEntries(
                                    (subColMap as Map).entries.map((subColEntry) {
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
            print("Error casting grid data in _mapAnswerToCorrectType (QID: ${questionDef.id}): $e. Data: $rawAnswer");
            return <String, Map<String, Map<String, num?>>>{};
          }
        }
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
      case QuestionType.multipleChoice:
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString();
      default:
        return rawAnswer.toString();
    }
  }


  void _initializeAndEvaluateInitialVisibility() {
    if (_allQuestionIdsInOrder.isEmpty) {
      questionVisibility.clear();
      questionVisibility.refresh();
      return;
    }

    for (String qId in _allQuestionIdsInOrder) {
      questionVisibility[qId] = false;
    }

    String? firstVisibleCandidateId = _allQuestionIdsInOrder.first;
    final firstQuestion = findQuestionById(firstVisibleCandidateId);

    if (firstQuestion != null) {
      questionVisibility[firstQuestion.id] = true;
      // MODIFIED: Pass questionDef to _mapAnswerToCorrectType if used here, or ensure default value logic is sound.
      // For initial evaluation, userAnswers might not be fully populated from submission yet if this is called too early.
      // However, it seems userAnswers is populated by _populateAnswersFromSubmission or default values before this.
      evaluateAndExecuteJumps(
          firstQuestion.id, userAnswers[firstQuestion.id] ?? _getDefaultAnswerForQuestionType(firstQuestion.type));
    }

    if (firstQuestion != null &&
        questionVisibility[firstQuestion.id] != true &&
        !(firstQuestion.unconditionalJumpTarget != null &&
            firstQuestion.unconditionalJumpTarget!.isNotEmpty)) {
      questionVisibility[firstQuestion.id] = true;
    }
    questionVisibility.refresh();
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

  dynamic getAnswerByQuestionId(String questionId) {
    return userAnswers[questionId];
  }

  String? getOtherAnswer(String questionId, {int? repeatIndex}) {
    if (repeatIndex != null) {
      return repeatableGroupOtherAnswers[questionId]?[repeatIndex];
    } else {
      return userOtherAnswers[questionId];
    }
  }

  void updateOtherAnswer(String questionId, String value, {int? repeatIndex}) {
    if (repeatIndex != null) {
      if (!repeatableGroupOtherAnswers.containsKey(questionId)) {
        repeatableGroupOtherAnswers[questionId] = RxMap<int, String>();
      }
      if (!repeatableGroupOtherAnswers[questionId]!.containsKey(repeatIndex)){
        final groupTag = findQuestionById(questionId)?.belongsToGroupTag;
        if(groupTag != null){
          final count = repeatableGroupCounts[groupTag] ?? 0;
          if(repeatIndex < count){
            repeatableGroupOtherAnswers[questionId]![repeatIndex] = '';
          } else {
            print("Warning: updateOtherAnswer for invalid repeatIndex $repeatIndex in QID $questionId");
            return;
          }
        } else {
          repeatableGroupOtherAnswers[questionId]![repeatIndex] = '';
        }
      }
      repeatableGroupOtherAnswers[questionId]![repeatIndex] = value;
      repeatableGroupOtherAnswers.refresh();
    } else {
      userOtherAnswers[questionId] = value;
      userOtherAnswers.refresh();
    }
  }

  String? _getSectionIdForQuestion(String questionId) {
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      if (section.questions.any((q) => q.id == questionId)) {
        return section.id;
      }
    }
    return null;
  }

  String? _getFirstQuestionIdOfSection(String sectionId) {
    if (loadedForm.value == null) return null;
    final section =
    loadedForm.value!.sections.firstWhereOrNull((s) => s.id == sectionId);
    return section?.questions.isNotEmpty == true
        ? section!.questions.first.id
        : null;
  }

  void _resetDependentChildrenAnswers(String parentQuestionId, {bool calledFromJumpClear = false}) {
    if (loadedForm.value == null) return;
    bool changed = false;
    for (var qId in _allQuestionIdsInOrder) {
      final qChild = findQuestionById(qId);
      if (qChild == null) continue;

      if (qChild.dependentOptions?.parentQuestionId == parentQuestionId) {
        dynamic defaultValue = _getDefaultAnswerForQuestionType(qChild.type);
        if (userAnswers.containsKey(qChild.id) &&
            userAnswers[qChild.id] != defaultValue &&
            (questionVisibility[qChild.id] == true || calledFromJumpClear)) {
          userAnswers[qChild.id] = defaultValue;
          if (qChild.hasOtherOption) userOtherAnswers[qChild.id] = '';
          changed = true;
          _resetDependentChildrenAnswers(qChild.id, calledFromJumpClear: calledFromJumpClear);
        }
        if (repeatableGroupAnswers.containsKey(qChild.id) &&
            (questionVisibility[qChild.id] == true || calledFromJumpClear)) {
          if (!(findQuestionById(parentQuestionId)?.isRepeatableGroupController ?? false) ||
              findQuestionById(parentQuestionId)?.controlledGroupTag != qChild.belongsToGroupTag) {
            final groupTag = qChild.belongsToGroupTag;
            if (groupTag != null) {
              final count = repeatableGroupCounts[groupTag] ?? 0;
              for (int i = 0; i < count; i++) {
                if (repeatableGroupAnswers[qChild.id]!.containsKey(i) &&
                    repeatableGroupAnswers[qChild.id]![i] != defaultValue) {
                  repeatableGroupAnswers[qChild.id]![i] = defaultValue;
                  if (qChild.hasOtherOption && repeatableGroupOtherAnswers.containsKey(qChild.id)) {
                    if (repeatableGroupOtherAnswers[qChild.id]!.containsKey(i)){
                      repeatableGroupOtherAnswers[qChild.id]![i] = '';
                    }
                  }
                  changed = true;
                }
              }
            }
          }
        }
      }
    }
    if (changed) {
      userAnswers.refresh();
      userOtherAnswers.refresh();
      repeatableGroupAnswers.refresh();
      repeatableGroupOtherAnswers.refresh();
    }
  }

  void _clearAnswersForSkippedQuestions(List<String> skippedQuestionIds) {
    if (skippedQuestionIds.isEmpty) return;
    bool changed = false;
    for (String qId in skippedQuestionIds) {
      final question = findQuestionById(qId);
      if (question == null) continue;
      dynamic defaultValue = _getDefaultAnswerForQuestionType(question.type);

      if (userAnswers.containsKey(qId) && userAnswers[qId] != defaultValue) {
        userAnswers[qId] = defaultValue;
        changed = true;
      }
      if (userOtherAnswers.containsKey(qId) && userOtherAnswers[qId]!.isNotEmpty) {
        userOtherAnswers[qId] = '';
        changed = true;
      }

      if (repeatableGroupAnswers.containsKey(qId)) {
        final groupTag = question.belongsToGroupTag;
        if (groupTag != null) {
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final answerMap = repeatableGroupAnswers[qId]!;
          final otherAnswerMap = repeatableGroupOtherAnswers[qId];
          for (int i = 0; i < count; i++) {
            if (answerMap.containsKey(i) && answerMap[i] != defaultValue) {
              answerMap[i] = defaultValue;
              changed = true;
            }
            if (otherAnswerMap != null && otherAnswerMap.containsKey(i) && otherAnswerMap[i]!.isNotEmpty) {
              otherAnswerMap[i] = '';
              changed = true;
            }
          }
        }
      }
      if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
        final groupTag = question.controlledGroupTag!;
        if ((repeatableGroupCounts[groupTag] ?? 0) > 0) {
          repeatableGroupCounts[groupTag] = 0;
          _adjustRepeatableGroupAnswers(groupTag, 0);
          changed = true;
        }
      }
      _resetDependentChildrenAnswers(qId, calledFromJumpClear: true);
    }
    if (changed) {
      userAnswers.refresh();
      userOtherAnswers.refresh();
      repeatableGroupAnswers.refresh();
      repeatableGroupOtherAnswers.refresh();
      repeatableGroupCounts.refresh();
      activeRepeatIndexForGroup.refresh();
    }
  }

  void evaluateAndExecuteJumps(String currentQuestionId, dynamic answerValue) {
    final question = findQuestionById(currentQuestionId);
    if (question == null ||
        loadedForm.value == null ||
        (questionVisibility[currentQuestionId] != true &&
            !isLoading.value &&
            !isEditMode.value )) {
      return;
    }

    String? jumpToTargetCompositeValue;

    if (question.unconditionalJumpTarget != null &&
        question.unconditionalJumpTarget!.isNotEmpty) {
      jumpToTargetCompositeValue = question.unconditionalJumpTarget;
    } else if (question.conditionalJumps.isNotEmpty) {
      String currentAnswerString = answerValue?.toString() ?? "";
      if (question.hasOtherOption && answerValue == _kOtherOptionValue) {
        currentAnswerString = getOtherAnswer(currentQuestionId) ?? "";
      }
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
            break;
          }
        }
      }
    }

    if (jumpToTargetCompositeValue != null) {
      _performJump(currentQuestionId, jumpToTargetCompositeValue);
    } else {
      int currentIndex = _allQuestionIdsInOrder.indexOf(currentQuestionId);
      if (currentIndex != -1 &&
          currentIndex + 1 < _allQuestionIdsInOrder.length) {
        String nextQuestionInSequenceId =
        _allQuestionIdsInOrder[currentIndex + 1];
        if (questionVisibility[nextQuestionInSequenceId] != true) {
          questionVisibility[nextQuestionInSequenceId] = true;
          final nextQDef = findQuestionById(nextQuestionInSequenceId);
          if (nextQDef?.belongsToGroupTag != null && (repeatableGroupCounts[nextQDef!.belongsToGroupTag!] ?? 0) > 0) {
            activeRepeatIndexForGroup.putIfAbsent(nextQDef.belongsToGroupTag!, () => 0);
            activeRepeatIndexForGroup.refresh();
          }
          questionVisibility.refresh();
          evaluateAndExecuteJumps(nextQuestionInSequenceId,
              userAnswers[nextQuestionInSequenceId] ?? (nextQDef != null ? _getDefaultAnswerForQuestionType(nextQDef.type) : ''));
        }
      }
    }
  }

  void _performJump(String currentQuestionId, String targetCompositeValue) {
    if (loadedForm.value == null) return;
    final currentIndexInOrder =
    _allQuestionIdsInOrder.indexOf(currentQuestionId);
    if (currentIndexInOrder == -1) {
      return;
    }

    String? effectiveNextVisibleQId;
    List<String> idsToHideAndClear = [];

    List<String> parts = targetCompositeValue.split('_');
    String type = parts.first;
    String? targetEntityId;

    if (type == 'question' && parts.length > 1) {
      targetEntityId = parts.sublist(1).join('_');
      effectiveNextVisibleQId = targetEntityId;
    } else if (type == 'section' &&
        parts.length > 2 &&
        parts[1] == 'start') {
      targetEntityId = parts.sublist(2).join('_');
      effectiveNextVisibleQId = _getFirstQuestionIdOfSection(targetEntityId);
    } else if (targetCompositeValue == 'end_of_current_section') {
      final currentSectionId = _getSectionIdForQuestion(currentQuestionId);
      if (currentSectionId != null) {
        int currentSecIdx = loadedForm.value!.sections
            .indexWhere((s) => s.id == currentSectionId);
        bool afterCurrentInSec = false;
        for (var qInSection
        in loadedForm.value!.sections[currentSecIdx].questions) {
          if (qInSection.id == currentQuestionId) {
            afterCurrentInSec = true;
            continue;
          }
          if (afterCurrentInSec) idsToHideAndClear.add(qInSection.id);
        }
        if (currentSecIdx + 1 < loadedForm.value!.sections.length) {
          effectiveNextVisibleQId = _getFirstQuestionIdOfSection(
              loadedForm.value!.sections[currentSecIdx + 1].id);
        } else {
          effectiveNextVisibleQId = null;
        }
      } else {
        effectiveNextVisibleQId = null;
      }
    } else if (targetCompositeValue == 'end_of_form') {
      effectiveNextVisibleQId = null;
    }

    int targetIndex = _allQuestionIdsInOrder.length;
    if (effectiveNextVisibleQId != null) {
      targetIndex = _allQuestionIdsInOrder.indexOf(effectiveNextVisibleQId);
      if (targetIndex == -1) {
        effectiveNextVisibleQId = null;
        targetIndex = _allQuestionIdsInOrder.length;
      }
    }

    for (int i = currentIndexInOrder + 1; i < targetIndex; i++) {
      if (_allQuestionIdsInOrder[i] != effectiveNextVisibleQId) {
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }
    if (effectiveNextVisibleQId != null && targetIndex < currentIndexInOrder) {
      for (int i = targetIndex + 1; i < currentIndexInOrder; i++) {
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }

    bool visibilityChanged = false;
    for (String qId in _allQuestionIdsInOrder) {
      if (qId == effectiveNextVisibleQId) {
        if (questionVisibility[qId] != true) {
          questionVisibility[qId] = true;
          final qDef = findQuestionById(qId);
          if (qDef?.belongsToGroupTag != null && (repeatableGroupCounts[qDef!.belongsToGroupTag!] ?? 0) > 0) {
            activeRepeatIndexForGroup[qDef.belongsToGroupTag!] = 0;
            activeRepeatIndexForGroup.refresh();
          }
          visibilityChanged = true;
        }
      } else if (qId != currentQuestionId && questionVisibility[qId] != false) {
        if (idsToHideAndClear.contains(qId) ||
            (effectiveNextVisibleQId == null && _allQuestionIdsInOrder.indexOf(qId) > currentIndexInOrder) ||
            (effectiveNextVisibleQId != null &&
                _allQuestionIdsInOrder.indexOf(qId) > targetIndex && targetIndex < _allQuestionIdsInOrder.length)
        ) {
          if (questionVisibility[qId] != false) {
            questionVisibility[qId] = false;
            visibilityChanged = true;
          }
        }
      }
    }

    Set<String> uniqueIdsToClear = Set.from(idsToHideAndClear);
    if(effectiveNextVisibleQId == null){
      for(int i = currentIndexInOrder + 1; i < _allQuestionIdsInOrder.length; i++){
        uniqueIdsToClear.add(_allQuestionIdsInOrder[i]);
        if (questionVisibility[_allQuestionIdsInOrder[i]] != false) {
          questionVisibility[_allQuestionIdsInOrder[i]] = false;
          visibilityChanged = true;
        }
      }
    }

    if (uniqueIdsToClear.isNotEmpty) {
      _clearAnswersForSkippedQuestions(uniqueIdsToClear.toList());
    }
    if (visibilityChanged) {
      questionVisibility.refresh();
    }

    if (effectiveNextVisibleQId != null && questionVisibility[effectiveNextVisibleQId] == true) {
      final targetQuestionDef = findQuestionById(effectiveNextVisibleQId);
      dynamic targetAnswer = userAnswers[effectiveNextVisibleQId] ??
          (targetQuestionDef != null ? _getDefaultAnswerForQuestionType(targetQuestionDef.type) : '');
      evaluateAndExecuteJumps(effectiveNextVisibleQId, targetAnswer);
    }
  }

  void updateUserAnswer(String questionId, dynamic value) {
    dynamic oldValue = userAnswers[questionId];
    userAnswers[questionId] = value;
    final question = findQuestionById(questionId);

    if (question != null && question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '');
    }

    if (question != null && question.isRepeatableGroupController && question.controlledGroupTag != null) {
      int count = 0;
      if (value is String) {
        count =
            int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (value is num) {
        count = value.toInt();
      }

      final ValidationRule? qValidation = question.validation;
      if (qValidation != null) {
        if (qValidation.minValue != null && count < qValidation.minValue!) {
          count = qValidation.minValue!.toInt();
        }
        if (qValidation.maxValue != null && count > qValidation.maxValue!) {
          count = qValidation.maxValue!.toInt();
        }
      }
      if (question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          num? artCount = (artCountValueDynamic is num)
              ? artCountValueDynamic
              : num.tryParse(artCountValueDynamic
              .toString()
              .replaceAll(RegExp(r'[^0-9.]'), '')
              .replaceAll(',', '.'));
          if (artCount != null && count > artCount) {
            count = artCount.toInt();
            Get.snackbar("Info Validasi",
                "Jumlah pekerja tidak boleh melebihi ${artQuestion.questionText} ($artCount). Dibatasi menjadi $count.",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 4));
          }
        }
      }

      if ((repeatableGroupCounts[question.controlledGroupTag!] ?? 0) != count) {
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
      }
      userAnswers[questionId] = count.toString();
    }

    if (oldValue != value) {
      bool isParent = loadedForm.value?.sections.any((s) =>
          s.questions.any((qChild) =>
          qChild.dependentOptions?.parentQuestionId == questionId)) ??
          false;
      if (isParent) _resetDependentChildrenAnswers(questionId);
    }
    if (question != null) evaluateAndExecuteJumps(questionId, value);
    userAnswers.refresh();
  }

  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }
    if (repeatableGroupAnswers[questionId]!.length <= repeatIndex) {
      for(int i = repeatableGroupAnswers[questionId]!.length; i <= repeatIndex; i++){
        final qDef = findQuestionById(questionId);
        repeatableGroupAnswers[questionId]![i] = qDef != null ? _getDefaultAnswerForQuestionType(qDef.type) : '';
      }
    }
    dynamic oldValue = repeatableGroupAnswers[questionId]![repeatIndex];
    repeatableGroupAnswers[questionId]![repeatIndex] = value;

    final question = findQuestionById(questionId);
    if (question != null && question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '', repeatIndex: repeatIndex);
    }
    repeatableGroupAnswers.refresh();
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
      activeRepeatIndexForGroup.putIfAbsent(groupTag, () => 0);
      if (activeRepeatIndexForGroup[groupTag]! >= newCount) {
        activeRepeatIndexForGroup[groupTag] = newCount - 1;
      }
    }
    activeRepeatIndexForGroup.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
  }

  void goToNextRepeatableItem(String groupTag) {
    if (repeatableGroupCounts.containsKey(groupTag) && activeRepeatIndexForGroup.containsKey(groupTag)) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      int maxIdx = repeatableGroupCounts[groupTag]! - 1;
      if (currentIdx < maxIdx) {
        activeRepeatIndexForGroup[groupTag] = currentIdx + 1;
        activeRepeatIndexForGroup.refresh();
      }
    }
  }

  void goToPreviousRepeatableItem(String groupTag) {
    if (activeRepeatIndexForGroup.containsKey(groupTag)) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      if (currentIdx > 0) {
        activeRepeatIndexForGroup[groupTag] = currentIdx - 1;
        activeRepeatIndexForGroup.refresh();
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
          print("Error dalam getGridMap saat konversi: $e. Data: $currentGridData");
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
      gridAnswers
          .putIfAbsent(rowLabel, () => {})
          .putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      if (!userAnswers.containsKey(questionId)) {
        userAnswers[questionId] = <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(userAnswers[questionId]);
      gridAnswers
          .putIfAbsent(rowLabel, () => {})
          .putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
    // No need to call refresh explicitly for userAnswers or repeatableGroupAnswers if using RxMaps correctly.
    // However, if the nested maps are not Rx, then a refresh might be needed for the top-level RxMap.
    // For safety or if issues persist:
    // if (repeatIndex != null) repeatableGroupAnswers.refresh(); else userAnswers.refresh();
  }

  // Lokasi: di dalam class InputUserController extends GetxController { ... }

  String? _performLocalValidation(
      FormQuestion question, dynamic answer, String questionDisplayName, {int? repeatIndex}) {
    // Abaikan validasi jika pertanyaan tidak terlihat
    if (questionVisibility[question.id] != true) {
      return null;
    }

    bool isEmpty = _isAnswerEmpty(answer, question.type);

    // Validasi khusus untuk opsi 'Lainnya' jika dipilih dan wajib diisi
    if (question.isRequired && question.hasOtherOption && answer == _kOtherOptionValue) {
      String? otherText;
      if (repeatIndex != null) {
        otherText = repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        otherText = userOtherAnswers[question.id];
      }
      if (otherText == null || otherText.trim().isEmpty) {
        return 'Isian "Lainnya" pada "$questionDisplayName" wajib diisi.';
      }
      isEmpty = false; // Jika 'Lainnya' diisi, anggap tidak kosong
    }

    // Validasi untuk pertanyaan wajib yang kosong
    if (question.isRequired && isEmpty) {
      return 'Pertanyaan "$questionDisplayName" wajib diisi.';
    }

    final ValidationRule? rule = question.validation;
    // Lanjutkan validasi hanya jika ada aturan dan jawaban tidak kosong (atau memang kosong tapi tidak wajib)
    if (rule == null || isEmpty) {
      return null;
    }

    // Validasi berdasarkan tipe string (panjang, regex, format khusus)
    if (answer is String && answer.isNotEmpty) {
      String effectiveValueString = answer.trim();

      if (rule.minLength != null && effectiveValueString.length < rule.minLength!) {
        return 'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.';
      }
      if (rule.maxLength != null && effectiveValueString.length > rule.maxLength!) {
        return 'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.';
      }
      if (rule.regex != null && rule.regex!.isNotEmpty && !RegExp(rule.regex!).hasMatch(effectiveValueString)) {
        return 'Format "$questionDisplayName" tidak sesuai.';
      }

      // Validasi predefined rules
      if (rule.predefinedRule == 'nik' && !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
        return 'NIK untuk "$questionDisplayName" harus 16 digit angka.';
      }
      if (rule.predefinedRule == 'email' && !GetUtils.isEmail(effectiveValueString)) {
        return 'Format email untuk "$questionDisplayName" tidak valid.';
      }
      if (rule.predefinedRule == 'numbersOnly' && !GetUtils.isNumericOnly(effectiveValueString.replaceAll(',', '').replaceAll('.', ''))) {
        return '"$questionDisplayName" hanya boleh angka.';
      }
    }

    // Validasi khusus untuk tipe Number (nilai min/max)
    if (question.type == QuestionType.number && answer != null && answer.toString().isNotEmpty) {
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.'));
      if (numAnswer == null) {
        return '"$questionDisplayName" harus berupa angka.';
      }

      if (rule.minValue != null && numAnswer < rule.minValue!) {
        return '"$questionDisplayName" minimal ${rule.minValue}.';
      }
      if (rule.maxValue != null && numAnswer > rule.maxValue!) {
        return '"$questionDisplayName" maksimal ${rule.maxValue}.';
      }

      // Validasi silang dengan pertanyaan lain (misalnya, jumlah pekerja vs ART)
      if (question.code == "203" || question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          dynamic artCountValueDynamic;
          if (repeatIndex != null && artQuestion.belongsToGroupTag == question.belongsToGroupTag) {
            artCountValueDynamic = repeatableGroupAnswers[artQuestion.id]?[repeatIndex];
          } else {
            artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          }
          num? artCount = (artCountValueDynamic is String)
              ? num.tryParse(artCountValueDynamic.replaceAll(',', '.'))
              : (artCountValueDynamic is num ? artCountValueDynamic : null);

          if (artCount != null && numAnswer > artCount) {
            return '$questionDisplayName ($numAnswer) tidak boleh melebihi ${artQuestion.questionText} ($artCount).';
          }
        }
      }
    }
    return null; // Validasi lolos, tidak ada pesan error
  }

  Future<bool> submitForm() async {
    // Validasi awal: pastikan form dan pengguna valid
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isLoading.value = true; // Aktifkan indikator loading

    // Picu validasi bawaan FormField untuk menampilkan error langsung di kolom input
    bool formKeyValidationPassed = formKey.currentState!.validate();

    String? firstInvalidSectionIdToFocus;
    bool allValidationsPassed = true;
    List<String> validationErrors = []; // Daftar pesan error yang akan ditampilkan ke pengguna

    // Iterasi melalui setiap pertanyaan untuk validasi kustom
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        // Lewati pertanyaan yang tidak terlihat
        if (questionVisibility[question.id] != true) {
          continue;
        }

        dynamic answerToValidate;
        String questionDisplayName = question.questionText;
        int? repeatIndexForValidation;

        // Tentukan jawaban dan nama tampilan pertanyaan berdasarkan apakah itu bagian dari grup berulang
        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          answerToValidate = userAnswers[question.id];
        } else {
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final int currentActiveRepeatIndex = activeRepeatIndexForGroup[groupTag] ?? 0;

          if (currentActiveRepeatIndex < count) {
            answerToValidate = repeatableGroupAnswers[question.id]?[currentActiveRepeatIndex];
            questionDisplayName = "[Data ke-${currentActiveRepeatIndex + 1}] ${question.questionText}";
            repeatIndexForValidation = currentActiveRepeatIndex;
          } else {
            continue; // Lewati jika tidak ada instance aktif untuk grup berulang
          }
        }

        // Jalankan validasi lokal dan kumpulkan pesan error
        String? localValidationError = _performLocalValidation(
            question, answerToValidate, questionDisplayName, repeatIndex: repeatIndexForValidation);
        if (localValidationError != null) {
          allValidationsPassed = false;
          validationErrors.add(localValidationError);
          // Catat section pertama yang memiliki error untuk fokus
          if (firstInvalidSectionIdToFocus == null) {
            firstInvalidSectionIdToFocus = section.id;
          }
        }
      }
    }

    // Gabungkan hasil validasi formKey dengan validasi kustom.
    // Jika FormKey gagal, set `allValidationsPassed` ke false.
    if (!formKeyValidationPassed) {
      allValidationsPassed = false;

      // Tambahkan pesan error dari FormField bawaan yang mungkin belum tercakup
      // oleh `_performLocalValidation` (misal: hanya validasi `required` yang sederhana).
      // Kita iterasi lagi untuk mencari field yang kosong dan wajib, serta tambahkan ke daftar error.
      if (validationErrors.isEmpty || true) { // Gunakan `true` untuk selalu memeriksa dan melengkapi pesan
        SearchFormKeyErrorLoop:
        for (var section_ in loadedForm.value!.sections) {
          for (var q_ in section_.questions) {
            // Lewati pertanyaan yang tidak terlihat
            if (questionVisibility[q_.id] != true) {
              continue;
            }

            dynamic ans_;
            if (q_.belongsToGroupTag == null || q_.belongsToGroupTag!.isEmpty) {
              ans_ = userAnswers[q_.id];
            } else {
              final groupTag_ = q_.belongsToGroupTag!;
              final count_ = repeatableGroupCounts[groupTag_] ?? 0;
              final int activeIdx_ = activeRepeatIndexForGroup[groupTag_] ?? 0;
              if (activeIdx_ < count_) {
                ans_ = repeatableGroupAnswers[q_.id]?[activeIdx_];
              } else {
                continue;
              }
            }

            bool isOtherSelectedAndEmpty = false;
            if (q_.hasOtherOption && (ans_ == _kOtherOptionValue || (ans_ is List && ans_.contains(_kOtherOptionValue)))) {
              String? otherTextVal;
              if (q_.belongsToGroupTag != null && q_.belongsToGroupTag!.isNotEmpty) {
                final groupTag_ = q_.belongsToGroupTag!;
                final activeIdx_ = activeRepeatIndexForGroup[groupTag_] ?? 0;
                if (activeIdx_ < (repeatableGroupCounts[groupTag_] ?? 0)) {
                  otherTextVal = repeatableGroupOtherAnswers[q_.id]?[activeIdx_];
                }
              } else {
                otherTextVal = userOtherAnswers[q_.id];
              }
              if (otherTextVal == null || otherTextVal.trim().isEmpty) {
                isOtherSelectedAndEmpty = true;
              }
            }

            // Jika pertanyaan wajib dan kosong (termasuk kasus 'Lainnya' yang kosong)
            if (q_.isRequired && (_isAnswerEmpty(ans_, q_.type) && !isOtherSelectedAndEmpty || isOtherSelectedAndEmpty)) {
              String questionDisplayName = q_.questionText;
              if (q_.belongsToGroupTag != null && q_.belongsToGroupTag!.isNotEmpty) {
                final activeIdx_ = activeRepeatIndexForGroup[q_.belongsToGroupTag!] ?? 0;
                if (activeIdx_ < (repeatableGroupCounts[q_.belongsToGroupTag!] ?? 0)) {
                  questionDisplayName = "[Data ke-${activeIdx_ + 1}] ${q_.questionText}";
                }
              }

              // Tambahkan pesan spesifik ke daftar error, agar muncul di notifikasi tunggal
              if (isOtherSelectedAndEmpty) {
                validationErrors.add('Isian "Lainnya" pada "$questionDisplayName" wajib diisi.');
              } else {
                validationErrors.add('Pertanyaan "$questionDisplayName" wajib diisi.');
              }

              // Set section pertama dengan error untuk fokus
              if (firstInvalidSectionIdToFocus == null) {
                firstInvalidSectionIdToFocus = section_.id;
              }
              // Jangan `break SearchFormKeyErrorLoop` agar semua error FormField terkumpul
            }
          }
        }
      }
    }


    // Jika ada kegagalan validasi, tampilkan notifikasi dan hentikan proses
    if (!allValidationsPassed) {
      isLoading.value = false;

      // Hapus duplikasi pesan error dan gabungkan untuk notifikasi akhir
      final uniqueErrors = validationErrors.toSet().toList();
      String notificationMessage = 'Beberapa isian tidak valid atau kosong:\n' + uniqueErrors.join('\n');

      Get.snackbar(
        'Validasi Form Gagal', // Judul Snackbar
        '', // Pesan utama kosong karena akan menggunakan messageText
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 8), // Durasi lebih lama agar pengguna punya waktu membaca/scroll
        isDismissible: true, // Izinkan dismissal
        maxWidth: Get.width * 0.9, // Sesuaikan lebar snackbar
        margin: const EdgeInsets.all(10), // Tambahkan margin
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding konten
        borderRadius: 8, // Border radius snackbar

        // MODIFIKASI UTAMA: Gunakan messageText dengan SingleChildScrollView
        messageText: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.3, // Batasi tinggi maksimum snackbar agar tidak memenuhi seluruh layar
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Beberapa isian tidak valid atau kosong:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  uniqueErrors.join('\n'), // Gabungkan semua pesan dengan baris baru
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return false;
    }

    // --- Proses Pengumpulan dan Pengiriman Data (jika semua validasi lolos) ---
    // (Bagian ini tidak ada perubahan fungsional dari kode sebelumnya)
    List<QuestionAnswer> answersToSubmit = [];
    loadedForm.value!.sections.forEach((section) {
      section.questions.forEach((question) {
        if (questionVisibility[question.id] == true) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            dynamic answer = userAnswers[question.id];
            String? otherText = userOtherAnswers[question.id];

            if (question.hasOtherOption && answer == _kOtherOptionValue) {
              answer = otherText ?? '';
            }
            // Tambahkan jawaban hanya jika tidak kosong ATAU pertanyaan tidak wajib
            if (!_isAnswerEmpty(answer, question.type) || !question.isRequired) {
              answersToSubmit.add(QuestionAnswer(
                  questionId: question.id,
                  questionCode: question.code ?? '',
                  questionText: question.questionText,
                  answer: _prepareAnswerForFirestore(
                      answer, question.type, question.hasOtherOption, otherText),
                  questionType: question.type.toShortString()));
            }
          } else {
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) {
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              String? otherText = repeatableGroupOtherAnswers[question.id]?[i];

              if (question.hasOtherOption && answer == _kOtherOptionValue) {
                answer = otherText ?? '';
              }

              // Tambahkan jawaban hanya jika tidak kosong ATAU pertanyaan tidak wajib
              if (!_isAnswerEmpty(answer, question.type) || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                    questionId: "${question.id}_$i",
                    questionCode: "${question.code ?? ''}_${i + 1}",
                    questionText: "[Data ke-${i + 1}] ${question.questionText}",
                    answer: _prepareAnswerForFirestore(answer,
                        question.type, question.hasOtherOption, otherText),
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
      userName:
      _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? 'Anonim',
      submittedAt: (isEditMode.value && loadedSubmission.value?.submittedAt != null)
          ? loadedSubmission.value!.submittedAt
          : Timestamp.now(),
      answers: answersToSubmit,
    );

    Map<String, dynamic> firestoreData = submissionData.toFirestore();
    if (isEditMode.value) {
      firestoreData['updatedAt'] = Timestamp.now();
    }

    try {
      if (isEditMode.value) {
        await _db
            .collection('formSubmissions')
            .doc(submissionId.value)
            .set(firestoreData, SetOptions(merge: true));
        Get.snackbar('Berhasil', 'Perubahan berhasil disimpan!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);
      } else {
        await _db.collection('formSubmissions').add(firestoreData);
        Get.snackbar('Berhasil', 'Form berhasil dikirim!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);
      }
      isLoading.value = false;
      return true; // Submit berhasil
    } catch (e) {
      Get.snackbar('Error Simpan/Kirim', 'Gagal menyimpan data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 5));
      isLoading.value = false;
      return false; // Submit gagal karena error
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

  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type, bool hasOtherOption, String? otherText) {
    if (hasOtherOption) {
      if (type == QuestionType.multipleChoice ) {
        // 'answer' sudah merupakan otherText jika _kOtherOptionValue dipilih.
        // Tidak ada perlakuan khusus lagi di sini.
      }
      if (type == QuestionType.checkboxes && answer is List) {
        List<dynamic> preparedList = [];
        bool otherValueSubmittedInThisList = false; // Track if otherText has been added for this specific answer list
        for (var item in answer) {
          if (item == _kOtherOptionValue) {
            // This should ideally not happen if 'answer' was resolved correctly before calling this.
            // If it does, and otherText is available and not yet added, add it.
            if (otherText != null && otherText.isNotEmpty && !otherValueSubmittedInThisList) {
              preparedList.add(otherText);
              otherValueSubmittedInThisList = true;
            }
          } else {
            preparedList.add(item);
          }
        }
        // If the original 'answer' list *only* contained _kOtherOptionValue and otherText was used,
        // but then otherText was cleared, the list might be empty.
        // Or if 'answer' was directly the resolved otherText (now empty), this is handled below.
        return preparedList.isEmpty && (answer as List).contains(_kOtherOptionValue) && (otherText == null || otherText.isEmpty)
            ? [] // If only "other" was checked and text is empty, submit empty list
            : preparedList;
      }
    }

    if (type == QuestionType.number) {
      if (answer is String) {
        if (answer.trim().isEmpty) return null; // Store empty number as null
        return num.tryParse(answer.replaceAll(',', '.'));
      }
      if (answer is num) return answer;
    }
    if (answer is Map && type == QuestionType.gridNumeric) {
      Map<String, dynamic> firestoreGrid = {};
      (answer).forEach((rowKey, colMap) {
        // For single grids, rowKey will be "", which is converted to "default_row"
        String effectiveRowKey =
        rowKey.toString().isEmpty ? "default_row" : rowKey.toString();

        if (colMap is Map) {
          Map<String, dynamic> currentCols = {};
          (colMap).forEach((colKey, subColMap) {
            if (subColMap is Map) {
              Map<String, num?> currentSubCols = {};
              (subColMap).forEach((subColKey, cellValue) {
                if (cellValue is String) {
                  if (cellValue.trim().isEmpty) {
                    currentSubCols[subColKey.toString()] = null; // Store empty cell as null
                  } else {
                    currentSubCols[subColKey.toString()] =
                        num.tryParse(cellValue.replaceAll(',', '.'));
                  }
                } else if (cellValue is num?) {
                  currentSubCols[subColKey.toString()] = cellValue;
                } else {
                  currentSubCols[subColKey.toString()] = null; // Default to null for safety
                }
              });
              currentCols[colKey.toString()] = currentSubCols;
            }
          });
          firestoreGrid[effectiveRowKey] = currentCols;
        }
      });
      return firestoreGrid;
    }
    if (type == QuestionType.date && answer is String) {
      if (answer.trim().isEmpty) return null; // Store empty date as null
      try {
        final date = DateFormat('dd/MM/yyyy').parseStrict(answer);
        return Timestamp.fromDate(date);
      } catch (e) {
        try {
          final date = DateTime.parse(answer);
          return Timestamp.fromDate(date);
        } catch (e2) {
          print("Warning: Could not parse date string '$answer' for Firestore. Saving as string.");
          return answer;
        }
      }
    }
    return answer;
  }
}