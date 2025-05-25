// lib/presentation/admin/formpage/form_builder/admin_form_builder_controller.dart

import 'dart:async'; // Untuk Timer
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uid/uid.dart'; // Untuk ID unik lokal

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
// Pastikan path ini benar menuju definisi AppRoutes Anda
// Jika AppRoutes ada di lib/routes/app_routes.dart, pathnya mungkin:
// import 'package:aplikasi_pendataan_desa/routes/app_routes.dart';
import '../../../../infrastructure/navigation/routes.dart'; // Asumsi path ini benar

class AdminFormBuilderController extends GetxController {
  final RxString formTitle = ''.obs;
  final RxString formDescription = ''.obs;
  final RxList<FormSection> sections = <FormSection>[].obs;
  final RxBool isBusy = false.obs; // Flag untuk loading atau saving

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentFormId; // Firestore Document ID jika sedang mengedit
  DateTime? _originalCreatedAt; // Untuk menyimpan createdAt asli saat mengedit

  // Nama koleksi Firestore untuk menyimpan form
  static const String _formsCollectionPath = 'adminForms';

  // Getter untuk mengetahui apakah sedang dalam mode edit
  bool get isEditMode => _currentFormId != null && _currentFormId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // Listener untuk sinkronisasi judul form dari TextField ke RxString
    titleController.addListener(() {
      formTitle.value = titleController.text;
    });
    descriptionController.addListener(() {
      formDescription.value = descriptionController.text;
    });

