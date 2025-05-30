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

  final RxBool isLoading = false.obs;
  final RxString formId = ''.obs;
  final Rx<FormItem?> loadedForm = Rx<FormItem?>(null);
  final RxString errorMessage = ''.obs;

  final RxString submissionId = ''.obs;
  RxBool get isEditMode => RxBool(submissionId.value.isNotEmpty);
  final Rx<FormSubmission?> loadedSubmission = Rx<FormSubmission?>(null);

  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  final RxMap<String, RxMap<int, dynamic>> repeatableGroupAnswers = <String, RxMap<int, dynamic>>{}.obs;
  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<String> _allQuestionIdsInOrder = [];

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
        print("Info (onInit): Argumen diterima sebagai String (hanya formId): $extractedFormId");
      } else if (arguments is Map) {
        print("Info (onInit): Argumen diterima sebagai Map: $arguments");
        if (arguments.containsKey('formId') && arguments['formId'] is String && (arguments['formId'] as String).isNotEmpty) {
          extractedFormId = arguments['formId'] as String;
        } else {
          errorMessage.value = "Argumen Map tidak berisi 'formId' String yang valid dan tidak kosong. Isi Map: $arguments";
          isLoading.value = false;
          return;
        }
        if (arguments.containsKey('submissionId') && arguments['submissionId'] is String && (arguments['submissionId'] as String).isNotEmpty) {
          extractedSubmissionId = arguments['submissionId'] as String;
          submissionId.value = extractedSubmissionId; // Simpan submissionId jika ada
          print("Info (onInit): Mode Edit diaktifkan. SubmissionId: ${submissionId.value}");
        }
      } else {
        errorMessage.value = "Tipe argumen ID Form tidak valid (diterima: ${arguments.runtimeType}).";
        isLoading.value = false;
        return;
      }

      if (extractedFormId != null && extractedFormId.isNotEmpty) {
        formId.value = extractedFormId;
        fetchFormAndPotentialSubmissionData();
      } else {
        errorMessage.value = "ID Form kosong atau null setelah ekstraksi dari argumen.";
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

    if (formId.value.isEmpty) {
      errorMessage.value = "ID Form kosong, tidak dapat melanjutkan.";
      isLoading.value = false;
      Get.snackbar('Error Kritis', errorMessage.value, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    try {
      print("Mengambil struktur form untuk ID: ${formId.value}");
      final formDocSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (formDocSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(formDocSnapshot);
        if (loadedForm.value != null) {
          _allQuestionIdsInOrder.clear();
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
            }
          }
          print("Struktur form berhasil dimuat. Jumlah pertanyaan terurut: ${_allQuestionIdsInOrder.length}");
        } else {
          errorMessage.value = "Gagal memproses struktur form dari Firestore.";
          isLoading.value = false; return;
        }
      } else {
        errorMessage.value = "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        isLoading.value = false; return;
      }

      if (isEditMode.value) { // Periksa isEditMode.value
        print("Mode Edit: Mencoba mengambil data submission ID: ${submissionId.value}");
        final submissionDocSnapshot = await _db.collection('formSubmissions').doc(submissionId.value).get();
        if (submissionDocSnapshot.exists) {
          loadedSubmission.value = FormSubmission.fromFirestore(submissionDocSnapshot as DocumentSnapshot<Map<String, dynamic>>);
          if (loadedSubmission.value == null) {
            errorMessage.value = "Gagal memproses data submission yang ada (ID: ${submissionId.value}). Menampilkan form kosong.";
            Get.snackbar("Peringatan", errorMessage.value, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
          } else {
            print("Mode Edit: Data submission berhasil dimuat dengan ${loadedSubmission.value!.answers.length} jawaban.");
          }
        } else {
          errorMessage.value = "Data submission dengan ID '${submissionId.value}' tidak ditemukan. Menampilkan form sebagai isian baru.";
          submissionId.value = ''; // Keluar dari mode edit jika data submission tidak ditemukan
          Get.snackbar("Info", errorMessage.value, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
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
      case QuestionType.checkboxes: return <String>[];
      case QuestionType.gridNumeric: return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown: return null;
      default: return ''; // text, paragraph, number, date (date akan dihandle khusus saat display/save)
    }
  }

  void _initializeStatesBasedOnMode() {
    if (loadedForm.value == null) {
      print("_initializeStatesBasedOnMode: loadedForm null, tidak bisa lanjut.");
      return;
    }

    userAnswers.clear();
    repeatableGroupAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupAnswers.clear();
    repeatableGroupCounts.clear();
    questionVisibility.clear();

    if (isEditMode.value && loadedSubmission.value != null) {
      print("Mode Edit: Memulai _populateAnswersFromSubmission.");
      _populateAnswersFromSubmission();
    } else {
      if (isEditMode.value && loadedSubmission.value == null) {
        print("Mode Edit: Data submission tidak termuat, inisialisasi sebagai form baru.");
      } else {
        print("Mode Baru: Inisialisasi form kosong.");
      }
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
        }
      }
      repeatableGroupCounts.forEach((groupTag, count) {
        _adjustRepeatableGroupAnswers(groupTag, count);
      });
    }
    _initializeAndEvaluateInitialVisibility();
  }

  Future<void> fetchFormStructure() async {
    // AWAL PERUBAHAN: Tambahkan guard/pemeriksaan di sini
    if (formId.value.isEmpty) {
      errorMessage.value = "ID Form kosong atau tidak valid. Tidak dapat memuat form.";
      isLoading.value = false;
      loadedForm.value = null; // Pastikan juga loadedForm di-reset
      print("Error dalam fetchFormStructure: formId.value kosong.");
      // Anda bisa menampilkan Snackbar di sini jika diinginkan,
      // atau biarkan UI menampilkan errorMessage.value
      Get.snackbar('Error Kritis', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return; // Hentikan eksekusi lebih lanjut
    }
    // AKHIR PERUBAHAN

    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null; // Reset before fetching
    _allQuestionIdsInOrder.clear();
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        if (loadedForm.value != null) {
          // Populate the ordered list of question IDs
          _allQuestionIdsInOrder.clear(); // Pastikan bersih sebelum diisi ulang
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
            }
          }
        }
      } else {
        errorMessage.value = "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        loadedForm.value = null; // Pastikan reset jika tidak ditemukan
      }
    } catch (e, s) {
      print("Error fetching form structure for ID '${formId.value}': $e\n$s");
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      loadedForm.value = null; // Pastikan reset jika ada error
      Get.snackbar('Error Memuat', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // File: input_user_controller.dart

  void _populateAnswersFromSubmission() {
    if (loadedSubmission.value == null || loadedForm.value == null) {
      print("Populate: loadedSubmission atau loadedForm null, tidak bisa lanjut.");
      return;
    }
    print("Populate: Memulai memuat jawaban dari submission ID: ${loadedSubmission.value!.id}");
    print("Populate: Jawaban mentah dari submission: ${loadedSubmission.value!.answers.map((e) => '${e.questionCode}(${e.questionId}): ${e.answer}').toList()}");


    Map<String, int> tempGroupCounts = {};

    // 1. Isi userAnswers untuk pertanyaan non-repeatable-member dan hitung group counts dari controller
    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      bool isRepeatableMemberInstance = false;

      if (savedAnswer.questionId.contains('_')) {
        final parts = savedAnswer.questionId.split('_');
        if (parts.length > 1 && int.tryParse(parts.last) != null) {
          originalQuestionId = parts.sublist(0, parts.length - 1).join('_');
          isRepeatableMemberInstance = true;
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null) {
        print("Warning (populate): Definisi pertanyaan untuk ID '${originalQuestionId}' (dari '${savedAnswer.questionId}') tidak ditemukan. Dilewati.");
        continue;
      }

      dynamic answerValue = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
      // PENAMBAHAN LOG DI SINI
      print("Populate Detail: QID: ${questionDef.id}, QCode: ${questionDef.code ?? 'N/A'}, RawAnswer: ${savedAnswer.answer}, MappedAnswer: $answerValue, Type: ${questionDef.type}");


      if (!isRepeatableMemberInstance) { // Ini adalah jawaban untuk pertanyaan reguler atau group controller
        userAnswers[originalQuestionId] = answerValue;
        // print("Populate: UserAnswer untuk ${questionDef.code ?? originalQuestionId} = $answerValue"); // Sudah ada log di atas yang lebih detail

        if (questionDef.isRepeatableGroupController && questionDef.controlledGroupTag != null) {
          int count = 0;
          if (answerValue is String) count = int.tryParse(answerValue) ?? 0;
          else if (answerValue is num) count = answerValue.toInt();
          tempGroupCounts[questionDef.controlledGroupTag!] = count;
          // print("Populate: Group controller ${questionDef.code} count: $count for tag ${questionDef.controlledGroupTag}"); // Sudah ter-cover
        }
      }
    }

    tempGroupCounts.forEach((tag, count) {
      repeatableGroupCounts[tag] = count;
    });

    // 2. Inisialisasi struktur repeatableGroupAnswers berdasarkan counts
    repeatableGroupCounts.forEach((groupTag, count) {
      _adjustRepeatableGroupAnswers(groupTag, count);
    });

    // 3. Isi repeatableGroupAnswers dengan jawaban yang sesuai
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
      if (questionDef == null) continue;

      if (questionDef.belongsToGroupTag != null && questionDef.belongsToGroupTag!.isNotEmpty && repeatIndex != null) {
        if (repeatableGroupAnswers.containsKey(originalQuestionId) &&
            (repeatableGroupAnswers[originalQuestionId]?.length ?? 0) > repeatIndex) {
          dynamic answerValue = _mapAnswerToCorrectType(savedAnswer.answer, questionDef.type);
          repeatableGroupAnswers[originalQuestionId]![repeatIndex] = answerValue;
          // print("Populate: Repeatable ${questionDef.code ?? originalQuestionId}[$repeatIndex] = $answerValue"); // Sudah ter-cover
        } else {
          // print("Warning (populate): Slot jawaban untuk repeatable Q ${questionDef.code ?? originalQuestionId}[$repeatIndex] tidak ada atau di luar batas. Count: ${repeatableGroupCounts[questionDef.belongsToGroupTag!]}");
        }
      }
    }

    // 4. Pastikan semua pertanyaan (non-repeatable member) di form memiliki entri di userAnswers
    for (var qId in _allQuestionIdsInOrder) {
      final qDef = findQuestionById(qId);
      if (qDef != null && (qDef.belongsToGroupTag == null || qDef.belongsToGroupTag!.isEmpty)) {
        if (!userAnswers.containsKey(qId)) {
          userAnswers[qId] = _getDefaultAnswerForQuestionType(qDef.type);
          // print("Populate: Defaulting missing non-repeatable Q: ${qDef.code ?? qId}");
        }
      }
    }

    userAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupCounts.refresh();
    print("Populate: Selesai memuat. userAnswers: ${Map.from(userAnswers)}");
    print("Populate: Selesai memuat. repeatableGroupCounts: ${Map.from(repeatableGroupCounts)}");
    // Anda bisa menambahkan log untuk repeatableGroupAnswers jika dirasa perlu, tapi bisa sangat besar
    // print("Populate: Selesai memuat. repeatableGroupAnswers: ${Map.from(repeatableGroupAnswers)}");
  }

  dynamic _mapAnswerToCorrectType(dynamic rawAnswer, QuestionType questionType) {
    if (rawAnswer == null) return _getDefaultAnswerForQuestionType(questionType);

    switch (questionType) {
      case QuestionType.checkboxes:
        if (rawAnswer is List) return List<String>.from(rawAnswer.map((item) => item.toString()));
        return <String>[];
      case QuestionType.number:
        if (rawAnswer is num) return rawAnswer.toString();
        if (rawAnswer is String) return rawAnswer;
        return (num.tryParse(rawAnswer.toString().replaceAll(',', '.')) ?? '').toString(); // Ganti koma jika ada
      case QuestionType.date:
        if (rawAnswer is Timestamp) return DateFormat('dd/MM/yyyy').format(rawAnswer.toDate());
        if (rawAnswer is String) { // Coba parse jika formatnya dd/MM/yyyy, jika tidak kembalikan apa adanya
          try { DateFormat('dd/MM/yyyy').parseStrict(rawAnswer); return rawAnswer; }
          catch (_) { /* Biarkan jika bukan format tsb, mungkin sudah string lain */ }
        }
        return rawAnswer.toString(); // Fallback
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
                                      if (subColEntry.value is num) valNum = subColEntry.value as num?;
                                      else if (subColEntry.value is String) valNum = num.tryParse((subColEntry.value as String).replaceAll(',', '.'));
                                      return MapEntry(subColEntry.key.toString(), valNum);
                                    }
                                    )
                                )
                            );
                          })
                      )
                  );
                })
            );
          } catch (e) {
            print("Error mapping grid answer: $e. Raw: $rawAnswer");
            return <String, Map<String, Map<String, num?>>>{};
          }
        }
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
      case QuestionType.multipleChoice:
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString(); // Bisa jadi null
      default: // text, paragraph
        return rawAnswer.toString();
    }
  }

  void _initializeAndEvaluateInitialVisibility() {
    if (_allQuestionIdsInOrder.isEmpty) {
      questionVisibility.clear();
      questionVisibility.refresh();
      print("_initializeAndEvaluateInitialVisibility: Tidak ada pertanyaan, visibilitas dikosongkan.");
      return;
    }

    for (String qId in _allQuestionIdsInOrder) {
      questionVisibility[qId] = false;
    }

    String? firstVisibleCandidateId = _allQuestionIdsInOrder.first;
    final firstQuestion = findQuestionById(firstVisibleCandidateId);

    if (firstQuestion != null) {
      print("InitialVisibility: Memproses pertanyaan pertama: ${firstQuestion.code ?? firstQuestion.id}");
      questionVisibility[firstQuestion.id] = true; // Selalu buat pertanyaan pertama visible dulu
      // Kemudian evaluasi jump dari pertanyaan pertama ini
      evaluateAndExecuteJumps(firstQuestion.id, userAnswers[firstQuestion.id]);
    } else {
      print("InitialVisibility: Pertanyaan pertama tidak ditemukan dalam _allQuestionIdsInOrder.");
    }
    // evaluateAndExecuteJumps sudah memanggil questionVisibility.refresh() jika ada perubahan
    // Jika tidak ada jump dari pertanyaan pertama, pastikan setidaknya pertanyaan pertama tetap visible
    if (firstQuestion != null && questionVisibility[firstQuestion.id] != true &&
        !(firstQuestion.unconditionalJumpTarget != null && firstQuestion.unconditionalJumpTarget!.isNotEmpty)) {
      questionVisibility[firstQuestion.id] = true;
    }
    questionVisibility.refresh(); // Panggil sekali lagi di akhir untuk memastikan konsistensi
    print("InitialVisibility: Selesai. Visible Qs: ${questionVisibility.entries.where((e)=>e.value).map((e)=> findQuestionById(e.key)?.code ?? e.key).toList()}");
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
    final section = loadedForm.value!.sections.firstWhereOrNull((s) => s.id == sectionId);
    return section?.questions.isNotEmpty == true ? section!.questions.first.id : null;
  }

  void _resetDependentChildrenAnswers(String parentQuestionId, {bool calledFromJumpClear = false}) {
    if (loadedForm.value == null) return;
    bool changed = false;
    for (var qId in _allQuestionIdsInOrder) { // Iterasi semua pertanyaan untuk menemukan anak
      final qChild = findQuestionById(qId);
      if (qChild == null) continue;

      if (qChild.dependentOptions?.parentQuestionId == parentQuestionId) {
        dynamic defaultValue = _getDefaultAnswerForQuestionType(qChild.type);
        if (userAnswers.containsKey(qChild.id) && userAnswers[qChild.id] != defaultValue && (questionVisibility[qChild.id] == true || calledFromJumpClear)) {
          print("Resetting dependent child ${qChild.code ?? qChild.id} of parent ${findQuestionById(parentQuestionId)?.code ?? parentQuestionId}");
          userAnswers[qChild.id] = defaultValue;
          changed = true;
          _resetDependentChildrenAnswers(qChild.id, calledFromJumpClear: calledFromJumpClear); // Rekursif
        }
        if (repeatableGroupAnswers.containsKey(qChild.id) && (questionVisibility[qChild.id] == true || calledFromJumpClear)) {
          if (!(findQuestionById(parentQuestionId)?.isRepeatableGroupController ?? false)) {
            final groupTag = qChild.belongsToGroupTag;
            if (groupTag != null) {
              final count = repeatableGroupCounts[groupTag] ?? 0;
              for (int i = 0; i < count; i++) {
                if (repeatableGroupAnswers[qChild.id]![i] != defaultValue) {
                  repeatableGroupAnswers[qChild.id]![i] = defaultValue;
                  changed = true;
                }
              }
              print("Resetting repeatable dependent child instances for ${qChild.code ?? qChild.id}");
            }
          }
        }
      }
    }
    if (changed) {
      userAnswers.refresh();
      repeatableGroupAnswers.refresh();
    }
  }

  void _clearAnswersForSkippedQuestions(List<String> skippedQuestionIds) {
    if (skippedQuestionIds.isEmpty) return;
    print("Clearing answers for skipped questions: ${skippedQuestionIds.map((id)=>findQuestionById(id)?.code ?? id).toList()}");
    bool changed = false;
    for (String qId in skippedQuestionIds) {
      final question = findQuestionById(qId);
      if (question == null) continue;

      dynamic defaultValue = _getDefaultAnswerForQuestionType(question.type);

      if (userAnswers.containsKey(qId) && userAnswers[qId] != defaultValue) {
        print("DEBUG CLEAR: Clearing regular Q: ${question.code ?? qId}. Old: ${userAnswers[qId]} -> New: $defaultValue");
        userAnswers[qId] = defaultValue;
        changed = true;
      }

      if (userAnswers.containsKey(qId) && userAnswers[qId] != defaultValue) {
        userAnswers[qId] = defaultValue;
        print("Cleared/Reset answer for regular Q: ${question.code ?? qId}");
        changed = true;
      }
      if (repeatableGroupAnswers.containsKey(qId)) {
        final groupTag = question.belongsToGroupTag;
        if (groupTag != null) {
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final answerMap = repeatableGroupAnswers[qId]!;
          for(int i = 0; i < count; i++){
            if(answerMap.containsKey(i) && answerMap[i] != defaultValue){
              print("DEBUG CLEAR: Clearing repeatable Q: ${question.code ?? qId}[$i]. Old: ${answerMap[i]} -> New: $defaultValue");
              answerMap[i] = defaultValue;
              changed = true;
            }
          }
        }
      }
      if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
        final groupTag = question.controlledGroupTag!;
        if ((repeatableGroupCounts[groupTag] ?? 0) > 0) {
          repeatableGroupCounts[groupTag] = 0;
          _adjustRepeatableGroupAnswers(groupTag, 0); // Ini akan membersihkan jawaban anggota
          print("Reset count and members for group: $groupTag (controller: ${question.code ?? qId})");
          changed = true;
        }
      }
      _resetDependentChildrenAnswers(qId, calledFromJumpClear: true);
    }
    if (changed) {
      userAnswers.refresh();
      repeatableGroupAnswers.refresh();
      repeatableGroupCounts.refresh();
    }
  }

  void evaluateAndExecuteJumps(String currentQuestionId, dynamic answerValue) {
    final question = findQuestionById(currentQuestionId);
    if (question == null || loadedForm.value == null || (questionVisibility[currentQuestionId] != true && !isLoading.value) ) { // Jangan evaluasi jika tidak visible & tidak sedang loading awal
      if(question != null) print("Skipping jump eval for Q: ${question.code ?? currentQuestionId} (Visible: ${questionVisibility[currentQuestionId]}, Loading: ${isLoading.value})");
      return;
    }
    print("Evaluating jumps for Q: ${question.code ?? currentQuestionId} with answer: '$answerValue' (Visible: ${questionVisibility[currentQuestionId]})");

    String? jumpToTargetCompositeValue;

    if (question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty) {
      jumpToTargetCompositeValue = question.unconditionalJumpTarget;
      print("Unconditional jump triggered from Q: ${question.code ?? currentQuestionId} to $jumpToTargetCompositeValue");
    } else if (question.conditionalJumps.isNotEmpty) {
      String currentAnswerString = answerValue?.toString() ?? "";
      for (var jumpRule in question.conditionalJumps) {
        if (jumpRule.conditionValue == currentAnswerString) {
          if (jumpRule.jumpToQuestionId == 'END_OF_FORM') jumpToTargetCompositeValue = 'end_of_form';
          else if (jumpRule.jumpToQuestionId == 'END_OF_SECTION') {
            jumpToTargetCompositeValue = (jumpRule.jumpToSectionId != null && jumpRule.jumpToSectionId!.isNotEmpty)
                ? 'section_start_${jumpRule.jumpToSectionId}'
                : 'end_of_current_section';
          } else if (jumpRule.jumpToQuestionId.isNotEmpty) {
            jumpToTargetCompositeValue = 'question_${jumpRule.jumpToQuestionId}';
          }
          if (jumpToTargetCompositeValue != null) {
            print("Conditional jump from Q: ${question.code ?? currentQuestionId} on answer '$currentAnswerString' to $jumpToTargetCompositeValue");
            break;
          }
        }
      }
    }

    if (jumpToTargetCompositeValue != null) {
      _performJump(currentQuestionId, jumpToTargetCompositeValue);
    } else {
      int currentIndex = _allQuestionIdsInOrder.indexOf(currentQuestionId);
      if (currentIndex != -1 && currentIndex + 1 < _allQuestionIdsInOrder.length) {
        String nextQuestionInSequenceId = _allQuestionIdsInOrder[currentIndex + 1];
        if (questionVisibility[nextQuestionInSequenceId] != true) {
          questionVisibility[nextQuestionInSequenceId] = true;
          print("No jump from ${question.code ?? currentQuestionId}, making next in sequence ${findQuestionById(nextQuestionInSequenceId)?.code ?? nextQuestionInSequenceId} visible.");
          questionVisibility.refresh();
          evaluateAndExecuteJumps(nextQuestionInSequenceId, userAnswers[nextQuestionInSequenceId]);
        }
      } else if (currentIndex == _allQuestionIdsInOrder.length - 1) {
        print("Last question ${question.code ?? currentQuestionId} answered, no jump, end of form flow.");
      }
    }
  }

  void _performJump(String currentQuestionId, String targetCompositeValue) {
    if (loadedForm.value == null) return;
    final currentIndexInOrder = _allQuestionIdsInOrder.indexOf(currentQuestionId);
    if (currentIndexInOrder == -1) {
      print("Error (_performJump): currentQuestionId '$currentQuestionId' not found in _allQuestionIdsInOrder.");
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
    } else if (type == 'section' && parts.length > 2 && parts[1] == 'start') {
      targetEntityId = parts.sublist(2).join('_');
      effectiveNextVisibleQId = _getFirstQuestionIdOfSection(targetEntityId);
    } else if (targetCompositeValue == 'end_of_current_section') {
      final currentSectionId = _getSectionIdForQuestion(currentQuestionId);
      if (currentSectionId != null) {
        int currentSecIdx = loadedForm.value!.sections.indexWhere((s) => s.id == currentSectionId);
        // Hide questions from current + 1 in this section
        bool afterCurrentInSec = false;
        for(var qInSection in loadedForm.value!.sections[currentSecIdx].questions){
          if(qInSection.id == currentQuestionId) {afterCurrentInSec = true; continue;}
          if(afterCurrentInSec) idsToHideAndClear.add(qInSection.id);
        }
        // Determine next section's first question
        if (currentSecIdx + 1 < loadedForm.value!.sections.length) {
          effectiveNextVisibleQId = _getFirstQuestionIdOfSection(loadedForm.value!.sections[currentSecIdx + 1].id);
        } else { // No next section
          effectiveNextVisibleQId = null; // End of form
        }
      } else { effectiveNextVisibleQId = null; /* End of form if section not found */ }
    } else if (targetCompositeValue == 'end_of_form') {
      effectiveNextVisibleQId = null; // End of form
    }

    // Determine all questions to hide: from current+1 up to (but not including) the target, or to end if no target
    int targetIndex = _allQuestionIdsInOrder.length; // Default to end of form
    if (effectiveNextVisibleQId != null) {
      targetIndex = _allQuestionIdsInOrder.indexOf(effectiveNextVisibleQId);
      if (targetIndex == -1) { // Target not found in ordered list (e.g. deleted question)
        print("Warning (_performJump): Target question '$effectiveNextVisibleQId' not in _allQuestionIdsInOrder. Treating as end of form.");
        effectiveNextVisibleQId = null; // Treat as end of form
        targetIndex = _allQuestionIdsInOrder.length;
      }
    }

    // Add questions between current and target (or end) to hide list
    for (int i = currentIndexInOrder + 1; i < targetIndex; i++) {
      if (!_allQuestionIdsInOrder[i].contains(effectiveNextVisibleQId ?? '###NEVER_MATCH_THIS###')) { // Don't hide the target itself
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }
    // If jumping backward, also hide questions from target+1 up to current-1
    if (effectiveNextVisibleQId != null && targetIndex < currentIndexInOrder) {
      for (int i = targetIndex + 1; i < currentIndexInOrder; i++) {
        idsToHideAndClear.add(_allQuestionIdsInOrder[i]);
      }
    }


    bool visibilityChanged = false;
    for (String qId in _allQuestionIdsInOrder) { // Iterate all to ensure correct state
      if (qId == effectiveNextVisibleQId) {
        if (questionVisibility[qId] != true) {
          questionVisibility[qId] = true;
          visibilityChanged = true;
        }
      } else if (qId != currentQuestionId && questionVisibility[qId] != false) { // Don't hide current question yet
        // Only hide if it's not the target AND it was previously visible
        if(idsToHideAndClear.contains(qId) || (effectiveNextVisibleQId == null && _allQuestionIdsInOrder.indexOf(qId) > currentIndexInOrder) ){
          questionVisibility[qId] = false;
          visibilityChanged = true;
        } else if (effectiveNextVisibleQId != null && _allQuestionIdsInOrder.indexOf(qId) > targetIndex) {
          // Hide questions AFTER the target if we jumped to a specific target
          questionVisibility[qId] = false;
          visibilityChanged = true;
        }
      }
    }

    // Collect unique IDs to clear answers for
    Set<String> uniqueIdsToClear = Set.from(idsToHideAndClear);
    // If jumping to end of form, all questions after current are candidates for clearing
    if (effectiveNextVisibleQId == null) {
      for (int i = currentIndexInOrder + 1; i < _allQuestionIdsInOrder.length; i++) {
        uniqueIdsToClear.add(_allQuestionIdsInOrder[i]);
      }
    }


    if (uniqueIdsToClear.isNotEmpty) {
      _clearAnswersForSkippedQuestions(uniqueIdsToClear.toList());
    }
    if (visibilityChanged) {
      questionVisibility.refresh();
    }

    print("---"); // Garis pemisah untuk keterbacaan
    print("DEBUG VISIBILITY FINAL: Visible Questions after jump from ${findQuestionById(currentQuestionId)?.code ?? currentQuestionId}:");
    questionVisibility.entries.where((e) => e.value).forEach((entry) {
      print("  - ${findQuestionById(entry.key)?.code ?? entry.key} (ID: ${entry.key})");
    });
    print("---");

    print("_performJump from ${findQuestionById(currentQuestionId)?.code} to target: ${findQuestionById(effectiveNextVisibleQId ?? '')?.code ?? targetCompositeValue}. Cleared answers for: ${uniqueIdsToClear.map((id) => findQuestionById(id)?.code ?? id).toList()}");

    if (effectiveNextVisibleQId != null && questionVisibility[effectiveNextVisibleQId] == true) {
      evaluateAndExecuteJumps(effectiveNextVisibleQId, userAnswers[effectiveNextVisibleQId]);
    }
  }

  void updateUserAnswer(String questionId, dynamic value) {
    dynamic oldValue = userAnswers[questionId];
    userAnswers[questionId] = value;
    final question = findQuestionById(questionId);
    print("updateUserAnswer for Q: ${question?.code ?? questionId}, NewValue: '$value', OldValue: '$oldValue'");

    if (question != null && question.isRepeatableGroupController && question.controlledGroupTag != null) {
      int count = 0;
      if (value is String) count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; // Pastikan hanya angka
      else if (value is num) count = value.toInt();

      final ValidationRule? qValidation = question.validation;
      if (qValidation != null) {
        if (qValidation.minValue != null && count < qValidation.minValue!) count = qValidation.minValue!.toInt();
        if (qValidation.maxValue != null && count > qValidation.maxValue!) count = qValidation.maxValue!.toInt();
      }
      // Validasi silang (contoh)
      if (question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          num? artCount = (artCountValueDynamic is num) ? artCountValueDynamic : num.tryParse(artCountValueDynamic.toString().replaceAll(RegExp(r'[^0-9.]'), '').replaceAll(',', '.'));
          if (artCount != null && count > artCount) {
            count = artCount.toInt();
            Get.snackbar("Info Validasi", "Jumlah pekerja tidak boleh melebihi ${artQuestion.questionText} ($artCount). Dibatasi menjadi $count.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
          }
        }
      }
      if ((repeatableGroupCounts[question.controlledGroupTag!] ?? 0) != count) {
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
      }
      userAnswers[questionId] = count.toString(); // Simpan sebagai string
    }

    if (oldValue != value) {
      bool isParent = loadedForm.value?.sections.any((s) => s.questions.any((qChild) => qChild.dependentOptions?.parentQuestionId == questionId)) ?? false;
      if (isParent) _resetDependentChildrenAnswers(questionId);
    }
    if (question != null) evaluateAndExecuteJumps(questionId, value);
    userAnswers.refresh();
  }

  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    if (!repeatableGroupAnswers.containsKey(questionId)) repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();

    // Pastikan slot untuk repeatIndex ada
    if(repeatableGroupAnswers[questionId]!.length <= repeatIndex){
      // Tambah slot jika belum ada (seharusnya sudah dihandle _adjustRepeatableGroupAnswers)
      for(int i = repeatableGroupAnswers[questionId]!.length; i <= repeatIndex; i++){
        final qDef = findQuestionById(questionId);
        repeatableGroupAnswers[questionId]![i] = qDef != null ? _getDefaultAnswerForQuestionType(qDef.type) : '';
      }
    }

    repeatableGroupAnswers[questionId]![repeatIndex] = value;
    final question = findQuestionById(questionId);
    print("updateRepeatableGroupAnswer for Q: ${question?.code ?? questionId}[$repeatIndex], NewValue: '$value'");
    if (question != null) evaluateAndExecuteJumps(questionId, value);
    repeatableGroupAnswers.refresh();
  }

  void _adjustRepeatableGroupAnswers(String groupTag, int newCount) {
    if (loadedForm.value == null) return;
    print("Adjusting repeatable group '$groupTag' to $newCount items.");
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
        }
      }
    }
    repeatableGroupAnswers.refresh();
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel, String colLabel, String subColLabel, String? value) {
    String? parseableValue = value?.replaceAll(',', '.');
    num? numericValue = parseableValue != null && parseableValue.isNotEmpty ? num.tryParse(parseableValue) : null;
    final question = findQuestionById(questionId);
    String qCodeForPrint = question?.code ?? questionId;

    Map<String, Map<String, Map<String, num?>>> getGridMap(dynamic currentGridData) {
      if (currentGridData is Map<String, Map<String, Map<String, num?>>>) return currentGridData;
      if (currentGridData is Map) { // Coba konversi jika Map generik
        try {
          return Map<String, Map<String, Map<String, num?>>>.fromEntries(
              (currentGridData).entries.map((rowEntry) {
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
                                  (subColMap as Map).entries.map((subColEntry) =>
                                      MapEntry(subColEntry.key.toString(), subColEntry.value as num?))
                              ));
                        }))
                );
              }));
        } catch (e) { return <String, Map<String, Map<String, num?>>>{}; }
      }
      return <String, Map<String, Map<String, num?>>>{};
    }

    if (repeatIndex != null) {
      if (!repeatableGroupAnswers.containsKey(questionId)) repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      Map<String, Map<String, Map<String, num?>>> gridAnswers = getGridMap(repeatableGroupAnswers[questionId]![repeatIndex]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      Map<String, Map<String, Map<String, num?>>> gridAnswers = getGridMap(userAnswers[questionId]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
    // Tidak memanggil evaluateAndExecuteJumps dari sini untuk grid per sel
  }

  bool _performLocalValidation(FormQuestion question, dynamic answer, String questionDisplayName) {
    if (questionVisibility[question.id] != true) return true;

    if (question.isRequired) {
      bool isEmpty = _isAnswerEmpty(answer, question.type);
      if (isEmpty) {
        Get.snackbar('Validasi Gagal', 'Pertanyaan "$questionDisplayName" wajib diisi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3));
        return false;
      }
    }
    final ValidationRule? rule = question.validation;
    if (rule == null) return true;

    if (answer is String && answer.isNotEmpty) {
      String effectiveValueString = answer.trim();
      if (rule.minLength != null && effectiveValueString.length < rule.minLength!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.maxLength != null && effectiveValueString.length > rule.maxLength!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.regex != null && rule.regex!.isNotEmpty && !RegExp(rule.regex!).hasMatch(effectiveValueString)) { Get.snackbar('Validasi Gagal', 'Format "$questionDisplayName" tidak sesuai.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.predefinedRule == 'nik' && !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) { Get.snackbar('Validasi Gagal', 'NIK harus 16 digit angka.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.predefinedRule == 'email' && !GetUtils.isEmail(effectiveValueString)) { Get.snackbar('Validasi Gagal', 'Format email tidak valid.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.predefinedRule == 'numbersOnly' && !GetUtils.isNumericOnly(effectiveValueString.replaceAll(',', '').replaceAll('.', ''))) { Get.snackbar('Validasi Gagal', '"$questionDisplayName" hanya boleh angka.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
    }
    if (question.type == QuestionType.number && answer != null && answer.toString().isNotEmpty) {
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.'));
      if (numAnswer == null) { Get.snackbar('Validasi Gagal', '"$questionDisplayName" harus berupa angka.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.minValue != null && numAnswer < rule.minValue!) { Get.snackbar('Validasi Gagal', '"$questionDisplayName" minimal ${rule.minValue}.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}
      if (rule.maxValue != null && numAnswer > rule.maxValue!) { Get.snackbar('Validasi Gagal', '"$questionDisplayName" maksimal ${rule.maxValue}.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white); return false;}

      if (question.code == "203" || question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          num? artCount = num.tryParse(artCountValueDynamic.toString().replaceAll(',', '.'));
          if (artCount != null && numAnswer > artCount) {
            Get.snackbar("Validasi Gagal", "$questionDisplayName ($numAnswer) tidak boleh > ${artQuestion.questionText} ($artCount).", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
            return false;
          }
        }
      }
    }
    return true;
  }

  // File: input_user_controller.dart (sebagian metode submitForm)

  Future<void> submitForm() async {
    print("SubmitForm: Memulai proses submit."); // DEBUG
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.', snackPosition: SnackPosition.BOTTOM);
      print("SubmitForm: Error - Form atau pengguna tidak valid."); // DEBUG
      return; // Sebaiknya throw error agar bisa ditangani pemanggil jika ini adalah kondisi gagal
      // throw Exception('Form atau pengguna tidak valid.');
    }

    print("SubmitForm: Memvalidasi formKey..."); // DEBUG
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Validasi Form Gagal', 'Harap periksa kembali isian Anda pada kolom yang ditandai error.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds: 4));
      print("SubmitForm: Validasi formKey GAGAL."); // DEBUG
      return; // Sebaiknya throw error
      // throw Exception('Validasi Form Gagal.');
    }
    print("SubmitForm: Validasi formKey BERHASIL."); // DEBUG

    bool allCustomValidationPassed = true;
    print("SubmitForm: Memulai validasi kustom..."); // DEBUG
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        if (questionVisibility[question.id] != true) continue;

        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          if (!_performLocalValidation(question, userAnswers[question.id], question.questionText)) {
            allCustomValidationPassed = false;
            print("SubmitForm: Validasi kustom GAGAL untuk pertanyaan (non-group): ${question.code ?? question.id} - ${question.questionText}"); // DEBUG
            break;
          }
        } else {
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          for (int i = 0; i < count; i++) {
            if (!_performLocalValidation(question, repeatableGroupAnswers[question.id]?[i], "[Data ke-${i+1}] ${question.questionText}")) {
              allCustomValidationPassed = false;
              print("SubmitForm: Validasi kustom GAGAL untuk pertanyaan (group): ${question.code ?? question.id}[$i] - ${question.questionText}"); // DEBUG
              break;
            }
          }
        }
        if (!allCustomValidationPassed) break;
      }
      if (!allCustomValidationPassed) break;
    }

    if (!allCustomValidationPassed) {
      print("SubmitForm: Validasi kustom secara keseluruhan GAGAL. Proses dihentikan."); // DEBUG
      // Snackbar untuk validasi kustom sudah ada di _performLocalValidation.
      return; // Sebaiknya throw error agar pemanggil tahu proses gagal.
      // throw Exception('Validasi kustom gagal.');
    }
    print("SubmitForm: Validasi kustom BERHASIL."); // DEBUG

    isLoading.value = true;
    print("SubmitForm: isLoading di-set ke true. Mempersiapkan data..."); // DEBUG
    List<QuestionAnswer> answersToSubmit = [];

    loadedForm.value!.sections.forEach((section) {
      section.questions.forEach((question) {
        if (questionVisibility[question.id] == true) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            dynamic answer = userAnswers[question.id];
            if (!_isAnswerEmpty(answer, question.type) || !question.isRequired) {
              answersToSubmit.add(QuestionAnswer(
                  questionId: question.id,
                  questionCode: question.code ?? '',
                  questionText: question.questionText,
                  answer: _prepareAnswerForFirestore(answer, question.type),
                  questionType: question.type.toShortString()));
            }
          } else {
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) {
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              if (!_isAnswerEmpty(answer, question.type) || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                    questionId: "${question.id}_$i",
                    questionCode: "${question.code ?? ''}_${i + 1}",
                    questionText: "[Data ke-${i+1}] ${question.questionText}",
                    answer: _prepareAnswerForFirestore(answer, question.type),
                    questionType: question.type.toShortString()));
              }
            }
          }
        }
      });
    });
    print("SubmitForm: Data siap: ${answersToSubmit.length} jawaban akan dikirim."); // DEBUG
    // answersToSubmit.forEach((ans) => print("SubmitForm: Detail Jawaban - QCode: ${ans.questionCode}, Answer: ${ans.answer}")); // DEBUG

    final submissionData = FormSubmission(
      id: isEditMode.value ? submissionId.value : null,
      formId: loadedForm.value!.id,
      formTitle: loadedForm.value!.title,
      userId: _auth.currentUser!.uid,
      userName: _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? 'Anonim',
      submittedAt: (isEditMode.value && loadedSubmission.value?.submittedAt != null) ? loadedSubmission.value!.submittedAt : Timestamp.now(),
      answers: answersToSubmit,
    );

    Map<String, dynamic> firestoreData = submissionData.toFirestore();
    if(isEditMode.value) {
      firestoreData['updatedAt'] = Timestamp.now();
      // Pertimbangkan apakah submittedAt harus di-update atau tidak saat edit.
      // Jika field 'submittedAt' hanya untuk waktu pembuatan awal, maka jangan di-remove atau di-update.
      // Jika loadedSubmission.value.submittedAt sudah benar, maka tidak perlu operasi khusus.
    }
    // print("SubmitForm: Data Firestore yang akan dikirim: $firestoreData"); // DEBUG (hati-hati jika ada data sensitif)

    try {
      print("SubmitForm: Mencoba mengirim/menyimpan ke Firestore. Mode Edit: ${isEditMode.value}"); // DEBUG
      if (isEditMode.value) {
        await _db.collection('formSubmissions').doc(submissionId.value).set(firestoreData, SetOptions(merge: true));
        print("SubmitForm: BERHASIL update (mode edit)."); // DEBUG
        Get.snackbar('Berhasil', 'Perubahan berhasil disimpan!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      } else {
        DocumentReference docRef = await _db.collection('formSubmissions').add(firestoreData);
        print("SubmitForm: BERHASIL menambah data baru dengan ID: ${docRef.id}."); // DEBUG
        Get.snackbar('Berhasil', 'Form berhasil dikirim!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      }

      // ----- NAVIGASI INTERNAL DIHAPUS DARI SINI -----
      // Blok kode yang sebelumnya memanggil Get.back() telah dihapus.
      // Navigasi sekarang sepenuhnya dikontrol oleh callback onConfirm di Input_User_Screen.dart.

      // Jika Anda masih memerlukan logika reset form setelah submit berhasil
      // (misalnya jika screen ini tidak selalu dinavigasi keluar),
      // Anda bisa menempatkan logika reset di sini, TAPI TANPA Get.back().
      // Contoh:
      // if (isEditMode.value) { // Keluar dari mode edit jika ini adalah edit
      //    submissionId.value = '';
      //    isEditMode.value = false; // Pastikan ini juga di-reset
      // }
      // _initializeStatesBasedOnMode(); // Atau metode reset yang lebih sesuai
      // formKey.currentState?.reset();


    } catch (e, s) {
      print("SubmitForm: GAGAL mengirim/menyimpan. Error: $e\nStackTrace: $s"); // DEBUG
      Get.snackbar('Error Simpan/Kirim', 'Gagal menyimpan data: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white, duration: const Duration(seconds: 5));
      // Penting: Lempar kembali error agar bisa ditangkap oleh callback onConfirm
      // dan mencegah navigasi jika terjadi kegagalan.
      throw e;
    } finally {
      print("SubmitForm: Blok finally dieksekusi. isLoading akan di-set ke false."); //DEBUG
      isLoading.value = false;
    }
  }

  bool _isAnswerEmpty(dynamic answer, QuestionType type) {
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty;
    if (answer is Map) {
      if (type == QuestionType.gridNumeric) { // Grid dianggap kosong jika semua selnya kosong
        return !(answer).values.any((row) =>
        (row is Map) && row.values.any((col) =>
        (col is Map) && col.values.any((cell) => cell != null && cell.toString().trim().isNotEmpty)
        )
        );
      }
      return answer.isEmpty; // Untuk map generik lainnya
    }
    return false; // Defaultnya tidak kosong jika bukan tipe di atas dan tidak null
  }

  // In input_user_controller.dart
  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type) {
    if (type == QuestionType.number) {
      if (answer is String) return num.tryParse(answer.replaceAll(',', '.'));
    }
    if (answer is Map && type == QuestionType.gridNumeric) {
      Map<String, dynamic> firestoreGrid = {}; // Use dynamic for intermediate map
      (answer as Map).forEach((rowKey, colMap) {
        // IMPORTANT FIX HERE: Check if rowKey is an empty string
        // If gridRowLabels is empty, rowKey will be "", which is not allowed by Firestore as a top-level key.
        String effectiveRowKey = rowKey.toString().isEmpty ? "default_row" : rowKey.toString(); // Use a placeholder or skip if needed.
        // "default_row" is a safe choice if only one row.

        // Consider if `rowKey` is actually just `""` (empty string) because `gridRowLabels` in FormItem
        // is empty for this question (Q303 in your case). Firestore does not allow empty string keys.
        if (rowKey.toString().isEmpty) {
          // If the row label is empty, and it's from `gridRowLabels: []`
          // We need to decide how to store this.
          // Option 1: If there's only one row (because gridRowLabels is empty),
          //           we can flatten the structure or use a default key.
          //           From your log, Q303 is `{: {Senin: ...}}`, suggesting an empty key.
          //           Let's use a default key.
          effectiveRowKey = "GridData"; // A generic key, if the original row label was empty.
        } else {
          effectiveRowKey = rowKey.toString();
        }


        if (colMap is Map) {
          Map<String, dynamic> currentCols = {}; // Use dynamic for intermediate map
          (colMap).forEach((colKey, subColMap) {
            if (subColMap is Map) {
              Map<String, num?> currentSubCols = {};
              (subColMap).forEach((subColKey, cellValue) {
                if (cellValue is String) {
                  currentSubCols[subColKey.toString()] = num.tryParse(cellValue.replaceAll(',', '.'));
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
        return Timestamp.fromDate(DateFormat('dd/MM/yyyy').parseStrict(answer));
      } catch (e) { return answer; /* Simpan sebagai string jika format salah */ }
    }
    return answer; // Untuk tipe lain, kembalikan apa adanya
  }
}