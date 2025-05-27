import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import './input_user_model.dart';
// Pastikan path Routes sudah benar
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';


class InputUserController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs; // isLoading untuk memuat struktur form & proses submit
  final RxString formId = ''.obs;
  final Rx<FormItem?> loadedForm = Rx<FormItem?>(null);
  final RxString errorMessage = ''.obs;

  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  final RxMap<String, RxMap<int, dynamic>> repeatableGroupAnswers =
      <String, RxMap<int, dynamic>>{}.obs;
  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      formId.value = Get.arguments as String;
      fetchFormStructure();
    } else {
      errorMessage.value = "ID Form tidak valid.";
      isLoading.value = false;
    }
  }

  Future<void> fetchFormStructure() async {
    isLoading.value = true; // Untuk loading struktur form
    errorMessage.value = '';
    try {
      final docSnapshot =
      await _db.collection('adminForms').doc(formId.value).get();
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        _initializeStates(); // Inisialisasi state setelah form dimuat
      } else {
        errorMessage.value = "Struktur form tidak ditemukan.";
      }
    } catch (e) {
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
      Get.snackbar('Error Memuat', errorMessage.value, // Judul snackbar lebih spesifik
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
    } finally {
      isLoading.value = false; // Selesai loading struktur form
    }
  }

  void _initializeStates() {
    if (loadedForm.value == null) return;

    userAnswers.clear();

    // Hapus dan inisialisasi ulang repeatableGroupAnswers
    // agar RxMap internal juga baru dan bersih dari listener lama jika ada
    final newRepeatableGroupAnswers = <String, RxMap<int, dynamic>>{};
    final newRepeatableGroupCounts = <String, int>{};
    final newQuestionVisibility = <String, bool>{};

    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        newQuestionVisibility[question.id] = true; // Default semua terlihat

        if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
          newRepeatableGroupCounts[question.controlledGroupTag!] = 0; // Default count
        }
        if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
          newRepeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        // Inisialisasi nilai awal untuk checkbox agar tidak null saat diakses UI
        if (question.type == QuestionType.checkboxes) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            userAnswers[question.id] = <String>[];
          }
          // Untuk checkbox di repeatable group, akan dihandle di _buildQuestionInput
        }
        // Untuk dropdown, pastikan tidak ada nilai invalid yang tersisa
        if (question.type == QuestionType.dropdown) {
          userAnswers[question.id] = null; // Atau nilai default yang valid jika ada
        }
      }
    }

    repeatableGroupAnswers.value = newRepeatableGroupAnswers;
    repeatableGroupCounts.value = newRepeatableGroupCounts;
    questionVisibility.value = newQuestionVisibility;

    evaluateAllConditions(); // Evaluasi kondisi awal

    // Refresh manual untuk memastikan semua UI listener terpicu setelah clear dan re-populasi
    userAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupCounts.refresh();
    questionVisibility.refresh();

    // Jika Anda menggunakan ScrollController untuk scroll ke atas, bisa dipicu di sini.
    // update(); // Mungkin tidak perlu jika semua state utama sudah Rx
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

  void updateUserAnswer(String questionId, dynamic value) {
    userAnswers[questionId] = value;
    // print("Answer updated for $questionId: $value");

    final question = findQuestionById(questionId);
    if (question != null &&
        question.isRepeatableGroupController &&
        question.controlledGroupTag != null) {
      int count = 0;
      if (value is String) {
        count = int.tryParse(value) ?? 0;
      } else if (value is num) {
        count = value.toInt();
      }

      ValidationRule? qValidation = question.validation;
      if (qValidation?.minValue != null) {
        if (count < qValidation!.minValue!.toInt()) {
          count = qValidation.minValue!.toInt();
        }
      }
      if (qValidation?.maxValue != null) {
        if (count > qValidation!.maxValue!.toInt()) {
          count = qValidation.maxValue!.toInt();
        }
      }

      if (repeatableGroupCounts[question.controlledGroupTag!] != count) {
        repeatableGroupCounts[question.controlledGroupTag!] = count;
        //  print("Repeatable group count for ${question.controlledGroupTag} set to $count");
      }
    }
    evaluateAllConditions();
  }

  void updateRepeatableGroupAnswer(
      String questionId, int repeatIndex, dynamic value) {
    if (!repeatableGroupAnswers.containsKey(questionId)) {
      repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
    }

    final question = findQuestionById(questionId);
    if (question != null && question.type == QuestionType.checkboxes) {
      if (value is List<String>) {
        repeatableGroupAnswers[question.id]![repeatIndex] = value;
      } else {
        var currentAnswer = repeatableGroupAnswers[question.id]![repeatIndex];
        if (currentAnswer == null && value is! List<String>) {
          repeatableGroupAnswers[question.id]![repeatIndex] = <String>[];
        }
      }
    } else if (question != null) {
      repeatableGroupAnswers[question.id]![repeatIndex] = value;
    } else {
      print("Error: Question with ID $questionId not found in updateRepeatableGroupAnswer");
    }
    // print("Repeatable answer for $questionId [$repeatIndex] updated: $value");
  }

  void evaluateAllConditions() {
    if (loadedForm.value == null) return;
    bool changed = false; // Flag untuk menandai apakah ada perubahan visibilitas
    Map<String, bool> newVisibilityState = Map.from(questionVisibility); // Salin state saat ini

    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        bool shouldBeVisible = true;
        // TODO: Implementasikan logika evaluasi conditional jump yang canggih
        // Ini akan memodifikasi `shouldBeVisible` berdasarkan `userAnswers` dan `question.conditionalJumps`
        // Contoh sangat sederhana (tidak lengkap):
        // for (var otherSection in loadedForm.value!.sections) {
        //   for (var sourceQuestion in otherSection.questions) {
        //     for (var jump in sourceQuestion.conditionalJumps) {
        //       if (jump.jumpToQuestionId == question.id || (jump.jumpToSectionId != null && section.id == jump.jumpToSectionId)) {
        //         // Pertanyaan ini adalah target lompatan.
        //         // Cek apakah kondisi lompatan dari sourceQuestion terpenuhi.
        //         // Jika TIDAK terpenuhi, dan ini adalah satu-satunya cara untuk mencapai pertanyaan ini,
        //         // maka shouldBeVisible = false;
        //         // Ini logika yang kompleks.
        //       }
        //     }
        //   }
        // }


        if (newVisibilityState[question.id] != shouldBeVisible) {
          newVisibilityState[question.id] = shouldBeVisible;
          changed = true;
        }
      }
    }

    if (changed) {
      questionVisibility.value = newVisibilityState; // Update RxMap dengan map baru
      questionVisibility.refresh();
    }
  }

  Future<void> submitForm() async {
    if (loadedForm.value == null || _auth.currentUser == null) {
      Get.snackbar('Error', 'Form atau pengguna tidak valid.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true; // Mulai loading untuk proses submit
    final currentUser = _auth.currentUser!;
    List<QuestionAnswer> answersToSubmit = [];
    bool validationFailed = false;

    void addAnswerToList(FormQuestion question, dynamic answer, String qIdSuffix, String qCodeSuffix, String qTextPrefix) {
      bool answerIsEmpty = (answer == null ||
          (answer is String && answer.trim().isEmpty) ||
          (answer is List && answer.isEmpty));

      if (!answerIsEmpty) {
        answersToSubmit.add(QuestionAnswer(
          questionId: "${question.id}$qIdSuffix",
          questionCode: "${question.code ?? ''}$qCodeSuffix",
          questionText: "$qTextPrefix${question.questionText}",
          answer: answer,
          questionType: question.type.toShortString(),
        ));
      } else if (question.isRequired) {
        Get.snackbar('Validasi Gagal',
            'Pertanyaan "$qTextPrefix${question.questionText}" wajib diisi.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
            duration: const Duration(seconds: 4)); // Durasi lebih lama untuk pesan validasi
        validationFailed = true;
      }
    }

    for (var section in loadedForm.value!.sections) {
      if (validationFailed) break;
      for (var question in section.questions) {
        if (validationFailed) break;
        if (questionVisibility[question.id] == true &&
            (question.belongsToGroupTag == null ||
                question.belongsToGroupTag!.isEmpty)) {
          addAnswerToList(question, userAnswers[question.id],"", "", "");
        }
      }
    }

    if (validationFailed) {
      isLoading.value = false; // Hentikan loading jika validasi gagal
      return;
    }

    for (var section in loadedForm.value!.sections) {
      if (validationFailed) break;
      for (var question in section.questions) {
        if (validationFailed) break;
        if (questionVisibility[question.id] == true &&
            question.belongsToGroupTag != null &&
            question.belongsToGroupTag!.isNotEmpty) {
          final groupTag = question.belongsToGroupTag!;
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final answersForThisQuestionGroup = repeatableGroupAnswers[question.id];

          for (int i = 0; i < count; i++) {
            if (validationFailed) break;
            addAnswerToList(question, answersForThisQuestionGroup?[i], "_$i", "_${i+1}", "[Data ke-${i+1}] ");
          }
        }
      }
    }

    if (validationFailed) {
      isLoading.value = false; // Hentikan loading jika validasi gagal
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

      // --- PERUBAHAN UNTUK NOTIFIKASI DAN RESET ---
      // Set isLoading ke false SEBELUM menampilkan snackbar atau dialog
      // agar UI tidak "freeze" oleh loading indicator saat snackbar/dialog muncul.
      isLoading.value = false;

      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar(); // Tutup snackbar sebelumnya jika ada
      Get.snackbar('Berhasil', 'Form berhasil dikirim!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3), // Durasi snackbar
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );

      // Reset form untuk entri berikutnya
      _initializeStates();

      // Anda bisa tambahkan scroll ke atas di sini jika formnya panjang
      // misalnya dengan menggunakan ScrollController yang di-manage di GetX
      // dan diakses dari sini untuk memanggil animateTo(0, ...).

      // Tidak ada Get.back() di sini agar pengguna tetap di halaman form.
      // --- AKHIR PERUBAHAN ---

    } catch (e) {
      isLoading.value = false; // Pastikan isLoading false jika ada error
      Get.snackbar('Error Pengiriman', 'Gagal mengirim form: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white);
    }
    // isLoading.value = false; // Ini sudah dihandle di dalam try dan catch
  }
}