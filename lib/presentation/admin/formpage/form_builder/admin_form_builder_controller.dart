import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';
import '../../../../infrastructure/navigation/routes.dart';

/// [AdminFormBuilderController] adalah pengelola status (state manager) untuk fitur pembuatan dan pengeditan formulir admin.
/// 
/// Controller ini menangani logika kompleks seperti:
/// 1. **Struktur Form**: Manajemen section dan pertanyaan dengan berbagai tipe (teks, angka, dropdown, grid, dll).
/// 2. **Logika Kondisional**: Lompatan (jump) pertanyaan, ketergantungan opsi (dependent options), dan visibilitas berdasarkan kelompok usia.
/// 3. **Grup Berulang (Repeatable Groups)**: Kontroler grup berulang dinamis berdasarkan input angka.
/// 4. **Kelompok Usia**: Konfigurasi kelompok usia untuk klasifikasi otomatis data penduduk.
/// 5. **Hybrid Storage**: Menyimpan struktur form ke Firestore untuk digunakan oleh petugas lapangan.
class AdminFormBuilderController extends GetxController {
  /// Judul formulir.
  final RxString formTitle = ''.obs;
  /// Deskripsi atau instruksi formulir.
  final RxString formDescription = ''.obs;
  /// Periode aktif formulir (Format: yyyy-MM).
  final RxString selectedPeriod = ''.obs; 
  /// Apakah formulir otomatis diduplikasi setiap bulan.
  final RxBool autoDuplicateMonthly = false.obs; 
  /// Apakah periode sebelumnya otomatis dikunci saat periode baru aktif.
  final RxBool lockPreviousPeriod = true.obs; 
  /// Daftar seksi (sections) di dalam formulir.
  final RxList<FormSection> sections = <FormSection>[].obs;
  /// Konfigurasi kelompok usia yang berlaku pada formulir ini.
  final RxList<AgeGroupConfig> ageGroups = <AgeGroupConfig>[].obs;
  /// Status pemrosesan data (loading state).
  final RxBool isBusy = false.obs;

  /// Role admin yang sedang mengakses (global_admin, admin_desa, dll).
  final RxString userRole = ''.obs;
  /// ID desa admin.
  final RxString villageId = ''.obs;
  /// Nama desa admin.
  final RxString villageName = ''.obs;
  /// Daftar desa yang tersedia (untuk admin global).
  final RxList<VillageModel> allVillages = <VillageModel>[].obs;
  /// ID desa yang dikaitkan dengan formulir ini (null untuk form umum).
  final RxString selectedVillageIdForForm = ''.obs;
  /// Nama desa yang dikaitkan dengan formulir ini.
  final RxString selectedVillageNameForForm = ''.obs;