    // Periksa argumen untuk mode edit atau buat form baru
    if (Get.arguments != null && Get.arguments is String) {
      _currentFormId = Get.arguments as String;
      if (_currentFormId!.isNotEmpty) {
        _loadFormForEditing(_currentFormId!);
      } else {
        // Argumen ada tapi string kosong, anggap form baru
        _initializeNewForm();
      }
    } else {
      _initializeNewForm();
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void _initializeNewForm() {
    formTitle.value = '';
    formDescription.value = '';
    titleController.text = '';
    descriptionController.text = '';
    sections.clear(); // Bersihkan section yang mungkin ada
    addSection(); // Mulai dengan satu bagian default untuk form baru
    _currentFormId = null;
    _originalCreatedAt = null;
    update(); // Trigger update jika diperlukan setelah clear dan add
  }

  Future<void> _loadFormForEditing(String formId) async {
    isBusy.value = true;
    try {
      final docSnapshot = await _db.collection(_formsCollectionPath).doc(formId).get();

      if (docSnapshot.exists) {
        final formItem = FormItem.fromFirestore(docSnapshot);
        formTitle.value = formItem.title;
        formDescription.value = formItem.description;
        sections.assignAll(formItem.sections);
        titleController.text = formItem.title;
        descriptionController.text = formItem.description;
        _originalCreatedAt = formItem.createdAt;
        // _currentFormId sudah di-set dari argumen
        Get.snackbar('Informasi', 'Form "${formItem.title}" berhasil dimuat.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Form dengan ID "$formId" tidak ditemukan.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade300, colorText: Colors.white);
        _initializeNewForm(); // Kembali ke state form baru jika tidak ditemukan
      }
    } catch (e) {
      Get.snackbar('Error Memuat Form', 'Gagal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      print('Error loading form for editing: $e');
      _initializeNewForm(); // Kembali ke state form baru jika ada error
    } finally {
      isBusy.value = false;
    }
  }

  // --- Manajemen Bagian (Sections) ---
  void addSection() {
    sections.add(FormSection(
      id: UId.getId(), // ID unik lokal untuk bagian
      title: 'Bagian ${sections.length + 1}',
      questions: [],
    ));
  }

  void updateSectionTitle(String sectionId, String title) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) {
      // Membuat objek baru untuk memastikan reaktivitas GetX
      sections[index] = sections[index].copyWith(title: title);
    }
  }

  void updateSectionDescription(String sectionId, String description) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) {
      sections[index] = sections[index].copyWith(description: description, setDescriptionNull: description.isEmpty);
    }
  }

  void removeSection(String sectionId) {
    sections.removeWhere((s) => s.id == sectionId);
    if (sections.isEmpty) {
      addSection(); // Pastikan selalu ada minimal satu bagian
    }
  }

  // --- Manajemen Pertanyaan dalam Bagian ---
  void addQuestionToSection(String sectionId, QuestionType type) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final newQuestion = FormQuestion(
        id: UId.getId(), // ID unik lokal untuk pertanyaan
        questionText: '', // Biarkan kosong agar diisi pengguna
        type: type,
        options: (type == QuestionType.multipleChoice || type == QuestionType.checkboxes || type == QuestionType.dropdown)
            ? ['Opsi 1'] // Opsi default awal
            : [],
        isRequired: false,
        conditionalJumps: [],
        validation: ValidationRule(), // Inisialisasi default jika perlu
      );
      final currentSection = sections[sectionIndex];
      // Buat list pertanyaan baru untuk memastikan reaktivitas
      final updatedQuestions = List<FormQuestion>.from(currentSection.questions)..add(newQuestion);
      sections[sectionIndex] = currentSection.copyWith(questions: updatedQuestions);
    }
  }

  // Metode helper internal untuk update properti pertanyaan
  void _updateQuestionProperty(String sectionId, String questionId, FormQuestion Function(FormQuestion currentQ) updater) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final section = sections[sectionIndex];
      final questionList = section.questions;
      final questionIndex = questionList.indexWhere((q) => q.id == questionId);
      if (questionIndex != -1) {
        final updatedQuestion = updater(questionList[questionIndex]);
        final newQuestionsList = List<FormQuestion>.from(questionList);
        newQuestionsList[questionIndex] = updatedQuestion;
        sections[sectionIndex] = section.copyWith(questions: newQuestionsList);
      }
    }
  }

  void updateQuestionText(String sectionId, String questionId, String text) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(questionText: text));
  }

  void updateQuestionRequired(String sectionId, String questionId, bool isRequired) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(isRequired: isRequired));
  }

  void updateQuestionHasOtherOption(String sectionId, String questionId, bool hasOther) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(hasOtherOption: hasOther));
  }

  void addOption(String sectionId, String questionId) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      final newOptions = List<String>.from(q.options)..add('Opsi ${q.options.length + 1}');
      return q.copyWith(options: newOptions);
    });
  }

  void updateOption(String sectionId, String questionId, int optionIndex, String newText) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (optionIndex >= 0 && optionIndex < q.options.length) {
        final newOptions = List<String>.from(q.options);
        newOptions[optionIndex] = newText;
        return q.copyWith(options: newOptions);
      }
      return q;
    });
  }

  void removeOption(String sectionId, String questionId, int optionIndex) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (optionIndex >= 0 && optionIndex < q.options.length) {
        final newOptions = List<String>.from(q.options)..removeAt(optionIndex);
        return q.copyWith(options: newOptions);
      }
      return q;
    });
  }

  void removeQuestion(String sectionId, String questionId) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final section = sections[sectionIndex];
      final updatedQuestions = List<FormQuestion>.from(section.questions)..removeWhere((q) => q.id == questionId);
      sections[sectionIndex] = section.copyWith(questions: updatedQuestions);
    }
  }

  void updateValidation(String sectionId, String questionId, ValidationRule? validation) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(validation: validation, setValidationNull: validation == null));
  }

  void addConditionalJump(String sectionId, String questionId, ConditionalJump jump) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      final updatedJumps = List<ConditionalJump>.from(q.conditionalJumps)..add(jump);
      return q.copyWith(conditionalJumps: updatedJumps);
    });
  }

  void removeConditionalJump(String sectionId, String questionId, String targetIdToRemove) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      final updatedJumps = List<ConditionalJump>.from(q.conditionalJumps)
        ..removeWhere((j) => j.jumpToQuestionId == targetIdToRemove || j.jumpToSectionId == targetIdToRemove);
      return q.copyWith(conditionalJumps: updatedJumps);
    });
  }

  void updateQuestionRepeatable(String sectionId, String questionId, bool repeatable, {int? count}) {
    _updateQuestionProperty(sectionId, questionId, (q) =>
        q.copyWith(
          repeatable: repeatable,
          repeatCount: repeatable ? (count ?? q.repeatCount ?? 1) : null,
          setRepeatCountNull: !repeatable,
        )
    );
  }


  // --- Simpan Form ---
  Future<void> saveForm() async {
    print("DEBUG: saveForm() dipanggil.");

    if (formTitle.value.trim().isEmpty) {
      print("DEBUG: Judul form kosong, proses dihentikan.");
      Get.snackbar('Input Error', 'Judul form tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    if (_auth.currentUser == null) {
      print("DEBUG: User tidak login, proses dihentikan.");
      Get.snackbar('Autentikasi Error', 'Anda harus login untuk menyimpan form.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      return;
    }

    isBusy.value = true;
    print("DEBUG: isBusy diatur ke true, memulai proses simpan.");
    try {
      String formIdToSave = _currentFormId ?? _db.collection(_formsCollectionPath).doc().id;
      final DateTime createdAtValue = isEditMode ? (_originalCreatedAt ?? DateTime.now()) : DateTime.now();

      print("DEBUG: Form ID untuk disimpan: $formIdToSave");
      print("DEBUG: Judul Form: ${formTitle.value.trim()}");

      final formToSave = FormItem(
        id: formIdToSave,
        title: formTitle.value.trim(),
        description: formDescription.value.trim(),
        createdAt: createdAtValue,
        createdByUserId: _auth.currentUser!.uid,
        sections: sections.map((s) => s.cleanUpQuestionsBeforeSave()).toList(),
      );

      print("DEBUG: Data form yang akan disimpan: ${formToSave.toFirestore()}");

      await _db.collection(_formsCollectionPath).doc(formIdToSave).set(formToSave.toFirestore());

      print("DEBUG: Form berhasil disimpan ke Firestore.");

      const snackbarDuration = Duration(seconds: 3);

      Get.snackbar(
        'Berhasil',
        isEditMode ? 'Form "${formToSave.title}" berhasil diperbarui!' : 'Form "${formToSave.title}" berhasil dibuat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: snackbarDuration,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        isDismissible: true,
        mainButton: TextButton(
          onPressed: () {
            if (Get.isSnackbarOpen) {
              Get.closeCurrentSnackbar();
            }
            // Jika ingin navigasi saat OK ditekan juga, panggil _navigateBackIfPossible di sini.
            // Tapi hati-hati dengan Timer yang juga akan memanggilnya.
          },
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );

      Timer(snackbarDuration, () {
        _navigateBackIfPossible();
      });

    } catch (e) {
      print("DEBUG: Error saat menyimpan form: $e");
      Get.snackbar('Error Simpan Form', 'Gagal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      if(!isClosed) {
        isBusy.value = false; // Set false juga di catch jika error
      }
    }
    // finally { // 'finally' akan dijalankan bahkan jika ada return di try atau catch
    //   // Jika Get.back() berhasil, controller mungkin sudah di-dispose.
    //   // Menyetel isBusy di sini bisa menyebabkan error jika controller sudah 'closed'.
    //   // Lebih baik set isBusy = false di akhir blok try (setelah navigasi) dan di blok catch.
    //   // Namun, jika navigasi gagal atau Snackbar masih tampil, isBusy harus false.
    //   // Pendekatan paling aman adalah di akhir try dan di catch.
    //   // Jika navigasi dihandle oleh Timer, maka set isBusy = false setelah timer atau di akhir try.
    //   // Untuk sekarang, kita biarkan isBusy di-set false setelah navigasi atau setelah error.
    // }
  }

  void _navigateBackIfPossible() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar(); // Tutup snackbar jika masih ada
    }
    // Tutup dialog atau bottom sheet lain yang mungkin masih terbuka
    // Get.back(closeOverlays: true) bisa menutup snackbar juga, jadi hati-hati urutannya
    if (Get.isOverlaysOpen) { // Lebih umum daripada isDialogOpen atau isBottomSheetOpen
      Get.back(closeOverlays: true);
    }

    if (Get.currentRoute == AppRoutes.adminFormBuilder) {
      Get.back();
      print("DEBUG: Get.back() dipanggil dari _navigateBackIfPossible.");
    } else {
      print("DEBUG: Tidak memanggil Get.back() karena rute saat ini bukan adminFormBuilder. Rute saat ini: ${Get.currentRoute}");
    }
    if(!isClosed) { // Pastikan controller belum di-dispose
      isBusy.value = false; // Set isBusy false setelah semua selesai
      print("DEBUG: isBusy diatur ke false setelah navigasi/timer.");
    }
  }
}