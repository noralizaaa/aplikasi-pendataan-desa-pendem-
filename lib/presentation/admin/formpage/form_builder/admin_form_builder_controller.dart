import 'dart:async'; // Untuk Timer
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uid/uid.dart'; // Untuk ID unik lokal

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import '../../../../infrastructure/navigation/routes.dart';

class AdminFormBuilderController extends GetxController {
  final RxString formTitle = ''.obs;
  final RxString formDescription = ''.obs;
  final RxList<FormSection> sections = <FormSection>[].obs;
  final RxBool isBusy = false.obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentFormId;
  DateTime? _originalCreatedAt;

  static const String _formsCollectionPath = 'adminForms';

  bool get isEditMode => _currentFormId != null && _currentFormId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    titleController.addListener(() {
      formTitle.value = titleController.text;
    });
    descriptionController.addListener(() {
      formDescription.value = descriptionController.text;
    });

    if (Get.arguments != null && Get.arguments is String) {
      _currentFormId = Get.arguments as String;
      if (_currentFormId!.isNotEmpty) {
        _loadFormForEditing(_currentFormId!);
      } else {
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
    sections.clear();
    addSection(); // Mulai dengan satu bagian default
    _currentFormId = null;
    _originalCreatedAt = null;
    update();
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
        Get.snackbar('Informasi', 'Form "${formItem.title}" berhasil dimuat.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Form dengan ID "$formId" tidak ditemukan.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade300, colorText: Colors.white);
        _initializeNewForm();
      }
    } catch (e) {
      Get.snackbar('Error Memuat Form', 'Gagal memuat: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      _initializeNewForm();
    } finally {
      isBusy.value = false;
    }
  }

  void addSection() {
    sections.add(FormSection(
      id: UId.getId(),
      title: '', // Judul akan diisi pengguna, UI akan menampilkan Romawi jika kosong
      questions: [],
    ));
  }

  void updateSectionTitle(String sectionId, String title) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) {
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

  void addQuestionToSection(String sectionId, QuestionType type) {
    final sectionIndexInList = sections.indexWhere((s) => s.id == sectionId); // 0-based index
    if (sectionIndexInList != -1) {
      final currentSection = sections[sectionIndexInList];
      // Nomor pertanyaan berikutnya dalam bagian ini (1-based)
      int nextQuestionNumberInThisSection = currentSection.questions.length + 1;
      // Nomor bagian (1-based) untuk awalan kode
      int sectionNumberForCode = sectionIndexInList + 1;

      // Kode otomatis: [NomorBagian][NomorUrutPertanyaanDalamBagian, 2 digit]
      // Contoh: Bagian 1, Pertanyaan 1 -> 101; Bagian 3, Pertanyaan 12 -> 312
      String suggestedCode = '$sectionNumberForCode${nextQuestionNumberInThisSection.toString().padLeft(2, '0')}';

      final newQuestion = FormQuestion(
        id: UId.getId(),
        code: suggestedCode, // Kode otomatis berdasarkan nomor bagian dan urutan pertanyaan
        questionText: '',
        type: type,
        options: (type == QuestionType.multipleChoice || type == QuestionType.checkboxes || type == QuestionType.dropdown)
            ? ['Opsi 1'] // Opsi default awal
            : [],
        isRequired: false,
        conditionalJumps: [],
        validation: ValidationRule(),
        dependentOptions: null,
      );
      final updatedQuestions = List<FormQuestion>.from(currentSection.questions)..add(newQuestion);
      sections[sectionIndexInList] = currentSection.copyWith(questions: updatedQuestions);
    }
  }

  void _updateQuestionProperty(String sectionId, String questionId, FormQuestion Function(FormQuestion currentQ) updater) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final section = sections[sectionIndex];
      final questionList = section.questions;
      final questionIndexInOriginalList = questionList.indexWhere((q) => q.id == questionId);
      if (questionIndexInOriginalList != -1) {
        final updatedQuestion = updater(questionList[questionIndexInOriginalList]);
        final newQuestionsList = List<FormQuestion>.from(questionList);
        newQuestionsList[questionIndexInOriginalList] = updatedQuestion;
        sections[sectionIndex] = section.copyWith(questions: newQuestionsList);
      }
    }
  }

  void updateQuestionCode(String sectionId, String questionId, String newCode) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(code: newCode.trim()));
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

  void updateValidation(String sectionId, String questionId, ValidationRule? newValidationRule) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      // If newValidationRule is completely empty (all fields null or default/none), then set validation to null.
      bool isNewRuleEffectivelyEmpty = newValidationRule == null ||
          (newValidationRule.minLength == null &&
              newValidationRule.maxLength == null &&
              newValidationRule.minValue == null &&
              newValidationRule.maxValue == null &&
              (newValidationRule.regex == null || newValidationRule.regex!.isEmpty) &&
              (newValidationRule.predefinedRule == null || newValidationRule.predefinedRule!.isEmpty)); // 'none' is handled by copyWith

      ValidationRule? ruleToSet = newValidationRule;
      if (ruleToSet != null) {
        // Example: If a predefinedRule is chosen (and it's not 'custom'),
        // you might want to clear the custom regex.
        // For now, we let both coexist, validation execution logic would prioritize.
        // if (ruleToSet.predefinedRule != null && ruleToSet.predefinedRule!.isNotEmpty && ruleToSet.predefinedRule != 'custom_regex_identifier_if_any') {
        //   ruleToSet = ruleToSet.copyWith(regex: null, setRegexNull: true);
        // }
      }
      return q.copyWith(validation: ruleToSet, setValidationNull: isNewRuleEffectivelyEmpty);
    });
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
          repeatCount: repeatable ? (count ?? q.repeatCount) : null,
          setRepeatCountNull: !repeatable,
        )
    );
  }

  List<FormQuestion> getPotentialParentQuestions(String? currentSectionIdToExclude, String currentQuestionIdToExclude) {
    final List<FormQuestion> potentialParents = [];
    for (var section in sections) {
      for (var question in section.questions) {
        if (question.id == currentQuestionIdToExclude) continue;
        if ((question.type == QuestionType.dropdown ||
            question.type == QuestionType.multipleChoice ||
            question.type == QuestionType.checkboxes) &&
            question.options.isNotEmpty) {
          potentialParents.add(question);
        }
      }
    }
    return potentialParents;
  }

  FormQuestion? findQuestionById(String questionId) {
    for (var section in sections) {
      for (var q_item in section.questions) {
        if (q_item.id == questionId) return q_item;
      }
    }
    return null;
  }

  void setParentQuestionForDependency(String sectionId, String questionId, String? newParentQuestionId) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (newParentQuestionId == null || newParentQuestionId.isEmpty) {
        return q.copyWith(dependentOptions: null, setDependentOptionsNull: true);
      }
      final newConfig = (q.dependentOptions?.parentQuestionId == newParentQuestionId
          ? q.dependentOptions
          : DependentOptionsConfig(parentQuestionId: newParentQuestionId, optionMapping: {}))!
          .copyWith(parentQuestionId: newParentQuestionId);
      return q.copyWith(dependentOptions: newConfig, setDependentOptionsNull: false);
    });
  }

  void updateMappingForParentOption(String sectionId, String questionId, String parentOptionValue, List<String> childOptions) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (q.dependentOptions == null || q.dependentOptions!.parentQuestionId.isEmpty) return q;

      final newMapping = Map<String, List<String>>.from(q.dependentOptions!.optionMapping);
      newMapping[parentOptionValue] = childOptions;
      return q.copyWith(dependentOptions: q.dependentOptions!.copyWith(optionMapping: newMapping));
    });
  }

  void removeMappingForParentOption(String sectionId, String questionId, String parentOptionValue) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (q.dependentOptions == null) return q;
      final newMapping = Map<String, List<String>>.from(q.dependentOptions!.optionMapping);
      newMapping.remove(parentOptionValue);
      return q.copyWith(dependentOptions: q.dependentOptions!.copyWith(optionMapping: newMapping));
    });
  }

  Future<void> saveForm() async {
    if (formTitle.value.trim().isEmpty) {
      Get.snackbar('Input Error', 'Judul form tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    if (_auth.currentUser == null) {
      Get.snackbar('Autentikasi Error', 'Anda harus login untuk menyimpan form.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      return;
    }

    isBusy.value = true;
    try {
      String formIdToSave = _currentFormId ?? _db.collection(_formsCollectionPath).doc().id;
      final DateTime createdAtValue = isEditMode ? (_originalCreatedAt ?? DateTime.now()) : DateTime.now();

      final formToSave = FormItem(
        id: formIdToSave,
        title: formTitle.value.trim(),
        description: formDescription.value.trim(),
        createdAt: createdAtValue,
        createdByUserId: _auth.currentUser!.uid,
        sections: sections.map((s) => s.cleanUpQuestionsBeforeSave()).toList(),
      );

      await _db.collection(_formsCollectionPath).doc(formIdToSave).set(formToSave.toFirestore());

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
            if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          },
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );

      Timer(snackbarDuration, _navigateBackIfPossible);

    } catch (e) {
      Get.snackbar('Error Simpan Form', 'Gagal menyimpan: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      if(!isClosed) isBusy.value = false;
    }
  }

  void _navigateBackIfPossible() {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    if (Get.isOverlaysOpen) Get.back(closeOverlays: true);

    if (Get.currentRoute == AppRoutes.adminFormBuilder) {
      Get.back();
    }
    if(!isClosed) isBusy.value = false;
  }
}