  final Uuid _uuid = const Uuid();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Menampilkan snackbar yang aman dari context null atau overlay issue.
  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    final context = Get.context;
    if (context == null) {
      debugPrint('Snackbar skipped: Get.context is null');
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('Snackbar skipped: Overlay is null');
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
      margin: margin,
      borderRadius: borderRadius,
    );
  }

  /// Peta kontroler ekspansi untuk setiap seksi (section) di UI.
  final Map<String, ExpansibleController> sectionExpansionControllers = {};

  String? _currentFormId;
  DateTime? _originalCreatedAt;
  String? _originalFormVersion;

  static const String _formsCollectionPath = 'adminForms';

  // --- Caches untuk Optimasi Performa UI ---
  List<Map<String, String>>? _allQuestionsCache;
  List<Map<String, String>>? _numericQuestionsCache;
  List<Map<String, String>>? _textOrNumericQuestionsCache;
  List<String>? _controlledGroupTagsCache;
  Map<String, FormQuestion>? _questionByIdCache;

  /// Mengecek apakah sedang dalam mode edit formulir lama.
  bool get isEditMode {
    return _currentFormId != null && _currentFormId!.isNotEmpty;
  }

  @override
  void onInit() {
    super.onInit();

    titleController.addListener(() {
      formTitle.value = titleController.text;
    });

    descriptionController.addListener(() {
      formDescription.value = descriptionController.text;
    });

    _fetchUserInfo().then((_) {
      final arguments = Get.arguments;

      if (arguments is String && arguments.isNotEmpty) {
        _currentFormId = arguments;

        debugPrint(
          'AdminFormBuilderController: Mode Edit untuk form ID: $_currentFormId',
        );

        _loadFormForEditing(_currentFormId!);
      } else {
        debugPrint(
          'AdminFormBuilderController: Mode Buat Form Baru. Argumen: $arguments',
        );

        _currentFormId = null;
        _initializeNewForm();
      }
    });
  }

  /// Mengambil informasi profil dan role admin yang sedang aktif.
  Future<void> _fetchUserInfo() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          userRole.value = data?['role'] as String? ?? 'user';
          villageId.value = data?['villageId'] as String? ?? '';
          villageName.value = data?['villageName'] as String? ?? '';

          if (userRole.value == 'global_admin' || userRole.value == 'admin') {
            final villageSnapshot = await _db.collection('villages').get();
            allVillages.assignAll(villageSnapshot.docs.map((doc) => VillageModel.fromFirestore(doc)).toList());
          } else if (userRole.value == 'admin_desa' || userRole.value == 'admindesa') {
            selectedVillageIdForForm.value = villageId.value;
            selectedVillageNameForForm.value = villageName.value;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user info: $e");
      }
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    _clearAllSectionExpansionControllers();
    _clearCaches();
    super.onClose();
  }

  /// Membersihkan kontroler UI seksi.
  void _clearAllSectionExpansionControllers() {
    for (final controller in sectionExpansionControllers.values) {
      controller.dispose();
    }
    sectionExpansionControllers.clear();
  }

  /// Membersihkan cache pertanyaan agar data UI tetap sinkron.
  void _clearCaches() {
    _allQuestionsCache = null;
    _numericQuestionsCache = null;
    _textOrNumericQuestionsCache = null;
    _controlledGroupTagsCache = null;
    _questionByIdCache = null;
  }

  /// Memperbarui data seksi pada indeks tertentu.
  void _setSectionAt(int index, FormSection section) {
    sections[index] = section;
    _clearCaches();
  }

  /// Inisialisasi formulir baru dengan data default.
  void _initializeNewForm() {
    formTitle.value = '';
    formDescription.value = '';
    selectedPeriod.value = DateFormat('yyyy-MM').format(DateTime.now());
    autoDuplicateMonthly.value = false;
    lockPreviousPeriod.value = true;

    titleController.text = '';
    descriptionController.text = '';

    _clearAllSectionExpansionControllers();
    _clearCaches();

    sections.clear();
    ageGroups.clear();

    addSection();

    _originalCreatedAt = null;
    _originalFormVersion = '1.0';
  }

  /// Memuat struktur formulir yang sudah ada dari Firestore untuk diedit.
  Future<void> _loadFormForEditing(String formId) async {
    isBusy.value = true;

    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
      await _db.collection(_formsCollectionPath).doc(formId).get();

      if (!docSnapshot.exists) {
        Get.snackbar(
          'Error',
          'Form dengan ID "$formId" tidak ditemukan. Membuat form baru.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade300,
          colorText: Colors.white,
        );

        _currentFormId = null;
        _initializeNewForm();
        return;
      }

      final FormItem formItem = FormItem.fromFirestore(docSnapshot);

      // VALIDASI AKSES UNTUK ADMIN DESA
      final bool isGeneralForm = formItem.villageId == null;
      if ((userRole.value == 'admin_desa' || userRole.value == 'admindesa') && isGeneralForm) {
        Get.snackbar(
          'Akses Ditolak',
          'Admin Desa tidak diperbolehkan mengedit Form Umum secara langsung.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        if (Navigator.canPop(Get.context!)) {
          Navigator.pop(Get.context!);
        }
        return;
      }

      formTitle.value = formItem.title;
      formDescription.value = formItem.description;
      selectedPeriod.value = formItem.period ?? DateFormat('yyyy-MM').format(DateTime.now());
      autoDuplicateMonthly.value = formItem.autoDuplicateMonthly;
      lockPreviousPeriod.value = formItem.lockPreviousPeriod;
      selectedVillageIdForForm.value = formItem.villageId ?? '';
      selectedVillageNameForForm.value = formItem.villageName ?? '';
      
      ageGroups.assignAll(formItem.ageGroups);

      titleController.text = formItem.title;
      descriptionController.text = formItem.description;

      _originalCreatedAt = formItem.createdAt;
      _originalFormVersion = formItem.formVersion ?? '1.0';

      _clearAllSectionExpansionControllers();
      _clearCaches();

      // KRITIKAL: Pastikan semua pertanyaan lama memiliki ID unik (UUID)
      // Ini memperbaiki masalah form lama yang tidak bisa menggunakan logika bersyarat
      final List<FormSection> loadedSections = formItem.sections.map((section) {
        final updatedQuestions = section.questions.map((q) {
          if (q.id.isEmpty) {
            return q.copyWith(id: _uuid.v4());
          }
          return q;
        }).toList();
        return section.copyWith(questions: updatedQuestions);
      }).toList();

      sections.assignAll(loadedSections);

      for (final FormSection section in loadedSections) {
        sectionExpansionControllers[section.id] = ExpansibleController();
      }

      debugPrint(
        'AdminFormBuilderController: Form "${formItem.title}" berhasil dimuat dengan ${loadedSections.length} section.',
      );
    } catch (e, s) {
      debugPrint('Error loading form: $e\n$s');

      Get.snackbar(
        'Error Memuat Form',
        'Gagal memuat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );

      _currentFormId = null;
      _initializeNewForm();
    } finally {
      if (!isClosed) {
        isBusy.value = false;
      }
    }
  }

  /// Menambah seksi (section) baru ke dalam formulir.
  void addSection() {
    final FormSection newSection = FormSection(
      id: _uuid.v4(),
      title: '',
      questions: [],
      isRepeatable: false,
    );

    sections.add(newSection);
    sectionExpansionControllers[newSection.id] = ExpansibleController();

    _clearCaches();
  }

  // --- LOGIKA AGE GROUP DINAMIS ---

  /// Menambah konfigurasi kelompok usia baru.
  void addAgeGroup() {
    final String newId = _uuid.v4();
    ageGroups.add(AgeGroupConfig(
      id: newId,
      key: 'kelompok_${ageGroups.length + 1}',
      label: 'Kelompok Baru ${ageGroups.length + 1}',
      minAge: 0,
      maxAge: 100,
      gender: 'Semua',
    ));
  }

  /// Memperbarui konfigurasi kelompok usia pada indeks tertentu.
  void updateAgeGroup(int index, AgeGroupConfig updated) {
    ageGroups[index] = updated;
  }

  /// Menghapus konfigurasi kelompok usia pada indeks tertentu.
  void removeAgeGroup(int index) {
    ageGroups.removeAt(index);
  }

  /// Memperbarui judul seksi tertentu.
  void updateSectionTitle(String sectionId, String title) {
    final int index = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (index != -1) {
      _setSectionAt(
        index,
        sections[index].copyWith(title: title),
      );
    }
  }

  /// Memperbarui deskripsi seksi tertentu.
  void updateSectionDescription(String sectionId, String description) {
    final int index = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (index != -1) {
      _setSectionAt(
        index,
        sections[index].copyWith(
          description: description,
          setDescriptionNull: description.isEmpty,
        ),
      );
    }
  }

  /// Mengatur properti perulangan (repeatability) untuk seksi tertentu.
  void updateSectionRepeatability({
    required String sectionId,
    required bool isRepeatable,
    String? triggerQuestionId,
    int? minRepeats,
    int? maxRepeats,
  }) {
    final int index = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (index == -1) {
      return;
    }

    final FormSection currentSection = sections[index];

    if (isRepeatable) {
      _setSectionAt(
        index,
        currentSection.copyWith(
          isRepeatable: true,
          repeatTriggerQuestionId: triggerQuestionId,
          setRepeatTriggerQuestionIdNull: triggerQuestionId == null,
          minRepeats: minRepeats ?? (triggerQuestionId != null ? 0 : 1),
          setMinRepeatsNull: false,
          maxRepeats: maxRepeats,
          setMaxRepeatsNull: maxRepeats == null,
        ),
      );
    } else {
      _setSectionAt(
        index,
        currentSection.copyWith(
          isRepeatable: false,
          repeatTriggerQuestionId: null,
          setRepeatTriggerQuestionIdNull: true,
          minRepeats: null,
          setMinRepeatsNull: true,
          maxRepeats: null,
          setMaxRepeatsNull: true,
        ),
      );
    }
  }

  /// Menghapus seksi berdasarkan ID-nya.
  void removeSection(String sectionId) {
    sectionExpansionControllers.remove(sectionId);

    sections.removeWhere((section) {
      return section.id == sectionId;
    });

    _clearCaches();

    if (sections.isEmpty) {
      addSection();
    }
  }

  /// Mengubah urutan seksi di dalam formulir.
  void reorderSections(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final FormSection item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    _clearCaches();
  }

  /// Menambah pertanyaan baru ke dalam seksi tertentu.
  void addQuestionToSection(String sectionId, QuestionType type) {
    final int sectionIndex = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (sectionIndex == -1) {
      return;
    }

    final FormSection currentSection = sections[sectionIndex];

    final bool questionHasOptions =
        type == QuestionType.multipleChoice ||
            type == QuestionType.checkboxes ||
            type == QuestionType.dropdown;

    final FormQuestion newQuestion = FormQuestion(
      id: _uuid.v4(),
      questionText: '',
      type: type,
      options: questionHasOptions
          ? [
        const QuestionOption(value: 'Opsi 1'),
      ]
          : [],
      validation: ValidationRule.empty(),
    );

    final List<FormQuestion> updatedQuestions =
    List<FormQuestion>.from(currentSection.questions);

    updatedQuestions.add(newQuestion);

    _setSectionAt(
      sectionIndex,
      currentSection.copyWith(
        questions: updatedQuestions,
      ),
    );
  }

  /// Fungsi internal untuk memperbarui properti spesifik dari suatu pertanyaan.
  void _updateQuestionProperty(
      String sectionId,
      String questionId,
      FormQuestion Function(FormQuestion currentQuestion) updater,
      ) {
    final int sectionIndex = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (sectionIndex == -1) {
      return;
    }

    final FormSection section = sections[sectionIndex];

    final int questionIndex = section.questions.indexWhere((question) {
      return question.id == questionId;
    });

    if (questionIndex == -1) {
      return;
    }

    final FormQuestion updatedQuestion = updater(
      section.questions[questionIndex],
    );

    final List<FormQuestion> newQuestionsList =
    List<FormQuestion>.from(section.questions);

    newQuestionsList[questionIndex] = updatedQuestion;

    _setSectionAt(
      sectionIndex,
      section.copyWith(
        questions: newQuestionsList,
      ),
    );
  }

  /// Mengatur apakah pertanyaan digunakan sebagai judul rangkuman data lapangan.
  void updateQuestionUseAsTitle(
      String sectionId,
      String questionId,
      bool useAsTitle,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(useAsTitle: useAsTitle);
    });
  }

  /// Mengatur apakah pertanyaan digunakan sebagai deskripsi rangkuman data lapangan.
  void updateQuestionUseAsDescription(
      String sectionId,
      String questionId,
      bool useAsDescription,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(useAsDescription: useAsDescription);
    });
  }

  /// Mengatur apakah pertanyaan bersifat hanya-baca (read-only).
  void updateQuestionIsReadOnly(
      String sectionId,
      String questionId,
      bool isReadOnly,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(isReadOnly: isReadOnly);
    });
  }

  /// Mengatur perhitungan usia otomatis berdasarkan input tanggal lahir.
  void updateQuestionAutoCalculateAge(
      String sectionId,
      String questionId,
      bool autoCalculate,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        autoCalculateAge: autoCalculate,
        ageTargetQuestionId: autoCalculate ? question.ageTargetQuestionId : null,
        setAgeTargetQuestionIdNull: !autoCalculate,
      );
    });
  }

  /// Menentukan ID pertanyaan target untuk hasil perhitungan usia.
  void updateQuestionAgeTargetQuestionId(
      String sectionId,
      String questionId,
      String? targetId,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        ageTargetQuestionId: targetId,
        setAgeTargetQuestionIdNull: targetId == null,
      );
    });
  }

  /// Mengatur klasifikasi kelompok usia otomatis berdasarkan usia yang terhitung.
  void updateQuestionAutoClassifyAgeGroup(
      String sectionId,
      String questionId,
      bool autoClassify,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(autoClassifyAgeGroup: autoClassify);
    });
  }

  /// Menentukan sumber data jenis kelamin untuk klasifikasi kelompok usia.
  void updateQuestionGenderSourceQuestionId(
      String sectionId,
      String questionId,
      String? genderSourceId,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        genderSourceQuestionId: genderSourceId,
        setGenderSourceQuestionIdNull: genderSourceId == null,
      );
    });
  }

  /// Mengatur apakah pertanyaan ini merupakan hasil kalkulasi rangkuman (summary computed).
  void updateQuestionIsComputedSummary(
      String sectionId,
      String questionId,
      bool isComputed,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(isComputedSummary: isComputed);
    });
  }

  /// Menentukan tipe kalkulasi rangkuman (misal: COUNT, SUM).
  void updateQuestionSummaryType(
      String sectionId,
      String questionId,
      String? summaryType,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        summaryType: summaryType,
        setSummaryTypeNull: summaryType == null,
      );
    });
  }

  /// Menentukan kunci grup untuk perhitungan rangkuman data.
  void updateQuestionSummaryGroupKey(
      String sectionId,
      String questionId,
      String? groupKey,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        summaryGroupKey: groupKey,
        setSummaryGroupKeyNull: groupKey == null,
      );
    });
  }

  /// Mengatur visibilitas pertanyaan berdasarkan klasifikasi kelompok usia.
  void updateQuestionIsConditionalByAgeGroup(
      String sectionId,
      String questionId,
      bool isConditional,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(isConditionalByAgeGroup: isConditional);
    });
  }

  /// Menentukan daftar kelompok usia yang diperbolehkan melihat pertanyaan ini.
  void updateQuestionVisibleWhenAgeGroups(
      String sectionId,
      String questionId,
      List<String> groups,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(visibleWhenAgeGroups: groups);
    });
  }

  /// Menentukan kunci grup rangkuman bersyarat (conditional summary).
  void updateQuestionConditionalSummaryGroupKey(
      String sectionId,
      String questionId,
      String? groupKey,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        conditionalSummaryGroupKey: groupKey,
        setConditionalSummaryGroupKeyNull: groupKey == null,
      );
    });
  }

  /// Memperbarui teks pertanyaan.
  void updateQuestionText(
      String sectionId,
      String questionId,
      String text,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(questionText: text);
    });
  }

  /// Mengatur apakah pertanyaan wajib diisi (required).
  void updateQuestionRequired(
      String sectionId,
      String questionId,
      bool isRequired,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(isRequired: isRequired);
    });
  }

  /// Mengatur keberadaan opsi "Lainnya" pada tipe pilihan.
  void updateQuestionHasOtherOption(
      String sectionId,
      String questionId,
      bool hasOther,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(hasOtherOption: hasOther);
    });
  }

  /// Memperbarui deskripsi bantuan untuk pertanyaan.
  void updateQuestionDescription(
      String sectionId,
      String questionId,
      String description,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        description: description,
        setDescriptionNull: description.isEmpty,
      );
    });
  }

  /// Menambah opsi baru untuk pertanyaan tipe pilihan.
  void addOption(String sectionId, String questionId) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final List<QuestionOption> newOptions =
      List<QuestionOption>.from(question.options);

      newOptions.add(
        QuestionOption(value: 'Opsi ${question.options.length + 1}'),
      );

      return question.copyWith(options: newOptions);
    });
  }

  /// Memperbarui nilai teks pada opsi tertentu.
  void updateOptionValue(
      String sectionId,
      String questionId,
      int optionIndex,
      String newValue,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (optionIndex < 0 || optionIndex >= question.options.length) {
        return question;
      }

      final List<QuestionOption> newOptions =
      List<QuestionOption>.from(question.options);

      newOptions[optionIndex] = newOptions[optionIndex].copyWith(
        value: newValue,
      );

      return question.copyWith(options: newOptions);
    });
  }

  /// Memperbarui deskripsi bantuan pada opsi tertentu.
  void updateOptionDescription(
      String sectionId,
      String questionId,
      int optionIndex,
      String newDescription,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (optionIndex < 0 || optionIndex >= question.options.length) {
        return question;
      }

      final List<QuestionOption> newOptions =
      List<QuestionOption>.from(question.options);

      newOptions[optionIndex] = newOptions[optionIndex].copyWith(
        description: newDescription,
        setDescriptionNull: newDescription.isEmpty,
      );

      return question.copyWith(options: newOptions);
    });
  }

  /// Menghapus opsi tertentu berdasarkan indeksnya.
  void removeOption(
      String sectionId,
      String questionId,
      int optionIndex,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (optionIndex < 0 || optionIndex >= question.options.length) {
        return question;
      }

      final List<QuestionOption> newOptions =
      List<QuestionOption>.from(question.options);

      newOptions.removeAt(optionIndex);

      return question.copyWith(options: newOptions);
    });
  }

  /// Menghapus pertanyaan dari seksi berdasarkan ID-nya.
  void removeQuestion(String sectionId, String questionId) {
    final int sectionIndex = sections.indexWhere((section) {
      return section.id == sectionId;
    });

    if (sectionIndex == -1) {
      return;
    }

    final FormSection section = sections[sectionIndex];

    final List<FormQuestion> updatedQuestions =
    List<FormQuestion>.from(section.questions);

    updatedQuestions.removeWhere((question) {
      return question.id == questionId;
    });

    _setSectionAt(
      sectionIndex,
      section.copyWith(
        questions: updatedQuestions,
      ),
    );
  }

  /// Mengubah urutan pertanyaan di dalam suatu seksi.
  void reorderQuestions(String sectionId, int oldIndex, int newIndex) {
    final int sectionIndex = sections.indexWhere((section) => section.id == sectionId);
    if (sectionIndex == -1) return;

    final FormSection section = sections[sectionIndex];
    final List<FormQuestion> updatedQuestions = List<FormQuestion>.from(section.questions);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final FormQuestion item = updatedQuestions.removeAt(oldIndex);
    updatedQuestions.insert(newIndex, item);

    _setSectionAt(
      sectionIndex,
      section.copyWith(questions: updatedQuestions),
    );
  }

  /// Memperbarui aturan validasi untuk suatu pertanyaan.
  void updateValidation(
      String sectionId,
      String questionId,
      ValidationRule? newValidationRuleFromUI,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final bool shouldSetToEmpty = newValidationRuleFromUI == null ||
          newValidationRuleFromUI.isEffectivelyEmpty;

      return question.copyWith(
        validation: shouldSetToEmpty
            ? ValidationRule.empty()
            : newValidationRuleFromUI,
      );
    });
  }

  /// Menambah logika lompatan bersyarat (conditional jump) ke pertanyaan ini.
  void addConditionalJump(
      String sectionId,
      String questionId,
      ConditionalJump jump,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final List<ConditionalJump> jumps =
      List<ConditionalJump>.from(question.conditionalJumps);

      jumps.add(jump);

      return question.copyWith(conditionalJumps: jumps);
    });
  }

  /// Menghapus logika lompatan bersyarat berdasarkan ID targetnya.
  void removeConditionalJump(
      String sectionId,
      String questionId,
      String targetIdToRemove,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final List<ConditionalJump> jumps =
      List<ConditionalJump>.from(question.conditionalJumps);

      jumps.removeWhere((jump) {
        return jump.jumpToQuestionId == targetIdToRemove ||
            jump.jumpToSectionId == targetIdToRemove;
      });

      return question.copyWith(conditionalJumps: jumps);
    });
  }

  /// Mengatur apakah pertanyaan bersifat dapat diulang (repeatable) dengan jumlah tertentu.
  void updateQuestionRepeatable(
      String sectionId,
      String questionId,
      bool repeatable, {
        int? count,
      }) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      return question.copyWith(
        repeatable: repeatable,
        repeatCount: repeatable ? (count ?? question.repeatCount) : null,
        setRepeatCountNull: !repeatable,
      );
    });
  }

  /// Mendapatkan daftar pertanyaan angka yang berpotensi menjadi kontroler grup berulang.
  List<FormQuestion> getPotentialRepeatableGroupControllers(
      String currentSectionId,
      String currentQuestionId,
      ) {
    final List<FormQuestion> controllersList = [];

    for (final FormSection section in sections) {
      for (final FormQuestion question in section.questions) {
        if (question.id == currentQuestionId) {
          continue;
        }

        final bool isNumber = question.type == QuestionType.number;
        final bool hasNoGroup = question.belongsToGroupTag == null ||
            question.belongsToGroupTag!.isEmpty;

        if (isNumber && hasNoGroup) {
          controllersList.add(question);
        }
      }
    }

    return controllersList;
  }

  /// Mendapatkan daftar tag grup yang sedang dikontrol oleh pertanyaan kontroler grup berulang.
  List<String> getAvailableControlledGroupTags(
      String currentSectionId,
      String currentQuestionId,
      ) {
    if (_controlledGroupTagsCache != null) {
      return _controlledGroupTagsCache!;
    }

    final Set<String> tags = {};

    for (final FormSection section in sections) {
      for (final FormQuestion question in section.questions) {
        final bool hasControlledGroup =
            question.isRepeatableGroupController &&
                question.controlledGroupTag != null &&
                question.controlledGroupTag!.isNotEmpty;

        if (hasControlledGroup) {
          tags.add(question.controlledGroupTag!);
        }
      }
    }

    final List<String> result = tags.toList();
    result.sort();

    _controlledGroupTagsCache = result;

    return result;
  }

  /// Mengatur pertanyaan sebagai kontroler grup berulang dengan tag tertentu.
  void updateQuestionAsRepeatableGroupController(
      String sectionId,
      String questionId,
      bool isController,
      String? groupTag,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (isController) {
        return question.copyWith(
          isRepeatableGroupController: true,
          controlledGroupTag: groupTag?.trim(),
          setControlledGroupTagNull:
          groupTag == null || groupTag.trim().isEmpty,
          belongsToGroupTag: null,
          setBelongsToGroupTagNull: true,
        );
      }

      return question.copyWith(
        isRepeatableGroupController: false,
        controlledGroupTag: null,
        setControlledGroupTagNull: true,
      );
    });
  }

  /// Mengatur pertanyaan agar menjadi anggota dari grup berulang tertentu berdasarkan tag.
  void updateQuestionBelongsToGroupTag(
      String sectionId,
      String questionId,
      String? groupTag,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (groupTag != null && groupTag.isNotEmpty) {
        return question.copyWith(
          belongsToGroupTag: groupTag,
          setBelongsToGroupTagNull: false,
          isRepeatableGroupController: false,
          controlledGroupTag: null,
          setControlledGroupTagNull: true,
        );
      }

      return question.copyWith(
        belongsToGroupTag: null,
        setBelongsToGroupTagNull: true,
      );
    });
  }

  /// Fungsi internal untuk memperbarui label pada komponen tipe Grid.
  void _updateGridLabels(
      String sectionId,
      String questionId,
      List<String> newLabels,
      String labelType,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      switch (labelType) {
        case 'rows':
          return question.copyWith(gridRowLabels: newLabels);
        case 'cols':
          return question.copyWith(gridColumnLabels: newLabels);
        case 'subCols':
          return question.copyWith(gridSubColumnLabels: newLabels);
        default:
          return question;
      }
    });
  }

  /// Memperbarui label baris Grid dari string yang dipisahkan koma.
  void updateGridRowLabelsFromString(
      String sectionId,
      String questionId,
      String commaSeparatedLabels,
      ) {
    final List<String> labels = commaSeparatedLabels
        .split(',')
        .map((value) {
      return value.trim();
    })
        .where((value) {
      return value.isNotEmpty;
    })
        .toList();

    _updateGridLabels(sectionId, questionId, labels, 'rows');
  }

  /// Memperbarui label kolom Grid dari string yang dipisahkan koma.
  void updateGridColumnLabelsFromString(
      String sectionId,
      String questionId,
      String commaSeparatedLabels,
      ) {
    final List<String> labels = commaSeparatedLabels
        .split(',')
        .map((value) {
      return value.trim();
    })
        .where((value) {
      return value.isNotEmpty;
    })
        .toList();

    _updateGridLabels(sectionId, questionId, labels, 'cols');
  }

  /// Memperbarui label sub-kolom Grid dari string yang dipisahkan koma.
  void updateGridSubColumnLabelsFromString(
      String sectionId,
      String questionId,
      String commaSeparatedLabels,
      ) {
    final List<String> labels = commaSeparatedLabels
        .split(',')
        .map((value) {
      return value.trim();
    })
        .where((value) {
      return value.isNotEmpty;
    })
        .toList();

    _updateGridLabels(sectionId, questionId, labels, 'subCols');
  }

  /// Membangun cache pertanyaan secara internal untuk optimasi pencarian di UI.
  void _buildQuestionCachesIfNeeded() {
    if (_allQuestionsCache != null &&
        _numericQuestionsCache != null &&
        _textOrNumericQuestionsCache != null &&
        _questionByIdCache != null) {
      return;
    }

    final List<Map<String, String>> allQuestions = [];
    final List<Map<String, String>> numericQuestions = [];
    final List<Map<String, String>> textOrNumericQuestions = [];
    final Map<String, FormQuestion> questionById = {};

    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final FormSection section = sections[sectionIndex];

      for (int questionIndex = 0;
      questionIndex < section.questions.length;
      questionIndex++) {
        final FormQuestion question = section.questions[questionIndex];

        questionById[question.id] = question;

        final String questionText = question.questionText.isNotEmpty
            ? question.questionText.length > 35
            ? '${question.questionText.substring(0, 32)}...'
            : question.questionText
            : '(Tanpa Teks)';

        final Map<String, String> questionMap = {
          'id': question.id,
          'text': questionText,
        };

        allQuestions.add(questionMap);

        if (question.type == QuestionType.number) {
          numericQuestions.add(questionMap);
        }

        if (question.type == QuestionType.number || question.type == QuestionType.text) {
          textOrNumericQuestions.add(questionMap);
        }
      }
    }

    _allQuestionsCache = allQuestions;
    _numericQuestionsCache = numericQuestions;
    _textOrNumericQuestionsCache = textOrNumericQuestions;
    _questionByIdCache = questionById;
  }

  /// Mendapatkan seluruh pertanyaan yang tersedia untuk dikaitkan (linking) dalam logika lompatan atau dependensi.
  List<Map<String, String>> getAllQuestionsForLinking({
    String? currentQuestionIdToExclude,
    bool numericOnly = false,
    bool textOrNumericOnly = false,
  }) {
    _buildQuestionCachesIfNeeded();

    List<Map<String, String>> source;
    if (numericOnly) {
      source = _numericQuestionsCache!;
    } else if (textOrNumericOnly) {
      source = _textOrNumericQuestionsCache!;
    } else {
      source = _allQuestionsCache!;
    }

    if (currentQuestionIdToExclude == null ||
        currentQuestionIdToExclude.isEmpty) {
      return List<Map<String, String>>.from(source);
    }

    return source.where((questionMap) {
      return questionMap['id'] != currentQuestionIdToExclude;
    }).toList();
  }

  /// Mendapatkan daftar pertanyaan induk (parent) potensial untuk logika opsi bergantung (dependent options).
  List<FormQuestion> getPotentialParentQuestions(
      String? currentSectionIdToExclude,
      String currentQuestionIdToExclude,
      ) {
    final List<FormQuestion> potentialParents = [];

    for (final FormSection section in sections) {
      for (final FormQuestion question in section.questions) {
        if (question.id == currentQuestionIdToExclude) {
          continue;
        }

        final bool isOptionQuestion = question.type == QuestionType.dropdown ||
            question.type == QuestionType.multipleChoice ||
            question.type == QuestionType.checkboxes;

        if (isOptionQuestion && question.options.isNotEmpty) {
          potentialParents.add(question);
        }
      }
    }

    return potentialParents;
  }

  /// Mencari data objek pertanyaan berdasarkan ID-nya.
  FormQuestion? findQuestionById(String? questionId) {
    if (questionId == null || questionId.isEmpty) {
      return null;
    }

    _buildQuestionCachesIfNeeded();

    return _questionByIdCache?[questionId];
  }

  /// Menetapkan pertanyaan induk untuk konfigurasi opsi bergantung (dependent options).
  void setParentQuestionForDependency(
      String sectionId,
      String questionId,
      String? newParentQuestionId,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      if (newParentQuestionId == null || newParentQuestionId.isEmpty) {
        return question.copyWith(
          dependentOptions: null,
          setDependentOptionsNull: true,
        );
      }

      final DependentOptionsConfig? currentConfig =
          question.dependentOptions;

      final DependentOptionsConfig newConfig =
      currentConfig != null &&
          currentConfig.parentQuestionId == newParentQuestionId
          ? currentConfig.copyWith(parentQuestionId: newParentQuestionId)
          : DependentOptionsConfig(
        parentQuestionId: newParentQuestionId,
        optionMapping: {},
      );

      return question.copyWith(
        dependentOptions: newConfig,
        setDependentOptionsNull: false,
      );
    });
  }

  /// Memperbarui pemetaan (mapping) opsi anak berdasarkan pilihan pada opsi induk.
  void updateMappingForParentOption(
      String sectionId,
      String questionId,
      String parentOptionValue,
      List<String> childOptions,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final DependentOptionsConfig? existingConfig =
          question.dependentOptions;

      if (existingConfig == null ||
          existingConfig.parentQuestionId.isEmpty) {
        return question;
      }

      final Map<String, List<String>> newMapping =
      Map<String, List<String>>.from(existingConfig.optionMapping);

      newMapping[parentOptionValue] = childOptions;

      final DependentOptionsConfig updatedConfig =
      existingConfig.copyWith(optionMapping: newMapping);

      return question.copyWith(
        dependentOptions: updatedConfig,
        setDependentOptionsNull: false,
      );
    });
  }

  /// Menghapus pemetaan opsi untuk nilai induk tertentu.
  void removeMappingForParentOption(
      String sectionId,
      String questionId,
      String parentOptionValue,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final DependentOptionsConfig? existingConfig =
          question.dependentOptions;

      if (existingConfig == null) {
        return question;
      }

      final Map<String, List<String>> newMapping =
      Map<String, List<String>>.from(existingConfig.optionMapping);

      newMapping.remove(parentOptionValue);

      final DependentOptionsConfig updatedConfig =
      existingConfig.copyWith(optionMapping: newMapping);

      return question.copyWith(
        dependentOptions: updatedConfig,
        setDependentOptionsNull: false,
      );
    });
  }

  /// Memperbarui target lompatan tanpa syarat (unconditional jump) untuk pertanyaan ini.
  void updateUnconditionalJump(
      String sectionId,
      String questionId,
      String? newTargetCompositeValue,
      ) {
    _updateQuestionProperty(sectionId, questionId, (question) {
      final String? targetToSet = newTargetCompositeValue != null &&
          newTargetCompositeValue.trim().isEmpty
          ? null
          : newTargetCompositeValue;

      return question.copyWith(
        unconditionalJumpTarget: targetToSet,
        setUnconditionalJumpTargetNull: targetToSet == null,
      );
    });
  }

  /// Menampilkan dialog konfirmasi sebelum menyimpan formulir ke Firestore.
  Future<void> saveForm() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Get.theme.colorScheme.secondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Simpan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menyimpan perubahan pada form "${formTitle.value.trim().isNotEmpty ? formTitle.value.trim() : "Tanpa Judul"}"?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(Get.overlayContext!).canPop()) {
                Navigator.of(Get.overlayContext!).pop();
              }
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
            icon: const Icon(
              Icons.save_alt_rounded,
              size: 18,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {
              if (Navigator.of(Get.overlayContext!).canPop()) {
                Navigator.of(Get.overlayContext!).pop();
              }
              _executeSaveForm();
            },
            label: const Text(
              'Ya, Simpan',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Keluar dari halaman pembangun formulir dengan aman, menangani overlay dan context.
  void _safePopPage() {
    try {
      if (Get.isOverlaysOpen) {
        Get.back(closeOverlays: true);
      }
      
      Future.delayed(const Duration(milliseconds: 200), () {
        if (Get.context != null && Navigator.canPop(Get.context!)) {
          Navigator.of(Get.context!).pop();
        } else {
          Get.back();
        }
      });
    } catch (e) {
      debugPrint("Error popping admin page: $e");
      Get.back();
    }
  }

  /// Eksekusi penyimpanan formulir ke koleksi `adminForms` di Firestore.
  /// 
  /// Menangani pemberian ID otomatis (jika baru), manajemen versi otomatis (+0.1),
  /// pembersihan pertanyaan (cleaning) sebelum simpan, dan penentuan wilayah desa.
  Future<void> _executeSaveForm() async {
    if (formTitle.value.trim().isEmpty || _auth.currentUser == null) {
      showSafeSnackbar(
        title: 'Error',
        message: 'Judul form tidak boleh kosong dan Anda harus login.',
      );

      if (!isClosed) {
        isBusy.value = false;
      }

      return;
    }

    isBusy.value = true;

    try {
      final String formIdToSave =
          _currentFormId ?? _db.collection(_formsCollectionPath).doc().id;

      final DateTime createdAtValue = _originalCreatedAt ?? DateTime.now();

      String newVersion = _originalFormVersion ?? '1.0';

      if (isEditMode && _originalFormVersion != null) {
        double currentVersion = double.tryParse(_originalFormVersion!) ?? 1.0;
        currentVersion += 0.1;
        newVersion =
            ((currentVersion * 10).round() / 10).toStringAsFixed(1);
      }

      final FormItem formToSave = FormItem(
        id: formIdToSave,
        title: formTitle.value.trim(),
        description: formDescription.value.trim(),
        period: selectedPeriod.value,
        villageId: selectedVillageIdForForm.value.isNotEmpty ? selectedVillageIdForForm.value : null,
        villageName: selectedVillageNameForForm.value.isNotEmpty ? selectedVillageNameForForm.value : null,
        createdAt: createdAtValue,
        updatedAt: DateTime.now(),
        createdByUserId: _auth.currentUser!.uid,
        sections: sections.map((section) {
          return section.cleanUpQuestionsBeforeSave();
        }).toList(),
        formVersion: newVersion,
        autoDuplicateMonthly: autoDuplicateMonthly.value,
        lockPreviousPeriod: lockPreviousPeriod.value,
        ageGroups: ageGroups,
      );

      await _db.collection(_formsCollectionPath).doc(formIdToSave).set(
        formToSave.toFirestore(),
      );

      showSafeSnackbar(
        title: 'Berhasil',
        message: isEditMode
            ? 'Form "${formToSave.title}" (v${formToSave.formVersion}) berhasil diperbarui!'
            : 'Form "${formToSave.title}" (v${formToSave.formVersion}) berhasil dibuat!',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(milliseconds: 1200),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );

      await Future.delayed(const Duration(milliseconds: 800));

      _safePopPage();
    } catch (e, s) {
      debugPrint('Error saving form: $e\n$s');

      showSafeSnackbar(
        title: 'Error Simpan Form',
        message: 'Gagal menyimpan: ${e.toString()}',
      );

      if (!isClosed) {
        isBusy.value = false;
      }
    }
  }

  /// Menavigasi kembali ke halaman sebelumnya jika memungkinkan.
  void _navigateBackIfPossible() {
    if (isClosed) {
      return;
    }

    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    if (Get.isOverlaysOpen) {
      Get.back(closeOverlays: true);
    }

    if (Get.currentRoute == AppRoutes.adminFormBuilder) {
      Get.back();
    }

    isBusy.value = false;
  }
}