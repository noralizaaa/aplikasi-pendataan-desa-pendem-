// File: input_user_controller.dart

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

  // Konstanta untuk nilai opsi "Lainnya" (harus sama dengan yang di UI)
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

  // --- AWAL TAMBAHAN: State untuk Teks "Lainnya" ---
  final RxMap<String, String> userOtherAnswers = <String, String>{}.obs;
  final RxMap<String, RxMap<int, String>> repeatableGroupOtherAnswers = <String, RxMap<int, String>>{}.obs;
  // --- AKHIR TAMBAHAN ---

  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

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
    // ... (logika sectionHasAnswers tetap sama)
    final section =
    loadedForm.value?.sections.firstWhereOrNull((s) => s.id == sectionId);
    if (section == null) return false;

    for (var question in section.questions) {
      bool hasMainAnswer = false;
      bool hasOtherTextForSelectedOther = false;

      if (question.belongsToGroupTag == null ||
          question.belongsToGroupTag!.isEmpty) {
        // Regular question
        hasMainAnswer = userAnswers.containsKey(question.id) &&
            !_isAnswerEmpty(userAnswers[question.id], question.type);
        if (question.hasOtherOption && userAnswers[question.id] == _kOtherOptionValue) {
          hasOtherTextForSelectedOther = userOtherAnswers[question.id]?.isNotEmpty ?? false;
          if (hasMainAnswer && hasOtherTextForSelectedOther) return true;
        } else if (hasMainAnswer) {
          return true;
        }
      } else {
        // Repeatable group question
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
    // ... (logika onInit untuk mengambil argumen tetap sama)
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
    // ... (logika pengambilan form dan submission tetap sama)
    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    loadedSubmission.value = null;
    _allQuestionIdsInOrder.clear();

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
    // ... (tetap sama)
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
    // --- AWAL TAMBAHAN: Bersihkan state "OtherAnswers" ---
    userOtherAnswers.clear();
    repeatableGroupOtherAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupOtherAnswers.clear();
    // --- AKHIR TAMBAHAN ---
    repeatableGroupCounts.clear();
    questionVisibility.clear();

    if (isEditMode.value && loadedSubmission.value != null) {
      _populateAnswersFromSubmission();
    } else {
      // Inisialisasi form kosong (logika yang sudah ada)
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
          }
        }
        if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
          if (!repeatableGroupAnswers.containsKey(question.id)) {
            repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
          }
          // --- AWAL TAMBAHAN: Inisialisasi map untuk repeatableGroupOtherAnswers ---
          if (question.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(question.id)) {
              repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
            }
          }
          // --- AKHIR TAMBAHAN ---
        }
      }
      repeatableGroupCounts.forEach((groupTag, count) {
        _adjustRepeatableGroupAnswers(groupTag, count);
      });
    }
    _initializeAndEvaluateInitialVisibility();
  }

  Future<void> fetchFormStructure() async {
    // ... (logika fetchFormStructure tetap sama)
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

    // Inisialisasi userAnswers dan userOtherAnswers dengan default dulu
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

      // --- AWAL MODIFIKASI: Logika untuk memisahkan jawaban utama dan teks "Lainnya" ---
      dynamic mappedMainAnswer;
      String? otherText;

      if (questionDef.hasOtherOption && savedAnswer.answer is String) {
        bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
        if (questionDef.type == QuestionType.multipleChoice) {
          if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) { // Anggap sebagai teks "Lainnya"
            mappedMainAnswer = _kOtherOptionValue;
            otherText = savedAnswer.answer as String;
          } else { // Opsi standar atau kosong (jika tidak wajib)
            mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
          }
        } else if (questionDef.type == QuestionType.checkboxes && savedAnswer.answer is List) {
          List<String> tempCheckboxAnswers = [];
          bool otherFound = false;
          for(var item in (savedAnswer.answer as List)){
            if(questionDef.options.contains(item.toString())){
              tempCheckboxAnswers.add(item.toString());
            } else if (item.toString().isNotEmpty) { // Anggap item ini adalah teks "Lainnya"
              if(!otherFound){ // Hanya satu teks "Lainnya" per pertanyaan checkbox
                tempCheckboxAnswers.add(_kOtherOptionValue);
                otherText = item.toString();
                otherFound = true;
              } else {
                // Jika ada lebih dari satu item non-predefined, ini anomali,
                // mungkin tambahkan ke otherText atau log error. Untuk saat ini, ambil yang pertama.
                print("Warning: Multiple non-predefined options found for checkbox ${questionDef.id}, using first as 'Other'.");
              }
            }
          }
          mappedMainAnswer = tempCheckboxAnswers;
        } else {
          mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
        }
      } else {
        mappedMainAnswer = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
      }
      // --- AKHIR MODIFIKASI ---

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
      } else if (potentialRepeatIndex != null) {
        // Penanganan untuk repeatable group members sudah dipindahkan ke loop kedua
      }
    }

    tempGroupCounts.forEach((tag, count) {
      repeatableGroupCounts[tag] = count;
    });

    repeatableGroupCounts.forEach((groupTag, count) {
      _adjustRepeatableGroupAnswers(groupTag, count); // Pastikan map diinisialisasi
      // Inisialisasi juga untuk repeatableGroupOtherAnswers
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


    // Loop kedua untuk mengisi repeatableGroupAnswers dan repeatableGroupOtherAnswers
    // Ini dilakukan setelah repeatableGroupCounts dan struktur map diinisialisasi
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
        continue; // Hanya proses anggota grup repeatable di sini
      }

      if (repeatableGroupAnswers.containsKey(originalQuestionId) &&
          (repeatableGroupAnswers[originalQuestionId]?.length ?? 0) > repeatIndex) {

        dynamic mappedMainAnswerRepeat;
        String? otherTextRepeat;

        if (questionDef.hasOtherOption && savedAnswer.answer is String) {
          bool isPredefinedOption = questionDef.options.contains(savedAnswer.answer as String);
          if (questionDef.type == QuestionType.multipleChoice) {
            if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
              mappedMainAnswerRepeat = _kOtherOptionValue;
              otherTextRepeat = savedAnswer.answer as String;
            } else {
              mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
            }
          } else { // Untuk checkbox dalam repeatable (asumsi format answer sama)
            mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
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
          mappedMainAnswerRepeat = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
        }

        repeatableGroupAnswers[originalQuestionId]![repeatIndex] = mappedMainAnswerRepeat;
        if (otherTextRepeat != null && repeatableGroupOtherAnswers.containsKey(originalQuestionId)) {
          repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = otherTextRepeat;
        }
      }
    }


    userAnswers.refresh();
    userOtherAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
    repeatableGroupCounts.refresh();
  }

  dynamic _mapAnswerToCorrectType(dynamic rawAnswer, QuestionType questionType) {
    // ... (Bagian awal _mapAnswerToCorrectType tetap sama)
    if (rawAnswer == null) {
      return _getDefaultAnswerForQuestionType(questionType);
    }

    switch (questionType) {
      case QuestionType.checkboxes:
        if (rawAnswer is List) {
          // Penanganan pemisahan _kOtherOptionValue sudah dilakukan di _populateAnswersFromSubmission
          return List<String>.from(rawAnswer.map((item) => item.toString()));
        }
        return <String>[];
    // ... (case lain tetap sama seperti sebelumnya)
      case QuestionType.number:
        if (rawAnswer is num) return rawAnswer.toString();
        if (rawAnswer is String) return rawAnswer;
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
          } catch (_) {}
        }
        return rawAnswer.toString();
      case QuestionType.gridNumeric:
        if (rawAnswer is Map) {
          try {
            return Map<String, Map<String, Map<String, num?>>>.fromEntries(
                (rawAnswer).entries.map((rowEntry) {
                  var colMap = rowEntry.value;
                  if (colMap is! Map) colMap = <String, dynamic>{};
                  return MapEntry(
                      rowEntry.key.toString(),
                      Map<String, Map<String, num?>>.fromEntries(
                          (colMap as Map).entries.map((colEntry) {
                            var subColMap = colEntry.value;
                            if (subColMap is! Map) subColMap = <String, dynamic>{};
                            return MapEntry(
                                colEntry.key.toString(),
                                Map<String, num?>.fromEntries(
                                    (subColMap as Map).entries.map((subColEntry) {
                                      num? valNum;
                                      if (subColEntry.value is num) {
                                        valNum = subColEntry.value as num?;
                                      } else if (subColEntry.value is String) {
                                        valNum = num.tryParse((subColEntry.value as String)
                                            .replaceAll(',', '.'));
                                      }
                                      return MapEntry(subColEntry.key.toString(), valNum);
                                    })));
                          })));
                }));
          } catch (e) {
            return <String, Map<String, Map<String, num?>>>{};
          }
        }
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
      case QuestionType.multipleChoice: // Penanganan pemisahan _kOtherOptionValue sudah dilakukan di _populate
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString();
      default:
        return rawAnswer.toString();
    }
  }

  void _initializeAndEvaluateInitialVisibility() {
    // ... (tetap sama)
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
      evaluateAndExecuteJumps(
          firstQuestion.id, userAnswers[firstQuestion.id]);
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
    // ... (tetap sama)
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (q.id == questionId) return q;
      }
    }
    return null;
  }

  FormQuestion? findQuestionByCode(String questionCode) {
    // ... (tetap sama)
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (q.code == questionCode) return q;
      }
    }
    return null;
  }

  dynamic getAnswerByQuestionId(String questionId) {
    // ... (tetap sama)
    return userAnswers[questionId];
  }

  // --- AWAL TAMBAHAN: Metode untuk get/update "Other" answer ---
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
      // Pastikan map untuk repeatIndex sudah ada jika belum
      if (!repeatableGroupOtherAnswers[questionId]!.containsKey(repeatIndex)){
        final groupTag = findQuestionById(questionId)?.belongsToGroupTag;
        if(groupTag != null){
          final count = repeatableGroupCounts[groupTag] ?? 0;
          if(repeatIndex < count){ // Hanya inisialisasi jika index valid
            repeatableGroupOtherAnswers[questionId]![repeatIndex] = '';
          } else {
            // Seharusnya tidak terjadi jika UI benar, tapi sebagai safety
            print("Warning: updateOtherAnswer for invalid repeatIndex $repeatIndex in QID $questionId");
            return;
          }
        } else {
          repeatableGroupOtherAnswers[questionId]![repeatIndex] = ''; // fallback jika groupTag tidak ketemu
        }
      }
      repeatableGroupOtherAnswers[questionId]![repeatIndex] = value;
      repeatableGroupOtherAnswers.refresh(); // Perlu refresh untuk RxMap dalam RxMap
    } else {
      userOtherAnswers[questionId] = value;
      userOtherAnswers.refresh();
    }
    final question = findQuestionById(questionId);
    print("updateOtherAnswer for Q: ${question?.code ?? questionId}${repeatIndex != null ? '[$repeatIndex]' : ''}, NewOtherValue: '$value'");
  }
  // --- AKHIR TAMBAHAN ---

  String? _getSectionIdForQuestion(String questionId) {
    // ... (tetap sama)
    if (loadedForm.value == null) return null;
    for (var section in loadedForm.value!.sections) {
      if (section.questions.any((q) => q.id == questionId)) {
        return section.id;
      }
    }
    return null;
  }

  String? _getFirstQuestionIdOfSection(String sectionId) {
    // ... (tetap sama)
    if (loadedForm.value == null) return null;
    final section =
    loadedForm.value!.sections.firstWhereOrNull((s) => s.id == sectionId);
    return section?.questions.isNotEmpty == true
        ? section!.questions.first.id
        : null;
  }

  void _resetDependentChildrenAnswers(String parentQuestionId, {bool calledFromJumpClear = false}) {
    // ... (logika _resetDependentChildrenAnswers tetap sama)
    // PERLU DIPERTIMBANGKAN: Apakah reset dependent children juga harus mengosongkan 'other answers' mereka?
    // Jika ya, tambahkan logika serupa untuk userOtherAnswers dan repeatableGroupOtherAnswers.
    // Untuk saat ini, saya biarkan seperti semula karena kompleksitasnya.
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
          // Jika child yang direset juga punya opsi "Lainnya", kosongkan teksnya
          if (qChild.hasOtherOption) userOtherAnswers[qChild.id] = '';
          changed = true;
          _resetDependentChildrenAnswers(qChild.id, calledFromJumpClear: calledFromJumpClear);
        }
        if (repeatableGroupAnswers.containsKey(qChild.id) &&
            (questionVisibility[qChild.id] == true || calledFromJumpClear)) {
          if (!(findQuestionById(parentQuestionId)?.isRepeatableGroupController ?? false)) {
            final groupTag = qChild.belongsToGroupTag;
            if (groupTag != null) {
              final count = repeatableGroupCounts[groupTag] ?? 0;
              for (int i = 0; i < count; i++) {
                if (repeatableGroupAnswers[qChild.id]![i] != defaultValue) {
                  repeatableGroupAnswers[qChild.id]![i] = defaultValue;
                  // Jika child yang direset juga punya opsi "Lainnya", kosongkan teksnya
                  if (qChild.hasOtherOption && repeatableGroupOtherAnswers.containsKey(qChild.id)) {
                    repeatableGroupOtherAnswers[qChild.id]![i] = '';
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
      userOtherAnswers.refresh(); // Tambahan refresh
      repeatableGroupAnswers.refresh();
      repeatableGroupOtherAnswers.refresh(); // Tambahan refresh
    }
  }

  void _clearAnswersForSkippedQuestions(List<String> skippedQuestionIds) {
    // ... (logika _clearAnswersForSkippedQuestions)
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
      // --- AWAL TAMBAHAN: Bersihkan juga other answers ---
      if (userOtherAnswers.containsKey(qId) && userOtherAnswers[qId]!.isNotEmpty) {
        userOtherAnswers[qId] = '';
        changed = true;
      }
      // --- AKHIR TAMBAHAN ---

      if (repeatableGroupAnswers.containsKey(qId)) {
        final groupTag = question.belongsToGroupTag;
        if (groupTag != null) {
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final answerMap = repeatableGroupAnswers[qId]!;
          // --- AWAL TAMBAHAN: Map untuk other answers repeatable ---
          final otherAnswerMap = repeatableGroupOtherAnswers[qId];
          // --- AKHIR TAMBAHAN ---
          for (int i = 0; i < count; i++) {
            if (answerMap.containsKey(i) && answerMap[i] != defaultValue) {
              answerMap[i] = defaultValue;
              changed = true;
            }
            // --- AWAL TAMBAHAN: Bersihkan juga other answers repeatable ---
            if (otherAnswerMap != null && otherAnswerMap.containsKey(i) && otherAnswerMap[i]!.isNotEmpty) {
              otherAnswerMap[i] = '';
              changed = true;
            }
            // --- AKHIR TAMBAHAN ---
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
      userOtherAnswers.refresh(); // Tambahan
      repeatableGroupAnswers.refresh();
      repeatableGroupOtherAnswers.refresh(); // Tambahan
      repeatableGroupCounts.refresh();
    }
  }

  void evaluateAndExecuteJumps(String currentQuestionId, dynamic answerValue) {
    // ... (logika evaluateAndExecuteJumps tetap sama)
    final question = findQuestionById(currentQuestionId);
    if (question == null ||
        loadedForm.value == null ||
        (questionVisibility[currentQuestionId] != true &&
            !isLoading.value)) { // Cek isLoading agar tidak skip jump saat awal load
      return;
    }

    String? jumpToTargetCompositeValue;

    if (question.unconditionalJumpTarget != null &&
        question.unconditionalJumpTarget!.isNotEmpty) {
      jumpToTargetCompositeValue = question.unconditionalJumpTarget;
    } else if (question.conditionalJumps.isNotEmpty) {
      String currentAnswerString = answerValue?.toString() ?? "";
      // --- AWAL MODIFIKASI: Jika jawaban adalah "Lainnya", gunakan teks "Lainnya" untuk evaluasi kondisi ---
      if (question.hasOtherOption && answerValue == _kOtherOptionValue) {
        currentAnswerString = getOtherAnswer(currentQuestionId) ?? "";
        // Jika ini repeatable, perlu repeatIndex. Tapi jump biasanya dari non-repeatable parent.
        // Jika jump dari repeatable, logika ini perlu penyesuaian.
        // Untuk saat ini, asumsi jump dari non-repeatable parent / pertanyaan tunggal
      }
      // --- AKHIR MODIFIKASI ---
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
          questionVisibility.refresh();
          evaluateAndExecuteJumps(nextQuestionInSequenceId,
              userAnswers[nextQuestionInSequenceId]);
        }
      }
    }
  }

  void _performJump(String currentQuestionId, String targetCompositeValue) {
    // ... (logika _performJump tetap sama)
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
      if (!_allQuestionIdsInOrder[i]
          .contains(effectiveNextVisibleQId ?? '###NEVER_MATCH_THIS###')) {
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }
    if (effectiveNextVisibleQId != null && targetIndex < currentIndexInOrder) { // Backward jump
      for (int i = targetIndex + 1; i < currentIndexInOrder; i++) {
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }

    bool visibilityChanged = false;
    for (String qId in _allQuestionIdsInOrder) {
      if (qId == effectiveNextVisibleQId) {
        if (questionVisibility[qId] != true) {
          questionVisibility[qId] = true;
          visibilityChanged = true;
        }
      } else if (qId != currentQuestionId && questionVisibility[qId] != false) {
        if (idsToHideAndClear.contains(qId) ||
            (effectiveNextVisibleQId == null && _allQuestionIdsInOrder.indexOf(qId) > currentIndexInOrder) ){
          questionVisibility[qId] = false;
          visibilityChanged = true;
        } else if (effectiveNextVisibleQId != null && _allQuestionIdsInOrder.indexOf(qId) > targetIndex) {
          // Sembunyikan pertanyaan setelah target jika target bukan null
          questionVisibility[qId] = false;
          visibilityChanged = true;
        }
      }
    }


    Set<String> uniqueIdsToClear = Set.from(idsToHideAndClear);
    if(effectiveNextVisibleQId == null){ // Jump ke akhir form atau akhir section (yang juga akhir form)
      for(int i = currentIndexInOrder + 1; i < _allQuestionIdsInOrder.length; i++){
        uniqueIdsToClear.add(_allQuestionIdsInOrder[i]);
      }
    }

    if (uniqueIdsToClear.isNotEmpty) {
      _clearAnswersForSkippedQuestions(uniqueIdsToClear.toList());
    }
    if (visibilityChanged) {
      questionVisibility.refresh();
    }

    if (effectiveNextVisibleQId != null && questionVisibility[effectiveNextVisibleQId] == true) {
      evaluateAndExecuteJumps(effectiveNextVisibleQId, userAnswers[effectiveNextVisibleQId]);
    }
  }

  void updateUserAnswer(String questionId, dynamic value) {
    dynamic oldValue = userAnswers[questionId];
    userAnswers[questionId] = value;
    final question = findQuestionById(questionId);

    // --- AWAL TAMBAHAN: Kosongkan other answer jika pilihan standar dipilih ---
    if (question != null && question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, ''); // Kosongkan teks "Lainnya"
    }
    // --- AKHIR TAMBAHAN ---

    if (question != null && question.isRepeatableGroupController && question.controlledGroupTag != null) {
      // ... (logika repeatable group controller tetap sama)
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
    // ... (logika updateRepeatableGroupAnswer)
    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }

    // Pastikan map untuk repeatIndex sudah ada
    if (repeatableGroupAnswers[questionId]!.length <= repeatIndex) {
      for(int i = repeatableGroupAnswers[questionId]!.length; i <= repeatIndex; i++){
        final qDef = findQuestionById(questionId);
        repeatableGroupAnswers[questionId]![i] = qDef != null ? _getDefaultAnswerForQuestionType(qDef.type) : '';
      }
    }
    dynamic oldValue = repeatableGroupAnswers[questionId]![repeatIndex];
    repeatableGroupAnswers[questionId]![repeatIndex] = value;

    // --- AWAL TAMBAHAN: Kosongkan other answer repeatable jika pilihan standar dipilih ---
    final question = findQuestionById(questionId);
    if (question != null && question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(questionId, '', repeatIndex: repeatIndex); // Kosongkan teks "Lainnya"
    }
    // --- AKHIR TAMBAHAN ---

    if (question != null) evaluateAndExecuteJumps(questionId, value); // Perlu penyesuaian untuk jump dari repeatable
    repeatableGroupAnswers.refresh();
  }

  void _adjustRepeatableGroupAnswers(String groupTag, int newCount) {
    // ... (logika _adjustRepeatableGroupAnswers)
    if (loadedForm.value == null) return;
    for (var section in loadedForm.value!.sections) {
      for (var qInGroup in section.questions) {
        if (qInGroup.belongsToGroupTag == groupTag) {
          // Adjust main answers
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
          // --- AWAL TAMBAHAN: Adjust "other" answers ---
          if (qInGroup.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(qInGroup.id)) {
              repeatableGroupOtherAnswers[qInGroup.id] = RxMap<int, String>();
            }
            final otherAnswerMap = repeatableGroupOtherAnswers[qInGroup.id]!;
            otherAnswerMap.removeWhere((key, _) => key >= newCount);
            for (int i = 0; i < newCount; i++) {
              if (!otherAnswerMap.containsKey(i)) {
                otherAnswerMap[i] = ''; // Default empty string untuk other text
              }
            }
          }
          // --- AKHIR TAMBAHAN ---
        }
      }
    }
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh(); // Tambahan
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel,
      String colLabel, String subColLabel, String? value) {
    // ... (logika updateGridAnswer tetap sama)
    String? parseableValue = value?.replaceAll(',', '.');
    num? numericValue = parseableValue != null && parseableValue.isNotEmpty
        ? num.tryParse(parseableValue)
        : null;

    Map<String, Map<String, Map<String, num?>>> getGridMap(dynamic currentGridData) {
      if (currentGridData is Map<String, Map<String, Map<String, num?>>>) {
        return currentGridData; // Kembalikan langsung jika tipe sudah sesuai
      }
      if (currentGridData is Map) {
        try {
          // Lakukan konversi dari Map<dynamic, dynamic>
          return Map<String, Map<String, Map<String, num?>>>.fromEntries(
              (currentGridData as Map<dynamic, dynamic>).entries.map((rowEntry) {
                var colMap = rowEntry.value;
                // Pastikan colMap adalah Map, jika tidak, jadikan Map kosong
                if (colMap is! Map) colMap = <String, dynamic>{};

                return MapEntry(
                    rowEntry.key.toString(), // Key baris
                    Map<String, Map<String, num?>>.fromEntries(
                        (colMap as Map<dynamic, dynamic>).entries.map((colEntry) {
                          var subColMap = colEntry.value;
                          // Pastikan subColMap adalah Map, jika tidak, jadikan Map kosong
                          if (subColMap is! Map) subColMap = <String, dynamic>{};

                          return MapEntry(
                              colEntry.key.toString(), // Key kolom
                              Map<String, num?>.fromEntries(
                                  (subColMap as Map<dynamic, dynamic>).entries.map((subColEntry) {
                                    // Konversi nilai sel ke num?
                                    num? cellValue;
                                    if (subColEntry.value == null) {
                                      cellValue = null;
                                    } else if (subColEntry.value is num) {
                                      cellValue = subColEntry.value as num;
                                    } else {
                                      cellValue = num.tryParse(subColEntry.value.toString());
                                    }
                                    return MapEntry(
                                        subColEntry.key.toString(), // Key sub-kolom
                                        cellValue
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
          return <String, Map<String, Map<String, num?>>>{}; // Kembalikan map kosong jika error
        }
      }
      // Jika currentGridData bukan Map, kembalikan map kosong
      return <String, Map<String, Map<String, num?>>>{};
    }

    if (repeatIndex != null) {
      if (!repeatableGroupAnswers.containsKey(questionId)) {
        repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(repeatableGroupAnswers[questionId]![repeatIndex]);
      gridAnswers
          .putIfAbsent(rowLabel, () => {})
          .putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
      getGridMap(userAnswers[questionId]);
      gridAnswers
          .putIfAbsent(rowLabel, () => {})
          .putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
  }

  bool _performLocalValidation(FormQuestion question, dynamic answer, String questionDisplayName) {
    // ... (logika _performLocalValidation)
    if (questionVisibility[question.id] != true) return true;

    bool isEmpty = _isAnswerEmpty(answer, question.type);

    // --- AWAL MODIFIKASI: Validasi untuk "Lainnya" yang wajib ---
    if (question.isRequired && question.hasOtherOption && answer == _kOtherOptionValue) {
      String? otherText;
      // Cek apakah ini pertanyaan repeatable atau bukan untuk mendapatkan otherText
      bool isRepeatableContext = question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty;
      if (isRepeatableContext) {
        // Perlu repeatIndex untuk mendapatkan otherText, ini tidak tersedia langsung di sini.
        // Validasi spesifik "Lainnya" yang wajib untuk repeatable akan lebih baik ditangani di UI
        // atau memerlukan passing repeatIndex ke _performLocalValidation.
        // Untuk saat ini, jika "Lainnya" dipilih, anggap tidak kosong untuk validasi isRequired umum.
        // Validasi teks "Lainnya" itu sendiri akan ditangani oleh validator TextFormField di UI.
        isEmpty = false; // Anggap tidak kosong jika _kOtherOptionValue dipilih
      } else {
        otherText = userOtherAnswers[question.id];
      }
      if (otherText == null || otherText.trim().isEmpty) {
        Get.snackbar('Validasi Gagal',
            'Isian "Lainnya" untuk "$questionDisplayName" wajib diisi.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
        return false;
      }
      isEmpty = false; // Jika otherText ada, maka tidak kosong
    }
    // --- AKHIR MODIFIKASI ---


    if (question.isRequired && isEmpty) {
      Get.snackbar('Validasi Gagal',
          'Pertanyaan "$questionDisplayName" wajib diisi.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds: 3));
      return false;
    }
    // ... (sisa validasi standar tetap sama)
    final ValidationRule? rule = question.validation;
    if (rule == null) return true;

    if (answer is String && answer.isNotEmpty) {
      String effectiveValueString = answer.trim();
      if (rule.minLength != null &&
          effectiveValueString.length < rule.minLength!) {
        Get.snackbar('Validasi Gagal',
            'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.maxLength != null &&
          effectiveValueString.length > rule.maxLength!) {
        Get.snackbar('Validasi Gagal',
            'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.regex != null &&
          rule.regex!.isNotEmpty &&
          !RegExp(rule.regex!).hasMatch(effectiveValueString)) {
        Get.snackbar(
            'Validasi Gagal', 'Format "$questionDisplayName" tidak sesuai.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.predefinedRule == 'nik' &&
          !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
        Get.snackbar(
            'Validasi Gagal', 'NIK harus 16 digit angka.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.predefinedRule == 'email' &&
          !GetUtils.isEmail(effectiveValueString)) {
        Get.snackbar(
            'Validasi Gagal', 'Format email tidak valid.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.predefinedRule == 'numbersOnly' &&
          !GetUtils.isNumericOnly(
              effectiveValueString.replaceAll(',', '').replaceAll('.', ''))) {
        Get.snackbar(
            'Validasi Gagal', '"$questionDisplayName" hanya boleh angka.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
    }
    if (question.type == QuestionType.number &&
        answer != null &&
        answer.toString().isNotEmpty) {
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.'));
      if (numAnswer == null) {
        Get.snackbar(
            'Validasi Gagal', '"$questionDisplayName" harus berupa angka.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.minValue != null && numAnswer < rule.minValue!) {
        Get.snackbar(
            'Validasi Gagal', '"$questionDisplayName" minimal ${rule.minValue}.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }
      if (rule.maxValue != null && numAnswer > rule.maxValue!) {
        Get.snackbar(
            'Validasi Gagal', '"$questionDisplayName" maksimal ${rule.maxValue}.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white);
        return false;
      }

      if (question.code == "203" || question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          num? artCount =
          num.tryParse(artCountValueDynamic.toString().replaceAll(',', '.'));
          if (artCount != null && numAnswer > artCount) {
            Get.snackbar("Validasi Gagal",
                "$questionDisplayName ($numAnswer) tidak boleh > ${artQuestion.questionText} ($artCount).",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white);
            return false;
          }
        }
      }
    }
    return true;
  }

  Future<void> submitForm() async {
    // ... (validasi formKey dan custom validation tetap sama di awal)
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!formKey.currentState!.validate()) {
      Get.snackbar('Validasi Form Gagal',
          'Harap periksa kembali isian Anda pada kolom yang ditandai error.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds: 4));
      return;
    }

    bool allCustomValidationPassed = true;
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        if (questionVisibility[question.id] != true) continue;

        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          if (!_performLocalValidation(question, userAnswers[question.id], question.questionText)) {
            allCustomValidationPassed = false;
            break;
          }
        } else {
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          for (int i = 0; i < count; i++) {
            if (!_performLocalValidation(question, repeatableGroupAnswers[question.id]?[i], "[Data ke-${i + 1}] ${question.questionText}")) {
              allCustomValidationPassed = false;
              break;
            }
          }
        }
        if (!allCustomValidationPassed) break;
      }
      if (!allCustomValidationPassed) break;
    }

    if (!allCustomValidationPassed) return;


    isLoading.value = true;
    List<QuestionAnswer> answersToSubmit = [];

    loadedForm.value!.sections.forEach((section) {
      section.questions.forEach((question) {
        if (questionVisibility[question.id] == true) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            dynamic answer = userAnswers[question.id];
            String? otherText = userOtherAnswers[question.id]; // Ambil teks "Lainnya"

            // --- AWAL MODIFIKASI: Ganti _kOtherOptionValue dengan otherText ---
            if (question.hasOtherOption && answer == _kOtherOptionValue) {
              answer = otherText ?? ''; // Gunakan teks "Lainnya", atau string kosong jika null
            }
            // --- AKHIR MODIFIKASI ---

            if (!_isAnswerEmpty(answer, question.type) || (question.hasOtherOption && answer == (otherText??'')) || !question.isRequired) {
              answersToSubmit.add(QuestionAnswer(
                  questionId: question.id,
                  questionCode: question.code ?? '',
                  questionText: question.questionText,
                  answer: _prepareAnswerForFirestore(answer, question.type, question.hasOtherOption, otherText),
                  questionType: question.type.toShortString()));
            }
          } else { // Repeatable group
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) {
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              String? otherText = repeatableGroupOtherAnswers[question.id]?[i]; // Ambil teks "Lainnya" repeatable

              // --- AWAL MODIFIKASI: Ganti _kOtherOptionValue dengan otherText untuk repeatable ---
              if (question.hasOtherOption && answer == _kOtherOptionValue) {
                answer = otherText ?? '';
              }
              // --- AKHIR MODIFIKASI ---

              if (!_isAnswerEmpty(answer, question.type) || (question.hasOtherOption && answer == (otherText??'')) || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                    questionId: "${question.id}_$i",
                    questionCode: "${question.code ?? ''}_${i + 1}",
                    questionText: "[Data ke-${i + 1}] ${question.questionText}",
                    answer: _prepareAnswerForFirestore(answer, question.type, question.hasOtherOption, otherText),
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
        await _db.collection('formSubmissions').doc(submissionId.value).set(firestoreData, SetOptions(merge: true));
        Get.snackbar('Berhasil', 'Perubahan berhasil disimpan!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        await _db.collection('formSubmissions').add(firestoreData);
        Get.snackbar('Berhasil', 'Form berhasil dikirim!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error Simpan/Kirim', 'Gagal menyimpan data: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white, duration: const Duration(seconds: 5));
      throw e; // Dilempar lagi agar UI bisa menangani jika perlu (misal: Get.back() di onConfirm dialog)
    } finally {
      isLoading.value = false;
    }
  }

  bool _isAnswerEmpty(dynamic answer, QuestionType type) {
    // ... (logika _isAnswerEmpty tetap sama)
    // PERTIMBANGAN: Jika jawaban utama adalah _kOtherOptionValue,
    // apakah ini dianggap kosong jika teks "Lainnya" juga kosong?
    // Untuk saat ini, _isAnswerEmpty hanya memeriksa nilai 'answer' utama.
    // Validasi spesifik teks "Lainnya" yang wajib ditangani di _performLocalValidation atau UI validator.
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty;
    if (answer is Map) {
      if (type == QuestionType.gridNumeric) {
        return !(answer).values.any((row) =>
        (row is Map) &&
            row.values.any((col) =>
            (col is Map) &&
                col.values.any((cell) =>
                cell != null && cell.toString().trim().isNotEmpty)));
      }
      return answer.isEmpty;
    }
    return false;
  }

  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type, bool hasOtherOption, String? otherText) {
    // --- AWAL MODIFIKASI: Penanganan untuk _kOtherOptionValue dan Checkbox ---
    if (hasOtherOption) {
      if (type == QuestionType.multipleChoice && answer == _kOtherOptionValue) {
        return otherText ?? ''; // Kirim teks "Lainnya"
      }
      if (type == QuestionType.checkboxes && answer is List) {
        List<dynamic> preparedList = [];
        for (var item in answer) {
          if (item == _kOtherOptionValue) {
            if (otherText != null && otherText.isNotEmpty) {
              preparedList.add(otherText); // Ganti placeholder dengan teks
            }
          } else {
            preparedList.add(item);
          }
        }
        return preparedList;
      }
    }
    // --- AKHIR MODIFIKASI ---

    // ... (sisa logika _prepareAnswerForFirestore tetap sama)
    if (type == QuestionType.number) {
      if (answer is String) {
        return num.tryParse(answer.replaceAll(',', '.'));
      }
    }
    if (answer is Map && type == QuestionType.gridNumeric) {
      Map<String, dynamic> firestoreGrid = {};
      (answer as Map).forEach((rowKey, colMap) {
        String effectiveRowKey =
        rowKey.toString().isEmpty ? "default_row" : rowKey.toString();

        if (colMap is Map) {
          Map<String, dynamic> currentCols = {};
          (colMap).forEach((colKey, subColMap) {
            if (subColMap is Map) {
              Map<String, num?> currentSubCols = {};
              (subColMap).forEach((subColKey, cellValue) {
                if (cellValue is String) {
                  currentSubCols[subColKey.toString()] =
                      num.tryParse(cellValue.replaceAll(',', '.'));
                } else if (cellValue is num?) {
                  currentSubCols[subColKey.toString()] = cellValue;
                } else {
                  currentSubCols[subColKey.toString()] = null;
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
      try {
        return Timestamp.fromDate(
            DateFormat('dd/MM/yyyy').parseStrict(answer));
      } catch (e) {
        return answer;
      }
    }
    return answer;
  }
}