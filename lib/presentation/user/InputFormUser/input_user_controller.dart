import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Pastikan path ini benar dan admin_form_model.dart adalah versi PATOKAN Anda
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import './input_user_model.dart'; // Untuk FormSubmission, QuestionAnswer
// import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Jika diperlukan untuk navigasi
// import 'package:intl/intl.dart'; // DateFormat tidak digunakan langsung di controller ini lagi

class InputUserController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs;
  final RxString formId = ''.obs;
  final Rx<FormItem?> loadedForm = Rx<FormItem?>(null);
  final RxString errorMessage = ''.obs;

  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  final RxMap<String, RxMap<int, dynamic>> repeatableGroupAnswers = <String, RxMap<int, dynamic>>{}.obs;
  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      formId.value = Get.arguments as String;
      if (formId.value.isNotEmpty) {
        fetchFormStructure();
      } else {
        errorMessage.value = "ID Form tidak valid.";
        isLoading.value = false;
      }
    } else {
      errorMessage.value = "Argumen ID Form tidak ditemukan.";
      isLoading.value = false;
    }
  }

  Future<void> fetchFormStructure() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final docSnapshot = await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        _initializeStates();
      } else {
        errorMessage.value = "Struktur form tidak ditemukan.";
        loadedForm.value = null;
      }
    } catch (e, s) {
      print("Error fetching form structure: $e\n$s");
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      loadedForm.value = null;
      Get.snackbar('Error Memuat', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void _initializeStates() {
    if (loadedForm.value == null) return;

    userAnswers.clear();
    final newRepeatableGroupAnswers = <String, RxMap<int, dynamic>>{};
    final newRepeatableGroupCounts = <String, int>{};
    final newQuestionVisibility = <String, bool>{};

    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        newQuestionVisibility[question.id] = true;

        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          newRepeatableGroupCounts[question.controlledGroupTag!] = 0;
        }
        if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
          newRepeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.type == QuestionType.checkboxes) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            userAnswers[question.id] = <String>[];
          }
        } else if (question.type == QuestionType.dropdown) {
          userAnswers[question.id] = null;
        } else if (question.type == QuestionType.gridNumeric) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            userAnswers[question.id] = <String, Map<String, Map<String, num?>>>{};
          }
        }
      }
    }
    repeatableGroupAnswers.value = newRepeatableGroupAnswers;
    repeatableGroupCounts.value = newRepeatableGroupCounts;
    questionVisibility.value = newQuestionVisibility;

    userAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupCounts.refresh();
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
    if (userAnswers.containsKey(questionId)) {
      return userAnswers[questionId];
    }
    return null;
  }

  void _resetDependentChildrenAnswers(String parentQuestionId) {
    if (loadedForm.value == null) return;
    bool changed = false;
    for (var section in loadedForm.value!.sections) {
      for (var q_child in section.questions) {
        if (q_child.dependentOptions?.parentQuestionId == parentQuestionId) {
          if (userAnswers[q_child.id] != null) { // Hanya reset jika sudah ada jawaban
            print("InputUserController: Mereset jawaban untuk pertanyaan anak ${q_child.id} karena induk $parentQuestionId berubah.");
            userAnswers[q_child.id] = null; // Set ke null (atau nilai default awal jika ada)
            changed = true;
          }
          // Jika pertanyaan anak ini ada di dalam repeatable group, logika resetnya lebih kompleks
          // Untuk sekarang, kita fokus pada pertanyaan anak non-repeatable
          if (repeatableGroupAnswers.containsKey(q_child.id)){
            // Jika anak ada di repeatable group, dan induknya BUKAN repeatable group controller
            // Maka semua instance anak di repeatable group harus direset.
            if(!(findQuestionById(parentQuestionId)?.isRepeatableGroupController ?? false)){
              repeatableGroupAnswers[q_child.id]?.clear(); // Reset semua instance jawaban anak ini
              print("InputUserController: Mereset semua instance jawaban untuk pertanyaan anak repeatable ${q_child.id}");
              changed = true;
            }
          }

        }
      }
    }
    if (changed) {
      userAnswers.refresh(); // Untuk memicu Obx yang mengamati userAnswers
      repeatableGroupAnswers.refresh();
    }
  }

  void updateUserAnswer(String questionId, dynamic value) {
    dynamic oldValue = userAnswers[questionId]; // Simpan nilai lama sebelum diupdate
    userAnswers[questionId] = value;
    final question = findQuestionById(questionId);

    print("InputUserController: updateUserAnswer for Q_ID $questionId, New Value: $value, Old Value: $oldValue");


    if (question != null && question.isRepeatableGroupController && question.controlledGroupTag != null) {
      int count = 0;
      if (value is String) {
        count = int.tryParse(value) ?? 0;
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

      // Contoh validasi silang hardcode (tetap ada dari sebelumnya)
      if (question.code == "204") {
        final artQuestion = findQuestionByCode("112");
        if (artQuestion != null) {
          final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
          num? artCount;
          if (artCountValueDynamic is num) { artCount = artCountValueDynamic; }
          else if (artCountValueDynamic is String) { artCount = num.tryParse(artCountValueDynamic); }

          if (artCount != null && count > artCount) {
            count = artCount.toInt();
            Get.snackbar("Info Validasi",
                "Jumlah pekerja tidak boleh melebihi ${artQuestion.questionText} ($artCount). Dibatasi menjadi $count.",
                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
          }
        }
      }

      if (repeatableGroupCounts[question.controlledGroupTag!] != count) {
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
      }
      // Simpan kembali nilai count yang mungkin sudah disesuaikan
      // dan pastikan tipenya sesuai dengan yang diharapkan TextFormField (biasanya String)
      userAnswers[questionId] = count.toString();
    }

    // Panggil _resetDependentChildrenAnswers HANYA JIKA nilai pertanyaan ini benar-benar berubah
    // DAN pertanyaan ini adalah induk dari pertanyaan lain (untuk optimasi)
    if (oldValue != value) {
      // Cek apakah pertanyaan ini adalah induk dari pertanyaan lain
      bool isParentForOtherQuestions = false;
      if (loadedForm.value != null) {
        for (var section in loadedForm.value!.sections) {
          for (var q_child in section.questions) {
            if (q_child.dependentOptions?.parentQuestionId == questionId) {
              isParentForOtherQuestions = true;
              break;
            }
          }
          if (isParentForOtherQuestions) break;
        }
      }
      if (isParentForOtherQuestions) {
        _resetDependentChildrenAnswers(questionId);
      }
    }
    // evaluateAllConditions();
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
          answerMap.removeWhere((key, value) => key >= newCount);
          for (int i = 0; i < newCount; i++) {
            if (!answerMap.containsKey(i)) {
              if (qInGroup.type == QuestionType.checkboxes) {
                answerMap[i] = <String>[];
              } else if (qInGroup.type == QuestionType.gridNumeric) {
                answerMap[i] = <String, Map<String, Map<String, num?>>>{};
              } else if (qInGroup.type == QuestionType.dropdown){
                answerMap[i] = null;
              }
            }
          }
        }
      }
    }
    repeatableGroupAnswers.refresh();
  }

  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }
    repeatableGroupAnswers[questionId]![repeatIndex] = value;
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel, String colLabel, String subColLabel, String? value) {
    num? numericValue = value != null && value.isNotEmpty ? num.tryParse(value) : null;
    if (repeatIndex != null) {
      if (!repeatableGroupAnswers.containsKey(questionId)) repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      if (repeatableGroupAnswers[questionId]![repeatIndex] == null || repeatableGroupAnswers[questionId]![repeatIndex] is! Map) {
        repeatableGroupAnswers[questionId]![repeatIndex] = <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers = Map.from(repeatableGroupAnswers[questionId]![repeatIndex]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      if (userAnswers[questionId] == null || userAnswers[questionId] is! Map) {
        userAnswers[questionId] = <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers = Map.from(userAnswers[questionId]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
  }

  // --- `_performLocalValidation` DIPINDAHKAN MENJADI METHOD KELAS ---
  bool _performLocalValidation(FormQuestion question, dynamic answer, String questionDisplayName) {
    if (question.isRequired && (answer == null || (answer is String && answer.trim().isEmpty) || (answer is List && answer.isEmpty) || (answer is Map && answer.isEmpty))) {
      Get.snackbar('Validasi Gagal', 'Pertanyaan "$questionDisplayName" wajib diisi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3));
      return false;
    }
    if (!question.isRequired && (answer == null || (answer is String && answer.trim().isEmpty) || (answer is List && answer.isEmpty) || (answer is Map && answer.isEmpty))) {
      return true;
    }

    final ValidationRule? rule = question.validation;
    if (rule == null) return true;

    if (answer is String && answer.isNotEmpty) {
      if (rule.minLength != null && answer.length < rule.minLength!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }
      if (rule.maxLength != null && answer.length > rule.maxLength!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }
      if (rule.regex != null && rule.regex!.isNotEmpty && !RegExp(rule.regex!).hasMatch(answer)) { Get.snackbar('Validasi Gagal', 'Format jawaban "$questionDisplayName" tidak sesuai pola.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }
      if (rule.predefinedRule == 'nik') {
        if (!RegExp(r'^\d{16}$').hasMatch(answer)) { Get.snackbar('Validasi Gagal', 'Format NIK untuk "$questionDisplayName" harus 16 digit angka.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }
      }
    }

    if (question.type == QuestionType.number) {
      num? numAnswer = (answer is num) ? answer : num.tryParse(answer.toString());
      if (numAnswer == null && answer != null && answer.toString().isNotEmpty) {
        Get.snackbar('Validasi Gagal', 'Format angka tidak valid untuk "$questionDisplayName".', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false;
      }
      if (numAnswer != null) {
        if (rule.minValue != null && numAnswer < rule.minValue!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" minimal ${rule.minValue}.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }
        if (rule.maxValue != null && numAnswer > rule.maxValue!) { Get.snackbar('Validasi Gagal', 'Jawaban "$questionDisplayName" maksimal ${rule.maxValue}.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds:3)); return false; }

        // --- VALIDASI ANTAR PERTANYAAN (CONTOH HARDCODE) ---
        if (question.code == "203" || question.code == "204") { // Ganti "203", "204" dengan kode aktual
          final artQuestion = findQuestionByCode("112"); // Ganti "112" dengan kode aktual Jumlah ART
          if (artQuestion != null) {
            final artCountValueDynamic = getAnswerByQuestionId(artQuestion.id);
            num? artCount;
            if (artCountValueDynamic is num) { artCount = artCountValueDynamic; }
            else if (artCountValueDynamic is String) { artCount = num.tryParse(artCountValueDynamic); }

            if (artCount != null && numAnswer > artCount) {
              Get.snackbar("Validasi Gagal", "$questionDisplayName (jawaban: $numAnswer) tidak boleh melebihi ${artQuestion.questionText} ($artCount).", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
              return false;
            } else if (artCount == null && (artCountValueDynamic != null && artCountValueDynamic.toString().isNotEmpty) ) {
              print("Warning: Nilai untuk pertanyaan referensi ${artQuestion.code} ('$artCountValueDynamic') tidak valid (bukan angka) untuk perbandingan numerik.");
            } else if (artCount == null) {
              print("Warning: Nilai untuk pertanyaan referensi ${artQuestion.code} belum diisi atau tidak ditemukan.");
            }
          } else {
            print("Warning: Pertanyaan referensi dengan kode '112' tidak ditemukan untuk validasi ${question.code}.");
          }
        }
        // --- AKHIR CONTOH HARDCODE ---
      }
    }
    return true;
  }


  Future<void> submitForm() async {
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Panggil validasi Form widget di UI terlebih dahulu
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Validasi Gagal',
          'Harap periksa kembali isian Anda pada kolom yang ditandai.', // Pesan lebih umum
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
      return;
    }

    isLoading.value = true;
    final currentUser = _auth.currentUser!;
    List<QuestionAnswer> answersToSubmit = [];
    bool allCustomValidationPassed = true;


    for (var section in loadedForm.value!.sections) {
      if (!allCustomValidationPassed) break;
      for (var question in section.questions) {
        if (!allCustomValidationPassed) break;
        if (questionVisibility[question.id] == true && (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty)) {
          dynamic answer = userAnswers[question.id];
          if (!_performLocalValidation(question, answer, question.questionText)) { // Panggil _performLocalValidation
            allCustomValidationPassed = false;
            break;
          }
          bool answerIsEmpty = (answer == null || (answer is String && answer.trim().isEmpty) || (answer is List && answer.isEmpty) || (answer is Map && answer.isEmpty));
          if(!answerIsEmpty || !question.isRequired) {
            answersToSubmit.add(QuestionAnswer(
              questionId: question.id, questionCode: question.code ?? '', questionText: question.questionText,
              answer: answer, questionType: question.type.toShortString(),
            ));
          }
        }
      }
    }

    if (allCustomValidationPassed) {
      for (var section in loadedForm.value!.sections) {
        if (!allCustomValidationPassed) break;
        for (var question in section.questions) {
          if (!allCustomValidationPassed) break;
          if (questionVisibility[question.id] == true && question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            final answersForThisQuestionGroup = repeatableGroupAnswers[question.id];

            for (int i = 0; i < count; i++) {
              if (!allCustomValidationPassed) break;
              dynamic answer = answersForThisQuestionGroup?[i];
              String qDisplayName = "[Data ke-${i + 1}] ${question.questionText}";
              if (!_performLocalValidation(question, answer, qDisplayName)) { // Panggil _performLocalValidation
                allCustomValidationPassed = false;
                break;
              }
              bool answerIsEmpty = (answer == null || (answer is String && answer.trim().isEmpty) || (answer is List && answer.isEmpty) || (answer is Map && answer.isEmpty));
              if(!answerIsEmpty || !question.isRequired) {
                answersToSubmit.add(QuestionAnswer(
                  questionId: "${question.id}_$i", questionCode: "${question.code ?? ''}_${i + 1}", questionText: qDisplayName,
                  answer: answer, questionType: question.type.toShortString(),
                ));
              }
            }
          }
        }
      }
    }

    if (!allCustomValidationPassed) {
      isLoading.value = false;
      // Snackbar error sudah ditampilkan oleh _performLocalValidation
      return;
    }

    final submission = FormSubmission(
      formId: loadedForm.value!.id,
      formTitle: loadedForm.value!.title,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? currentUser.email ?? 'Anonim',
      submittedAt: Timestamp.now(),
      answers: answersToSubmit,
    );

    try {
      await _db.collection('formSubmissions').add(submission.toFirestore());
      isLoading.value = false;
      Get.snackbar('Berhasil', 'Form berhasil dikirim!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade600, colorText: Colors.white);
      _initializeStates();
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error Pengiriman', 'Gagal mengirim form: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
    }
  }
}