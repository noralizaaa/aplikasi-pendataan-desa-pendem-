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
          submissionId.value = ''; // Treat as new form if submission not found
          Get.snackbar("Info", errorMessage.value,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4));
        }
      }
      // Initialize states after both form and potential submission are loaded
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
        return <String, Map<String, Map<String, num?>>>{}; // Ensure this matches expected type
      case QuestionType.dropdown:
        return null; // Dropdown often uses null for no selection
      default:
        return ''; // Default for text, paragraph, number (initially string)
    }
  }

  void _initializeStatesBasedOnMode() {
    // print("[InputUserController] _initializeStatesBasedOnMode started.");
    if (loadedForm.value == null) {
      // print("[InputUserController] _initializeStatesBasedOnMode aborted: loadedForm is null.");
      return;
    }

    // Clear all previous answers and control states
    userAnswers.clear();
    repeatableGroupAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupAnswers.clear();
    userOtherAnswers.clear();
    repeatableGroupOtherAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupOtherAnswers.clear();
    repeatableGroupCounts.clear();
    questionVisibility.clear(); // Visibility should be recalculated
    activeRepeatIndexForGroup.clear();

    // Initialize all questions with default empty/null answers first
    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null) continue;

      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        // Non-repeatable question
        userAnswers[question.id] = _getDefaultAnswerForQuestionType(question.type);
        if (question.hasOtherOption) {
          userOtherAnswers[question.id] = '';
        }
      } else {
        // Member of a repeatable group (but not the controller itself)
        // Ensure the map for this question exists, will be populated by _adjustRepeatableGroupAnswers or _populateAnswersFromSubmission
        if (!repeatableGroupAnswers.containsKey(question.id)) {
          repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.hasOtherOption && !repeatableGroupOtherAnswers.containsKey(question.id)) {
          repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
        }
      }
    }

    // If in edit mode and a submission was successfully loaded, populate answers from it
    if (isEditMode.value && loadedSubmission.value != null) {
      // print("[InputUserController] Populating answers from submission.");
      _populateAnswersFromSubmission(); // This will overwrite defaults with actual submission data
    } else {
      // print("[InputUserController] Initializing answers for new form / no submission / failed submission load.");
      // For new forms or if submission didn't load, set up initial counts for repeatable groups (usually 0 or based on defaults)
      for (var qId in _allQuestionIdsInOrder) {
        final question = findQuestionById(qId);
        if (question == null) continue;

        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          // The answer for the controller question (e.g., a number input) determines the count
          dynamic controllerAnswer = userAnswers[question.id]; // Should be its default value, e.g., '' or '0'
          int count = 0;
          if (controllerAnswer is String && controllerAnswer.isNotEmpty) {
            count = int.tryParse(controllerAnswer) ?? 0;
          } else if (controllerAnswer is num) {
            count = controllerAnswer.toInt();
          }
          // Ensure controller answer itself is also set if it wasn't (e.g. '0' if not set)
          if (userAnswers[question.id] == null || userAnswers[question.id].toString().isEmpty) {
            userAnswers[question.id] = '0';
          }


          repeatableGroupCounts[question.controlledGroupTag!] = count;
          if (count > 0) {
            activeRepeatIndexForGroup.putIfAbsent(question.controlledGroupTag!, () => 0);
          }
          _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
        }
      }
    }

    // Refresh all RxMaps to ensure UI updates
    userAnswers.refresh();
    userOtherAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
    repeatableGroupCounts.refresh();
    activeRepeatIndexForGroup.refresh();

    // Finally, determine initial visibility based on the (now populated) answers
    _initializeAndEvaluateInitialVisibility();
    // print("[InputUserController] _initializeStatesBasedOnMode finished.");
  }


  Future<void> fetchFormStructure() async {
    // print("[InputUserController] fetchFormStructure started.");
    if (formId.value.isEmpty) {
      errorMessage.value =
      "ID Form kosong atau tidak valid. Tidak dapat memuat form.";
      isLoading.value = false;
      loadedForm.value = null; // Ensure loadedForm is null on critical error
      Get.snackbar('Error Kritis', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null; // Reset before fetching
    _allQuestionIdsInOrder.clear(); // Clear question order list

    expandedSectionId.value = ''; // Reset section expansion

    try {
      final docSnapshot =
      await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        if (loadedForm.value != null) {
          _allQuestionIdsInOrder.clear(); // Redundant, but safe
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
            }
          }
          // Set initial expansion for sections
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
          _initializeStatesBasedOnMode(); // Initialize answers and visibility
        } else {
          errorMessage.value = "Gagal memproses struktur form dari Firestore.";
          // loadedForm.value remains null
        }
      } else {
        errorMessage.value =
        "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        loadedForm.value = null; // Explicitly null if not found
      }
    } catch (e, s) {
      // print("[InputUserController] Error saat fetchFormStructure: $e\n$s");
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      loadedForm.value = null; // Null on error
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

    Map<String, int> tempGroupCounts = {};

    // First pass: Populate non-repeatable answers and determine group counts
    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      bool isRepeatableMemberInstance = false;

      // --- Logic to correctly identify original question ID from potentially suffixed ID ---
      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        final potentialIndex = int.tryParse(parts.last);
        if (potentialIndex != null) {
          String tempOriginalQId = parts.sublist(0, parts.length - 1).join('_');
          final tempQDef = findQuestionById(tempOriginalQId);
          if (tempQDef != null && tempQDef.belongsToGroupTag != null && tempQDef.belongsToGroupTag!.isNotEmpty) {
            isRepeatableMemberInstance = true;
            // For repeatable members, the originalQuestionId is the one without the suffix.
            originalQuestionId = tempOriginalQId;
          }
        }
      }
      // --- End of identification logic ---

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null) {
        continue;
      }

      if (questionDef.belongsToGroupTag != null && questionDef.belongsToGroupTag!.isNotEmpty) {
        isRepeatableMemberInstance = true;
      }

      dynamic mappedMainAnswer;
      String? otherText;

      if (questionDef.hasOtherOption) {
        if (savedAnswer.answer is String) {
          // --- PERBAIKAN: Menggunakan .any() untuk mengecek di dalam List<QuestionOption> ---
          bool isPredefinedOption = questionDef.options.any((opt) => opt.value == savedAnswer.answer);
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
            // --- PERBAIKAN: Menggunakan .any() untuk mengecek di dalam List<QuestionOption> ---
            if (questionDef.options.any((opt) => opt.value == item.toString())) {
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
          if (mappedMainAnswer is String && mappedMainAnswer.isNotEmpty) {
            count = int.tryParse(mappedMainAnswer) ?? 0;
          } else if (mappedMainAnswer is num) {
            count = mappedMainAnswer.toInt();
          }
          tempGroupCounts[questionDef.controlledGroupTag!] = count;
        }
      }
    }

    // Set up repeatable group structures based on the counts found.
    tempGroupCounts.forEach((tag, count) {
      repeatableGroupCounts[tag] = count;
      if (count > 0) {
        activeRepeatIndexForGroup.putIfAbsent(tag, () => 0);
      } else {
        activeRepeatIndexForGroup.remove(tag);
      }
      _adjustRepeatableGroupAnswers(tag, count);
    });

    // Second pass: Populate answers for members of repeatable groups.
    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      int? repeatIndex;
      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        final potentialIndex = int.tryParse(parts.last);
        if (potentialIndex != null) {
          String tempOriginalQId = parts.sublist(0, parts.length - 1).join('_');
          final tempQDef = findQuestionById(tempOriginalQId);
          if (tempQDef != null && tempQDef.belongsToGroupTag != null && tempQDef.belongsToGroupTag!.isNotEmpty) {
            originalQuestionId = tempOriginalQId;
            repeatIndex = potentialIndex;
          }
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null || questionDef.belongsToGroupTag == null || questionDef.belongsToGroupTag!.isEmpty || repeatIndex == null) {
        continue;
      }

      if (repeatableGroupAnswers.containsKey(originalQuestionId) && repeatIndex < (repeatableGroupCounts[questionDef.belongsToGroupTag!] ?? 0)) {
        dynamic mappedMainAnswerRepeat;
        String? otherTextRepeat;

        if (questionDef.hasOtherOption) {
          if (savedAnswer.answer is String) {
            // --- PERBAIKAN DI SINI JUGA ---
            bool isPredefinedOption = questionDef.options.any((opt) => opt.value == savedAnswer.answer);
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
              // --- PERBAIKAN DI SINI JUGA ---
              if (questionDef.options.any((opt) => opt.value == item.toString())) {
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

        if (!repeatableGroupAnswers[originalQuestionId]!.containsKey(repeatIndex)) {
          repeatableGroupAnswers[originalQuestionId]![repeatIndex] = _getDefaultAnswerForQuestionType(questionDef.type);
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
    // Check if the controller question for this groupTag is itself visible
    final controllerQ = loadedForm.value?.sections
        .expand((s) => s.questions)
        .firstWhereOrNull((q) => q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
    if (controllerQ != null) {
      // A group is visible if its controlling question is visible.
      return questionVisibility[controllerQ.id] ?? true; // Default to true if not found (shouldn't happen for known Qs)
    }
    return true; // If no controller (e.g. static group not driven by a number), assume visible.
  }


  dynamic _mapAnswerToCorrectType(dynamic rawAnswer, FormQuestion questionDef) {
    if (rawAnswer == null) {
      // If raw answer from Firestore is null, return the default "empty" state for that question type.
      return _getDefaultAnswerForQuestionType(questionDef.type);
    }

    switch (questionDef.type) {
      case QuestionType.checkboxes:
        if (rawAnswer is List) {
          // Ensure all items are strings, as expected by CheckboxListTile state.
          return List<String>.from(rawAnswer.map((item) => item.toString()));
        }
        return <String>[]; // Default to empty list if not a list (error case)
      case QuestionType.number:
      // Number answers are stored as num in Firestore, but text input handles them as strings.
      // Convert num to string, formatting for display (e.g., using comma for decimal).
        if (rawAnswer is num) return rawAnswer.toString().replaceAll('.', ',');
        if (rawAnswer is String) {
          // If it's already a string (e.g. from older data or direct string save)
          // ensure it's in the display format if it represents a number.
          // However, _prepareAnswerForFirestore saves numbers as num or null.
          // So, if it's a string here, it might be an old format.
          // For simplicity, return as is if string, assuming it's correctly formatted or will be handled.
          return rawAnswer;
        }
        // Fallback for unexpected types, try to parse and format.
        return (num.tryParse(rawAnswer.toString().replaceAll(',', '.'))?.toString().replaceAll('.', ',') ?? '');
      case QuestionType.date:
        if (rawAnswer is Timestamp) {
          // Format Firestore Timestamp to 'dd/MM/yyyy' string for DatePicker.
          return DateFormat('dd/MM/yyyy').format(rawAnswer.toDate());
        }
        if (rawAnswer is String) {
          // If it's already a string, attempt to parse and reformat to ensure consistency.
          // This handles cases where date might be stored in a different string format.
          try {
            // First, try parsing as our target display format. If it works, it's already good.
            DateFormat('dd/MM/yyyy').parseStrict(rawAnswer);
            return rawAnswer;
          } catch (_) {
            // If not in display format, try parsing as ISO or other common formats.
            try {
              final date = DateTime.parse(rawAnswer);
              return DateFormat('dd/MM/yyyy').format(date);
            } catch (e) {
              // print("[InputUserController] Peringatan: Gagal mem-parse string tanggal '$rawAnswer' di _mapAnswerToCorrectType. Mengembalikan nilai mentah.");
              return rawAnswer; // Return raw string if all parsing fails.
            }
          }
        }
        // Fallback for other types, convert to string.
        return rawAnswer.toString();
      case QuestionType.gridNumeric:
        if (rawAnswer is Map) {
          try {
            // Perform a deep cast/conversion to the expected Map structure.
            return Map<String, Map<String, Map<String, num?>>>.fromEntries(
                (rawAnswer as Map<dynamic,dynamic>).entries.map((rowEntry) {
                  String effectiveRowKey = rowEntry.key.toString();
                  // Handle the "default_row" case for single-row grids without explicit row labels
                  if ((questionDef.gridRowLabels.isEmpty) && effectiveRowKey == "default_row") {
                    effectiveRowKey = ""; // UI expects "" for the single unnamed row's key
                  }

                  var colMap = rowEntry.value;
                  // Ensure colMap is a Map, even if it's empty or wrong type from Firestore.
                  if (colMap is! Map) colMap = <String, dynamic>{};

                  return MapEntry(
                      effectiveRowKey,
                      Map<String, Map<String, num?>>.fromEntries(
                          (colMap as Map<dynamic,dynamic>).entries.map((colEntry) {
                            var subColMap = colEntry.value;
                            // Ensure subColMap is a Map.
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
                                        // Try to parse if it's not a num (e.g., a string representation of a number).
                                        valNum = num.tryParse((subColEntry.value.toString())
                                            .replaceAll(',', '.')); // Use dot for parsing.
                                      }
                                      return MapEntry(subColEntry.key.toString(), valNum);
                                    })));
                          })));
                }));
          } catch (e) {
            // print("[InputUserController] Error casting grid data in _mapAnswerToCorrectType (QID: ${questionDef.id}): $e. Data: $rawAnswer");
            return <String, Map<String, Map<String, num?>>>{}; // Return empty grid on error.
          }
        }
        return <String, Map<String, Map<String, num?>>>{}; // Default to empty grid if not a map.
      case QuestionType.dropdown:
      case QuestionType.multipleChoice: // Radio buttons
      // These typically store the selected option's string value.
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString() ?? _getDefaultAnswerForQuestionType(questionDef.type); // Null for dropdown, '' for others
      default: // For text, paragraph, etc.
        return rawAnswer.toString();
    }
  }


  void _initializeAndEvaluateInitialVisibility() {
    // print("[InputUserController] _initializeAndEvaluateInitialVisibility started.");
    if (_allQuestionIdsInOrder.isEmpty || loadedForm.value == null) {
      questionVisibility.clear(); // Clear if no questions/form
      questionVisibility.refresh();
      // print("[InputUserController] _initializeAndEvaluateInitialVisibility aborted: No questions or form not loaded.");
      return;
    }

    // Set all questions to initially hidden. Visibility will be determined by jumps.
    for (String qId in _allQuestionIdsInOrder) {
      questionVisibility[qId] = false;
    }

    // The first question in the defined order is always initially visible.
    String? firstQuestionIdInForm = _allQuestionIdsInOrder.firstOrNull;
    if (firstQuestionIdInForm != null) {
      final firstQuestion = findQuestionById(firstQuestionIdInForm);
      if (firstQuestion != null) {
        // print("[InputUserController] First question to make visible: ${firstQuestion.id}");
        questionVisibility[firstQuestionIdInForm] = true;

        // If the first question belongs to a repeatable group, ensure its active index is set.
        if (firstQuestion.belongsToGroupTag != null &&
            firstQuestion.belongsToGroupTag!.isNotEmpty &&
            (repeatableGroupCounts[firstQuestion.belongsToGroupTag!] ?? 0) > 0) {
          activeRepeatIndexForGroup.putIfAbsent(firstQuestion.belongsToGroupTag!, () => 0);
        }

        // Evaluate jumps starting from this first question, using its current answer.
        dynamic firstAnswer = _getAnswerForEvaluation(firstQuestion);
        // print("[InputUserController] Evaluating jumps for first question: ${firstQuestion.id} with answer: $firstAnswer");
        evaluateAndExecuteJumps(firstQuestionIdInForm, firstAnswer);
      } else {
        // print("[InputUserController] _initializeAndEvaluateInitialVisibility: First question definition not found for ID $firstQuestionIdInForm.");
      }
    } else {
      // print("[InputUserController] _initializeAndEvaluateInitialVisibility: No questions in _allQuestionIdsInOrder.");
    }
    questionVisibility.refresh(); // Update UI based on visibility changes.
    activeRepeatIndexForGroup.refresh();
    // print("[InputUserController] _initializeAndEvaluateInitialVisibility finished. Current expandedSectionId: ${expandedSectionId.value}");
  }


  dynamic _getAnswerForEvaluation(FormQuestion question, {int? specificRepeatIndex}) {
    if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
      // For questions within a repeatable group
      final groupTag = question.belongsToGroupTag!;
      // Use specificRepeatIndex if provided (e.g., when validating a particular instance),
      // otherwise use the currently active index for that group.
      final int indexToUse = specificRepeatIndex ?? activeRepeatIndexForGroup[groupTag] ?? 0;
      final count = repeatableGroupCounts[groupTag] ?? 0;

      if (indexToUse >= 0 && indexToUse < count && // Check bounds
          repeatableGroupAnswers.containsKey(question.id) &&
          repeatableGroupAnswers[question.id]!.containsKey(indexToUse)) {
        return repeatableGroupAnswers[question.id]![indexToUse];
      }
      // Return default if out of bounds or answer not found for that index
      return _getDefaultAnswerForQuestionType(question.type);
    }
    // For non-repeatable questions
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
    if (questionCode.isEmpty) return null;
    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (q.code == questionCode) return q;
      }
    }
    return null;
  }

  String? getOtherAnswer(String questionId, {int? repeatIndex}) {
    final question = findQuestionById(questionId);
    if (question == null) return null;

    if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty && repeatIndex != null) {
      // Ensure the nested maps exist before trying to access
      if (repeatableGroupOtherAnswers.containsKey(questionId) &&
          repeatableGroupOtherAnswers[questionId]!.containsKey(repeatIndex)) {
        return repeatableGroupOtherAnswers[questionId]![repeatIndex];
      }
    } else if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
      return userOtherAnswers[questionId];
    }
    return null; // Default if not found
  }

  void updateOtherAnswer(String questionId, String value, {int? repeatIndex}) {
    final question = findQuestionById(questionId);
    if (question == null || !question.hasOtherOption) return; // Only proceed if question exists and has "other"

    if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty && repeatIndex != null) {
      // For repeatable group item's "other" answer
      final groupTag = question.belongsToGroupTag!;
      final count = repeatableGroupCounts[groupTag] ?? 0;

      if (repeatIndex >= 0 && repeatIndex < count) { // Check bounds
        // Ensure the map for the question ID exists
        if (!repeatableGroupOtherAnswers.containsKey(questionId)) {
          repeatableGroupOtherAnswers[questionId] = RxMap<int, String>();
        }
        // Ensure the entry for the repeatIndex exists before updating
        // repeatableGroupOtherAnswers[questionId]!.putIfAbsent(repeatIndex, () => ''); // Not strictly needed if direct assignment follows
        repeatableGroupOtherAnswers[questionId]![repeatIndex] = value;
      } else {
        // print("[InputUserController] Peringatan: updateOtherAnswer untuk repeatIndex $repeatIndex (QID: $questionId) di luar batas count $count.");
        return; // Index out of bounds
      }
    } else if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
      // For non-repeatable question's "other" answer
      userOtherAnswers[questionId] = value;
    }
    // No need to call refresh on RxMap for individual item changes, GetX handles it.
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

    // Iterate through all questions to find children of parentQuestionId
    for (var qId in _allQuestionIdsInOrder) {
      final qChild = findQuestionById(qId);
      // Check if qChild is indeed a dependent of parentQuestionId
      if (qChild == null || qChild.dependentOptions?.parentQuestionId != parentQuestionId) continue;

      // Only reset if the child question is currently visible OR if this reset is forced (e.g., by jump logic)
      if (questionVisibility[qChild.id] == true || calledFromJumpClear) {
        dynamic defaultValue = _getDefaultAnswerForQuestionType(qChild.type);

        if (qChild.belongsToGroupTag == null || qChild.belongsToGroupTag!.isEmpty) {
          // Non-repeatable child question
          if (userAnswers[qChild.id] != defaultValue) { // Check if reset is actually needed
            userAnswers[qChild.id] = defaultValue;
            if (qChild.hasOtherOption) userOtherAnswers[qChild.id] = '';
            // Recursively reset children of this child question
            _resetDependentChildrenAnswers(qChild.id, calledFromJumpClear: true);
          }
        } else {
          // Repeatable child question
          final groupTag = qChild.belongsToGroupTag!;
          final parentQuestion = findQuestionById(parentQuestionId); // Get parent definition
          final count = repeatableGroupCounts[groupTag] ?? 0;

          for (int i = 0; i < count; i++) {
            bool shouldResetThisInstance = false;
            // Determine if this specific instance of the child should be reset based on its parent context
            if (parentQuestion?.belongsToGroupTag == qChild.belongsToGroupTag) {
              // Parent and child are in the same repeatable group instance
              shouldResetThisInstance = true;
            } else if (parentQuestion?.belongsToGroupTag == null) {
              // Parent is a non-repeatable question, affecting all instances of the repeatable child
              shouldResetThisInstance = true;
            }
            else if (parentQuestion?.isRepeatableGroupController == true && parentQuestion?.controlledGroupTag == qChild.belongsToGroupTag) {
              // Parent is the controller for the child's group
              shouldResetThisInstance = true;
            }


            if (shouldResetThisInstance &&
                repeatableGroupAnswers.containsKey(qChild.id) &&
                repeatableGroupAnswers[qChild.id]!.containsKey(i) &&
                repeatableGroupAnswers[qChild.id]![i] != defaultValue) { // Check if reset needed

              repeatableGroupAnswers[qChild.id]![i] = defaultValue;
              if (qChild.hasOtherOption && repeatableGroupOtherAnswers.containsKey(qChild.id)) {
                if (repeatableGroupOtherAnswers[qChild.id]!.containsKey(i)){ // Check before assigning
                  repeatableGroupOtherAnswers[qChild.id]![i] = '';
                }
              }
              // Recursively reset children of this specific instance (if any - less common for repeatable children to be parents themselves)
              // This part might need careful thought if repeatable children can also be parents of other repeatable questions.
              // For now, assuming simple dependency.
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
        // Non-repeatable question
        if (userAnswers.containsKey(qId) && userAnswers[qId] != defaultValue) {
          userAnswers[qId] = defaultValue;
        }
        if (question.hasOtherOption && userOtherAnswers.containsKey(qId) && userOtherAnswers[qId]!.isNotEmpty) {
          userOtherAnswers[qId] = '';
        }
        // If it's a group controller, reset its count and adjust the group
        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          final groupTag = question.controlledGroupTag!;
          // Only reset if count is not already 0 or its string representation
          if ((repeatableGroupCounts[groupTag] ?? 0) > 0 || (userAnswers[qId]?.toString() ?? '0') != '0') {
            userAnswers[qId] = '0'; // Assuming controller takes string '0' for count zero
            repeatableGroupCounts[groupTag] = 0;
            _adjustRepeatableGroupAnswers(groupTag, 0); // Clears items in the group
          }
        }
      } else {
        // Repeatable question
        final groupTag = question.belongsToGroupTag!;
        final count = repeatableGroupCounts[groupTag] ?? 0; // Current count of this group

        if (repeatableGroupAnswers.containsKey(qId)) {
          final answerMap = repeatableGroupAnswers[qId]!;
          for (int i = 0; i < count; i++) { // Iterate only existing instances
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
      // After clearing a question's answer, also reset any children that depended on it.
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

    // A question must be visible to trigger its jump logic,
    // UNLESS we are in the initial loading phase where visibility is being determined.
    bool isCurrentlyVisible = questionVisibility[currentQuestionId] ?? false;
    if (!isCurrentlyVisible && !isLoading.value) { // isLoading.value allows initial evaluation even if not yet "fully" visible
      // print("[evaluateAndExecuteJumps] Aborted: Q_ID: $currentQuestionId not visible and not initial loading phase.");
      return;
    }

    String? jumpToTargetCompositeValue; // Stores the target of the jump (e.g., 'question_X', 'section_start_Y', 'end_of_form')
    dynamic effectiveAnswerForJump = answerValue;

    // If "Other" is selected, use the text from the "Other" field for jump evaluation
    if (question.hasOtherOption && answerValue == _kOtherOptionValue) {
      int? currentRepeatIndexForEval;
      if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
        final groupTag = question.belongsToGroupTag!;
        currentRepeatIndexForEval = activeRepeatIndexForGroup[groupTag] ?? 0; // Default to 0 if not found
        // Ensure index is valid
        if (currentRepeatIndexForEval >= (repeatableGroupCounts[groupTag] ?? 0)) {
          currentRepeatIndexForEval = null; // Or handle as error / default to first item
        }
      }
      effectiveAnswerForJump = getOtherAnswer(currentQuestionId, repeatIndex: currentRepeatIndexForEval) ?? "";
    }

    // Check for unconditional jump first
    if (question.unconditionalJumpTarget != null &&
        question.unconditionalJumpTarget!.isNotEmpty) {
      jumpToTargetCompositeValue = question.unconditionalJumpTarget;
      // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - Unconditional jump to: $jumpToTargetCompositeValue");
    } else if (question.conditionalJumps.isNotEmpty) {
      // Check conditional jumps if no unconditional jump
      String currentAnswerString = effectiveAnswerForJump?.toString() ?? "";
      for (var jumpRule in question.conditionalJumps) {
        if (jumpRule.conditionValue == currentAnswerString) {
          // Determine target type based on jumpRule properties
          if (jumpRule.jumpToQuestionId == 'END_OF_FORM') {
            jumpToTargetCompositeValue = 'end_of_form';
          } else if (jumpRule.jumpToQuestionId == 'END_OF_SECTION') {
            // Jump to next section if jumpToSectionId is specified, otherwise end of current section
            jumpToTargetCompositeValue =
            (jumpRule.jumpToSectionId != null &&
                jumpRule.jumpToSectionId!.isNotEmpty)
                ? 'section_start_${jumpRule.jumpToSectionId}' // Jump to the start of a specific NEXT section
                : 'end_of_current_section'; // Jump past current section's questions
          } else if (jumpRule.jumpToQuestionId.isNotEmpty) {
            jumpToTargetCompositeValue =
            'question_${jumpRule.jumpToQuestionId}'; // Jump to a specific question
          }

          if (jumpToTargetCompositeValue != null) {
            // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - Conditional jump to: $jumpToTargetCompositeValue based on answer: '$currentAnswerString'");
            break; // First matching rule wins
          }
        }
      }
    }

    if (jumpToTargetCompositeValue != null) {
      // If a jump target is determined, perform the jump
      _performJump(currentQuestionId, jumpToTargetCompositeValue);
    } else {
      // No jump rule met, proceed to the next question in sequence
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

        // Make the next question visible if it's not already
        if (questionVisibility[nextQuestionInSequenceId] != true) {
          questionVisibility[nextQuestionInSequenceId] = true;
          localVisibilityChanged = true;
          // print("[evaluateAndExecuteJumps] Made $nextQuestionInSequenceId visible.");
        }

        // If the next question is part of a repeatable group, ensure its active index is set (typically to 0)
        if (nextQDef.belongsToGroupTag != null && nextQDef.belongsToGroupTag!.isNotEmpty &&
            (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) > 0) {
          if (!activeRepeatIndexForGroup.containsKey(nextQDef.belongsToGroupTag!)) {
            activeRepeatIndexForGroup.putIfAbsent(nextQDef.belongsToGroupTag!, () => 0);
            localGroupIndexChanged = true;
          } else if (activeRepeatIndexForGroup[nextQDef.belongsToGroupTag!]! >= (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) &&
              (repeatableGroupCounts[nextQDef.belongsToGroupTag!] ?? 0) > 0) {
            // If index is somehow out of bounds (e.g. count decreased), reset to 0
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


        // Recursively evaluate jumps for the next question
        dynamic nextAnswer = _getAnswerForEvaluation(nextQDef);
        evaluateAndExecuteJumps(nextQuestionInSequenceId, nextAnswer);
      } else {
        // print("[evaluateAndExecuteJumps] Q_ID: $currentQuestionId - No next sequential question (end of form or list).");
        // This is the end of the form or the last question visible based on current path
      }
    }
  }


  void _performJump(String currentQuestionId, String targetCompositeValue) {
    // print("[_performJump] currentQ: $currentQuestionId, targetComposite: $targetCompositeValue, currentExpandedSection: ${expandedSectionId.value}");

    if (loadedForm.value == null) return;
    final currentIndexInOrder = _allQuestionIdsInOrder.indexOf(currentQuestionId);
    if (currentIndexInOrder == -1) {
      // print("[_performJump] Peringatan: currentQuestionId '$currentQuestionId' tidak ada dalam _allQuestionIdsInOrder.");
      return; // Should not happen if currentQuestionId is valid
    }

    bool visibilityChangedInPerformJump = false;
    String? effectiveNextVisibleQId; // The ID of the question that will become visible due to the jump

    List<String> parts = targetCompositeValue.split('_');
    String type = parts.first;
    String? targetEntityId; // Can be a question ID or section ID

    if (type == 'question' && parts.length > 1) {
      targetEntityId = parts.sublist(1).join('_'); // Reconstruct ID if it contained underscores
      effectiveNextVisibleQId = targetEntityId;
    } else if (type == 'section' && parts.length > 2 && parts[1] == 'start') {
      targetEntityId = parts.sublist(2).join('_');
      effectiveNextVisibleQId = _getFirstQuestionIdOfSection(targetEntityId); // Jump to first Q of target section
    } else if (targetCompositeValue == 'end_of_current_section') {
      final currentSectionId = _getSectionIdForQuestion(currentQuestionId);
      if (currentSectionId != null) {
        int currentSecIdx = loadedForm.value!.sections.indexWhere((s) => s.id == currentSectionId);
        if (currentSecIdx != -1 && currentSecIdx + 1 < loadedForm.value!.sections.length) {
          // Target is the first question of the next section
          effectiveNextVisibleQId = _getFirstQuestionIdOfSection(loadedForm.value!.sections[currentSecIdx + 1].id);
        } else {
          // End of last section, equivalent to end of form
          effectiveNextVisibleQId = null;
        }
      } else {
        effectiveNextVisibleQId = null; // Should not happen if currentQuestionId is valid
      }
    } else if (targetCompositeValue == 'end_of_form') {
      effectiveNextVisibleQId = null; // No next question, end of form
    }

    // final String? initialEffectiveNextVisibleQIdForLog = effectiveNextVisibleQId; // For logging if needed

    // Validate that the target question ID (if any) actually exists in the form
    if (effectiveNextVisibleQId != null && !_allQuestionIdsInOrder.contains(effectiveNextVisibleQId)) {
      // print("[_performJump] Peringatan: Target lompatan '$effectiveNextVisibleQId' dari '$targetCompositeValue' tidak ditemukan dalam _allQuestionIdsInOrder. Dibatalkan menjadi null (lompat ke akhir).");
      effectiveNextVisibleQId = null; // Treat as jump to end if target is invalid
    }

    // Determine questions to hide and clear answers for:
    // These are questions between the current one and the jump target (or end of form).
    List<String> idsToActuallyHideAndClear = [];
    for (int i = currentIndexInOrder + 1; i < _allQuestionIdsInOrder.length; i++) {
      String qIdToProcess = _allQuestionIdsInOrder[i];
      // If we have a specific jump target, stop hiding/clearing once we reach it.
      // If effectiveNextVisibleQId is null (jump to end), all subsequent questions are hidden.
      if (effectiveNextVisibleQId != null && qIdToProcess == effectiveNextVisibleQId) {
        // We've reached the target question of the jump, don't hide it or subsequent ones handled by its own logic.
        break;
      }

      idsToActuallyHideAndClear.add(qIdToProcess);
      if (questionVisibility[qIdToProcess] != false) { // Check if visibility actually changes
        questionVisibility[qIdToProcess] = false;
        visibilityChangedInPerformJump = true;
      }
    }

    if (idsToActuallyHideAndClear.isNotEmpty) {
      _clearAnswersForSkippedQuestions(idsToActuallyHideAndClear);
    }

    bool groupIndexChangedInPerformJump = false;
    // Make the target question visible (if there is one)
    if (effectiveNextVisibleQId != null) {
      final targetQuestionDef = findQuestionById(effectiveNextVisibleQId);
      if (targetQuestionDef != null) {
        if (questionVisibility[effectiveNextVisibleQId] != true) { // Check if visibility actually changes
          questionVisibility[effectiveNextVisibleQId] = true;
          visibilityChangedInPerformJump = true;
        }
        // If the target is in a repeatable group, set its active index (usually to 0)
        if (targetQuestionDef.belongsToGroupTag != null && targetQuestionDef.belongsToGroupTag!.isNotEmpty &&
            (repeatableGroupCounts[targetQuestionDef.belongsToGroupTag!] ?? 0) > 0) {
          // Set or reset active index for the group of the target question.
          // Important to ensure the correct instance is shown/focused.
          if (!activeRepeatIndexForGroup.containsKey(targetQuestionDef.belongsToGroupTag!) ||
              activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] != 0 ) { // Only if not already 0 or not set
            activeRepeatIndexForGroup.putIfAbsent(targetQuestionDef.belongsToGroupTag!, () => 0); // Ensure it exists
            if(activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] != 0) groupIndexChangedInPerformJump = true;
            activeRepeatIndexForGroup[targetQuestionDef.belongsToGroupTag!] = 0; // Set to first item
          }
        }
      } else {
        // print("[_performJump] Peringatan: Definisi pertanyaan untuk target lompatan '$effectiveNextVisibleQId' tidak ditemukan. Lompatan dibatalkan menjadi null.");
        effectiveNextVisibleQId = null; // Effectively jumps to end if definition is missing
      }
    }
    /*
    // Section expansion logic (currently commented out, can be revisited if needed)
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
      // Refresh if group index changed OR if the target is in a group (to ensure UI reflects active index)
      activeRepeatIndexForGroup.refresh();
    }


    // If there's a new visible question, recursively evaluate its jumps
    if (effectiveNextVisibleQId != null && (questionVisibility[effectiveNextVisibleQId] == true)) {
      final targetQuestionDef = findQuestionById(effectiveNextVisibleQId);
      if (targetQuestionDef != null) {
        dynamic targetAnswer = _getAnswerForEvaluation(targetQuestionDef); // Get its current answer
        // print("[_performJump] Melakukan evaluasi rekursif untuk Q_ID: $effectiveNextVisibleQId");
        evaluateAndExecuteJumps(effectiveNextVisibleQId, targetAnswer);
      } else {
        // print("[_performJump] Tidak ada evaluasi rekursif karena target question def null untuk Q_ID: $effectiveNextVisibleQId");
      }
    } else {
      // print("[_performJump] Tidak ada evaluasi rekursif. effectiveNextQ: $effectiveNextVisibleQId, visibility: ${effectiveNextVisibleQId != null ? questionVisibility[effectiveNextVisibleQId] : 'N/A'}");
      // This means we jumped to the end of the form, or the target question was invalid/not found.
    }
    // print("[_performJump] Selesai untuk currentQ: $currentQuestionId. Final expandedSectionId: ${expandedSectionId.value}");
  }


  void updateUserAnswer(String questionId, dynamic value) {
    final question = findQuestionById(questionId);
    if (question == null) return;

    dynamic actualUpdatedValue = value;
    dynamic valueBeforeUpdate = userAnswers[questionId]; // Get value before potential modification

    // Special handling for repeatable group controller questions (numeric input for count)
    if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
      int count = 0;
      if (value is String && value.isNotEmpty) {
        // Allow only digits for count
        count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (value is num) {
        count = value.toInt();
      }

      // Apply min/max validation if defined for the controller question
      final ValidationRule? qValidation = question.validation;
      if (qValidation != null) {
        if (qValidation.minValue != null && count < qValidation.minValue!) count = qValidation.minValue!.toInt();
        if (qValidation.maxValue != null && count > qValidation.maxValue!) count = qValidation.maxValue!.toInt();
      }

      // Custom validation: Example for question code "204" (Jumlah yang memiliki HP)
      // compared against question code "112" (Jumlah Anggota Rumah Tangga - ART)
      if (question.code == "204") { // Example: "Number of people with phones"
        final artQuestion = findQuestionByCode("112"); // Example: "Number of household members"
        if (artQuestion != null) {
          // Get the answer of the ART question for comparison
          final artCountValueDynamic = _getAnswerForEvaluation(artQuestion); // Gets from userAnswers or repeatable
          num? artCount = (artCountValueDynamic is String && artCountValueDynamic.isNotEmpty)
              ? num.tryParse(artCountValueDynamic.replaceAll(',', '.')) // Assuming display uses comma
              : (artCountValueDynamic is num ? artCountValueDynamic : null);

          if (artCount != null && count > artCount) {
            count = artCount.toInt(); // Cap the count
            Get.snackbar(
                "Info Validasi",
                "Jumlah ${question.questionText} tidak boleh melebihi ${artQuestion.questionText} ($artCount). Dibatasi menjadi $count.",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 4));
          }
        }
      }
      actualUpdatedValue = count.toString(); // Store count as string

      // Update userAnswers and repeatableGroupCounts, then adjust group items
      if ((repeatableGroupCounts[question.controlledGroupTag!] ?? 0) != count ||
          (userAnswers[questionId]?.toString() ?? '0') != actualUpdatedValue) { // Check if change is significant
        userAnswers[questionId] = actualUpdatedValue;
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
        // activeRepeatIndexForGroup might need refresh if count changes affecting current index
        activeRepeatIndexForGroup.refresh();
      } else {
        userAnswers[questionId] = actualUpdatedValue; // Still update if value is same but type might differ initially
      }
    } else {
      // For regular questions
      userAnswers[questionId] = actualUpdatedValue;
    }

    // If "Other" was selected and now a predefined option is chosen, clear the "Other" text.
    if (question.hasOtherOption && actualUpdatedValue != _kOtherOptionValue && valueBeforeUpdate == _kOtherOptionValue) {
      updateOtherAnswer(questionId, ''); // Clear other text for non-repeatable
    }

    // If the answer value actually changed, reset dependent children
    if (valueBeforeUpdate != actualUpdatedValue) {
      // Check if this question is a parent to any dependent dropdowns
      bool isParent = loadedForm.value?.sections.any((s) =>
          s.questions.any((qChild) =>
          qChild.dependentOptions?.parentQuestionId == questionId)) ?? false;
      if (isParent) {
        _resetDependentChildrenAnswers(questionId);
      }
    }

    // After updating any answer, re-evaluate jump logic
    evaluateAndExecuteJumps(questionId, userAnswers[questionId]);
  }


  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    final question = findQuestionById(questionId);
    // Ensure question exists and belongs to a group
    if (question == null || question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) return;

    final groupTag = question.belongsToGroupTag!;
    final count = repeatableGroupCounts[groupTag] ?? 0;

    // Ensure repeatIndex is valid
    if (repeatIndex < 0 || repeatIndex >= count) {
      // print("[InputUserController] Peringatan: updateRepeatableGroupAnswer untuk index $repeatIndex di luar batas count $count (QID: $questionId).");
      return;
    }

    // Ensure the map for this question and index exists
    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }
    if (!repeatableGroupAnswers[questionId]!.containsKey(repeatIndex)){
      // Initialize with default if accessing for the first time (should be rare if _adjust is correct)
      repeatableGroupAnswers[questionId]![repeatIndex] = _getDefaultAnswerForQuestionType(question.type);
    }

    dynamic oldValue = repeatableGroupAnswers[questionId]![repeatIndex];
    repeatableGroupAnswers[questionId]![repeatIndex] = value;

    // If "Other" was selected and now a predefined option is chosen, clear the "Other" text for this instance.
    if (question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '', repeatIndex: repeatIndex);
    }

    // If the answer value actually changed for this instance, reset its dependent children (if any)
    if (oldValue != value) {
      // Check if this question (within a group) is a parent to any dependent dropdowns
      // Note: Dependent logic for repeatable parents to repeatable children needs careful design.
      // This assumes a simpler dependency or that _resetDependentChildrenAnswers can handle it.
      bool isParent = loadedForm.value?.sections.any((s) =>
          s.questions.any((qChild) =>
          qChild.dependentOptions?.parentQuestionId == questionId)) ?? false;
      if (isParent) {
        // This might need more nuanced logic if the child is also repeatable and needs specific instance targeting.
        _resetDependentChildrenAnswers(questionId); // Potentially too broad if child is not in same group instance
      }
    }

    // Evaluate jumps based on the changed answer of this specific repeatable instance.
    // Use _getAnswerForEvaluation with specificRepeatIndex to ensure the correct instance's answer is used.
    dynamic answerForEval = _getAnswerForEvaluation(question, specificRepeatIndex: repeatIndex);
    evaluateAndExecuteJumps(questionId, answerForEval);
  }


  void _adjustRepeatableGroupAnswers(String groupTag, int newCount) {
    if (loadedForm.value == null) return;

    // Iterate through all questions to find those belonging to the specified groupTag
    for (var section in loadedForm.value!.sections) {
      for (var qInGroup in section.questions) {
        if (qInGroup.belongsToGroupTag == groupTag) {
          // Adjust main answers
          if (!repeatableGroupAnswers.containsKey(qInGroup.id)) {
            repeatableGroupAnswers[qInGroup.id] = RxMap<int, dynamic>();
          }
          final answerMap = repeatableGroupAnswers[qInGroup.id]!;
          // Remove answers for indices beyond the new count
          answerMap.removeWhere((key, _) => key >= newCount);
          // Add default answers for new indices up to the new count
          for (int i = 0; i < newCount; i++) {
            if (!answerMap.containsKey(i)) {
              answerMap[i] = _getDefaultAnswerForQuestionType(qInGroup.type);
            }
          }

          // Adjust "other" answers if the question has an "other" option
          if (qInGroup.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(qInGroup.id)) {
              repeatableGroupOtherAnswers[qInGroup.id] = RxMap<int, String>();
            }
            final otherAnswerMap = repeatableGroupOtherAnswers[qInGroup.id]!;
            otherAnswerMap.removeWhere((key, _) => key >= newCount);
            for (int i = 0; i < newCount; i++) {
              if (!otherAnswerMap.containsKey(i)) {
                otherAnswerMap[i] = ''; // Default for "other" text is empty string
              }
            }
          }
        }
      }
    }

    // Adjust the active index for the group
    if (newCount == 0) {
      activeRepeatIndexForGroup.remove(groupTag); // No active item if group is empty
    } else {
      // If group has items, ensure active index is valid (typically 0 for new/adjusted groups)
      if (!activeRepeatIndexForGroup.containsKey(groupTag) || activeRepeatIndexForGroup[groupTag]! >= newCount) {
        activeRepeatIndexForGroup[groupTag] = 0; // Default to first item
      }
      // This condition might be redundant due to the line above but ensures safety:
      if (activeRepeatIndexForGroup[groupTag]! >= newCount && newCount > 0) { // Should be newCount -1 if newCount > 0
        activeRepeatIndexForGroup[groupTag] = newCount -1; // last valid index
      }
      if (activeRepeatIndexForGroup[groupTag]! < 0 && newCount > 0) { // Should not happen
        activeRepeatIndexForGroup[groupTag] = 0;
      }
    }
  }

  void goToNextRepeatableItem(String groupTag) {
    if (repeatableGroupCounts.containsKey(groupTag) &&
        activeRepeatIndexForGroup.containsKey(groupTag) &&
        repeatableGroupCounts[groupTag]! > 0) { // Ensure group is not empty
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      int maxIdx = repeatableGroupCounts[groupTag]! - 1;
      if (currentIdx < maxIdx) {
        activeRepeatIndexForGroup[groupTag] = currentIdx + 1;
      }
    }
  }

  void goToPreviousRepeatableItem(String groupTag) {
    if (activeRepeatIndexForGroup.containsKey(groupTag)) { // No need to check count, if index exists, count > 0
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      if (currentIdx > 0) {
        activeRepeatIndexForGroup[groupTag] = currentIdx - 1;
      }
    }
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel,
      String colLabel, String subColLabel, String? value) {
    // Prepare the numeric value, allowing for null if input is empty
    String? parseableValue = value?.replaceAll(',', '.'); // Use dot as decimal for parsing
    num? numericValue = parseableValue != null && parseableValue.isNotEmpty
        ? num.tryParse(parseableValue)
        : null; // Null if empty or invalid

    // Helper to safely get or initialize the grid map structure
    Map<String, Map<String, Map<String, num?>>> getGridMap(dynamic currentGridData) {
      if (currentGridData is Map<String, Map<String, Map<String, num?>>>) {
        return currentGridData; // Already in correct format
      }
      // Attempt to cast/convert if it's a generic Map (e.g., from Firestore deserialization)
      if (currentGridData is Map) {
        try {
          return Map<String, Map<String, Map<String, num?>>>.fromEntries(
              (currentGridData as Map<dynamic, dynamic>).entries.map((rowEntry) {
                var colMap = rowEntry.value;
                if (colMap is! Map) colMap = <String, dynamic>{}; // Ensure colMap is a Map

                return MapEntry(
                    rowEntry.key.toString(),
                    Map<String, Map<String, num?>>.fromEntries(
                        (colMap as Map<dynamic, dynamic>).entries.map((colEntry) {
                          var subColMap = colEntry.value;
                          if (subColMap is! Map) subColMap = <String, dynamic>{}; // Ensure subColMap is a Map

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
          return <String, Map<String, Map<String, num?>>>{}; // Fallback to empty if cast fails
        }
      }
      return <String, Map<String, Map<String, num?>>>{}; // Default empty if not a map at all
    }

    if (repeatIndex != null) { // Grid is within a repeatable group
      // Ensure necessary maps exist down to the specific index
      if (!repeatableGroupAnswers.containsKey(questionId)) {
        repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      }
      if (!repeatableGroupAnswers[questionId]!.containsKey(repeatIndex)) {
        repeatableGroupAnswers[questionId]![repeatIndex] = <String, Map<String, Map<String, num?>>>{}; // Init as empty grid
      }

      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(repeatableGroupAnswers[questionId]![repeatIndex]);

      // Update the specific cell value
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers; // Assign back to RxMap
    } else { // Grid is a non-repeatable question
      // Ensure userAnswers for this questionId is a grid map
      if (!userAnswers.containsKey(questionId) || userAnswers[questionId] == null || userAnswers[questionId] is! Map ) {
        userAnswers[questionId] = <String, Map<String, Map<String, num?>>>{}; // Init as empty grid
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(userAnswers[questionId]);

      // Update the specific cell value
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers; // Assign back to RxMap
    }
    // No need to call .refresh() on RxMap for individual item changes if using GetX correctly.
    // However, if the entire map object reference changes (like above by reassigning), GetX detects it.
  }

  String? _performLocalValidation(
      FormQuestion question, dynamic answer, String questionDisplayName, {int? repeatIndex}) {
    // Skip validation if the question is not currently visible
    if (questionVisibility[question.id] != true) {
      return null;
    }

    bool isEmpty = _isAnswerEmpty(answer, question.type);
    String? otherText;

    // Special handling for "Other" option: if selected, the "Other" text field becomes the value to validate
    if (question.hasOtherOption) {
      // Get the "other" text based on whether it's in a repeatable group or not
      if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty && repeatIndex != null) {
        otherText = repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        otherText = userOtherAnswers[question.id];
      }

      if (answer == _kOtherOptionValue && (otherText == null || otherText.trim().isEmpty)) {
        // If "Other" is selected but its text is empty
        if (question.isRequired) return 'Isian "Lainnya" pada "$questionDisplayName" wajib diisi.';
        isEmpty = true; // Treat as empty for non-required "Other" if text is blank
      }
      else if (answer == _kOtherOptionValue && (otherText != null && otherText.trim().isNotEmpty)) {
        // If "Other" is selected and text is provided, it's not empty
        isEmpty = false;
      }
    }

    // Standard "isRequired" check
    if (question.isRequired && isEmpty) {
      return 'Pertanyaan "$questionDisplayName" wajib diisi.';
    }

    // If not required and empty, no further validation needed for this question
    if (isEmpty && !question.isRequired) {
      return null;
    }

    // Proceed with specific validation rules if present
    final ValidationRule? rule = question.validation;
    if (rule == null) {
      return null; // No rules to apply
    }

    String effectiveStringValue = ""; // Value to use for string-based validations
    if (answer == _kOtherOptionValue && otherText != null) {
      effectiveStringValue = otherText.trim(); // Use "Other" text if "Other" is selected
    } else if (answer is String) {
      effectiveStringValue = answer.trim();
    }
    // Note: for non-string answers like lists (checkboxes) or maps (grid),
    // isEmpty check above handles their emptiness. String validations below apply to text-like inputs.

    // String-based validations (minLength, maxLength, regex, predefined rules)
    if (effectiveStringValue.isNotEmpty || (answer is String && answer.isNotEmpty && question.type != QuestionType.number && question.type != QuestionType.gridNumeric)) {
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
      // numbersOnly for general text fields that should only contain numbers.
      // For QuestionType.number, its own validation handles numeric checks more specifically.
      if (rule.predefinedRule == 'numbersOnly' && !GetUtils.isNumericOnly(effectiveStringValue.replaceAll(',', '').replaceAll('.', ''))) {
        return '"$questionDisplayName" hanya boleh angka.';
      }
    }

    // Numeric validations (minValue, maxValue, and custom comparisons)
    if (question.type == QuestionType.number && answer != null && answer.toString().isNotEmpty) {
      // Answer for number type is stored as string (e.g., "123,45") in userAnswers, convert for validation
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.')); // Use dot for parsing

      if (numAnswer == null && answer.toString().isNotEmpty) { // Should not be empty if we reached here and it's required
        return '"$questionDisplayName" harus berupa angka.';
      }
      if(numAnswer == null) return null; // If somehow null (e.g. non-required and malformed), skip numeric rules

      if (rule.minValue != null && numAnswer < rule.minValue!) {
        return '"$questionDisplayName" minimal ${rule.minValue}.';
      }
      if (rule.maxValue != null && numAnswer > rule.maxValue!) {
        return '"$questionDisplayName" maksimal ${rule.maxValue}.';
      }

      // Custom validation example (e.g. Q203/Q204 vs Q112)
      if (question.code == "203" || question.code == "204") { // Specific question codes
        final artQuestion = findQuestionByCode("112"); // Find the question to compare against
        if (artQuestion != null) {
          dynamic artCountValueDynamic;
          // Determine context for getting ART answer (repeatable or non-repeatable)
          if (repeatIndex != null && artQuestion.belongsToGroupTag == question.belongsToGroupTag) {
            // If both current and ART question are in the same group instance
            artCountValueDynamic = repeatableGroupAnswers[artQuestion.id]?[repeatIndex];
          } else {
            // If ART question is non-repeatable or in a different context
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
    // TODO: Add validation for GridNumeric if complex rules are needed (e.g. sum of row/col, cell-specific ranges)
    // For now, GridNumeric's emptiness is checked by _isAnswerEmpty. Individual cell format is implicitly numeric.

    return null; // No validation errors
  }


  Future<bool> submitForm() async {
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isLoading.value = true;
    formKey.currentState?.save(); // Ensure all onSaved from FormFields are called.
    bool formKeyValidationPassed = formKey.currentState?.validate() ?? true; // Trigger TextFormField validators.

    String? firstInvalidSectionIdToFocus;
    bool allCustomValidationsPassed = true;
    List<String> validationErrors = [];

    // Iterate through all questions in the form structure to perform custom validation.
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        // Only validate questions that are currently visible.
        if (questionVisibility[question.id] != true) {
          continue;
        }

        dynamic answerToValidate;
        String questionDisplayName = question.questionText; // Base display name

        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          // Non-repeatable question
          answerToValidate = userAnswers[question.id];
          String? localValidationError = _performLocalValidation(
              question, answerToValidate, questionDisplayName, repeatIndex: null);
          if (localValidationError != null) {
            allCustomValidationsPassed = false;
            if (!validationErrors.contains(localValidationError)) { // Add only unique errors
              validationErrors.add(localValidationError);
            }
            if (firstInvalidSectionIdToFocus == null) { // Mark section for focus
              firstInvalidSectionIdToFocus = section.id;
            }
          }
        } else {
          // Repeatable question
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          for (int i = 0; i < count; i++) { // Validate each instance
            answerToValidate = repeatableGroupAnswers[question.id]?[i];
            // Modify display name for context in error messages
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
      // If there's an invalid section and more than one section, try to expand it.
      if (firstInvalidSectionIdToFocus != null && expandedSectionId.value != firstInvalidSectionIdToFocus) {
        if ((loadedForm.value?.sections.length ?? 0) > 1) {
          expandedSectionId.value = firstInvalidSectionIdToFocus;
        }
      }

      final uniqueErrors = validationErrors.toSet().toList(); // Ensure unique messages
      String notificationMessage = uniqueErrors.join('\n');
      // Fallback message if custom validation passed but Form key validation failed (e.g. from internal TextFormField validator)
      if (uniqueErrors.isEmpty && !formKeyValidationPassed) {
        notificationMessage = "Beberapa pertanyaan wajib belum diisi atau formatnya salah. Silakan periksa kembali.";
      }


      Get.snackbar(
        'Validasi Form Gagal',
        '', // Title only, message in messageText for scrollability
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        isDismissible: true,
        messageText: ConstrainedBox( // To make the message area scrollable if too long
          constraints: BoxConstraints(maxHeight: Get.height * 0.25), // Limit height
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              notificationMessage.isNotEmpty ? notificationMessage : "Terjadi kesalahan validasi. Harap periksa semua isian.",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
      return false; // Validation failed
    }

    // --- All validations passed, proceed to prepare and submit data ---
    List<QuestionAnswer> answersToSubmit = [];
    loadedForm.value!.sections.forEach((section) {
      section.questions.forEach((question) {
        // Only include answers for questions that are currently visible
        if (questionVisibility[question.id] == true) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            // Non-repeatable question
            dynamic answer = userAnswers[question.id];
            String? otherText = userOtherAnswers[question.id];
            // If "Other" selected, use its text; otherwise, use the main answer.
            dynamic finalAnswer = (question.hasOtherOption && answer == _kOtherOptionValue) ? (otherText ?? '') : answer;

            // Include if not empty OR if not required (to save intentionally blank optional answers)
            // This was: if (!_isAnswerEmpty(finalAnswer, question.type) || !question.isRequired)
            // To ensure ALL filled answers (even if default-like for non-required) are saved when they were visible:
            // We can simplify: if an answer exists for a visible question, prepare it.
            // The _prepareAnswerForFirestore will handle nullifying empty numbers/dates if needed.
            // Let's stick to original logic: only save non-empty OR non-required.
            // If a non-required field is empty, _isAnswerEmpty will be true.
            // So it's saved if `!true || true` (if not required) -> true.
            // If it's required and empty: `!true || false` -> false (not saved, but validation should catch this).
            if (!_isAnswerEmpty(finalAnswer, question.type) || !question.isRequired) {
              answersToSubmit.add(QuestionAnswer(
                  questionId: question.id,
                  questionCode: question.code ?? '',
                  questionText: question.questionText,
                  answer: _prepareAnswerForFirestore(finalAnswer, question.type),
                  questionType: question.type.toShortString()));
            }

          } else {
            // Repeatable question
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) { // Iterate through each instance
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              String? otherText = repeatableGroupOtherAnswers[question.id]?[i];
              dynamic finalAnswer = (question.hasOtherOption && answer == _kOtherOptionValue) ? (otherText ?? '') : answer;

              if (!_isAnswerEmpty(finalAnswer, question.type) || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                    questionId: "${question.id}_$i", // Append index to ID for storage
                    questionCode: "${question.code ?? ''}_${i + 1}", // Append index to code
                    questionText: "[Data ke-${i + 1}] ${question.questionText}", // Contextualized text
                    answer: _prepareAnswerForFirestore(finalAnswer, question.type),
                    questionType: question.type.toShortString()));
              }
            }
          }
        }
      });
    });

    final submissionData = FormSubmission(
      id: isEditMode.value ? submissionId.value : null, // Use existing ID if editing
      formId: loadedForm.value!.id,
      formTitle: loadedForm.value!.title,
      userId: _auth.currentUser!.uid,
      userName: _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? 'Anonim',
      submittedAt: (isEditMode.value && loadedSubmission.value?.submittedAt != null)
          ? loadedSubmission.value!.submittedAt! // Preserve original submission time on edit
          : Timestamp.now(), // New submission time for new entries
      answers: answersToSubmit,
      // No 'updatedAt' here in the model directly, handled in Firestore data map
    );

    Map<String, dynamic> firestoreData = submissionData.toFirestore();
    if (isEditMode.value) {
      firestoreData['updatedAt'] = Timestamp.now(); // Add/update 'updatedAt' for edits
    }
    // For new submissions, 'submittedAt' serves as creation time, 'updatedAt' is not set.

    try {
      if (isEditMode.value) {
        // Update existing document
        await _db.collection('formSubmissions').doc(submissionId.value).set(firestoreData, SetOptions(merge: true));
        Get.snackbar('Berhasil', 'Perubahan berhasil disimpan!',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        // Add new document
        await _db.collection('formSubmissions').add(firestoreData);
        Get.snackbar('Berhasil', 'Form berhasil dikirim!',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      }
      isLoading.value = false;
      return true; // Submission successful
    } catch (e) {
      Get.snackbar('Error Simpan/Kirim', 'Gagal menyimpan data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white, duration: const Duration(seconds: 5));
      isLoading.value = false;
      return false; // Submission failed
    }
  }

  bool _isAnswerEmpty(dynamic answer, QuestionType type) {
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty; // For checkboxes
    if (answer is Map) {
      if (type == QuestionType.gridNumeric) {
        if (answer.isEmpty) return true;
        // A grid is empty if all its cells are null or effectively empty strings.
        return !(answer as Map<String, Map<String, Map<String, num?>>>).values.any((colMap) =>
            colMap.values.any((subColMap) =>
                subColMap.values.any((cellVal) => cellVal != null && cellVal.toString().trim().isNotEmpty)
            )
        );
      }
      return answer.isEmpty; // For other map types, though not standard form answers
    }
    return false; // Default: consider non-null, non-string, non-list, non-map as not empty (e.g. bool, num if used directly)
  }


  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type) {
    // Handle null answers explicitly first, especially for types that should store DB null
    if (answer == null) {
      switch (type) {
        case QuestionType.number:
        case QuestionType.date: // Store as null if explicitly null
        case QuestionType.gridNumeric: // Store empty grid as {} or null if truly no data.
        // Here, if answer is null, store null.
          return null;
        case QuestionType.checkboxes:
          return <String>[]; // Firestore expects an empty list for empty checkboxes
        default:
          return ""; // Default to empty string for text-based types if null
      }
    }

    // Handle non-null answers
    switch (type) {
      case QuestionType.number:
        if (answer is String) {
          if (answer.trim().isEmpty) return null; // Empty string for number field means no answer (null)
          return num.tryParse(answer.replaceAll(',', '.')); // Parse with dot as decimal
        }
        if (answer is num) return answer; // Already a number
        return null; // Invalid type for number
      case QuestionType.date:
        if (answer is String) {
          if (answer.trim().isEmpty) return null; // Empty string for date means no answer (null)
          try {
            // Parse 'dd/MM/yyyy' string to DateTime, then to Timestamp
            final date = DateFormat('dd/MM/yyyy').parseStrict(answer);
            return Timestamp.fromDate(date);
          } catch (e) {
            // If parsing fails, try to see if it's an ISO string or other parsable format
            try {
              final date = DateTime.parse(answer); // Handles ISO 8601 etc.
              return Timestamp.fromDate(date);
            } catch (e2) {
              // print("[InputUserController] Peringatan: Gagal mem-parse string tanggal '$answer' untuk Firestore. Menyimpan string mentah.");
              return answer; // Fallback: store the unparsable string if necessary (should be avoided)
            }
          }
        }
        if (answer is DateTime) return Timestamp.fromDate(answer); // Already DateTime
        if (answer is Timestamp) return answer; // Already Timestamp
        return null; // Invalid type for date
      case QuestionType.gridNumeric:
      // Ensure it's the correct map structure before attempting to process for Firestore.
        if (answer is Map<String, Map<String, Map<String, num?>>>) {
          Map<String, dynamic> firestoreGrid = {};
          answer.forEach((rowKey, colMap) {
            // For single-row grids without explicit labels, UI uses "" as key.
            // Firestore might not like empty keys, so map to a default string if needed.
            String effectiveRowKey = rowKey.toString().isEmpty ? "default_row" : rowKey.toString();
            Map<String, dynamic> currentCols = {};
            colMap.forEach((colKey, subColMap) {
              Map<String, num?> currentSubCols = {};
              subColMap.forEach((subColKey, cellValue) {
                // Ensure cellValue is num? (can be null)
                currentSubCols[subColKey.toString()] = (cellValue is num?) ? cellValue : num.tryParse(cellValue.toString());
              });
              currentCols[colKey.toString()] = currentSubCols;
            });
            firestoreGrid[effectiveRowKey] = currentCols;
          });
          return firestoreGrid;
        }
        return {}; // Return empty map if not the expected structure (or handle as error)
      case QuestionType.checkboxes:
      // Ensure it's a list of strings
        if (answer is List) return List<String>.from(answer.map((e) => e.toString()));
        return <String>[]; // Default to empty list
      default: // For text, paragraph, dropdown, multipleChoice (which store string)
        return answer.toString();
    }
  }

}