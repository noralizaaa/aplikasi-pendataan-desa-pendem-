import 'dart:async'; // Untuk Timer
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Untuk Colors, Get.snackbar, WidgetsBinding, dll.
import 'package:uid/uid.dart'; // Untuk ID unik lokal

// PASTIKAN PATH INI BENAR dan admin_form_model.dart adalah versi LENGKAP TERBARU
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

  final Map<String, ExpansionTileController> sectionExpansionControllers = {};

  String? _currentFormId; // ID form yang sedang diedit, null jika form baru
  DateTime? _originalCreatedAt; // Untuk mempertahankan createdAt saat edit
  String? _originalFormVersion; // Untuk menyimpan versi form saat edit

  static const String _formsCollectionPath = 'adminForms';

  bool get isEditMode => _currentFormId != null && _currentFormId!.isNotEmpty;

  String _toRoman(int number) {
    if (number < 1 || number > 3999) return number.toString();
    const List<String> rn = ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
    const List<int> val = [1000,900,500,400,100,90,50,40,10,9,5,4,1];
    String result = "";
    for (int i = 0; i < val.length; i++) {
      while (number >= val[i]) {
        result += rn[i];
        number -= val[i];
      }
    }
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    titleController.addListener(() => formTitle.value = titleController.text);
    descriptionController.addListener(() => formDescription.value = descriptionController.text);

    final arguments = Get.arguments;
    if (arguments is String && arguments.isNotEmpty) {
      _currentFormId = arguments;
      print("AdminFormBuilderController: Mode Edit untuk form ID: $_currentFormId");
      _loadFormForEditing(_currentFormId!);
    } else {
      print("AdminFormBuilderController: Mode Buat Form Baru (argumen: $arguments)");
      _currentFormId = null;
      _initializeNewForm();
    }
  }

  void _clearAllSectionExpansionControllers() {
    sectionExpansionControllers.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    _clearAllSectionExpansionControllers();
    super.onClose();
  }

  void _initializeNewForm() {
    formTitle.value = '';
    formDescription.value = '';
    titleController.text = '';
    descriptionController.text = '';
    _clearAllSectionExpansionControllers();
    sections.clear();
    addSection();
    _originalCreatedAt = null;
    _originalFormVersion = "1.0";
  }

  Future<void> _loadFormForEditing(String formId) async {
    isBusy.value = true;
    try {
      final docSnapshot = await _db.collection(_formsCollectionPath).doc(formId).get();
      if (docSnapshot.exists) {
        final formItem = FormItem.fromFirestore(docSnapshot);
        formTitle.value = formItem.title;
        formDescription.value = formItem.description;
        _clearAllSectionExpansionControllers();
        sections.assignAll(formItem.sections.map((section) {
          sectionExpansionControllers[section.id] = ExpansionTileController();
          return section;
        }).toList());
        titleController.text = formItem.title;
        descriptionController.text = formItem.description;
        _originalCreatedAt = formItem.createdAt;
        _originalFormVersion = formItem.formVersion ?? "1.0";
        Get.snackbar(
            'Informasi', 'Form "${formItem.title}" (Versi $_originalFormVersion) berhasil dimuat.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Form dengan ID "$formId" tidak ditemukan. Membuat form baru.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade300, colorText: Colors.white);
        _currentFormId = null;
        _initializeNewForm();
      }
    } catch (e,s) {
      print("Error loading form: $e\n$s");
      Get.snackbar('Error Memuat Form', 'Gagal memuat: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade400, colorText: Colors.white);
      _currentFormId = null;
      _initializeNewForm();
    } finally {
      isBusy.value = false;
    }
  }

  // --- MANAJEMEN BAGIAN (SECTION) ---
  void addSection() {
    final newSection = FormSection(
      id: UId.getId(),
      title: '',
      questions: [],
      isRepeatable: false,
    );
    final newExpansionController = ExpansionTileController();

    sections.add(newSection);
    sectionExpansionControllers[newSection.id] = newExpansionController;

    if (!isEditMode && sections.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if the controller is still valid in our map.
        if (sectionExpansionControllers[newSection.id] == newExpansionController) {
          // Since .isAttached is not available in older Flutter versions,
          // we rely on the post-frame callback timing.
          // For added safety, wrap in try-catch to handle potential assertion errors.
          try {
            newExpansionController.expand();
          } catch (e) {
            // This catch block would handle the '_state != null' assertion if it still occurs.
            print("AdminFormBuilderController: PostFrame - Error expanding ${newSection.id}: $e. "
                "This might indicate the ExpansionTile was not fully ready or was disposed.");
          }
        }
      });
    }
  }

  void updateSectionTitle(String sectionId, String title) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) sections[index] = sections[index].copyWith(title: title);
  }

  void updateSectionDescription(String sectionId, String description) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) sections[index] = sections[index].copyWith(description: description, setDescriptionNull: description.isEmpty);
  }

  void updateSectionRepeatability({
    required String sectionId,
    required bool isRepeatable,
    String? triggerQuestionId,
    String? triggerQuestionCode,
    int? minRepeats,
    int? maxRepeats,
  }) {
    final index = sections.indexWhere((s) => s.id == sectionId);
    if (index != -1) {
      final currentSection = sections[index];
      FormSection updatedSection;

      if (isRepeatable) {
        updatedSection = currentSection.copyWith(
          isRepeatable: true,
          repeatTriggerQuestionId: triggerQuestionId,
          setRepeatTriggerQuestionIdNull: triggerQuestionId == null,
          repeatTriggerQuestionCode: triggerQuestionCode,
          setRepeatTriggerQuestionCodeNull: triggerQuestionCode == null,
          minRepeats: minRepeats ?? (triggerQuestionId != null ? 0 : 1),
          setMinRepeatsNull: false,
          maxRepeats: maxRepeats,
          setMaxRepeatsNull: maxRepeats == null,
        );
      } else {
        updatedSection = currentSection.copyWith(
            isRepeatable: false,
            repeatTriggerQuestionId: null, setRepeatTriggerQuestionIdNull: true,
            repeatTriggerQuestionCode: null, setRepeatTriggerQuestionCodeNull: true,
            minRepeats: null, setMinRepeatsNull: true,
            maxRepeats: null, setMaxRepeatsNull: true
        );
      }
      sections[index] = updatedSection;
      // print("DEBUG: Section $sectionId repeatability updated. IsRepeatable: ${updatedSection.isRepeatable}, TriggerId: ${updatedSection.repeatTriggerQuestionId}, Min: ${updatedSection.minRepeats}");
    } else {
      // print("DEBUG: Section $sectionId tidak ditemukan untuk update repeatability.");
    }
  }

  void removeSection(String sectionId) {
    sectionExpansionControllers.remove(sectionId);
    sections.removeWhere((s) => s.id == sectionId);
    if (sections.isEmpty) {
      addSection();
    }
  }

  // --- MANAJEMEN PERTANYAAN (QUESTION) ---
  void addQuestionToSection(String sectionId, QuestionType type) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final currentSection = sections[sectionIndex];
      int nextQuestionNumberInSection = currentSection.questions.length + 1;
      int sectionNumberForCode = sectionIndex + 1;
      String suggestedCode = '$sectionNumberForCode${nextQuestionNumberInSection.toString().padLeft(2, '0')}';

      ValidationRule defaultValidation = ValidationRule.empty();

      final newQuestion = FormQuestion(
        id: UId.getId(),
        code: suggestedCode,
        questionText: '',
        type: type,
        options: (type == QuestionType.multipleChoice || type == QuestionType.checkboxes || type == QuestionType.dropdown) ? ['Opsi 1'] : [],
        validation: defaultValidation,
      );
      final updatedQuestions = List<FormQuestion>.from(currentSection.questions)..add(newQuestion);
      sections[sectionIndex] = currentSection.copyWith(questions: updatedQuestions);
    }
  }

  void _updateQuestionProperty(String sectionId, String questionId, FormQuestion Function(FormQuestion currentQ) updater) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final section = sections[sectionIndex];
      final questionIndex = section.questions.indexWhere((q) => q.id == questionId);
      if (questionIndex != -1) {
        final updatedQuestion = updater(section.questions[questionIndex]);
        final newQuestionsList = List<FormQuestion>.from(section.questions);
        newQuestionsList[questionIndex] = updatedQuestion;
        sections[sectionIndex] = section.copyWith(questions: newQuestionsList);
      }
    }
  }

  void updateQuestionCode(String sectionId, String questionId, String newCode) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(code: newCode.trim()));
  void updateQuestionText(String sectionId, String questionId, String text) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(questionText: text));
  void updateQuestionRequired(String sectionId, String questionId, bool isRequired) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(isRequired: isRequired));
  void updateQuestionHasOtherOption(String sectionId, String questionId, bool hasOther) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(hasOtherOption: hasOther));
  void updateQuestionDescription(String sectionId, String questionId, String description) {
    _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(description: description, setDescriptionNull: description.isEmpty));
  }

  void addOption(String sectionId, String questionId) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(options: List<String>.from(q.options)..add('Opsi ${q.options.length + 1}')));

  void updateOption(String sectionId, String questionId, int optionIndex, String newText) => _updateQuestionProperty(sectionId, questionId, (q) {
    if (optionIndex >= 0 && optionIndex < q.options.length) {
      final newOptions = List<String>.from(q.options);
      newOptions[optionIndex] = newText;
      return q.copyWith(options: newOptions);
    } return q;
  });

  void removeOption(String sectionId, String questionId, int optionIndex) => _updateQuestionProperty(sectionId, questionId, (q) {
    if (optionIndex >= 0 && optionIndex < q.options.length) {
      final newOptions = List<String>.from(q.options)..removeAt(optionIndex);
      return q.copyWith(options: newOptions);
    } return q;
  });

  void removeQuestion(String sectionId, String questionId) {
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    if (sectionIndex != -1) {
      final section = sections[sectionIndex];
      final updatedQuestions = List<FormQuestion>.from(section.questions)..removeWhere((q) => q.id == questionId);
      sections[sectionIndex] = section.copyWith(questions: updatedQuestions);
    }
  }

  void updateValidation(String sectionId, String questionId, ValidationRule? newValidationRuleFromUI) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      bool shouldSetToEmpty = newValidationRuleFromUI == null || newValidationRuleFromUI.isEffectivelyEmpty;
      return q.copyWith(
        validation: shouldSetToEmpty ? ValidationRule.empty() : newValidationRuleFromUI,
      );
    });
  }

  void addConditionalJump(String sectionId, String questionId, ConditionalJump jump) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(conditionalJumps: List<ConditionalJump>.from(q.conditionalJumps)..add(jump)));
  void removeConditionalJump(String sectionId, String questionId, String targetIdToRemove) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(conditionalJumps: List<ConditionalJump>.from(q.conditionalJumps)..removeWhere((j) => j.jumpToQuestionId == targetIdToRemove || j.jumpToSectionId == targetIdToRemove)));
  void updateQuestionRepeatable(String sectionId, String questionId, bool repeatable, {int? count}) => _updateQuestionProperty(sectionId, questionId, (q) => q.copyWith(repeatable: repeatable, repeatCount: repeatable ? (count ?? q.repeatCount) : null, setRepeatCountNull: !repeatable));

  List<FormQuestion> getPotentialRepeatableGroupControllers(String currentSectionId, String currentQuestionId) {
    final List<FormQuestion> controllersList = [];
    for (var section in sections) {
      for (var question in section.questions) {
        if (question.id == currentQuestionId) continue;
        if (question.type == QuestionType.number && (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty)) {
          controllersList.add(question);
        }
      }
    }
    return controllersList;
  }

  List<String> getAvailableControlledGroupTags(String currentSectionId, String currentQuestionId) {
    final Set<String> tags = {};
    for (var section in sections) {
      for (var question in section.questions) {
        if (question.isRepeatableGroupController &&
            question.controlledGroupTag != null &&
            question.controlledGroupTag!.isNotEmpty) {
          if (!(question.id == currentQuestionId && question.isRepeatableGroupController)) {
            tags.add(question.controlledGroupTag!);
          }
        }
      }
    }
    return tags.toList()..sort();
  }

  void updateQuestionAsRepeatableGroupController(String sectionId, String questionId, bool isController, String? groupTag) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (isController) {
        return q.copyWith(
          isRepeatableGroupController: true,
          controlledGroupTag: groupTag?.trim(), setControlledGroupTagNull: groupTag == null || groupTag.trim().isEmpty,
          belongsToGroupTag: null, setBelongsToGroupTagNull: true,
        );
      } else {
        return q.copyWith(
          isRepeatableGroupController: false,
          controlledGroupTag: null, setControlledGroupTagNull: true,
        );
      }
    });
  }

  void updateQuestionBelongsToGroupTag(String sectionId, String questionId, String? groupTag) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      if (groupTag != null && groupTag.isNotEmpty) {
        return q.copyWith(
          belongsToGroupTag: groupTag, setBelongsToGroupTagNull: false,
          isRepeatableGroupController: false, controlledGroupTag: null, setControlledGroupTagNull: true,
        );
      } else {
        return q.copyWith(belongsToGroupTag: null, setBelongsToGroupTagNull: true);
      }
    });
  }

  void _updateGridLabels(String sectionId, String questionId, List<String> newLabels, String labelType) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      switch (labelType) {
        case 'rows': return q.copyWith(gridRowLabels: newLabels);
        case 'cols': return q.copyWith(gridColumnLabels: newLabels);
        case 'subCols': return q.copyWith(gridSubColumnLabels: newLabels);
        default: return q;
      }
    });
  }
  void updateGridRowLabelsFromString(String sectionId, String questionId, String commaSeparatedLabels) {
    final labels = commaSeparatedLabels.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    _updateGridLabels(sectionId, questionId, labels, 'rows');
  }
  void updateGridColumnLabelsFromString(String sectionId, String questionId, String commaSeparatedLabels) {
    final labels = commaSeparatedLabels.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    _updateGridLabels(sectionId, questionId, labels, 'cols');
  }
  void updateGridSubColumnLabelsFromString(String sectionId, String questionId, String commaSeparatedLabels) {
    final labels = commaSeparatedLabels.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    _updateGridLabels(sectionId, questionId, labels, 'subCols');
  }

  List<Map<String, String>> getAllQuestionsForLinking({String? currentQuestionIdToExclude, bool numericOnly = false}) {
    final List<Map<String, String>> linkableQuestions = [];
    for (var secIdx = 0; secIdx < sections.length; secIdx++) {
      final section = sections[secIdx];
      for (var qIdx = 0; qIdx < section.questions.length; qIdx++) {
        final question = section.questions[qIdx];
        if (currentQuestionIdToExclude != null && question.id == currentQuestionIdToExclude) continue;
        if (numericOnly && question.type != QuestionType.number) continue;

        String sectionRoman = _toRoman(secIdx + 1);
        String questionNumberInSec = (qIdx + 1).toString();
        String defaultCodeDisplay = "${sectionRoman}.${questionNumberInSec}";

        linkableQuestions.add({
          'id': question.id,
          'code': question.code != null && question.code!.isNotEmpty ? question.code! : defaultCodeDisplay,
          'text': question.questionText.isNotEmpty
              ? (question.questionText.length > 35 ? '${question.questionText.substring(0,32)}...' : question.questionText)
              : '(P ${question.code ?? defaultCodeDisplay})',
        });
      }
    }
    return linkableQuestions;
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

  FormQuestion? findQuestionById(String? questionId) {
    if (questionId == null || questionId.isEmpty) return null;
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
      final currentConfig = q.dependentOptions;
      final newConfig = (currentConfig?.parentQuestionId == newParentQuestionId && currentConfig != null
          ? currentConfig
          : DependentOptionsConfig(parentQuestionId: newParentQuestionId, optionMapping: {}))
          .copyWith(parentQuestionId: newParentQuestionId);
      return q.copyWith(dependentOptions: newConfig, setDependentOptionsNull: false);
    });
  }

  void updateMappingForParentOption(String sectionId, String questionId, String parentOptionValue, List<String> childOptions) {
    // print("DEBUG_UpdateMapping: Called for Q_ID: $questionId, ParentOption: '$parentOptionValue', ChildOptions: $childOptions");
    _updateQuestionProperty(sectionId, questionId, (q) {
      // print("DEBUG_UpdateMapping: Current dependentOptions for Q_ID ${q.id} BEFORE update: ${q.dependentOptions?.toMap()}");
      DependentOptionsConfig currentDepOpts = q.dependentOptions ?? DependentOptionsConfig(parentQuestionId: q.dependentOptions?.parentQuestionId ?? '', optionMapping: {});
      if (currentDepOpts.parentQuestionId.isEmpty) {
        // print("DEBUG_UpdateMapping: ParentQuestionId is empty, skipping mapping update.");
        return q;
      }

      final newMapping = Map<String, List<String>>.from(currentDepOpts.optionMapping);
      newMapping[parentOptionValue] = childOptions;
      // print("DEBUG_UpdateMapping: New mapping to be set: $newMapping");

      final updatedDependentOptions = currentDepOpts.copyWith(optionMapping: newMapping);
      // print("DEBUG_UpdateMapping: Updated dependentOptions OBJECT: ${updatedDependentOptions.toMap()}");

      final updatedQuestion = q.copyWith(dependentOptions: updatedDependentOptions, setDependentOptionsNull: false);
      // print("DEBUG_UpdateMapping: Returning updated question. New dependentOptions in question: ${updatedQuestion.dependentOptions?.toMap()}");
      return updatedQuestion;
    });
  }
  void removeMappingForParentOption(String sectionId, String questionId, String parentOptionValue) { /* ... Implementasi Anda ... */ }

  void updateUnconditionalJump(String sectionId, String questionId, String? newTargetCompositeValue) {
    _updateQuestionProperty(sectionId, questionId, (q) {
      final targetToSet = (newTargetCompositeValue != null && newTargetCompositeValue.trim().isEmpty)
          ? null
          : newTargetCompositeValue;
      return q.copyWith(
        unconditionalJumpTarget: targetToSet,
        setUnconditionalJumpTargetNull: targetToSet == null,
      );
    });
  }

  Future<void> saveForm() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Get.theme.colorScheme.secondary, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('Konfirmasi Simpan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
          ],
        ),
        content: Text('Anda yakin ingin menyimpan perubahan pada form "${formTitle.value.trim().isNotEmpty ? formTitle.value.trim() : "Tanpa Judul"}"?', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(onPressed: Get.back, child: Text('Tidak', style: TextStyle(color: Colors.grey.shade800, fontSize: 14.5, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_alt_rounded, size: 18),
            style: ElevatedButton.styleFrom(backgroundColor: Get.theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))),
            onPressed: () { Get.back(); _executeSaveForm(); },
            label: const Text('Ya, Simpan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _executeSaveForm() async {
    if (formTitle.value.trim().isEmpty || _auth.currentUser == null) {
      Get.snackbar('Error', 'Judul form tidak boleh kosong dan Anda harus login.', snackPosition: SnackPosition.BOTTOM);
      isBusy.value = false; // Ensure isBusy is set to false on early return
      return;
    }

    isBusy.value = true;
    try {
      String formIdToSave = _currentFormId ?? _db.collection(_formsCollectionPath).doc().id;
      final DateTime createdAtValue = _originalCreatedAt ?? DateTime.now();
      final DateTime updatedAtValue = DateTime.now();

      String newVersion = _originalFormVersion ?? "1.0";
      if(isEditMode && _originalFormVersion != null){
        double currentV = double.tryParse(_originalFormVersion!) ?? 1.0;
        currentV += 0.1;
        // Format to one decimal place, e.g., 1.9 + 0.1 = 2.0, 1.0 + 0.1 = 1.1
        newVersion = ((currentV * 10).round() / 10).toStringAsFixed(1);
      }

      final formToSave = FormItem(
        id: formIdToSave,
        title: formTitle.value.trim(),
        description: formDescription.value.trim(),
        createdAt: createdAtValue,
        updatedAt: updatedAtValue,
        createdByUserId: _auth.currentUser!.uid,
        sections: sections.map((s) => s.cleanUpQuestionsBeforeSave()).toList(),
        formVersion: newVersion,
      );

      await _db.collection(_formsCollectionPath).doc(formIdToSave).set(formToSave.toFirestore());

      Get.snackbar(
        'Berhasil',
        isEditMode ? 'Form "${formToSave.title}" (v${formToSave.formVersion}) berhasil diperbarui!' : 'Form "${formToSave.title}" (v${formToSave.formVersion}) berhasil dibuat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600, colorText: Colors.white,
        duration: const Duration(seconds: 3), margin: const EdgeInsets.all(12), borderRadius: 10,
      );

      Timer(const Duration(milliseconds: 3200), _navigateBackIfPossible);

    } catch (e,s) {
      print("Error saving form: $e\n$s");
      Get.snackbar('Error Simpan Form', 'Gagal menyimpan: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      if(!isClosed) isBusy.value = false;
    }
    // Removed finally block for isBusy.value = false as _navigateBackIfPossible handles it,
    // and the catch block handles it for errors.
    // If _navigateBackIfPossible is not called due to an error before the Timer, isBusy needs to be reset.
    // The current structure with isBusy=false in the catch and _navigateBackIfPossible should cover it.
  }

  void _navigateBackIfPossible() {
    // Check if the controller is disposed before accessing Get properties or setting Rx value
    if (isClosed) return;

    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    if (Get.isOverlaysOpen) Get.back(closeOverlays: true); // Close any dialogs/bottomsheets

    // Only navigate back if the current route is the form builder page
    // This prevents accidental navigation if the user navigated away while saving.
    if (Get.currentRoute == AppRoutes.adminFormBuilder) { // Assuming AppRoutes.adminFormBuilder matches your route name
      Get.back();
    }

    isBusy.value = false;
  }
}