import 'dart:async'; // Untuk Timer
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uid/uid.dart'; // Untuk ID unik lokal

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import '../../../../infrastructure/navigation/routes.dart'; // Pastikan path ini benar

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

  // --- Methods for Repeatable Group Questions ---
  List<FormQuestion> getPotentialRepeatableGroupControllers(String currentSectionId, String currentQuestionId) {
    final List<FormQuestion> controllers = [];
    for (var section in sections) {
      for (var question in section.questions) {
        if (question.id == currentQuestionId) continue;
        if (question.type == QuestionType.number && (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty)) {
          controllers.add(question);
        }
      }
    }
    return controllers;
  }

  List<String> getAvailableControlledGroupTags(String currentSectionId, String currentQuestionId) {
    final Set<String> tags = {};
    final FormQuestion? currentQ = findQuestionById(currentQuestionId); // Panggil sekali di luar loop

    for (var section in sections) {
      for (var question in section.questions) {
        if (question.isRepeatableGroupController &&
            question.controlledGroupTag != null &&
            question.controlledGroupTag!.isNotEmpty) {
          // Jika pertanyaan saat ini (currentQ) adalah controller dan tagnya sama dengan tag yang sedang diiterasi,
          // maka jangan tambahkan tag ini ke daftar pilihan. Ini untuk mencegah currentQ memilih tagnya sendiri
          // untuk 'belongsToGroupTag'.
          if (currentQ != null &&
              currentQ.isRepeatableGroupController &&
              currentQ.id == question.id && // Memastikan ini adalah tag dari currentQ itu sendiri
              currentQ.controlledGroupTag == question.controlledGroupTag) {
            // Jangan tambahkan tag milik currentQ sendiri
          } else {
            tags.add(question.controlledGroupTag!);
          }
        }
      }
    }
    return tags.toList();
  }

  void updateQuestionAsRepeatableGroupController(String sectionId, String questionId, bool isController, String? groupTag) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (isController) {
        return q.copyWith(
          isRepeatableGroupController: true,
          controlledGroupTag: groupTag?.trim(),
          setControlledGroupTagNull: groupTag == null || groupTag.trim().isEmpty,
          belongsToGroupTag: null,
          setBelongsToGroupTagNull: true,
        );
      } else {
        return q.copyWith(
          isRepeatableGroupController: false,
          controlledGroupTag: null,
          setControlledGroupTagNull: true,
        );
      }
    });
  }

  void updateQuestionBelongsToGroupTag(String sectionId, String questionId, String? groupTag) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (groupTag != null && groupTag.isNotEmpty) {
        return q.copyWith(
          belongsToGroupTag: groupTag,
          setBelongsToGroupTagNull: false,
          isRepeatableGroupController: false,
          controlledGroupTag: null,
          setControlledGroupTagNull: true,
        );
      } else {
        return q.copyWith(
          belongsToGroupTag: null,
          setBelongsToGroupTagNull: true,
        );
      }
    });
  }
  // --- End of Methods for Repeatable Group Questions ---

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
    addSection();
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
        // Get.snackbar('Informasi', 'Form "${formItem.title}" berhasil dimuat.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
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
      title: '',
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
      addSection();
    }
  }

  void addQuestionToSection(String sectionId, QuestionType type) {
    final sectionIndexInList = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndexInList != -1) {
      final currentSection = sections[sectionIndexInList];
      int nextQuestionNumberInThisSection = currentSection.questions.length + 1;
      int sectionNumberForCode = sectionIndexInList + 1;
      String suggestedCode = '$sectionNumberForCode${nextQuestionNumberInThisSection.toString().padLeft(2, '0')}';

      final newQuestion = FormQuestion(
        id: UId.getId(),
        code: suggestedCode,
        questionText: '',
        type: type,
        options: (type == QuestionType.multipleChoice || type == QuestionType.checkboxes || type == QuestionType.dropdown)
            ? ['Opsi 1']
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
      bool isNewRuleEffectivelyEmpty = newValidationRule == null ||
          (newValidationRule.minLength == null &&
              newValidationRule.maxLength == null &&
              newValidationRule.minValue == null &&
              newValidationRule.maxValue == null &&
              (newValidationRule.regex == null || newValidationRule.regex!.isEmpty) &&
              (newValidationRule.predefinedRule == null || newValidationRule.predefinedRule!.isEmpty || newValidationRule.predefinedRule == 'none'));
      return q.copyWith(validation: newValidationRule, setValidationNull: isNewRuleEffectivelyEmpty);
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

  // --- LOGIKA SIMPAN DENGAN DIALOG KONFIRMASI ---
  Future<void> saveForm() async {
    if (formTitle.value.trim().isEmpty) {
      Get.snackbar('Input Error', 'Judul form tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    if (_auth.currentUser == null) {
      Get.snackbar('Autentikasi Error', 'Anda harus login untuk menyimpan form.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Get.theme.colorScheme.secondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Konfirmasi Simpan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Get.theme.textTheme.bodyLarge?.color ?? Colors.black87),
              ),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menyimpan perubahan pada form "${formTitle.value.trim().isNotEmpty ? formTitle.value.trim() : "Tanpa Judul"}"?',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.back(); // Tutup dialog
            },
            child: Text(
              'Tidak',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_alt_rounded, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 2,
            ),
            onPressed: () {
              Get.back();
              _executeSaveForm();
            },
            label: const Text('Ya, Simpan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _executeSaveForm() async {
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
      if(!isClosed) {
        isBusy.value = false;
      }
    }
  }
  // --- AKHIR LOGIKA SIMPAN ---

  void _navigateBackIfPossible() {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    if (Get.isOverlaysOpen) Get.back(closeOverlays: true);

    if (Get.currentRoute == AppRoutes.adminFormBuilder) {
      Get.back();
    }
    if(!isClosed) isBusy.value = false;
  }
}