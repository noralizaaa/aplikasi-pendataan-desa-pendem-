// File: input_user_controller.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert'; // Tambahan untuk JSON
import 'package:http/http.dart' as http; // Tambahan untuk Local API
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Pastikan path ini benar
import './input_user_model.dart'; // Pastikan path ini benar
import 'package:aplikasi_pendataan_desa/domain/village/village_model.dart';

enum FormItemType { header, sectionHeader, question, groupInstance, divider, sectionFooter }

/// [FlattenedFormItem] merepresentasikan satu baris item yang akan dirender pada list formulir.
/// 
/// Digunakan untuk meratakan struktur formulir yang kompleks (sections -> questions -> group instances)
/// menjadi satu daftar linier agar efisien saat dirender menggunakan [ListView].
class FlattenedFormItem {
  /// Jenis tipe item (header, section, pertanyaan, dsb).
  final FormItemType type;
  /// Referensi seksi jika tipe adalah [sectionHeader] atau [sectionFooter].
  final FormSection? section;
  /// Referensi pertanyaan jika tipe adalah [question].
  final FormQuestion? question;
  /// Tag grup jika pertanyaan ini merupakan anggota dari grup berulang.
  final String? groupTag;
  /// ID unik item untuk keperluan key di Flutter.
  final String id;

  FlattenedFormItem({
    required this.type,
    this.section,
    this.question,
    this.groupTag,
    required this.id,
  });
}

/// [InputUserController] adalah otak utama di balik pengisian formulir oleh Petugas (User).
/// 
/// Controller ini mengelola logika yang sangat kompleks, meliputi:
/// 1. **Visibilitas Dinamis**: Menampilkan/menyembunyikan pertanyaan berdasarkan jawaban sebelumnya.
/// 2. **Skip Logic & Jumps**: Melompati pertanyaan atau seksi tertentu sesuai aturan admin.
/// 3. **Repeatable Groups**: Menangani grup pertanyaan yang diulang berdasarkan input angka (misal: Daftar Anggota Keluarga).
/// 4. **Auto-Calculation**: Penghitungan usia otomatis dan klasifikasi kelompok usia real-time.
/// 5. **Hybrid Connectivity**: Mendukung penyimpanan data ke Firebase (Cloud) atau Server Lokal Desa (Local API).
/// 6. **Resume/Edit Mode**: Memungkinkan petugas melanjutkan isian yang tersimpan sebagai draf.
class InputUserController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Menandakan proses unggah gambar sedang berlangsung.
  final RxBool isUploadingImage = false.obs;
  /// Menandakan proses pengambilan lokasi GPS sedang berlangsung.
  final RxBool isGettingLocation = false.obs;

  /// Map untuk menyimpan file gambar sementara sebelum diunggah.
  final RxMap<String, File> selectedImageFiles = <String, File>{}.obs;

  static const String _kOtherOptionValue = '__other_option_value__';

  /// Status loading data formulir atau isian.
  final RxBool isLoading = false.obs;
  /// ID formulir yang sedang diisi.
  final RxString formId = ''.obs;
  /// Objek struktur formulir yang dimuat dari server.
  final Rx<FormItem?> loadedForm = Rx<FormItem?>(null);
  /// Pesan error jika terjadi kendala saat memuat data.
  final RxString errorMessage = ''.obs;

  /// ID isian (submission) jika sedang dalam mode edit.
  final RxString submissionId = ''.obs;
  /// Periode pendataan aktif (Format: YYYY-MM).
  final RxString currentPeriod = ''.obs;

  /// Mengecek apakah sedang dalam mode edit isian yang sudah ada.
  bool get isEditMode => submissionId.value.isNotEmpty;
  /// Data isian asli yang dimuat untuk mode edit.
  final Rx<FormSubmission?> loadedSubmission = Rx<FormSubmission?>(null);
  /// Menandakan formulir dalam status terkunci (tidak bisa diedit).
  final RxBool isLockedMode = false.obs;
  /// Menandakan tampilan hanya-baca (untuk Admin Monitoring).
  final RxBool isReadOnlyView = false.obs; // Tambahan untuk Admin RT

  /// Map jawaban utama user (Global/Mandiri).
  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  /// Map jawaban untuk pertanyaan di dalam grup berulang [questionId -> index -> answer].
  final RxMap<String, RxMap<int, dynamic>> repeatableGroupAnswers =
      <String, RxMap<int, dynamic>>{}.obs;

  /// Jawaban teks untuk opsi "Lainnya" pada pertanyaan global.
  final RxMap<String, String> userOtherAnswers = <String, String>{}.obs;
  /// Jawaban teks untuk opsi "Lainnya" pada pertanyaan grup berulang.
  final RxMap<String, RxMap<int, String>> repeatableGroupOtherAnswers =
      <String, RxMap<int, String>>{}.obs;

  /// Jumlah pengulangan aktif untuk setiap tag grup.
  final RxMap<String, int> repeatableGroupCounts = <String, int>{}.obs;
  /// Status visibilitas setiap pertanyaan (termasuk index-aware).
  final RxMap<String, bool> questionVisibility = <String, bool>{}.obs;

  /// Index aktif yang sedang ditampilkan untuk grup tertentu (untuk navigasi slider).
  final RxMap<String, int> activeRepeatIndexForGroup = <String, int>{}.obs;

  /// Data rekapitulasi kelompok usia (diperbarui real-time saat mengisi).
  final RxMap<String, RxMap<String, int>> summaryAgeGroups = <String, RxMap<String, int>>{}.obs;

  /// Daftar seluruh desa yang tersedia.
  final RxList<VillageModel> allVillages = <VillageModel>[].obs;
  /// ID desa terpilih untuk isian ini.
  final RxString selectedVillageId = ''.obs;
  /// Role petugas yang sedang mengisi.
  final RxString userRole = 'user'.obs;
  /// ID desa petugas.
  final RxString userVillageId = ''.obs;
  /// Wilayah RT petugas.
  final RxString userRt = ''.obs; 
  /// Wilayah RW petugas.
  final RxString userRw = ''.obs; 

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<String> _allQuestionIdsInOrder = [];
  final Map<String, int> _questionIndexMap = {}; 
  final Map<String, FormQuestion> _questionCache = {};

  /// ID seksi yang sedang dibuka/ekspansi.
  final RxString expandedSectionId = ''.obs;

  /// Daftar item yang telah diratakan untuk ditampilkan di UI.
  final RxList<FlattenedFormItem> flattenedItems = <FlattenedFormItem>[].obs;
  /// Jumlah item yang saat ini terlihat (untuk fitur Lazy Loading).
  final RxInt visibleItemCount = 20.obs; 
  static const int _lazyLoadBatchSize = 20;

  /// Menandakan adanya perubahan data yang belum disimpan.
  final RxBool hasUnsavedChanges = false.obs;
  final RxBool isExitDialogOpen = false.obs;
  /// Pesan status saat proses loading/saving.
  final RxString loadingMessage = ''.obs;

  // --- UNIFIED VISIBILITY HELPERS ---

  /// Mendapatkan key unik untuk visibilitas, mendukung index pada grup berulang.
  String _getVisKey(String qId, int? index) {
    if (index == null) return qId;
    return '${qId}_idx_$index';
  }

  /// Mengecek apakah suatu pertanyaan seharusnya terlihat di UI.
  /// 
  /// Jika pertanyaan berada dalam grup, [index] harus diberikan.
  bool isVisible(String qId, {int? index}) {
    final cleanQId = qId.replaceFirst('question_', '');
    final q = findQuestionById(cleanQId);
    
    // Jika pertanyaan adalah global (bukan anggota grup), abaikan index
    if (q != null && (q.belongsToGroupTag == null || q.belongsToGroupTag!.isEmpty)) {
      return questionVisibility[cleanQId] ?? false;
    }
    
    // Jika index null tapi pertanyaan ada dalam grup, cek apakah ada satu pun instansi yang visible
    if (index == null && q != null && q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
      final count = repeatableGroupCounts[q.belongsToGroupTag!] ?? 0;
      for (int i = 0; i < count; i++) {
        if (questionVisibility[_getVisKey(cleanQId, i)] == true) return true;
      }
      // Fallback: Jika belum ada instansi tapi key global ada (biasanya untuk initial state)
      return questionVisibility[cleanQId] ?? false;
    }
    
    // Untuk pertanyaan grup, gunakan index
    return questionVisibility[_getVisKey(cleanQId, index)] ?? false;
  }

  /// Mengatur status visibilitas suatu pertanyaan.
  void setVisible(String qId, bool value, {int? index}) {
    final cleanQId = qId.replaceFirst('question_', '');
    final q = findQuestionById(cleanQId);
    
    // Jika pertanyaan adalah global, simpan di key global
    if (q != null && (q.belongsToGroupTag == null || q.belongsToGroupTag!.isEmpty)) {
      questionVisibility[cleanQId] = value;
    } else if (q != null && q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
      if (index != null) {
        questionVisibility[_getVisKey(cleanQId, index)] = value;
      } else {
        // Jika pertanyaan grup tapi tidak ada index, terapkan ke semua yang ada
        final count = repeatableGroupCounts[q.belongsToGroupTag!] ?? 0;
        for (int i = 0; i < count; i++) {
          questionVisibility[_getVisKey(cleanQId, i)] = value;
        }
      }
    } else {
      questionVisibility[_getVisKey(cleanQId, index)] = value;
    }
  }

  void showSafeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
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
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  /// Mengambil daftar ID pertanyaan selanjutnya berdasarkan opsi yang dipilih.
  List<String> getNextQuestionIds(QuestionOption option) {
    final ids = <String>[];

    if (option.nextQuestionId != null &&
        option.nextQuestionId!.trim().isNotEmpty) {
      // Normalisasi: pastikan tidak ada prefix question_ saat pencarian di cache
      ids.add(option.nextQuestionId!.trim().replaceFirst('question_', ''));
    }

    if (option.nextQuestionIds.isNotEmpty) {
      ids.addAll(
        option.nextQuestionIds
            .map((id) => id.trim().replaceFirst('question_', ''))
            .where((id) => id.isNotEmpty),
      );
    }

    return ids.toSet().toList();
  }

  // Helper mencari Section ID dari sebuah Pertanyaan
  String? getSectionIdByQuestionId(String qId) {
    if (loadedForm.value == null) return null;
    for (final section in loadedForm.value!.sections) {
      if (section.questions.any((q) => q.id == qId)) return section.id;
    }
    return null;
  }

  // Deteksi apakah pertanyaan adalah Induk/Pemicu (Wajib Muncul Awal)
  bool isParentQuestion(String questionId) {
    final q = findQuestionById(questionId);
    if (q == null) return false;

    // 1. Controller grup berulang
    if (q.isRepeatableGroupController) return true;
    
    // 2. Punya aturan lompatan (Conditional Jumps)
    if (q.conditionalJumps.isNotEmpty) return true;
    
    // 3. Punya Opsi dengan Pertanyaan Lanjutan
    for (final opt in q.options) {
      if (getNextQuestionIds(opt).isNotEmpty) return true;
    }

    // 4. Menjadi sumber data untuk pertanyaan lain (Dependent Options)
    bool isSourceForOthers = _questionCache.values.any((otherQ) => 
        otherQ.dependentOptions?.parentQuestionId == questionId);
    if (isSourceForOthers) return true;

    // 5. Menjadi sumber perhitungan umur atau gender summary
    if (q.autoCalculateAge || q.autoClassifyAgeGroup) return true;

    return false;
  }

  bool isConditionalChild(FormQuestion q) {
    final currentIdx = _questionIndexMap[q.id] ?? -1;
    if (currentIdx == -1) return false;

    // 1. Berdasarkan Kelompok Usia
    if (q.isConditionalByAgeGroup) return true;
    
    // 2. Berdasarkan pilihan parent (Dependent Options)
    if (q.dependentOptions != null && q.dependentOptions!.parentQuestionId.isNotEmpty) {
      final parentId = q.dependentOptions!.parentQuestionId.replaceFirst('question_', '');
      final parentIdx = _questionIndexMap[parentId] ?? -1;
      if (parentIdx != -1 && parentIdx < currentIdx) return true;
    }
    
    final cleanQId = q.id.replaceFirst('question_', '');

    // 3. Menjadi target lompatan (Jump) dari pertanyaan lain SEBELUMNYA
    bool isTargetOfJump = _questionCache.values.any((otherQ) {
      final otherIdx = _questionIndexMap[otherQ.id] ?? -1;
      if (otherIdx == -1 || otherIdx >= currentIdx) return false;

      return otherQ.conditionalJumps.any((j) {
        final targetId = j.jumpToQuestionId.replaceFirst('question_', '');
        return targetId == cleanQId;
      });
    });
    if (isTargetOfJump) return true;

    // 4. Menjadi target branching (Opsi) dari pertanyaan lain SEBELUMNYA
    bool isTargetOfOption = _questionCache.values.any((otherQ) {
      final otherIdx = _questionIndexMap[otherQ.id] ?? -1;
      if (otherIdx == -1 || otherIdx >= currentIdx) return false;

      return otherQ.options.any((opt) {
        final children = getNextQuestionIds(opt);
        return children.contains(cleanQId);
      });
    });
    
    return isTargetOfOption;
  }

  bool isSameGroup(FormQuestion a, FormQuestion b) {
    return a.belongsToGroupTag != null && 
           a.belongsToGroupTag!.isNotEmpty && 
           a.belongsToGroupTag == b.belongsToGroupTag;
  }

  /// Menginisialisasi status visibilitas seluruh pertanyaan saat formulir dibuka.
  /// 
  /// Menyembunyikan pertanyaan bersyarat dan mengevaluasi logika isian yang sudah ada.
  void initializeVisibility() {
    questionVisibility.clear();
    if (loadedForm.value == null) return;

    // 1. Set Visibilitas Dasar (Tampilkan yang bukan anak, sembunyikan yang anak)
    for (final section in loadedForm.value!.sections) {
      for (final q in section.questions) {
        bool initialVal = !isConditionalChild(q);

        if (q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
          final count = repeatableGroupCounts[q.belongsToGroupTag!] ?? 0;
          for (int i = 0; i < count; i++) {
            setVisible(q.id, initialVal, index: i);
          }
        } else {
          setVisible(q.id, initialVal);
        }
      }
    }
    
    // 2. Evaluasi Ulang Seluruh Logika Berdasarkan Jawaban yang Sudah Ada (PENTING untuk Edit Mode)
    _evaluateAllLogicsSequentially();

    questionVisibility.refresh();
    updateFlattenedItemsDebounced();
  }

  /// Menjalankan evaluasi seluruh logika secara berurutan sesuai struktur form
  void _evaluateAllLogicsSequentially() {
    if (_allQuestionIdsInOrder.isEmpty) return;

    for (var qId in _allQuestionIdsInOrder) {
      final q = findQuestionById(qId);
      if (q == null) continue;

      // Jika pertanyaan ini memiliki logika (pemicu), evaluasi pengaruhnya ke anak-anaknya
      bool hasLogic = q.options.any((opt) => getNextQuestionIds(opt).isNotEmpty) || 
                      q.conditionalJumps.isNotEmpty || 
                      q.isRepeatableGroupController;

      if (!hasLogic) continue;

      if (q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
        final count = repeatableGroupCounts[q.belongsToGroupTag!] ?? 0;
        for (int i = 0; i < count; i++) {
          // Hanya evaluasi jika pertanyaan induknya sendiri terlihat
          if (isVisible(q.id, index: i)) {
            evaluateConditionalLogicForGroupQuestion(q.id, i, isInitial: true);
            final answer = repeatableGroupAnswers[q.id]?[i];
            evaluateAndExecuteJumps(q.id, answer, isInitial: true, repeatIndex: i);
          }
        }
      } else {
        if (isVisible(q.id)) {
          evaluateConditionalLogicForQuestion(q.id, isInitial: true);
          evaluateAndExecuteJumps(q.id, userAnswers[q.id], isInitial: true);
        }
      }
    }
    
    // Evaluasi juga kategori umur
    _evaluateAgeGroupVisibility();
  }

  Timer? _flattenedUpdateTimer;
  void updateFlattenedItemsDebounced() {
    _flattenedUpdateTimer?.cancel();
    // PERBAIKAN: Gunakan delay yang sangat kecil (10ms) agar UI terasa instan
    _flattenedUpdateTimer = Timer(const Duration(milliseconds: 10), () {
      if (!isClosed) {
        updateFlattenedItems();
      }
    });
  }

  void markFormAsChanged() {
    if (!hasUnsavedChanges.value) {
      hasUnsavedChanges.value = true;
    }
  }

  void hideQuestionsAfterInSameSection(String currentQuestionId, {int? index}) {
    if (loadedForm.value == null) return;
    final currentSectionId = getSectionIdByQuestionId(currentQuestionId);
    if (currentSectionId == null) return;
    final section = loadedForm.value!.sections.firstWhereOrNull((s) => s.id == currentSectionId);
    if (section == null) return;

    final currentIndex = section.questions.indexWhere((q) => q.id == currentQuestionId);
    if (currentIndex == -1) return;

    for (int i = currentIndex + 1; i < section.questions.length; i++) {
      final q = section.questions[i];
      if (isParentQuestion(q.id)) continue;
      setVisible(q.id, false, index: index);
    }
    questionVisibility.refresh();
    updateFlattenedItemsDebounced();
  }

  void markFormAsSaved() {
    hasUnsavedChanges.value = false;
  }

  /// Menangani aksi saat tombol Batal ditekan, memicu dialog konfirmasi jika ada perubahan.
  void onCancelPressed() {
    if (hasUnsavedChanges.value) {
      showExitConfirmationDialog();
      return;
    }
    _safePopPage();
  }

  Future<bool> handleBackPressed() async {
    if (isLoading.value) return false;
    if (hasUnsavedChanges.value) {
      showExitConfirmationDialog();
      return false;
    }
    return true;
  }

  void _safeCloseDialog() {
    try {
      // Gunakan Navigator standar untuk menutup dialog agar tidak menabrak logika snackbar GetX
      if (Get.isDialogOpen == true) {
        if (Get.context != null) {
          Navigator.of(Get.overlayContext ?? Get.context!).pop();
        } else {
          Get.back();
        }
      }
    } catch (e) {
      debugPrint("Error closing dialog: $e");
    }
  }

  void _safePopPage() {
    try {
      // 1. Bersihkan dialog saja jika ada
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext ?? Get.context!).pop();
      }
      
      // 2. Gunakan Navigator standar untuk pop page
      Future.delayed(const Duration(milliseconds: 50), () {
        if (Get.context != null) {
          // Gunakan Navigator dari context yang tersedia
          Navigator.of(Get.context!).maybePop();
        } else {
          Get.back();
        }
      });
    } catch (e) {
      debugPrint("Error popping page: $e");
      Get.back();
    }
  }

  void showExitConfirmationDialog() {
    if (isExitDialogOpen.value) {
      // Jika nyangkut, paksa reset jika sudah lewat 5 detik
      debugPrint("InputUserController: Exit dialog already open flag is true.");
      return;
    }
    
    isExitDialogOpen.value = true;

    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari Form ini?\nData yang belum disimpan akan hilang.',
            style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
              onPressed: () {
                isExitDialogOpen.value = false;
                _safeCloseDialog();
              },
              child:
                  Text('Batal', style: TextStyle(color: Colors.grey.shade700))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                isExitDialogOpen.value = false;
                hasUnsavedChanges.value = false; // RESET FLAG AGAR BISA POP
                _safeCloseDialog();
                // Gunakan microtask agar dialog benar-benar tertutup sebelum pop page
                Future.microtask(() => _safePopPage());
              },
              child: const Text('Ya, Keluar'))
        ],
      ),
      barrierDismissible: false,
    ).then((_) => isExitDialogOpen.value = false);
  }

  void toggleSectionExpansion(String sectionId) {
    if (expandedSectionId.value == sectionId) {
      expandedSectionId.value = '';
    } else {
      expandedSectionId.value = sectionId;
    }
    // Optimization: Immediate update if count is small, otherwise debounce
    if (flattenedItems.length < 50) {
      updateFlattenedItems();
    } else {
      updateFlattenedItemsDebounced();
    }
  }

  /// Membangun ulang daftar [flattenedItems] untuk dirender ke UI.
  /// 
  /// Fungsi ini mengatur pengelompokan pertanyaan dalam seksi dan grup berulang 
  /// berdasarkan urutan aslinya.
  void updateFlattenedItems() {
    if (loadedForm.value == null) {
      flattenedItems.clear();
      return;
    }

    final List<FlattenedFormItem> items = [];

    try {
      // 1. Form Header
      items.add(FlattenedFormItem(type: FormItemType.header, id: 'form_header'));

      // LOOP BERDASARKAN URUTAN ASLI SECTION
      for (final section in loadedForm.value!.sections) {
        final isExpanded = expandedSectionId.value == section.id || loadedForm.value!.sections.length == 1;

        // 2. Section Header
        items.add(FlattenedFormItem(
          type: FormItemType.sectionHeader,
          section: section,
          id: 'section_header_${section.id}',
        ));

        if (isExpanded) {
          final List<FormQuestion> questions = section.questions;
          Set<String> processedGroupTags = {};

          // LOOP BERDASARKAN URUTAN ASLI PERTANYAAN
          for (int k = 0; k < questions.length; k++) {
            final question = questions[k];

            // 1. Jika ini adalah Pertanyaan Pengontrol Grup
            if (question.isRepeatableGroupController && question.controlledGroupTag != null) {
              if (isVisible(question.id)) {
                items.add(FlattenedFormItem(type: FormItemType.question, question: question, id: 'question_${question.id}'));
                items.add(FlattenedFormItem(type: FormItemType.divider, id: 'divider_${question.id}_$k'));
              }
            } 
            
            // 2. Jika ini adalah Pertanyaan Anggota Grup
            else if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
              final groupTag = question.belongsToGroupTag!;
              if (!processedGroupTags.contains(groupTag)) {
                // Cari controller untuk grup ini
                final controllerQ = loadedForm.value?.sections
                    .expand((s) => s.questions)
                    .firstWhereOrNull((q) => q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
                
                final bool controllerVisible = controllerQ == null || isVisible(controllerQ.id);
                final int currentCount = repeatableGroupCounts[groupTag] ?? 0;

                debugPrint("CHECK GROUP INSTANCE: $groupTag");
                debugPrint("CONTROLLER FOUND: ${controllerQ?.questionText}");
                debugPrint("CONTROLLER VISIBLE: $controllerVisible");
                debugPrint("CURRENT COUNT: $currentCount");

                if (controllerVisible && currentCount > 0) {
                  items.add(FlattenedFormItem(
                    type: FormItemType.groupInstance,
                    section: section,
                    groupTag: groupTag,
                    id: 'group_${groupTag}_${section.id}',
                  ));
                  items.add(FlattenedFormItem(type: FormItemType.divider, id: 'divider_${groupTag}_$k'));
                  processedGroupTags.add(groupTag);
                }
              }
            } 
            
            // 3. Pertanyaan Mandiri
            else {
              if (isVisible(question.id)) {
                items.add(FlattenedFormItem(type: FormItemType.question, question: question, id: 'question_${question.id}'));
                items.add(FlattenedFormItem(type: FormItemType.divider, id: 'divider_${question.id}_$k'));
              }
            }
          }

          if (items.isNotEmpty && items.last.type == FormItemType.divider) {
            items.removeLast();
          }

          items.add(FlattenedFormItem(type: FormItemType.sectionFooter, section: section, id: 'section_footer_${section.id}'));
        }
      }

      flattenedItems.assignAll(items);
    } catch (e, stack) {
      debugPrint("Error in updateFlattenedItems: $e\n$stack");
    }
  }

  // Removed redundant _getSortedQuestions as they are sorted once at load time.

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
        if (question.hasOtherOption &&
            userAnswers[question.id] == _kOtherOptionValue) {
          hasOtherTextForSelectedOther =
              userOtherAnswers[question.id]?.isNotEmpty ?? false;
          if (hasMainAnswer && hasOtherTextForSelectedOther) return true;
        } else if (hasMainAnswer) {
          return true;
        }
      } else {
        final groupTag = question.belongsToGroupTag!;
        final count = repeatableGroupCounts[groupTag] ?? 0;
        if (repeatableGroupAnswers.containsKey(question.id)) {
          for (int i = 0; i < count; i++) {
            hasMainAnswer =
                repeatableGroupAnswers[question.id]!.containsKey(i) &&
                    !_isAnswerEmpty(
                        repeatableGroupAnswers[question.id]![i], question.type);

            if (question.hasOtherOption &&
                repeatableGroupAnswers[question.id]![i] == _kOtherOptionValue) {
              hasOtherTextForSelectedOther =
                  repeatableGroupOtherAnswers[question.id]?[i]?.isNotEmpty ??
                      false;
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
    _resetAllStatesSync();

    final dynamic arguments = Get.arguments;
    String? extractedFormId;
    String? extractedSubmissionId;

    if (arguments != null) {
      if (arguments is String) {
        extractedFormId = arguments;
        submissionId.value = '';
      } else if (arguments is Map) {
        if (arguments.containsKey('formId') &&
            arguments['formId'] is String &&
            (arguments['formId'] as String).isNotEmpty) {
          extractedFormId = arguments['formId'] as String;
        } else {
          errorMessage.value = "Argumen Map tidak berisi 'formId' yang valid.";
          isLoading.value = false;
          return;
        }

        if (arguments.containsKey('submissionId') &&
            arguments['submissionId'] is String &&
            (arguments['submissionId'] as String).isNotEmpty) {
          extractedSubmissionId = arguments['submissionId'] as String;
          submissionId.value = extractedSubmissionId;
        } else {
          submissionId.value = '';
        }

        // --- TAMBAHAN: Parse Flag Read-Only ---
        if (arguments.containsKey('isReadOnlyView')) {
          isReadOnlyView.value = arguments['isReadOnlyView'] == true;
        }

        if (arguments.containsKey('villageId') &&
            arguments['villageId'] is String &&
            (arguments['villageId'] as String).isNotEmpty) {
          selectedVillageId.value = arguments['villageId'] as String;
        }
      } else {
        errorMessage.value =
            "Tipe argumen tidak dikenal (${arguments.runtimeType})";
        isLoading.value = false;
        return;
      }

      if (extractedFormId.isNotEmpty) {
        formId.value = extractedFormId;
        fetchFormAndPotentialSubmissionData();
      } else {
        errorMessage.value = "ID Form tidak valid.";
        isLoading.value = false;
      }
    } else {
      errorMessage.value = "Argumen ID Form tidak ditemukan.";
      isLoading.value = false;
    }
  }

  void loadMoreItems() {
    if (visibleItemCount.value < flattenedItems.length) {
      visibleItemCount.value += _lazyLoadBatchSize;
      debugPrint("InputUserController: Lazy loading more items. Current count: ${visibleItemCount.value}");
    }
  }

  void _resetAllStatesSync() {
    submissionId.value = '';
    loadedForm.value = null;
    loadedSubmission.value = null;
    errorMessage.value = '';
    
    // Gunakan fungsi pembersihan total yang baru
    forceCleanupAllData();

    selectedImageFiles.clear();
    selectedVillageId.value = '';
    allVillages.clear();
    hasUnsavedChanges.value = false;
    isExitDialogOpen.value = false;
    isUploadingImage.value = false;
    isGettingLocation.value = false;
    isLoading.value = true;
  }

  void _resetAllStates() {
    _resetAllStatesSync();
    userAnswers.refresh();
    selectedImageFiles.refresh();
    repeatableGroupAnswers.refresh();
  }

  @override
  void onClose() {
    _resetAllStates();
    super.onClose();
  }

  /// Memuat struktur formulir dan data isian (jika mode edit) secara paralel.
  /// 
  /// Fungsi ini juga menangani deteksi role dan penentuan wilayah desa petugas.
  Future<void> fetchFormAndPotentialSubmissionData() async {
    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    loadedSubmission.value = null;
    _allQuestionIdsInOrder.clear();
    activeRepeatIndexForGroup.clear();
    expandedSectionId.value = '';
    isLockedMode.value = false;

    if (formId.value.isEmpty) {
      errorMessage.value = "ID Form kosong, tidak dapat melanjutkan.";
      isLoading.value = false;
      showSafeSnackbar(
        title: 'Error Kritis',
        message: errorMessage.value,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = "Pengguna tidak terautentikasi.";
        isLoading.value = false;
        return;
      }

      // 1. Fetch Form & Villages (FORCED FROM SERVER)
      final List<Future> initialTasks = [
        _db.collection('villages').get(),
        _db.collection('adminForms').doc(formId.value).get(const GetOptions(source: Source.server)),
        _db.collection('users').doc(user.uid).get(),
      ];
      
      final initialResults = await Future.wait(initialTasks);
      
      final villageSnapshot = initialResults[0] as QuerySnapshot<Map<String, dynamic>>;
      allVillages.assignAll(villageSnapshot.docs.map((doc) => VillageModel.fromFirestore(doc)).toList());
      
      final formDocSnapshot = initialResults[1] as DocumentSnapshot<Map<String, dynamic>>;
      final userDoc = initialResults[2] as DocumentSnapshot<Map<String, dynamic>>;

      if (userDoc.exists) {
        userRole.value = (userDoc.data()?['role'] as String? ?? 'user').toLowerCase().trim();
        userRt.value = (userDoc.data()?['rt']?.toString() ?? '').trim();
        userRw.value = (userDoc.data()?['rw']?.toString() ?? '').trim();
        
        // KRITIKAL: Pre-fill villageId dari profil user jika ini form baru
        if (selectedVillageId.value.isEmpty) {
          selectedVillageId.value = userDoc.data()?['villageId'] as String? ?? '';
          debugPrint("InputUserController: Profile info - Village: ${selectedVillageId.value}, RT: ${userRt.value}, RW: ${userRw.value}");
        }
      }

      if (!formDocSnapshot.exists) {
        errorMessage.value = "Struktur form dengan ID '${formId.value}' tidak ditemukan.";
        isLoading.value = false;
        return;
      }

      loadedForm.value = FormItem.fromFirestore(formDocSnapshot);
      _setupFormMetadata();

      // 2. Tentukan Periode
      final now = DateTime.now();
      currentPeriod.value = DateFormat('yyyy-MM').format(now);

      // 3. Cari/Buat Submission
      if (isEditMode) {
        final village = allVillages.firstWhereOrNull((v) => v.villageId == selectedVillageId.value);
        final bool useLocalApi = village?.serverType == 'local_api';

        if (useLocalApi) {
          // --- AMBIL DARI LAPTOP/SERVER DESA ---
          String baseUrl = village!.apiBaseUrl ?? "http://${village.localIpAddress}:${village.port}";
          if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
          
          final url = Uri.parse('$baseUrl/api/submissions/${submissionId.value}');
          final response = await http.get(url).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final Map<String, dynamic> localData = jsonDecode(response.body);
            loadedSubmission.value = FormSubmission.fromMap(localData, submissionId.value);
          } else {
             errorMessage.value = "Data tidak ditemukan di server desa.";
          }
        } else {
          // --- AMBIL DARI FIREBASE ---
          final doc = await _db.collection('formSubmissions').doc(submissionId.value).get();
          if (doc.exists) {
            loadedSubmission.value = FormSubmission.fromFirestore(doc);
          }
        }

        // Jika berhasil load
        if (loadedSubmission.value != null) {
          if (loadedSubmission.value?.villageId != null) {
            selectedVillageId.value = loadedSubmission.value!.villageId!;
          }
          
          // Cek Locking
          if (loadedSubmission.value!.isLocked || loadedSubmission.value!.status == 'locked') {
            isLockedMode.value = true;
          } else if (loadedSubmission.value!.period != currentPeriod.value && userRole.value != 'admin' && userRole.value != 'global_admin') {
             isLockedMode.value = true;
          }
          
          // Paksa mode terkunci jika dibuka dari view Read-Only (Admin RT)
          if (isReadOnlyView.value) {
            isLockedMode.value = true;
          }
        }
      }

      _initializeStatesBasedOnMode();
    } catch (e, stack) {
      debugPrint("Error in fetchFormAndPotentialSubmissionData: $e\n$stack");
      errorMessage.value = "Gagal memuat data: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  void _setupFormMetadata() {
    if (loadedForm.value == null) return;
    
    _allQuestionIdsInOrder.clear();
    _questionIndexMap.clear();
    _questionCache.clear();
    
    int idx = 0;
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        _allQuestionIdsInOrder.add(question.id);
        _questionIndexMap[question.id] = idx++;
        _questionCache[question.id] = question;
      }
    }
    
    // PERBAIKAN: Selalu ekspansi bagian pertama secara default jika ada data
    if (loadedForm.value!.sections.isNotEmpty) {
      if (expandedSectionId.value.isEmpty) {
        expandedSectionId.value = loadedForm.value!.sections.first.id;
        debugPrint("InputUserController: Auto-expanding first section: ${expandedSectionId.value}");
      }
    }
  }

  dynamic _getDefaultAnswerForQuestionType(QuestionType type) {
    switch (type) {
      case QuestionType.checkboxes:
        return <String>[];
      case QuestionType.gridNumeric:
        return <String, Map<String, Map<String, num?>>>{};
      case QuestionType.dropdown:
      case QuestionType.imageUpload:
      case QuestionType.location:
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
    userOtherAnswers.clear();
    repeatableGroupOtherAnswers.forEach((_, rxMap) => rxMap.clear());
    repeatableGroupOtherAnswers.clear();
    repeatableGroupCounts.clear();
    questionVisibility.clear();
    activeRepeatIndexForGroup.clear();

    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null) continue;

      if (question.belongsToGroupTag == null ||
          question.belongsToGroupTag!.isEmpty) {
        userAnswers[question.id] =
            _getDefaultAnswerForQuestionType(question.type);
        if (question.hasOtherOption) {
          userOtherAnswers[question.id] = '';
        }
      } else {
        if (!repeatableGroupAnswers.containsKey(question.id)) {
          repeatableGroupAnswers[question.id] = RxMap<int, dynamic>();
        }
        if (question.hasOtherOption &&
            !repeatableGroupOtherAnswers.containsKey(question.id)) {
          repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
        }
      }
    }

    if (isEditMode && loadedSubmission.value != null) {
      _populateAnswersFromSubmission();
    } else {
      for (var qId in _allQuestionIdsInOrder) {
        final question = findQuestionById(qId);
        if (question == null) continue;

        if (question.isRepeatableGroupController &&
            question.controlledGroupTag != null) {
          dynamic controllerAnswer = userAnswers[question.id];
          int count = 0;
          if (controllerAnswer is String && controllerAnswer.isNotEmpty) {
            count = int.tryParse(controllerAnswer) ?? 0;
          } else if (controllerAnswer is num) {
            count = controllerAnswer.toInt();
          }
          if (userAnswers[question.id] == null ||
              userAnswers[question.id].toString().isEmpty) {
            userAnswers[question.id] = '0';
          }
          repeatableGroupCounts[question.controlledGroupTag!] = count;
          if (count > 0) {
            activeRepeatIndexForGroup.putIfAbsent(
                question.controlledGroupTag!, () => 0);
          }
          _adjustRepeatableGroupAnswers(question.controlledGroupTag!, count);
        }
      }
    }

    userAnswers.refresh();
    userOtherAnswers.refresh();
    repeatableGroupAnswers.refresh();
    repeatableGroupOtherAnswers.refresh();
    repeatableGroupCounts.refresh();
    activeRepeatIndexForGroup.refresh();

    recalculateSummaryAgeGroups();
    _initializeAndEvaluateInitialVisibility();
    markFormAsSaved();
  }

  Future<void> fetchFormStructure() async {
    if (formId.value.isEmpty) {
      errorMessage.value = "ID Form tidak valid.";
      isLoading.value = false;
      loadedForm.value = null;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    loadedForm.value = null;
    _allQuestionIdsInOrder.clear();
    _questionCache.clear();
    expandedSectionId.value = '';

    try {
      final docSnapshot =
          await _db.collection('adminForms').doc(formId.value).get(const GetOptions(source: Source.server));
      if (docSnapshot.exists) {
        loadedForm.value = FormItem.fromFirestore(docSnapshot);
        if (loadedForm.value != null) {
          for (var section in loadedForm.value!.sections) {
            for (var question in section.questions) {
              _allQuestionIdsInOrder.add(question.id);
              _questionCache[question.id] = question;
            }
          }
          if (loadedForm.value!.sections.length == 1) {
            expandedSectionId.value = loadedForm.value!.sections.first.id;
          }
          _initializeStatesBasedOnMode();
        } else {
          errorMessage.value = "Gagal memproses struktur form.";
        }
      } else {
        errorMessage.value = "Struktur form tidak ditemukan.";
      }
    } catch (e) {
      errorMessage.value = "Gagal memuat form: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  void _populateAnswersFromSubmission() {
    if (loadedSubmission.value == null || loadedForm.value == null) return;
    Map<String, int> tempGroupCounts = {};

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      bool isRepeatableMemberInstance = false;
      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        final potentialIndex = int.tryParse(parts.last);
        if (potentialIndex != null) {
          String tempOriginalQId = parts.sublist(0, parts.length - 1).join('_');
          final tempQDef = findQuestionById(tempOriginalQId);
          if (tempQDef != null &&
              tempQDef.belongsToGroupTag != null &&
              tempQDef.belongsToGroupTag!.isNotEmpty) {
            isRepeatableMemberInstance = true;
            originalQuestionId = tempOriginalQId;
          }
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null) continue;
      if (questionDef.belongsToGroupTag != null &&
          questionDef.belongsToGroupTag!.isNotEmpty) {
        isRepeatableMemberInstance = true;
      } else {
        // PERBAIKAN: Jika pertanyaan sekarang Mandiri tapi data di DB masih format Grup (_0),
        // tetap anggap ini sebagai jawaban untuk pertanyaan Mandiri tersebut (untuk Form Duplikasi).
        if (originalQuestionId.contains('_')) {
           final baseId = originalQuestionId.split('_').first;
           final baseQ = findQuestionById(baseId);
           if (baseQ != null && (baseQ.belongsToGroupTag == null || baseQ.belongsToGroupTag!.isEmpty)) {
             originalQuestionId = baseId;
             isRepeatableMemberInstance = false;
           }
        }
      }

      dynamic mappedMainAnswer;
      String? otherText;

      if (questionDef.hasOtherOption) {
        if (savedAnswer.answer is String) {
          bool isPredefinedOption =
              questionDef.options.any((opt) => opt.value == savedAnswer.answer);
          if (!isPredefinedOption && (savedAnswer.answer as String).isNotEmpty) {
            mappedMainAnswer = _kOtherOptionValue;
            otherText = savedAnswer.answer as String;
          } else {
            mappedMainAnswer =
                _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else if (savedAnswer.answer is List &&
            questionDef.type == QuestionType.checkboxes) {
          List<String> tempCheckboxAnswers = [];
          List<String> otherTextsFound = [];
          for (var item in (savedAnswer.answer as List)) {
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
          mappedMainAnswer =
              _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }
      } else {
        mappedMainAnswer =
            _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
      }

      if (!isRepeatableMemberInstance) {
        // PERBAIKAN: Gunakan helper _isAnswerEmpty untuk mengecek apakah data benar-benar kosong.
        // Ini memastikan tipe data seperti Checkbox ([]) atau Grid ({}) tetap bisa dimuat dari DB.
        bool currentIsEmpty = !userAnswers.containsKey(originalQuestionId) || 
                             _isAnswerEmpty(userAnswers[originalQuestionId], questionDef.type);

        if (currentIsEmpty) {
          userAnswers[originalQuestionId] = mappedMainAnswer;
          if (otherText != null) {
            userOtherAnswers[originalQuestionId] = otherText;
          }
        }

        if (questionDef.isRepeatableGroupController &&
            questionDef.controlledGroupTag != null) {
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

    tempGroupCounts.forEach((tag, groupCount) {
      repeatableGroupCounts[tag] = groupCount;
      if (groupCount > 0) {
        activeRepeatIndexForGroup.putIfAbsent(tag, () => 0);
      } else {
        activeRepeatIndexForGroup.remove(tag);
      }
      _adjustRepeatableGroupAnswers(tag, groupCount);
    });

    for (var savedAnswer in loadedSubmission.value!.answers) {
      String originalQuestionId = savedAnswer.questionId;
      int? repeatIndex;
      final parts = savedAnswer.questionId.split('_');
      if (parts.length > 1) {
        final potentialIndex = int.tryParse(parts.last);
        if (potentialIndex != null) {
          String tempOriginalQId = parts.sublist(0, parts.length - 1).join('_');
          final tempQDef = findQuestionById(tempOriginalQId);
          if (tempQDef != null &&
              tempQDef.belongsToGroupTag != null &&
              tempQDef.belongsToGroupTag!.isNotEmpty) {
            originalQuestionId = tempOriginalQId;
            repeatIndex = potentialIndex;
          }
        }
      }

      final FormQuestion? questionDef = findQuestionById(originalQuestionId);
      if (questionDef == null ||
          questionDef.belongsToGroupTag == null ||
          questionDef.belongsToGroupTag!.isEmpty ||
          repeatIndex == null) {
        continue;
      }

      if (repeatableGroupAnswers.containsKey(originalQuestionId) &&
          repeatIndex <
              (repeatableGroupCounts[questionDef.belongsToGroupTag!] ?? 0)) {
        dynamic mappedMainAnswerRepeat;
        String? otherTextRepeat;

        if (questionDef.hasOtherOption) {
          if (savedAnswer.answer is String) {
            bool isPredefinedOption =
                questionDef.options.any((opt) => opt.value == savedAnswer.answer);
            if (!isPredefinedOption &&
                (savedAnswer.answer as String).isNotEmpty) {
              mappedMainAnswerRepeat = _kOtherOptionValue;
              otherTextRepeat = savedAnswer.answer as String;
            } else {
              mappedMainAnswerRepeat =
                  _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
            }
          } else if (savedAnswer.answer is List &&
              questionDef.type == QuestionType.checkboxes) {
            List<String> tempCheckboxAnswers = [];
            List<String> otherTextsFound = [];
            for (var item in (savedAnswer.answer as List)) {
              if (questionDef.options
                  .any((opt) => opt.value == item.toString())) {
                tempCheckboxAnswers.add(item.toString());
              } else if (item.toString().isNotEmpty) {
                otherTextsFound.add(item.toString());
              }
            }
            if (otherTextsFound.isNotEmpty) {
              tempCheckboxAnswers.add(_kOtherOptionValue);
              otherTextRepeat = otherTextsFound.join(', ');
            }
            mappedMainAnswerRepeat = tempCheckboxAnswers;
          } else {
            mappedMainAnswerRepeat =
                _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
          }
        } else {
          mappedMainAnswerRepeat =
              _mapAnswerToCorrectType(savedAnswer.answer, questionDef);
        }

        if (!repeatableGroupAnswers[originalQuestionId]!.containsKey(
            repeatIndex)) {
          repeatableGroupAnswers[originalQuestionId]![repeatIndex] =
              _getDefaultAnswerForQuestionType(questionDef.type);
        }
        repeatableGroupAnswers[originalQuestionId]![repeatIndex] =
            mappedMainAnswerRepeat;

        if (otherTextRepeat != null &&
            repeatableGroupOtherAnswers.containsKey(originalQuestionId)) {
          if (!repeatableGroupOtherAnswers[originalQuestionId]!
              .containsKey(repeatIndex)) {
            repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] = '';
          }
          repeatableGroupOtherAnswers[originalQuestionId]![repeatIndex] =
              otherTextRepeat;
        }
      }
    }
  }

  bool questionShouldBeVisible(String groupTag) {
    final controllerQ = loadedForm.value?.sections
        .expand((s) => s.questions)
        .firstWhereOrNull((q) =>
            q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
    if (controllerQ != null) {
      return questionVisibility[controllerQ.id] ?? true;
    }
    return true;
  }

  dynamic _mapAnswerToCorrectType(dynamic rawAnswer, FormQuestion questionDef) {
    if (rawAnswer == null) {
      return _getDefaultAnswerForQuestionType(questionDef.type);
    }
    switch (questionDef.type) {
      case QuestionType.checkboxes:
        if (rawAnswer is List) {
          return List<String>.from(rawAnswer.map((item) => item.toString()));
        }
        return <String>[];
      case QuestionType.number:
        if (rawAnswer is num) return rawAnswer.toString().replaceAll('.', ',');
        if (rawAnswer is String) return rawAnswer;
        return (num.tryParse(rawAnswer.toString().replaceAll(',', '.'))
                ?.toString()
                .replaceAll('.', ',') ??
            '');
      case QuestionType.date:
        if (rawAnswer is Timestamp) {
          return DateFormat('dd/MM/yyyy').format(rawAnswer.toDate());
        }
        if (rawAnswer is String) {
          try {
            DateFormat('dd/MM/yyyy').parseStrict(rawAnswer);
            return rawAnswer;
          } catch (_) {
            try {
              final date = DateTime.parse(rawAnswer);
              return DateFormat('dd/MM/yyyy').format(date);
            } catch (e) {
              return rawAnswer;
            }
          }
        }
        return rawAnswer.toString();
      case QuestionType.gridNumeric:
        if (rawAnswer is Map) {
          try {
            return Map<String, Map<String, Map<String, num?>>>.fromEntries(
                (rawAnswer).entries.map((rowEntry) {
              String effectiveRowKey = rowEntry.key.toString();
              if ((questionDef.gridRowLabels.isEmpty) &&
                  effectiveRowKey == "default_row") {
                effectiveRowKey = "";
              }
              var colMap = rowEntry.value;
              if (colMap is! Map) colMap = <String, dynamic>{};
              return MapEntry(
                  effectiveRowKey,
                  Map<String, Map<String, num?>>.fromEntries(
                      (colMap).entries.map((colEntry) {
                    var subColMap = colEntry.value;
                    if (subColMap is! Map) subColMap = <String, dynamic>{};
                    return MapEntry(
                        colEntry.key.toString(),
                        Map<String, num?>.fromEntries(
                            (subColMap).entries.map((subColEntry) {
                          num? valNum;
                          if (subColEntry.value == null) {
                            valNum = null;
                          } else if (subColEntry.value is num) {
                            valNum = subColEntry.value as num;
                          } else {
                            valNum = num.tryParse((subColEntry.value.toString())
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
      case QuestionType.imageUpload:
      case QuestionType.location:
        if (rawAnswer is Map) {
          return Map<String, dynamic>.from(rawAnswer);
        }
        return _getDefaultAnswerForQuestionType(questionDef.type);
      case QuestionType.dropdown:
      case QuestionType.multipleChoice:
        if (rawAnswer is String) return rawAnswer;
        return rawAnswer?.toString() ??
            _getDefaultAnswerForQuestionType(questionDef.type);
      default:
        return rawAnswer.toString();
    }
  }

  void _initializeAndEvaluateInitialVisibility() {
    initializeVisibility();
  }


  FormQuestion? findQuestionById(String questionId) {
    return _questionCache[questionId];
  }

  String? getOtherAnswer(String questionId, {int? repeatIndex}) {
    final question = findQuestionById(questionId);
    if (question == null) return null;
    if (question.belongsToGroupTag != null &&
        question.belongsToGroupTag!.isNotEmpty &&
        repeatIndex != null) {
      if (repeatableGroupOtherAnswers.containsKey(questionId) &&
          repeatableGroupOtherAnswers[questionId]!.containsKey(repeatIndex)) {
        return repeatableGroupOtherAnswers[questionId]![repeatIndex];
      }
    } else if (question.belongsToGroupTag == null ||
        question.belongsToGroupTag!.isEmpty) {
      return userOtherAnswers[questionId];
    }
    return null;
  }

  void updateOtherAnswer(String questionId, String value, {int? repeatIndex}) {
    final question = findQuestionById(questionId);
    if (question == null || !question.hasOtherOption) return;
    if (question.belongsToGroupTag != null &&
        question.belongsToGroupTag!.isNotEmpty &&
        repeatIndex != null) {
      final groupTag = question.belongsToGroupTag!;
      final count = repeatableGroupCounts[groupTag] ?? 0;
      if (repeatIndex >= 0 && repeatIndex < count) {
        if (!repeatableGroupOtherAnswers.containsKey(questionId)) {
          repeatableGroupOtherAnswers[questionId] = RxMap<int, String>();
        }
        repeatableGroupOtherAnswers[questionId]![repeatIndex] = value;
      } else {
        return;
      }
    } else if (question.belongsToGroupTag == null ||
        question.belongsToGroupTag!.isEmpty) {
      userOtherAnswers[questionId] = value;
    }
    markFormAsChanged();
  }

  void _resetDependentChildrenAnswers(String parentQuestionId,
      {bool calledFromJumpClear = false, int? repeatIndex}) {
    if (loadedForm.value == null) return;
    
    final cleanParentId = parentQuestionId.replaceFirst('question_', '');
    
    for (var qId in _allQuestionIdsInOrder) {
      final qChild = findQuestionById(qId);
      if (qChild == null ||
          qChild.dependentOptions?.parentQuestionId != cleanParentId) {
        continue;
      }
      
      // Gunakan isVisible yang sudah diperbaiki (index-aware)
      if (isVisible(qId, index: repeatIndex) || calledFromJumpClear) {
        dynamic defaultValue = _getDefaultAnswerForQuestionType(qChild.type);
        if (qChild.belongsToGroupTag == null ||
            qChild.belongsToGroupTag!.isEmpty) {
          // Child is Global
          if (userAnswers[qChild.id] != defaultValue) {
            userAnswers[qChild.id] = defaultValue;
            if (qChild.hasOtherOption) userOtherAnswers[qChild.id] = '';
            // PENTING: Teruskan repeatIndex meskipun qChild global, agar jika 
            // qChild punya anak di grup, kita tahu indeks mana yang memicu.
            _resetDependentChildrenAnswers(qChild.id,
                calledFromJumpClear: true, repeatIndex: repeatIndex);
          }
        } else {
          final groupTag = qChild.belongsToGroupTag!;
          final parentQuestion = findQuestionById(cleanParentId);

          // PROTEKSI: Jika pemicu punya index, hanya reset pada index tersebut
          // kecuali jika pemicunya benar-benar global (index == null)
          final List<int> indicesToReset = repeatIndex != null
              ? [repeatIndex]
              : List.generate(repeatableGroupCounts[groupTag] ?? 0, (i) => i);

          for (int i in indicesToReset) {
            bool shouldResetThisInstance = false;
            if (parentQuestion?.belongsToGroupTag == qChild.belongsToGroupTag) {
              shouldResetThisInstance = true;
            } else if (parentQuestion?.belongsToGroupTag == null) {
              shouldResetThisInstance = true;
            } else if (parentQuestion?.isRepeatableGroupController == true &&
                parentQuestion?.controlledGroupTag ==
                    qChild.belongsToGroupTag) {
              shouldResetThisInstance = true;
            }

            if (shouldResetThisInstance &&
                repeatableGroupAnswers.containsKey(qChild.id) &&
                repeatableGroupAnswers[qChild.id]!.containsKey(i) &&
                repeatableGroupAnswers[qChild.id]![i] != defaultValue) {
              repeatableGroupAnswers[qChild.id]![i] = defaultValue;
              if (qChild.hasOtherOption &&
                  repeatableGroupOtherAnswers.containsKey(qChild.id)) {
                if (repeatableGroupOtherAnswers[qChild.id]!.containsKey(i)) {
                  repeatableGroupOtherAnswers[qChild.id]![i] = '';
                }
              }
              // Rekursif dengan index yang sama
              _resetDependentChildrenAnswers(qChild.id,
                  calledFromJumpClear: true, repeatIndex: i);
            }
          }
        }
      }
    }
  }

  void _clearAnswersForSkippedQuestions(List<String> skippedQuestionIds, {int? specificRepeatIndex}) {
    // KITA MATIKAN PEMBERSIHAN OTOMATIS AGAR DATA BERSYARAT TIDAK HILANG
    return;
  }


  /// Mengambil dan menjalankan seluruh aturan lompatan (Jumps) setelah jawaban diperbarui.
  void evaluateAndExecuteJumps(String startQuestionId, dynamic answerValue, {bool isInitial = false, int? repeatIndex}) {
    if (loadedForm.value == null) return;

    final cleanId = startQuestionId.replaceFirst('question_', '');
    final question = findQuestionById(cleanId);
    if (question == null) return;

    bool stateChanged = false;
    final List<String> jumpTargets = [];
    dynamic evalAnswer = answerValue;

    if (question.hasOtherOption && answerValue == _kOtherOptionValue) {
      evalAnswer = getOtherAnswer(cleanId, repeatIndex: repeatIndex) ?? "";
    }

    // 1. EVALUASI ATURAN LOMPATAN (Multi-target Support)
    if (question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty) {
      jumpTargets.add(question.unconditionalJumpTarget!);
    } else if (question.conditionalJumps.isNotEmpty) {
      for (var jumpRule in question.conditionalJumps) {
        bool isMatch = false;
        final String ruleVal = jumpRule.conditionValue.trim().toLowerCase();
        
        if (evalAnswer is List) {
          isMatch = evalAnswer.any((e) => e.toString().trim().toLowerCase() == ruleVal);
        } else {
          isMatch = evalAnswer?.toString().trim().toLowerCase() == ruleVal;
        }

        if (isMatch) {
          jumpTargets.add(jumpRule.jumpToQuestionId);
        }
      }
    }

    // 2. EKSEKUSI LOMPATAN
    // PERBAIKAN: Selalu jalankan agar jika jumpTargets kosong, pertanyaan yang sebelumnya di-jump tetap dievaluasi (untuk disembunyikan/ditampilkan)
    debugPrint("DEBUG: evaluateAndExecuteJumps found targets for $cleanId: $jumpTargets");
    final changed = _performMultiJumpWithinSection(cleanId, jumpTargets, isInitial: isInitial, repeatIndex: repeatIndex);
    if (changed) stateChanged = true;
    // PERBAIKAN: Hapus else block yang memanggil _showNextQuestionsInSameSection
    // agar tidak menabrak logika visibilitas Opsi Lanjutan.

    if (stateChanged && !isInitial) {
      questionVisibility.refresh();
      updateFlattenedItems();
    }
  }

  bool _performMultiJumpWithinSection(String currentQId, List<String> targets, {bool isInitial = false, int? repeatIndex}) {
    // Normalisasi ID untuk pencarian index yang akurat
    final cleanQId = currentQId.replaceFirst('question_', '');
    final sectionId = getSectionIdByQuestionId(cleanQId);
    if (sectionId == null) return false;

    final section = loadedForm.value!.sections.firstWhere((s) => s.id == sectionId);
    final startIdx = section.questions.indexWhere((q) => q.id == cleanQId);
    if (startIdx == -1) return false;

    bool changed = false;
    final Set<String> targetIds = targets.map((t) => t.replaceFirst('question_', '')).toSet();

    // Identifikasi target terjauh dalam section ini untuk batas pembersihan (Semua Potensi Jump)
    int maxTargetIdx = startIdx;
    final currentQ = findQuestionById(cleanQId);
    if (currentQ != null) {
      final List<String> allPossibleTargets = [];
      if (currentQ.unconditionalJumpTarget != null) allPossibleTargets.add(currentQ.unconditionalJumpTarget!);
      allPossibleTargets.addAll(currentQ.conditionalJumps.map((j) => j.jumpToQuestionId));
      
      for (final tIdRaw in allPossibleTargets) {
        final tId = tIdRaw.replaceFirst('question_', '');
        if (tId == 'END_OF_FORM' || tId == 'END_OF_SECTION' || tId == 'end_of_form' || tId == 'end_of_current_section') {
          maxTargetIdx = section.questions.length - 1;
          break;
        }
        final idx = section.questions.indexWhere((q) => q.id == tId);
        if (idx > maxTargetIdx) maxTargetIdx = idx;
      }
    }
    
    // Pastikan target aktif juga masuk dalam jangkauan
    for (final tId in targetIds) {
      if (tId == 'END_OF_FORM' || tId == 'END_OF_SECTION' || tId == 'end_of_form' || tId == 'end_of_current_section') {
        maxTargetIdx = section.questions.length - 1;
        break;
      }
      final idx = section.questions.indexWhere((q) => q.id == tId);
      if (idx > maxTargetIdx) maxTargetIdx = idx;
    }

    // PROSES PERTANYAAN SETELAHNYA SAMPAI BATAS TARGET TERJAUH
    for (int i = startIdx + 1; i <= maxTargetIdx; i++) {
      final q = section.questions[i];
      
      if (targetIds.contains(q.id)) {
        // Ini adalah salah satu target -> TAMPILKAN
        if (!isVisible(q.id, index: repeatIndex)) {
          setVisible(q.id, true, index: repeatIndex);
          changed = true;
        }
      } else {
        // Bukan target -> Sembunyikan jika dia adalah anak bersyarat (skip logic)
        // Kecuali jika dia adalah Parent yang memang seharusnya tampil.
        if (isConditionalChild(q) && isVisible(q.id, index: repeatIndex)) {
          setVisible(q.id, false, index: repeatIndex);
          changed = true;
          _hideAllChildrenRecursive(q.id, index: repeatIndex, originalParentToProtect: cleanQId);
          if (!isInitial) _clearAnswersForSkippedQuestions([q.id], specificRepeatIndex: repeatIndex);
        }
      }
    }

    return changed;
  }

  bool _showNextQuestionsInSameSection(String currentQId, {int? repeatIndex}) {
    final sectionId = getSectionIdByQuestionId(currentQId);
    if (sectionId == null) return false;

    final section = loadedForm.value!.sections.firstWhere((s) => s.id == sectionId);
    final startIdx = section.questions.indexWhere((q) => q.id == currentQId);
    if (startIdx == -1) return false;

    bool changed = false;
    // Munculkan pertanyaan tepat setelah ini jika dia bukan anak pemicu lain/age group
    if (startIdx + 1 < section.questions.length) {
      final nextQ = section.questions[startIdx + 1];
      if (!isConditionalChild(nextQ)) {
        if (!isVisible(nextQ.id, index: repeatIndex)) {
          setVisible(nextQ.id, true, index: repeatIndex);
          changed = true;
        }
      }
    }
    return changed;
  }


  /// Memperbarui jawaban user untuk pertanyaan global dan memicu evaluasi logika terkait.
  void updateUserAnswer(String questionId, dynamic value) {
    final cleanId = questionId.replaceFirst('question_', '');
    userAnswers[cleanId] = value;
    markFormAsChanged();

    final question = findQuestionById(cleanId);

    debugPrint("UPDATE ANSWER: $questionId = $value");
    debugPrint("QUESTION FOUND: ${question?.questionText}");
    debugPrint("IS GROUP CONTROLLER: ${question?.isRepeatableGroupController}");
    debugPrint("CONTROLLED GROUP TAG: ${question?.controlledGroupTag}");

    if (question != null &&
        question.isRepeatableGroupController &&
        question.controlledGroupTag != null &&
        question.controlledGroupTag!.isNotEmpty) {

      final String groupTag = question.controlledGroupTag!;

      int count = 0;

      if (value is int) {
        count = value;
      } else if (value is num) {
        count = value.toInt();
      } else if (value is String) {
        // Parsing angka lebih kuat dari string (handle format ribuan/desimal lokal)
        count = int.tryParse(value.replaceAll(',', '.').split('.').first) ?? 0;
      }

      if (count < 0) count = 0;

      repeatableGroupCounts[groupTag] = count;

      if (count > 0) {
        if (!activeRepeatIndexForGroup.containsKey(groupTag)) {
          activeRepeatIndexForGroup[groupTag] = 0;
        }
      } else {
        activeRepeatIndexForGroup.remove(groupTag);
      }

      // Pastikan data jawaban grup sinkron dengan jumlah baru
      _adjustRepeatableGroupAnswers(groupTag, count);
      // Inisialisasi visibilitas untuk anggota baru
      initializeVisibilityForGroup(groupTag, count);

      repeatableGroupCounts.refresh();
      activeRepeatIndexForGroup.refresh();
      repeatableGroupAnswers.refresh();
      questionVisibility.refresh();

      debugPrint("GROUP TAG: $groupTag");
      debugPrint("GROUP COUNT: ${repeatableGroupCounts[groupTag]}");

      updateFlattenedItemsDebounced();
      return;
    }

    // 1. Evaluasi Opsi Bersyarat (Triggers) - LAKUKAN CLEANUP TERLEBIH DAHULU
    evaluateConditionalLogicForQuestion(questionId);

    // 2. Evaluasi Jumps - TAMPILKAN TARGET AKTIF
    evaluateAndExecuteJumps(questionId, value);
    
    // 3. Evaluasi Umur & Recap (Jika pemicu)
    if (question != null && (question.autoClassifyAgeGroup || question.autoCalculateAge || 
        loadedForm.value?.ageGroups.any((r) => r.triggerQuestionId == questionId) == true)) {
      _handleAgeCalculation(question, value);
      recalculateSummaryAgeGroups();
    }

    questionVisibility.refresh();
    updateFlattenedItemsDebounced();
  }

  void evaluateConditionalLogicForQuestion(String parentQuestionId, {bool isInitial = false}) {
    final cleanParentId = parentQuestionId.replaceFirst('question_', '');
    final parentQ = findQuestionById(cleanParentId);
    if (parentQ == null) return;

    debugPrint("EVALUATE LOGIC (Global): $cleanParentId");

    dynamic selectedValue = userAnswers[cleanParentId];
    
    // Fallback untuk pencarian jawaban jika parent berada di dalam grup
    if (selectedValue == null && parentQ.belongsToGroupTag != null && parentQ.belongsToGroupTag!.isNotEmpty) {
       final groupTag = parentQ.belongsToGroupTag!;
       final idx = activeRepeatIndexForGroup[groupTag] ?? 0;
       selectedValue = repeatableGroupAnswers[cleanParentId]?[idx];
    }

    final allPotentialChildIds = <String>{};
    // 1. Ambil semua potensi anak dari opsi (Branching)
    for (final opt in parentQ.options) {
      allPotentialChildIds.addAll(getNextQuestionIds(opt));
    }
    // 2. Ambil semua potensi anak dari aturan lompatan (Jumps)
    for (final jump in parentQ.conditionalJumps) {
      allPotentialChildIds.add(jump.jumpToQuestionId.replaceFirst('question_', ''));
    }
    if (parentQ.unconditionalJumpTarget != null && parentQ.unconditionalJumpTarget!.isNotEmpty) {
      allPotentialChildIds.add(parentQ.unconditionalJumpTarget!.replaceFirst('question_', ''));
    }

    final Set<String> activeChildIds = {};
    // A. Evaluasi Anak dari Opsi
    for (final opt in parentQ.options) {
      bool isMatch = false;
      if (selectedValue is List) {
        isMatch = selectedValue.contains(opt.value);
      } else {
        // PERBAIKAN: Perbandingan Case-Insensitive & Trim
        final String? parentVal = selectedValue?.toString().trim().toLowerCase();
        final String? optVal = opt.value.toString().trim().toLowerCase();
        isMatch = optVal != null && optVal == parentVal;
      }

      if (isMatch) {
        activeChildIds.addAll(getNextQuestionIds(opt));
      }
    }

    // B. Evaluasi Anak dari Jumps (agar pembersihan sinkron)
    for (final jump in parentQ.conditionalJumps) {
      bool isMatch = false;
      final String ruleVal = jump.conditionValue.trim().toLowerCase();
      if (selectedValue is List) {
        isMatch = selectedValue.any((e) => e.toString().trim().toLowerCase() == ruleVal);
      } else {
        isMatch = selectedValue?.toString().trim().toLowerCase() == ruleVal;
      }
      if (isMatch) {
        activeChildIds.add(jump.jumpToQuestionId.replaceFirst('question_', ''));
      }
    }
    if (parentQ.unconditionalJumpTarget != null && parentQ.unconditionalJumpTarget!.isNotEmpty) {
      activeChildIds.add(parentQ.unconditionalJumpTarget!.replaceFirst('question_', ''));
    }

    bool stateChanged = false;
    for (final childId in allPotentialChildIds) {
      final cleanChildId = childId.replaceFirst('question_', '');
      if (cleanChildId == cleanParentId) continue;

      if (!activeChildIds.contains(cleanChildId)) {
        // PERBAIKAN: Selalu paksa sembunyi tanpa isVisible check untuk sinkronisasi mutlak
        setVisible(cleanChildId, false);
        stateChanged = true;
        _hideAllChildrenRecursive(cleanChildId, originalParentToProtect: cleanParentId, isInitial: isInitial);
      }
    }

    for (final childId in activeChildIds) {
      final cleanChildId = childId.replaceFirst('question_', '');
      // PERBAIKAN: Paksa muncul
      setVisible(cleanChildId, true);
      stateChanged = true;
      
      final childQ = findQuestionById(cleanChildId);
      if (childQ != null) {
        if (childQ.belongsToGroupTag != null && childQ.belongsToGroupTag!.isNotEmpty) {
          final count = repeatableGroupCounts[childQ.belongsToGroupTag!] ?? 0;
          for (int i = 0; i < count; i++) {
            evaluateConditionalLogicForGroupQuestion(cleanChildId, i, isInitial: isInitial);
          }
        } else {
          evaluateConditionalLogicForQuestion(cleanChildId, isInitial: isInitial);
        }
      }
    }

    if (stateChanged) {
      questionVisibility.refresh();
      updateFlattenedItems(); // Update langsung tanpa debounce untuk perubahan logika
    }
  }

  void evaluateConditionalLogicForGroupQuestion(String parentQuestionId, int repeatIndex, {bool isInitial = false}) {
    final cleanParentId = parentQuestionId.replaceFirst('question_', '');
    final parentQ = findQuestionById(cleanParentId);
    if (parentQ == null) return;

    debugPrint("EVALUATE LOGIC (Group idx $repeatIndex): $cleanParentId");

    dynamic selectedValue = repeatableGroupAnswers[cleanParentId]?[repeatIndex];
    if (selectedValue == null && (parentQ.belongsToGroupTag == null || parentQ.belongsToGroupTag!.isEmpty)) {
      selectedValue = userAnswers[cleanParentId];
    }

    final allPotentialChildIds = <String>{};
    // 1. Ambil semua potensi anak dari opsi (Branching)
    for (final opt in parentQ.options) {
      allPotentialChildIds.addAll(getNextQuestionIds(opt));
    }
    // 2. Ambil semua potensi anak dari aturan lompatan (Jumps)
    for (final jump in parentQ.conditionalJumps) {
      allPotentialChildIds.add(jump.jumpToQuestionId.replaceFirst('question_', ''));
    }
    if (parentQ.unconditionalJumpTarget != null && parentQ.unconditionalJumpTarget!.isNotEmpty) {
      allPotentialChildIds.add(parentQ.unconditionalJumpTarget!.replaceFirst('question_', ''));
    }

    final Set<String> activeChildIds = {};
    // A. Evaluasi Anak dari Opsi
    for (final opt in parentQ.options) {
      bool isMatch = false;
      if (selectedValue is List) {
        isMatch = selectedValue.contains(opt.value);
      } else {
        // PERBAIKAN: Perbandingan Case-Insensitive & Trim
        final String? parentVal = selectedValue?.toString().trim().toLowerCase();
        final String? optVal = opt.value.toString().trim().toLowerCase();
        isMatch = optVal != null && optVal == parentVal;
      }

      if (isMatch) {
        activeChildIds.addAll(getNextQuestionIds(opt));
      }
    }

    // B. Evaluasi Anak dari Jumps (agar pembersihan sinkron)
    for (final jump in parentQ.conditionalJumps) {
      bool isMatch = false;
      final String ruleVal = jump.conditionValue.trim().toLowerCase();
      if (selectedValue is List) {
        isMatch = selectedValue.any((e) => e.toString().trim().toLowerCase() == ruleVal);
      } else {
        isMatch = selectedValue?.toString().trim().toLowerCase() == ruleVal;
      }
      if (isMatch) {
        activeChildIds.add(jump.jumpToQuestionId.replaceFirst('question_', ''));
      }
    }
    if (parentQ.unconditionalJumpTarget != null && parentQ.unconditionalJumpTarget!.isNotEmpty) {
      activeChildIds.add(parentQ.unconditionalJumpTarget!.replaceFirst('question_', ''));
    }

    bool stateChanged = false;
    for (final childId in allPotentialChildIds) {
      final cleanChildId = childId.replaceFirst('question_', '');
      if (cleanChildId == cleanParentId) continue;

      if (!activeChildIds.contains(cleanChildId)) {
        // PERBAIKAN: Selalu paksa sembunyi
        setVisible(cleanChildId, false, index: repeatIndex);
        stateChanged = true;
        _hideAllChildrenRecursive(cleanChildId, index: repeatIndex, originalParentToProtect: cleanParentId, isInitial: isInitial);
      }
    }

    for (final childId in activeChildIds) {
      final cleanChildId = childId.replaceFirst('question_', '');
      // PERBAIKAN: Paksa muncul
      setVisible(cleanChildId, true, index: repeatIndex);
      stateChanged = true;
      
      final childQ = findQuestionById(cleanChildId);
      if (childQ != null) {
        if (childQ.belongsToGroupTag != null && childQ.belongsToGroupTag!.isNotEmpty) {
          evaluateConditionalLogicForGroupQuestion(cleanChildId, repeatIndex, isInitial: isInitial);
        } else {
          evaluateConditionalLogicForQuestion(cleanChildId, isInitial: isInitial);
        }
      }
    }

    if (stateChanged) {
      questionVisibility.refresh();
      updateFlattenedItems(); // Update langsung
    }
  }

  void _hideAllChildrenRecursive(String questionId, {int? index, String? originalParentToProtect, bool isInitial = false}) {
    final cleanQId = questionId.replaceFirst('question_', '');
    final q = findQuestionById(cleanQId);
    if (q == null) return;
    
    final allChildIds = <String>{};
    for (final opt in q.options) {
      allChildIds.addAll(getNextQuestionIds(opt));
    }

    for (final jump in q.conditionalJumps) {
      final targetId = jump.jumpToQuestionId.replaceFirst('question_', '');
      if (targetId.isNotEmpty && targetId != 'END_OF_FORM' && targetId != 'END_OF_SECTION') {
        allChildIds.add(targetId);
      }
    }
    
    final List<String> toClear = [];
    for (final childId in allChildIds) {
      final cleanChildId = childId.replaceFirst('question_', '');
      
      if (originalParentToProtect != null && cleanChildId == originalParentToProtect.replaceFirst('question_', '')) {
        continue;
      }

      // PERBAIKAN: Selalu sembunyikan dan recurse tanpa mengecek isVisible
      setVisible(cleanChildId, false, index: index);
      toClear.add(cleanChildId);
      _hideAllChildrenRecursive(cleanChildId, index: index, originalParentToProtect: originalParentToProtect ?? cleanQId, isInitial: isInitial);
    }
    if (toClear.isNotEmpty && !isInitial) _clearAnswersForSkippedQuestions(toClear, specificRepeatIndex: index);
  }

  void initializeVisibilityForGroup(String groupTag, int count) {
    if (loadedForm.value == null) return;

    final groupQuestions = loadedForm.value!.sections
        .expand((section) => section.questions)
        .where((q) => q.belongsToGroupTag == groupTag)
        .toList();

    debugPrint("INIT VISIBILITY FOR GROUP: $groupTag");
    debugPrint("GROUP QUESTIONS FOUND: ${groupQuestions.length}");
    debugPrint("GROUP COUNT: $count");

    for (final q in groupQuestions) {
      final bool parent = isParentQuestion(q.id);
      final bool child = isConditionalChild(q);

      for (int i = 0; i < count; i++) {
        final String visKey = _getVisKey(q.id, i);
        
        // Aturan: Jangan timpa jika sudah ada (untuk menjaga state saat swiping/edit)
        // kecuali jika memang benar-benar baru.
        if (!questionVisibility.containsKey(visKey)) {
          if (parent) {
            setVisible(q.id, true, index: i);
          } else if (child) {
            setVisible(q.id, false, index: i);
          } else {
            setVisible(q.id, true, index: i);
          }
        }

        debugPrint(
          "VISIBILITY GROUP QUESTION: ${q.questionText}, index: $i, visible: ${isVisible(q.id, index: i)}"
        );
      }
    }

    questionVisibility.refresh();
  }

  void updateRepeatableGroupAnswer(String questionId, int repeatIndex, dynamic value) {
    final cleanId = questionId.replaceFirst('question_', '');
    final question = findQuestionById(cleanId);
    if (question == null) return;

    if (!repeatableGroupAnswers.containsKey(cleanId)) {
      repeatableGroupAnswers[cleanId] = RxMap<int, dynamic>();
    }
    
    dynamic oldValue = repeatableGroupAnswers[cleanId]![repeatIndex];
    repeatableGroupAnswers[cleanId]![repeatIndex] = value;

    if (question.hasOtherOption && value != _kOtherOptionValue && oldValue == _kOtherOptionValue) {
      updateOtherAnswer(cleanId, '', repeatIndex: repeatIndex);
    }

    if (oldValue != value) {
      bool isParent = loadedForm.value?.sections.any((s) => s.questions.any(
              (qChild) => qChild.dependentOptions?.parentQuestionId == cleanId)) ?? false;
      if (isParent) _resetDependentChildrenAnswers(cleanId, repeatIndex: repeatIndex);
    }

    markFormAsChanged();

    // 1. Evaluasi Opsi Bersyarat - LAKUKAN CLEANUP TERLEBIH DAHULU
    evaluateConditionalLogicForGroupQuestion(cleanId, repeatIndex);

    // 2. Evaluasi Jumps (Khusus Indeks Ini) - TAMPILKAN TARGET AKTIF
    evaluateAndExecuteJumps(cleanId, value, repeatIndex: repeatIndex);

    // 3. Evaluasi Umur & Recap (Khusus Indeks Ini)
    if (question.autoClassifyAgeGroup || question.autoCalculateAge ||
        loadedForm.value?.ageGroups.any((r) => r.triggerQuestionId == cleanId) == true) {
      _handleAgeCalculation(question, value, repeatIndex: repeatIndex);
      recalculateSummaryAgeGroups();
      _evaluateAgeGroupVisibility(specificIndex: repeatIndex, specificGroupTag: question.belongsToGroupTag);
    }
    
    questionVisibility.refresh();
    updateFlattenedItemsDebounced();
  }

  void _handleAgeCalculation(FormQuestion sourceQuestion, dynamic dateValue, {int? repeatIndex}) {
    if (sourceQuestion.type != QuestionType.date || !sourceQuestion.autoCalculateAge || sourceQuestion.ageTargetQuestionId == null) {
      return;
    }

    if (dateValue != null && dateValue.toString().isNotEmpty) {
      try {
        DateTime? birthDate;
        String dateStr = dateValue.toString();
        
        try {
          birthDate = DateFormat('dd/MM/yyyy').parseStrict(dateStr);
        } catch (_) {
          birthDate = DateTime.tryParse(dateStr);
        }

        if (birthDate != null) {
          final int age = calculateAge(birthDate);
          final String targetId = sourceQuestion.ageTargetQuestionId!;
          
          debugPrint("AGE CALCULATION: Source=${sourceQuestion.questionText}, BirthDate=$birthDate, CalculatedAge=$age, TargetId=$targetId");

          final targetQuestion = findQuestionById(targetId);
          if (targetQuestion != null) {
             if (repeatIndex != null && targetQuestion.belongsToGroupTag == sourceQuestion.belongsToGroupTag) {
               updateRepeatableGroupAnswer(targetId, repeatIndex, age.toString());
             } else {
               updateUserAnswer(targetId, age.toString());
             }
          }
        }
      } catch (e) {
        debugPrint("Error in _handleAgeCalculation: $e");
      }
    }
  }

  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Melakukan kalkulasi rekapitulasi data (jumlah penduduk per kelompok usia) secara real-time.
  void recalculateSummaryAgeGroups() {
    debugPrint("RECAP: === Memulai Kalkulasi Rekapitulasi ===");
    final Map<String, Map<String, int>> newSummaries = {};

    void addCount(String groupKey, String type) {
      newSummaries.putIfAbsent(groupKey, () => {});
      newSummaries[groupKey]![type] = (newSummaries[groupKey]![type] ?? 0) + 1;
    }

    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null || !question.autoClassifyAgeGroup || question.summaryGroupKey == null) continue;

      final groupKey = question.summaryGroupKey!.trim();
      debugPrint("RECAP: Menemukan Pertanyaan Classifier: '${question.questionText}' (ID: $qId, GroupKey: '$groupKey')");
      
      if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
        final ageStr = userAnswers[question.ageTargetQuestionId ?? '']?.toString() ?? '';
        final gender = userAnswers[question.genderSourceQuestionId ?? '']?.toString() ?? '';
        if (ageStr.isNotEmpty) {
          final int age = int.tryParse(ageStr) ?? -1;
          if (age >= 0) {
            final flags = _getAgeGroupFlags(age, gender, allAnswersOfPerson: userAnswers, personLabel: "Mandiri");
            for (var flag in flags) {
              addCount(groupKey, flag);
            }
          }
        }
      } else {
        final groupTag = question.belongsToGroupTag!;
        final count = repeatableGroupCounts[groupTag] ?? 0;
        debugPrint("RECAP: Memproses Anggota di Grup '$groupTag', Jumlah: $count");

        for (int i = 0; i < count; i++) {
          final ageStr = repeatableGroupAnswers[question.ageTargetQuestionId ?? '']?[i]?.toString() ?? '';
          final gender = repeatableGroupAnswers[question.genderSourceQuestionId ?? '']?[i]?.toString() ?? '';
          
          if (ageStr.isNotEmpty) {
            final int age = int.tryParse(ageStr) ?? -1;
            if (age >= 0) {
              final Map<String, dynamic> personAnswers = {};
              repeatableGroupAnswers.forEach((qId, map) {
                if (map.containsKey(i)) personAnswers[qId] = map[i];
              });

              final flags = _getAgeGroupFlags(age, gender, allAnswersOfPerson: personAnswers, personLabel: "Anggota ke-${i+1}");
              for (var flag in flags) {
                addCount(groupKey, flag);
              }
            }
          } else {
             debugPrint("RECAP: Anggota ke-${i+1} dilewati karena umur kosong.");
          }
        }
      }
    }

    summaryAgeGroups.clear();
    newSummaries.forEach((key, value) {
      summaryAgeGroups[key] = value.obs;
    });
    
    _updateComputedSummaryFields();
    _evaluateAgeGroupVisibility();
    
    // Perbaikan: Jangan panggil evaluateAndExecuteJumps dari pertanyaan pertama secara membabi buta.
    // Ini menyebabkan pertanyaan di tengah form tersembunyi jika bukan target lompatan pertanyaan awal.
    
    summaryAgeGroups.refresh();
    debugPrint("RECAP: === Kalkulasi Selesai. Hasil: ${newSummaries.toString()} ===");
  }

  List<String> _getAgeGroupFlags(int age, String gender, {Map<String, dynamic>? allAnswersOfPerson, String personLabel = "", String? currentQuestionId}) {
    List<String> flags = [];
    final String g = gender.toLowerCase().trim();
    final dynamicAgeGroups = loadedForm.value?.ageGroups ?? [];
    
    for (var rule in dynamicAgeGroups) {
      // 1. Cek Kriteria Umur
      bool ageMatch = age >= rule.minAge && age <= rule.maxAge;
      
      // 2. Cek Kriteria Gender
      bool genderMatch = true;
      String ruleGender = rule.gender.toLowerCase().trim();

      // PERBAIKAN: Jika rule butuh gender spesifik tapi input gender kosong, maka GAGAL match.
      if (ruleGender != 'semua' && g.isEmpty) {
        genderMatch = false;
      } else if (ruleGender == 'laki-laki' || ruleGender == 'pria' || ruleGender == 'male') {
        genderMatch = g.contains('laki') || g == 'l' || g == 'male' || g == 'pria';
      } else if (ruleGender == 'perempuan' || ruleGender == 'wanita' || ruleGender == 'female') {
        genderMatch = g.contains('perempuan') || g == 'p' || g == 'female' || g == 'wanita';
      }
      
      // 3. Cek Kriteria Jawaban Pemicu
      bool triggerMatch = true;
      String debugTriggerInfo = "";

      if (rule.triggerQuestionId != null && rule.triggerAnswerValue != null) {
        // PERBAIKAN: Jika rule ini mengecek jawaban pertanyaan yang sedang kita evaluasi visibilitasnya,
        // maka anggap trigger match = true agar pertanyaannya muncul untuk diisi.
        if (currentQuestionId != null && rule.triggerQuestionId == currentQuestionId) {
          triggerMatch = true;
        } else {
          final String? personAnswer = allAnswersOfPerson?[rule.triggerQuestionId]?.toString();
          String cleanPersonAns = personAnswer?.toLowerCase().trim() ?? "";
          String cleanRuleAns = rule.triggerAnswerValue!.toLowerCase().trim();
          
          triggerMatch = cleanPersonAns == cleanRuleAns;
          debugTriggerInfo = "(Trigger ID: ${rule.triggerQuestionId}, Jawaban: '$cleanPersonAns', Butuh: '$cleanRuleAns')";
        }
      }
      
      if (ageMatch && genderMatch && triggerMatch) {
        flags.add(rule.key.trim());
      } else {
        // Log untuk membantu debug rule yang GAGAL (hanya jika ada trigger pemicunya)
        if (rule.triggerQuestionId != null) {
           debugPrint("RECAP: [$personLabel] Gagal di rule '${rule.label}'. Umur Match: $ageMatch, Gender Match: $genderMatch, Trigger Match: $triggerMatch $debugTriggerInfo");
        }
      }
    }
    
    return flags;
  }

  void _updateComputedSummaryFields() {
    for (var qId in _allQuestionIdsInOrder) {
      final question = findQuestionById(qId);
      if (question == null || !question.isComputedSummary) continue;

      final val = getSummaryValue(question.summaryType?.trim(), question.summaryGroupKey?.trim());
      userAnswers[qId] = val.toString();
    }
  }

  int getSummaryValue(String? summaryType, String? summaryGroupKey) {
    if (summaryType == null || summaryGroupKey == null) return 0;
    return summaryAgeGroups[summaryGroupKey.trim()]?[summaryType.trim()] ?? 0;
  }

  void _evaluateAgeGroupVisibility({int? specificIndex, String? specificGroupTag}) {
    bool visibilityChanged = false;
    if (loadedForm.value == null) return;

    for (var section in loadedForm.value!.sections) {
      for (var q in section.questions) {
        if (!q.isConditionalByAgeGroup) continue;

        if (q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
          final groupTag = q.belongsToGroupTag!;
          if (specificGroupTag != null && groupTag != specificGroupTag) continue;
          
          final count = repeatableGroupCounts[groupTag] ?? 0;
          final List<int> indices = (specificIndex != null) ? [specificIndex] : List.generate(count, (i) => i);

          for (int i in indices) {
            final bool shouldBeVisible = _shouldShowByAgeGroup(q, specificRepeatIndex: i);
            if (isVisible(q.id, index: i) != shouldBeVisible) {
              setVisible(q.id, shouldBeVisible, index: i);
              visibilityChanged = true;
            }
          }
        } else {
          if (specificGroupTag != null) continue;
          final bool shouldBeVisible = _shouldShowByAgeGroup(q);
          if (isVisible(q.id) != shouldBeVisible) {
            setVisible(q.id, shouldBeVisible);
            visibilityChanged = true;
          }
        }
      }
    }
    
    if (visibilityChanged) {
      questionVisibility.refresh();
      updateFlattenedItemsDebounced();
    }
  }

  bool _shouldShowByAgeGroup(FormQuestion question, {int? specificRepeatIndex}) {
    if (!question.isConditionalByAgeGroup) return true;

    // --- OPSI B: LOGIKA PER INDIVIDU ---
    // Jika pertanyaan ini berada di dalam grup berulang (repeatable)
    if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty) {
      final groupTag = question.belongsToGroupTag!;
      // Gunakan specificRepeatIndex jika diberikan (saat evaluasi loop),
      // jika tidak gunakan active index (saat refresh UI/swipe)
      final int activeIdx = specificRepeatIndex ?? (activeRepeatIndexForGroup[groupTag] ?? 0);

      // Cari pertanyaan sumber (yang punya autoClassifyAgeGroup) di dalam grup yang sama
      final sourceQ = _questionCache.values.firstWhereOrNull((q) =>
        q.belongsToGroupTag == groupTag && q.autoClassifyAgeGroup);

      if (sourceQ != null) {
        final ageStr = repeatableGroupAnswers[sourceQ.ageTargetQuestionId ?? '']?[activeIdx]?.toString() ?? '';
        final gender = repeatableGroupAnswers[sourceQ.genderSourceQuestionId ?? '']?[activeIdx]?.toString() ?? '';
        
        if (ageStr.isNotEmpty) {
          final int age = int.tryParse(ageStr) ?? -1;
          if (age >= 0) {
            // PERBAIKAN: Ambil semua jawaban milik individu index ini agar trigger (Ya/Tidak) bisa terbaca
            final Map<String, dynamic> personAnswers = {};
            repeatableGroupAnswers.forEach((qId, map) {
              if (map.containsKey(activeIdx)) personAnswers[qId] = map[activeIdx];
            });

            // PERBAIKAN KRITIKAL: Kirim currentQuestionId agar trigger-self diabaikan khusus untuk visibilitas
            final personFlags = _getAgeGroupFlags(age, gender, 
                allAnswersOfPerson: personAnswers, 
                currentQuestionId: question.id);

            for (var type in question.visibleWhenAgeGroups) {
              if (personFlags.contains(type)) return true;
            }
          }
        }
        return false; // Sembunyikan jika kriteria individu tidak masuk
      }
    }

    // --- TETAP PAKAI OPSI A UNTUK PERTANYAAN GLOBAL (DI LUAR GRUP) ---
    final groupKey = question.summaryGroupKey?.trim(); 
    if (groupKey == null) return false;

    final summaries = summaryAgeGroups[groupKey];
    if (summaries == null) return false;

    for (var type in question.visibleWhenAgeGroups) {
      if ((summaries[type] ?? 0) > 0) return true;
    }
    return false;
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
          
          // JANGAN gunakan removeWhere di sini agar data tidak hilang saat tidak sengaja kurangi angka
          // answerMap.removeWhere((key, _) => key >= newCount);
          
          // Siapkan data default jika jumlah bertambah
          for (int i = 0; i < newCount; i++) {
            // Jika benar-benar baru (belum ada di map sama sekali), beri nilai default
            if (!answerMap.containsKey(i)) {
              answerMap[i] = _getDefaultAnswerForQuestionType(qInGroup.type);
            }
          }
          
          if (qInGroup.hasOtherOption) {
            if (!repeatableGroupOtherAnswers.containsKey(qInGroup.id)) {
              repeatableGroupOtherAnswers[qInGroup.id] = RxMap<int, String>();
            }
            final otherAnswerMap = repeatableGroupOtherAnswers[qInGroup.id]!;
            for (int i = 0; i < newCount; i++) {
              if (!otherAnswerMap.containsKey(i)) otherAnswerMap[i] = '';
            }
          }
        }
      }
    }
    
    // Sinkronisasi index aktif agar tidak out of bounds
    if (newCount == 0) {
      activeRepeatIndexForGroup.remove(groupTag);
    } else {
      if (!activeRepeatIndexForGroup.containsKey(groupTag) ||
          activeRepeatIndexForGroup[groupTag]! >= newCount) {
        activeRepeatIndexForGroup[groupTag] = 0;
      }
    }
    
    repeatableGroupAnswers.refresh();
  }

  void forceCleanupAllData() {
    userAnswers.clear();
    userOtherAnswers.clear();
    
    // Paksa hapus semua isi map di dalam repeatable group
    repeatableGroupAnswers.forEach((key, map) => map.clear());
    repeatableGroupAnswers.clear();
    
    repeatableGroupOtherAnswers.forEach((key, map) => map.clear());
    repeatableGroupOtherAnswers.clear();
    
    repeatableGroupCounts.clear();
    questionVisibility.clear();
    activeRepeatIndexForGroup.clear();
  }


  void refreshVisibility() {
    if (_allQuestionIdsInOrder.isEmpty || loadedForm.value == null) return;
    
    // 1. Segarkan logika kategori umur
    _evaluateAgeGroupVisibility();

    // 2. Segarkan logika kondisional dan lompatan secara berurutan
    // agar tidak ada pertanyaan yang tersembunyi secara tidak sengaja
    for (var qId in _allQuestionIdsInOrder) {
      final q = findQuestionById(qId);
      if (q == null) continue;

      if (q.belongsToGroupTag != null && q.belongsToGroupTag!.isNotEmpty) {
        final count = repeatableGroupCounts[q.belongsToGroupTag!] ?? 0;
        for (int i = 0; i < count; i++) {
          if (isVisible(q.id, index: i)) {
            // GUNAKAN isInitial: true AGAR DATA TIDAK TERHAPUS SAAT REFRESH/GESER
            evaluateConditionalLogicForGroupQuestion(q.id, i, isInitial: true);
            evaluateAndExecuteJumps(q.id, repeatableGroupAnswers[q.id]?[i], isInitial: true, repeatIndex: i);
          }
        }
      } else {
        if (isVisible(q.id)) {
          // GUNAKAN isInitial: true AGAR DATA TIDAK TERHAPUS SAAT REFRESH/GESER
          evaluateConditionalLogicForQuestion(q.id, isInitial: true);
          evaluateAndExecuteJumps(q.id, userAnswers[q.id], isInitial: true);
        }
      }
    }
    
    questionVisibility.refresh();
    updateFlattenedItemsDebounced();
  }

  void goToNextRepeatableItem(String groupTag) {
    if (repeatableGroupCounts.containsKey(groupTag) &&
        activeRepeatIndexForGroup.containsKey(groupTag) &&
        repeatableGroupCounts[groupTag]! > 0) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      int maxIdx = repeatableGroupCounts[groupTag]! - 1;
      if (currentIdx < maxIdx) {
        activeRepeatIndexForGroup[groupTag] = currentIdx + 1;
        refreshVisibility(); // REFRESH LOGIC SAAT GESER
      }
    }
  }

  void goToPreviousRepeatableItem(String groupTag) {
    if (activeRepeatIndexForGroup.containsKey(groupTag)) {
      int currentIdx = activeRepeatIndexForGroup[groupTag]!;
      if (currentIdx > 0) {
        activeRepeatIndexForGroup[groupTag] = currentIdx - 1;
        refreshVisibility(); // REFRESH LOGIC SAAT GESER
      }
    }
  }

  void updateGridAnswer(String questionId, int? repeatIndex, String rowLabel,
      String colLabel, String subColLabel, String? value) {
    String? parseableValue = value?.replaceAll(',', '.');
    num? numericValue = parseableValue != null && parseableValue.isNotEmpty
        ? num.tryParse(parseableValue)
        : null;

    if (repeatIndex != null) {
      if (!repeatableGroupAnswers.containsKey(questionId)) {
        repeatableGroupAnswers[questionId] = RxMap<int, dynamic>();
      }
      if (!repeatableGroupAnswers[questionId]!.containsKey(repeatIndex)) {
        repeatableGroupAnswers[questionId]![repeatIndex] =
            <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
          getGridMapForValidation(repeatableGroupAnswers[questionId]![repeatIndex]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(
          colLabel, () => {})[subColLabel] = numericValue;
      repeatableGroupAnswers[questionId]![repeatIndex] = gridAnswers;
    } else {
      if (!userAnswers.containsKey(questionId) ||
          userAnswers[questionId] == null ||
          userAnswers[questionId] is! Map) {
        userAnswers[questionId] = <String, Map<String, Map<String, num?>>>{};
      }
      Map<String, Map<String, Map<String, num?>>> gridAnswers =
          getGridMapForValidation(userAnswers[questionId]);
      gridAnswers.putIfAbsent(rowLabel, () => {}).putIfAbsent(
          colLabel, () => {})[subColLabel] = numericValue;
      userAnswers[questionId] = gridAnswers;
    }
    markFormAsChanged();
  }

  String? _performLocalValidation(FormQuestion question, dynamic answer,
      String questionDisplayName, {int? repeatIndex}) {
    if (!isVisible(question.id, index: repeatIndex)) return null;
    bool isEmpty = _isAnswerEmpty(answer, question.type);
    String? otherText;
    if (question.hasOtherOption) {
      if (question.belongsToGroupTag != null &&
          question.belongsToGroupTag!.isNotEmpty &&
          repeatIndex != null) {
        otherText = repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        otherText = userOtherAnswers[question.id];
      }
      if (answer == _kOtherOptionValue &&
          (otherText == null || otherText.trim().isEmpty)) {
        if (question.isRequired) {
          return 'Isian "Lainnya" pada "$questionDisplayName" wajib diisi.';
        }
        isEmpty = true;
      } else if (answer == _kOtherOptionValue &&
          (otherText != null && otherText.trim().isNotEmpty)) {
        isEmpty = false;
      }
    }
    if (question.isRequired && isEmpty) {
      return 'Pertanyaan "$questionDisplayName" wajib diisi.';
    }
    if (isEmpty && !question.isRequired) return null;
    final ValidationRule rule = question.validation;
    if (question.type == QuestionType.gridNumeric) {
      final gridData = getGridMapForValidation(answer);
      final List<String> rowLabels =
          question.gridRowLabels.isNotEmpty ? question.gridRowLabels : [""];
      final List<String> colLabels = question.gridColumnLabels;
      final List<String> subColLabels = question.gridSubColumnLabels;
      for (final row in rowLabels) {
        for (final col in colLabels) {
          for (final subCol in subColLabels) {
            final cellValue = gridData[row]?[col]?[subCol];
            if (rule.predefinedRule == 'gridAllCellsRequired' &&
                (cellValue == null || cellValue.toString().trim().isEmpty)) {
              return 'Semua sel pada grid "$questionDisplayName" wajib diisi.';
            }
            if (cellValue != null) {
              if (rule.minValue != null && cellValue < rule.minValue!) {
                return 'Nilai di grid "$questionDisplayName" (kolom $col) minimal ${rule.minValue}.';
              }
              if (rule.maxValue != null && cellValue > rule.maxValue!) {
                return 'Nilai di grid "$questionDisplayName" (kolom $col) maksimal ${rule.maxValue}.';
              }
            }
          }
        }
      }
    }
    String effectiveStringValue =
        (answer == _kOtherOptionValue && otherText != null)
            ? otherText.trim()
            : (answer is String ? answer.trim() : "");
    if (effectiveStringValue.isNotEmpty) {
      if (rule.minLength != null &&
          effectiveStringValue.length < rule.minLength!) {
        return 'Jawaban "$questionDisplayName" minimal ${rule.minLength} karakter.';
      }
      if (rule.maxLength != null &&
          effectiveStringValue.length > rule.maxLength!) {
        return 'Jawaban "$questionDisplayName" maksimal ${rule.maxLength} karakter.';
      }
      if (rule.regex != null &&
          rule.regex!.isNotEmpty &&
          !RegExp(rule.regex!).hasMatch(effectiveStringValue)) {
        return 'Format "$questionDisplayName" tidak sesuai (${rule.regex}).';
      }
      if (rule.predefinedRule == 'nik' &&
          !RegExp(r'^\d{16}$').hasMatch(effectiveStringValue)) {
        return 'NIK harus tepat 16 digit angka. (Sekarang: ${effectiveStringValue.length} digit)';
      }
      if (rule.predefinedRule == 'noKK' &&
          !RegExp(r'^\d{16}$').hasMatch(effectiveStringValue)) {
        return 'Nomor KK harus tepat 16 digit angka. (Sekarang: ${effectiveStringValue.length} digit)';
      }
      if (rule.predefinedRule == 'email' && !GetUtils.isEmail(effectiveStringValue)) {
        return 'Format email untuk "$questionDisplayName" tidak valid.';
      }
      if (rule.predefinedRule == 'numbersOnly' &&
          !GetUtils.isNumericOnly(
              effectiveStringValue.replaceAll(',', '').replaceAll('.', ''))) {
        return '"$questionDisplayName" hanya boleh berisi angka.';
      }
    }
    if (question.type == QuestionType.number &&
        answer != null &&
        answer.toString().isNotEmpty) {
      num? numAnswer = num.tryParse(answer.toString().replaceAll(',', '.'));
      if (numAnswer == null && answer.toString().isNotEmpty) {
        return '"$questionDisplayName" harus berupa angka.';
      }
      if (numAnswer == null) return null;
      if (rule.minValue != null && numAnswer < rule.minValue!) {
        return '"$questionDisplayName" minimal ${rule.minValue}.';
      }
      if (rule.maxValue != null && numAnswer > rule.maxValue!) {
        return '"$questionDisplayName" maksimal ${rule.maxValue}.';
      }
    }
    return null;
  }

  String _getImageAnswerKey(String questionId, int? repeatIndex) {
    return repeatIndex == null ? questionId : '${questionId}_$repeatIndex';
  }

  File? getSelectedImageFile(String questionId, {int? repeatIndex}) {
    return selectedImageFiles[_getImageAnswerKey(questionId, repeatIndex)];
  }

  Map<String, dynamic>? getImageAnswerMap(String questionId,
      {int? repeatIndex}) {
    dynamic answer;
    if (repeatIndex != null) {
      answer = repeatableGroupAnswers[questionId]?[repeatIndex];
    } else {
      answer = userAnswers[questionId];
    }
    return answer is Map ? Map<String, dynamic>.from(answer) : null;
  }

  String? getAnswerImageUrl(String questionId, {int? repeatIndex}) {
    final Map<String, dynamic>? answerMap =
        getImageAnswerMap(questionId, repeatIndex: repeatIndex);
    final dynamic imageUrl = answerMap?['imageUrl'];
    return (imageUrl is String && imageUrl.trim().isNotEmpty) ? imageUrl : null;
  }

  String? getAnswerLocalImagePath(String questionId, {int? repeatIndex}) {
    final Map<String, dynamic>? answerMap =
        getImageAnswerMap(questionId, repeatIndex: repeatIndex);
    final dynamic localPath = answerMap?['localPath'];
    if (localPath is String && localPath.trim().isNotEmpty) return localPath;
    return getSelectedImageFile(questionId, repeatIndex: repeatIndex)?.path;
  }

  bool hasAnswerImage(String questionId, {int? repeatIndex}) {
    return getSelectedImageFile(questionId, repeatIndex: repeatIndex) != null ||
        getAnswerLocalImagePath(questionId, repeatIndex: repeatIndex) != null ||
        getAnswerImageUrl(questionId, repeatIndex: repeatIndex) != null;
  }

  Future<void> pickAnswerImageFromCamera(
      {required String questionId, int? repeatIndex}) async {
    await pickAndUploadAnswerImage(
        questionId: questionId, source: ImageSource.camera, repeatIndex: repeatIndex);
  }

  Future<void> pickAnswerImageFromGallery(
      {required String questionId, int? repeatIndex}) async {
    await pickAndUploadAnswerImage(
        questionId: questionId, source: ImageSource.gallery, repeatIndex: repeatIndex);
  }

  void clearAnswerImage(String questionId, {int? repeatIndex}) {
    final String answerKey = _getImageAnswerKey(questionId, repeatIndex);
    selectedImageFiles.remove(answerKey);
    selectedImageFiles.refresh();
    if (repeatIndex != null) {
      updateRepeatableGroupAnswer(questionId, repeatIndex, null);
    } else {
      updateUserAnswer(questionId, null);
    }
  }

  /// Mengambil foto dari kamera atau galeri, lalu mengunggahnya ke server (Firebase/Lokal).
  Future<void> pickAndUploadAnswerImage(
      {required String questionId,
      required ImageSource source,
      int? repeatIndex}) async {
    try {
      final FormItem? form = loadedForm.value;
      final User? user = _auth.currentUser;
      if (form == null || user == null) {
        showSafeSnackbar(
          title: 'Error',
          message: 'Form atau pengguna tidak valid.',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }

      // Ambil info desa yang dipilih
      final village = allVillages.firstWhereOrNull((v) => v.villageId == selectedVillageId.value);
      final bool useLocalApi = village?.serverType == 'local_api';

      final XFile? pickedFile = await _imagePicker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1280);
      if (pickedFile == null) return;
      final File imageFile = File(pickedFile.path);
      if (!imageFile.existsSync() || imageFile.lengthSync() == 0) {
        throw "File gambar tidak terbaca atau kosong.";
      }

      final String answerKey = _getImageAnswerKey(questionId, repeatIndex);
      selectedImageFiles[answerKey] = imageFile;
      selectedImageFiles.refresh();

      isUploadingImage.value = true;
      markFormAsChanged();

      String? downloadUrl;
      String? storagePath;

      if (useLocalApi) {
        // --- JALUR LAPTOP/SERVER DESA ---
        String baseUrl = village!.apiBaseUrl ?? "http://${village.localIpAddress}:${village.port}";
        if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
        
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var resData = jsonDecode(response.body);
          downloadUrl = resData['imageUrl']; // URL dari laptop
          storagePath = "local_server/${path.basename(imageFile.path)}";
        } else {
          throw "Server Desa gagal menerima gambar (${response.statusCode})";
        }
      } else {
        // --- JALUR FIREBASE (DEFAULT) ---
        final String repeatSuffix = repeatIndex != null ? '_$repeatIndex' : '';
        final String fileName = '$questionId${repeatSuffix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        storagePath = 'submission_images/${form.id}/$fileName';

        final Reference ref = _storage.ref().child(storagePath);
        final UploadTask uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
        final TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      final Map<String, dynamic> finalAnswer = {
        'type': 'imageUpload',
        'localPath': imageFile.path,
        'imageUrl': downloadUrl,
        'storagePath': storagePath,
        'source': source == ImageSource.camera ? 'camera' : 'gallery',
        'isUploading': false,
        'updatedAt': Timestamp.now(),
      };

      if (repeatIndex != null) {
        updateRepeatableGroupAnswer(questionId, repeatIndex, finalAnswer);
      } else {
        updateUserAnswer(questionId, finalAnswer);
      }
      
      showSafeSnackbar(
        title: 'Berhasil',
        message: 'Gambar berhasil diunggah.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

    } catch (e, s) {
      debugPrint('Error upload image: $e\n$s');
      
      // Update status ke Gagal agar UI memberikan feedback yang benar (bukan loading terus)
      final String? existingUrl = getAnswerImageUrl(questionId, repeatIndex: repeatIndex);
      final String? localPath = getAnswerLocalImagePath(questionId, repeatIndex: repeatIndex);

      final Map<String, dynamic> errorAnswer = {
        'type': 'imageUpload',
        'localPath': localPath,
        'imageUrl': existingUrl,
        'isUploading': false,
        'uploadError': e.toString(),
        'updatedAt': Timestamp.now(),
      };

      if (repeatIndex != null) {
        updateRepeatableGroupAnswer(questionId, repeatIndex, errorAnswer);
      } else {
        updateUserAnswer(questionId, errorAnswer);
      }

      showSafeSnackbar(
        title: 'Upload Gagal',
        message: 'Proses terhenti: $e.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> removeAnswerImage(
      {required String questionId, int? repeatIndex}) async {
    try {
      dynamic currentAnswer;
      if (repeatIndex != null) {
        currentAnswer = repeatableGroupAnswers[questionId]?[repeatIndex];
      } else {
        currentAnswer = userAnswers[questionId];
      }
      String? storagePath;
      if (currentAnswer is Map && currentAnswer['storagePath'] != null) {
        storagePath = currentAnswer['storagePath'].toString();
      }
      final String answerKey = _getImageAnswerKey(questionId, repeatIndex);
      selectedImageFiles.remove(answerKey);
      selectedImageFiles.refresh();
      if (repeatIndex != null) {
        updateRepeatableGroupAnswer(questionId, repeatIndex, null);
      } else {
        updateUserAnswer(questionId, null);
      }
      markFormAsChanged();
      if (storagePath != null && storagePath.trim().isNotEmpty) {
        _storage.ref().child(storagePath).delete().catchError((error) {
          debugPrint('Info: File sudah tidak ada di Storage atau gagal hapus: $error');
        });
      }
    } catch (e) {
      debugPrint("Error removeAnswerImage: $e");
    }
  }

  /// Mengambil koordinat GPS saat ini menggunakan [Geolocator].
  Future<void> getCurrentLocationAnswer(
      {required String questionId, int? repeatIndex}) async {
    try {
      isGettingLocation.value = true;
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showSafeSnackbar(
          title: 'GPS Tidak Aktif',
          message: 'Aktifkan lokasi/GPS terlebih dahulu.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        showSafeSnackbar(
          title: 'Izin Lokasi Ditolak',
          message: 'Aplikasi tidak dapat mengambil lokasi karena izin ditolak.',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        showSafeSnackbar(
          title: 'Izin Lokasi Ditolak Permanen',
          message: 'Aktifkan izin lokasi dari pengaturan aplikasi.',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        await Geolocator.openAppSettings();
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final Map<String, dynamic> answerMap = {
        'type': 'location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'source': 'gps',
        'capturedAt': Timestamp.now(),
      };
      if (repeatIndex != null) {
        updateRepeatableGroupAnswer(questionId, repeatIndex, answerMap);
      } else {
        updateUserAnswer(questionId, answerMap);
      }
      showSafeSnackbar(
        title: 'Berhasil',
        message: 'Lokasi berhasil diambil.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e, s) {
      debugPrint('Error get location answer: $e\n$s');
      showSafeSnackbar(
        title: 'Gagal Mengambil Lokasi',
        message: 'Terjadi kesalahan: ${e.toString()}',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      isGettingLocation.value = false;
    }
  }

  /// Fungsi untuk mengecek kelengkapan dan validitas data secara akurat
  bool isFormComplete() {
    if (loadedForm.value == null) return false;
    
    // Validasi standar UI (regex, format, dll yang terdeteksi di form field)
    bool isStandardValid = formKey.currentState?.validate() ?? true;
    if (!isStandardValid) {
      debugPrint("COMPLETENESS: formKey validation failed");
      return false;
    }

    try {
      for (var section in loadedForm.value!.sections) {
        for (var question in section.questions) {
          
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            // PERTANYAAN MANDIRI
            if (isVisible(question.id)) {
              dynamic answer = userAnswers[question.id];
              String? error = _performLocalValidation(question, answer, question.questionText);
              
              if (error != null) {
                debugPrint("COMPLETENESS: Mandiri invalid: $error");
                return false;
              }
            }
          } else {
            // PERTANYAAN DALAM GRUP
            final String groupTag = question.belongsToGroupTag!;
            
            // Cek apakah controller grup ini visible
            final controllerQ = loadedForm.value?.sections
                .expand((s) => s.questions)
                .firstWhereOrNull((q) => q.isRepeatableGroupController && q.controlledGroupTag == groupTag);
            
            bool isGroupVisible = controllerQ == null || isVisible(controllerQ.id);
            if (!isGroupVisible) continue;

            final int count = repeatableGroupCounts[groupTag] ?? 0;
            
            for (int i = 0; i < count; i++) {
              if (isVisible(question.id, index: i)) {
                final answer = repeatableGroupAnswers[question.id]?[i];
                String? error = _performLocalValidation(
                  question, 
                  answer, 
                  "${question.questionText} (Anggota ${i + 1})", 
                  repeatIndex: i
                );

                if (error != null) {
                  debugPrint("COMPLETENESS: Group item invalid: $error");
                  return false;
                }
              }
            }
          }
        }
      }
      debugPrint("COMPLETENESS: Form is complete and valid!");
      return true;
    } catch (e) {
      debugPrint("Error during completeness check: $e");
      return false;
    }
  }


  void _showValidationErrorsDialog(List<String> errors) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Isian Belum Lengkap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mohon lengkapi atau perbaiki pertanyaan berikut sebelum mengirim data:'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: errors.length > 15 ? 16 : errors.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 15) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('... dan beberapa pertanyaan lainnya', 
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(errors[index], style: const TextStyle(fontSize: 13, height: 1.4))),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Mengirimkan seluruh data formulir ke server (Firebase atau Server Lokal Desa).
  /// 
  /// Mencakup proses validasi kelengkapan, ekstraksi identitas unik keluarga (NIK),
  /// penentuan koordinat lokasi, dan penyimpanan hasil rekapitulasi.
  Future<bool> submitForm({String status = "submitted"}) async {
    if (loadedForm.value == null || _auth.currentUser == null) {
      showSafeSnackbar(
        title: 'Error',
        message: 'Form atau pengguna tidak valid.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
    
    if (isLockedMode.value) {
      showSafeSnackbar(
        title: 'Data Terkunci',
        message: 'Data pada periode ini sudah dikunci.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    }

    // KHUSUS SUBMITTED: Jalankan validasi keras
    if (status == "submitted") {
      formKey.currentState?.save();
      bool formKeyValidationPassed = formKey.currentState?.validate() ?? true;
      String? firstInvalidSectionIdToFocus;
      bool allCustomValidationsPassed = true;
      List<String> validationErrors = [];

      for (var section in loadedForm.value!.sections) {
        for (var question in section.questions) {
          if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
            // VALIDASI MANDIRI
            if (!isVisible(question.id)) continue;
            dynamic answer = userAnswers[question.id];
            String? err = _performLocalValidation(question, answer, question.questionText);
            if (err != null) {
              allCustomValidationsPassed = false;
              validationErrors.add(err);
              firstInvalidSectionIdToFocus ??= section.id;
            }
          } else {
            // VALIDASI GRUP
            final groupTag = question.belongsToGroupTag!;
            final count = repeatableGroupCounts[groupTag] ?? 0;
            for (int i = 0; i < count; i++) {
              if (!isVisible(question.id, index: i)) continue;
              dynamic answer = repeatableGroupAnswers[question.id]?[i];
              String? err = _performLocalValidation(question, answer, "${question.questionText} (Anggota ${i + 1})", repeatIndex: i);
              if (err != null) {
                allCustomValidationsPassed = false;
                validationErrors.add(err);
                firstInvalidSectionIdToFocus ??= section.id;
              }
            }
          }
        }
      }

      if (!formKeyValidationPassed || !allCustomValidationsPassed) {
        isLoading.value = false;
        if (firstInvalidSectionIdToFocus != null) expandedSectionId.value = firstInvalidSectionIdToFocus;
        
        // Tampilkan dialog peringatan detail pertanyaan yang belum lengkap
        _showValidationErrorsDialog(validationErrors);

        return false;
      }
    }

    isLoading.value = true;
    loadingMessage.value = status == "draft" ? "Menyimpan draft..." : "Mengirim data...";
    
    if (isUploadingImage.value) {
      showSafeSnackbar(
        title: 'Mohon Tunggu',
        message: 'Gambar sedang diunggah...',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      isLoading.value = false;
      return false;
    }

    // Persiapkan data jawaban (Tetap simpan data anak/bersyarat meskipun tersembunyi)
    List<QuestionAnswer> answersToSubmit = [];
    List<String> allImageUrls = [];
    
    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        
        if (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) {
          // PERTANYAAN MANDIRI
          final answer = userAnswers[question.id];
          final bool hasValue = _hasActualValue(answer, question.type);

          // Simpan jika: Terlihat ATAU punya isi aktual
          if (isVisible(question.id) || hasValue) {
            dynamic finalAnswer = answer;
            
            if (question.hasOtherOption) {
              String? otherText = userOtherAnswers[question.id];
              if (question.type == QuestionType.checkboxes && answer is List) {
                if (answer.contains(_kOtherOptionValue)) {
                  List<dynamic> processedList = List.from(answer);
                  processedList.remove(_kOtherOptionValue);
                  if (otherText != null && otherText.trim().isNotEmpty) processedList.add(otherText.trim());
                  finalAnswer = processedList;
                }
              } else if (answer == _kOtherOptionValue) {
                finalAnswer = otherText ?? '';
              }
            }

            dynamic firestoreAnswer = _prepareAnswerForFirestore(finalAnswer, question.type);
            if (question.type == QuestionType.imageUpload && firestoreAnswer is Map) {
              String? url = firestoreAnswer['imageUrl'];
              if (url != null && url.isNotEmpty) allImageUrls.add(url);
            }
            answersToSubmit.add(QuestionAnswer(
                questionId: question.id,
                questionText: question.questionText,
                answer: firestoreAnswer,
                questionType: question.type.toShortString()));
          }
        } else {
          // PERTANYAAN GRUP
          final String groupTag = question.belongsToGroupTag!;
          final int count = repeatableGroupCounts[groupTag] ?? 0;
          
          for (int i = 0; i < count; i++) {
            final answer = repeatableGroupAnswers[question.id]?[i];
            final bool hasValue = _hasActualValue(answer, question.type);

            // Simpan jika: Terlihat ATAU punya isi aktual
            if (isVisible(question.id, index: i) || hasValue) {
              dynamic finalAnswer = answer;

              if (question.hasOtherOption) {
                String? otherText = repeatableGroupOtherAnswers[question.id]?[i];
                if (question.type == QuestionType.checkboxes && answer is List) {
                  if (answer.contains(_kOtherOptionValue)) {
                    List<dynamic> processedList = List.from(answer);
                    processedList.remove(_kOtherOptionValue);
                    if (otherText != null && otherText.trim().isNotEmpty) processedList.add(otherText.trim());
                    finalAnswer = processedList;
                  }
                } else if (answer == _kOtherOptionValue) {
                  finalAnswer = otherText ?? '';
                }
              }
              
              dynamic firestoreAnswer = _prepareAnswerForFirestore(finalAnswer, question.type);
              if (question.type == QuestionType.imageUpload && firestoreAnswer is Map) {
                String? url = firestoreAnswer['imageUrl'];
                if (url != null && url.isNotEmpty) allImageUrls.add(url);
              }
              answersToSubmit.add(QuestionAnswer(
                  questionId: "${question.id}_$i",
                  questionText: question.questionText,
                  answer: firestoreAnswer,
                  questionType: question.type.toShortString()));
            }
          }
        }
      }
    }

    final currentUser = _auth.currentUser!;
    String? villageIdToSubmit = selectedVillageId.value.isNotEmpty ? selectedVillageId.value : null;
    String? villageNameToSubmit;
    if (villageIdToSubmit != null) {
      villageNameToSubmit = allVillages.firstWhereOrNull((v) => v.villageId == villageIdToSubmit)?.villageName;
    }

    // Dynamic Title & Description
    String? dynamicTitle;
    String? dynamicDescription;
    String? extractedRT;
    String? extractedRW;

    for (var section in loadedForm.value!.sections) {
      for (var question in section.questions) {
        // Ekstraksi Judul & Deskripsi
        if (question.useAsTitle || question.useAsDescription) {
          dynamic answer = (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) 
              ? userAnswers[question.id] : repeatableGroupAnswers[question.id]?[0];
          if (answer != null) {
            String displayVal = (answer is List) ? answer.join(", ") : answer.toString();
            if (question.useAsTitle) dynamicTitle = displayVal;
            if (question.useAsDescription) dynamicDescription = displayVal;
          }
        }

        // --- EKSTRAKSI RT & RW UNTUK FILTERING ADMIN RT ---
        final qId = question.id.toUpperCase();
        final qText = question.questionText.trim().toUpperCase(); // Trim spasi
        
        if (isVisible(question.id)) {
          // 1. Ekstraksi RW
          if (qId == 'RW' || qId == '105' || qText == 'RW' || qText.contains('RUKUN WARGA') || qText.contains('NOMOR RW')) {
             final ans = (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) 
                ? userAnswers[question.id] : repeatableGroupAnswers[question.id]?[0];
             if (ans != null && ans.toString().isNotEmpty) {
               extractedRW = ans.toString().trim();
             }
          }
          
          // 2. Ekstraksi RT (Mendukung pola: Judul pertanyaan RT = Jawaban RW)
          final ansRT = (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) 
              ? userAnswers[question.id] : repeatableGroupAnswers[question.id]?[0];
          
          if (ansRT != null && ansRT.toString().isNotEmpty) {
            final String valRT = ansRT.toString().trim();
            final String currentRawRW = extractedRW ?? '';
            
            if (qId == 'RT' || qId == '104' || qText == 'RT' || qText.contains('RUKUN TETANGGA') || 
                (currentRawRW.isNotEmpty && qText == currentRawRW.toUpperCase())) {
               extractedRT = valRT;
            }
          }
        }
      }
    }

    double? lat, lon, acc;
    String? addr;
    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      lat = position.latitude; lon = position.longitude; acc = position.accuracy;
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        addr = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      }
    } catch (_) {}

    final submissionData = FormSubmission(
      id: submissionId.value.isNotEmpty ? submissionId.value : null,
      formId: loadedForm.value!.id,
      formTitle: loadedForm.value!.title,
      userId: currentUser.uid,
      userName: (currentUser.displayName?.isNotEmpty == true) ? currentUser.displayName! : (currentUser.email ?? "User"),
      period: currentPeriod.value,
      submittedAt: Timestamp.now(),
      createdAt: (submissionId.value.isNotEmpty && loadedSubmission.value?.createdAt != null) ? loadedSubmission.value!.createdAt : Timestamp.now(),
      answers: answersToSubmit,
      villageId: villageIdToSubmit,
      villageName: villageNameToSubmit,
      latitude: lat, longitude: lon, locationAccuracy: acc, locationAddress: addr,
      imageUrl: allImageUrls.isNotEmpty ? allImageUrls.first : null,
      imageUrls: allImageUrls.isNotEmpty ? allImageUrls : null,
      displayTitle: dynamicTitle,
      displayDescription: dynamicDescription,
      status: status, // "draft" atau "submitted"
      isLocked: false,
      isAutoGenerated: loadedSubmission.value?.isAutoGenerated ?? false,
      duplicatedFromPeriod: loadedSubmission.value?.duplicatedFromPeriod,
      computedSummary: summaryAgeGroups.map((key, value) => MapEntry(key, Map<String, int>.from(value))),
    );

    try {
      final Map<String, dynamic> firestoreData = submissionData.toFirestore();
      
      // PRIORITAS UTAMA: Gunakan RT/RW dari profil petugas agar filter Admin RT akurat
      if (userRt.value.isNotEmpty) firestoreData['rt'] = userRt.value;
      if (userRw.value.isNotEmpty) firestoreData['rw'] = userRw.value;
      
      // Jika profil kosong (misal petugas lama), baru gunakan hasil ekstraksi form (fallback)
      if ((firestoreData['rt'] == null || firestoreData['rt'] == '') && extractedRT != null) {
        firestoreData['rt'] = extractedRT;
      }
      if ((firestoreData['rw'] == null || firestoreData['rw'] == '') && extractedRW != null) {
        firestoreData['rw'] = extractedRW;
      }
      
      // LOGIKA UNIK: Cek apakah data keluarga ini sudah ada di periode ini (Update vs Create)
      String? targetSubmissionId = submissionId.value.isNotEmpty ? submissionId.value : null;

      if (targetSubmissionId == null) {
        final String familyKey = _getUniqueFamilyKeyFromAnswers(answersToSubmit, submissionData.namaKepalaRumahTangga);
        debugPrint('InputUserController: Mencari existing data untuk key: $familyKey');

        final existingSnap = await _db.collection('formSubmissions')
            .where('formId', isEqualTo: submissionData.formId)
            .where('period', isEqualTo: submissionData.period)
            .where('userId', isEqualTo: submissionData.userId)
            .get();

        for (var doc in existingSnap.docs) {
          final existingSub = FormSubmission.fromFirestore(doc);
          if (_getUniqueFamilyKeyForSubmission(existingSub) == familyKey) {
            targetSubmissionId = doc.id;
            debugPrint('InputUserController: Ditemukan data existing (AutoDuplicate), akan menimpa ID: $targetSubmissionId');
            break;
          }
        }
      }

      if (targetSubmissionId != null) firestoreData['updatedAt'] = Timestamp.now();

      final village = allVillages.firstWhereOrNull((v) => v.villageId == villageIdToSubmit);
      final bool useLocalApi = village?.serverType == 'local_api';

      if (useLocalApi) {
        loadingMessage.value = "Mengirim data ke server desa (${village?.villageName})...";
        await _submitToLocalApi(village!, firestoreData, targetSubmissionId != null, targetSubmissionId);
      } else {
        if (targetSubmissionId != null) {
          await _db.collection('formSubmissions').doc(targetSubmissionId).set(firestoreData, SetOptions(merge: true));
          submissionId.value = targetSubmissionId;
        } else {
          final docRef = await _db.collection('formSubmissions').add(firestoreData);
          submissionId.value = docRef.id;
        }
      }

      markFormAsSaved();

      // Tampilkan feedback sukses SEBELUM pindah halaman agar tidak Null Context
      showSafeSnackbar(
        title: 'Berhasil',
        message: status == "submitted" ? 'Data berhasil dikirim!' : 'Draft berhasil disimpan!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Beri jeda sedikit agar user bisa melihat snackbar
      await Future.delayed(const Duration(milliseconds: 1200));
      
      isLoading.value = false;
      _safePopPage();
      return true;
    } catch (e) {
      isLoading.value = false;
      debugPrint("Error in submitForm: $e");
      showSafeSnackbar(
        title: 'Error',
        message: 'Gagal menyimpan ke Firebase/Server: $e. Pastikan Rules Firebase sudah diset.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  bool _isAnswerEmpty(dynamic answer, QuestionType type) {
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty;
    if (answer is Map) {
      if (type == QuestionType.imageUpload) {
        return (answer['imageUrl'] == null ||
                answer['imageUrl'].toString().trim().isEmpty) &&
            (answer['localPath'] == null ||
                answer['localPath'].toString().trim().isEmpty);
      }
      if (type == QuestionType.location) return answer.isEmpty;
      if (type == QuestionType.gridNumeric) {
        if (answer.isEmpty) return true;
        return !(answer as Map<String, Map<String, Map<String, num?>>>)
            .values
            .any((colMap) => colMap.values.any((subColMap) => subColMap.values.any(
                (cellVal) =>
                    cellVal != null && cellVal.toString().trim().isNotEmpty)));
      }
      return answer.isEmpty;
    }
    return false;
  }

  /// Helper untuk mengecek apakah sebuah jawaban memiliki isi aktual
  bool _hasActualValue(dynamic answer, QuestionType type) {
    if (answer == null) return false;
    final def = _getDefaultAnswerForQuestionType(type);
    
    if (answer == def) return false;
    
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is List) return answer.isNotEmpty;
    if (answer is Map) return answer.isNotEmpty;
    
    return true;
  }

  dynamic _prepareAnswerForFirestore(dynamic answer, QuestionType type) {
    if (answer == null) {
      switch (type) {
        case QuestionType.number:
        case QuestionType.date:
        case QuestionType.gridNumeric:
        case QuestionType.imageUpload:
        case QuestionType.location:
          return null;
        case QuestionType.checkboxes:
          return <String>[];
        default:
          return "";
      }
    }
    switch (type) {
      case QuestionType.number:
        if (answer is String) {
          if (answer.trim().isEmpty) return null;
          return num.tryParse(answer.replaceAll(',', '.'));
        }
        return answer is num ? answer : null;
      case QuestionType.date:
        if (answer is String) {
          if (answer.trim().isEmpty) return null;
          try {
            return Timestamp.fromDate(
                DateFormat('dd/MM/yyyy').parseStrict(answer));
          } catch (e) {
            try {
              return Timestamp.fromDate(DateTime.parse(answer));
            } catch (e2) {
              return answer;
            }
          }
        }
        if (answer is DateTime) return Timestamp.fromDate(answer);
        return answer is Timestamp ? answer : null;
      case QuestionType.gridNumeric:
        if (answer is Map<String, Map<String, Map<String, num?>>>) {
          Map<String, dynamic> firestoreGrid = {};
          answer.forEach((rowKey, colMap) {
            String effectiveRowKey = rowKey.isEmpty ? "default_row" : rowKey;
            Map<String, dynamic> currentCols = {};
            colMap.forEach((colKey, subColMap) {
              Map<String, num?> currentSubCols = {};
              subColMap.forEach((subColKey, cellValue) {
                currentSubCols[subColKey] = cellValue;
              });
              currentCols[colKey] = currentSubCols;
            });
            firestoreGrid[effectiveRowKey] = currentCols;
          });
          return firestoreGrid;
        }
        return {};
      case QuestionType.imageUpload:
        if (answer is Map) {
          final Map<String, dynamic> imageAnswer =
              Map<String, dynamic>.from(answer);
          imageAnswer.remove('isUploading');
          imageAnswer.remove('uploadError');
          return imageAnswer;
        }
        return null;
      case QuestionType.location:
        return answer is Map ? Map<String, dynamic>.from(answer) : null;
      case QuestionType.checkboxes:
        return answer is List
            ? List<String>.from(answer.map((e) => e.toString()))
            : <String>[];
      default:
        return answer.toString();
    }
  }

  String? itemTitleOverrideForValidation(
      FormQuestion question, int? repeatIndex) {
    if (repeatIndex != null && question.belongsToGroupTag != null) {
      return "${question.questionText} (data ke-${repeatIndex + 1})";
    }
    return question.questionText;
  }

  Map<String, Map<String, Map<String, num?>>> getGridMapForValidation(
      dynamic currentGridData) {
    if (currentGridData is Map<String, Map<String, Map<String, num?>>>) {
      return currentGridData;
    }
    if (currentGridData is Map) {
      try {
        return Map<String, Map<String, Map<String, num?>>>.fromEntries(
            (currentGridData).entries.map((rowEntry) {
          var colMap = rowEntry.value;
          if (colMap is! Map) colMap = <String, dynamic>{};
          return MapEntry(
              rowEntry.key.toString(),
              Map<String, Map<String, num?>>.fromEntries(
                  colMap.entries.map((colEntry) {
                var subColMap = colEntry.value;
                if (subColMap is! Map) subColMap = <String, dynamic>{};
                return MapEntry(
                    colEntry.key.toString(),
                    Map<String, num?>.fromEntries(
                        subColMap.entries.map((subColEntry) {
                      num? cellValueNum;
                      if (subColEntry.value == null) {
                        cellValueNum = null;
                      } else if (subColEntry.value is num) {
                        cellValueNum = subColEntry.value as num;
                      } else {
                        cellValueNum = num.tryParse(subColEntry.value
                            .toString()
                            .replaceAll(',', '.'));
                      }
                      return MapEntry(subColEntry.key.toString(), cellValueNum);
                    })));
              })));
        }));
      } catch (e) {
        debugPrint(
            "Error in getGridMapForValidation: $e. Data: $currentGridData");
        return <String, Map<String, Map<String, num?>>>{};
      }
    }
    return <String, Map<String, Map<String, num?>>>{};
  }

  // --- HELPER UNTUK IDENTITAS KELUARGA ---
  String _getUniqueFamilyKeyFromAnswers(List<QuestionAnswer> answers, String? nameFromModel) {
    // 1. Cari NIK
    const List<String> nikCodes = ['107', 'NIK_KRT', 'NIK_KEPALA_KELUARGA', 'NIK'];
    for (var code in nikCodes) {
      final found = answers.firstWhereOrNull((a) => a.questionId.toUpperCase() == code.toUpperCase());
      if (found != null && found.answer != null && found.answer.toString().isNotEmpty && found.answer.toString() != "1") {
        return "NIK_${found.answer}";
      }
    }

    // 2. Cari Nama
    if (nameFromModel != null && nameFromModel.isNotEmpty) {
      return "NAME_${nameFromModel.toLowerCase().trim()}";
    }
    
    const List<String> nameCodes = ['106', '102', 'NAMA_KEPALA_KELUARGA', 'NAMA_KRT'];
    for (var code in nameCodes) {
      final found = answers.firstWhereOrNull((a) => a.questionId.toUpperCase() == code.toUpperCase());
      if (found != null && found.answer != null && found.answer.toString().isNotEmpty) {
        return "NAME_${found.answer.toString().toLowerCase().trim()}";
      }
    }

    return "RANDOM_${DateTime.now().millisecondsSinceEpoch}";
  }

  String _getUniqueFamilyKeyForSubmission(FormSubmission sub) {
    return _getUniqueFamilyKeyFromAnswers(sub.answers, sub.namaKepalaRumahTangga);
  }

  // --- HELPER UNTUK LOCAL API SERVER ---

  Future<bool> _submitToLocalApi(VillageModel village, Map<String, dynamic> data, bool isEdit, String? existingSubId) async {
    try {
      String baseUrl = village.apiBaseUrl ?? '';
      if (baseUrl.isEmpty) {
        // Fallback jika baseUrl kosong tapi ada IP dan Port
        if (village.localIpAddress != null && village.port != null) {
          baseUrl = "http://${village.localIpAddress}:${village.port}";
        } else {
          throw "Konfigurasi server untuk desa ${village.villageName} tidak lengkap.";
        }
      }
      
      // Hapus trailing slash jika ada
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      
      final url = Uri.parse('$baseUrl/api/submissions${isEdit ? '/$existingSubId' : ''}');
      
      // Konversi data Firestore (Timestamp, dll) ke format JSON standar
      final Map<String, dynamic> jsonData = _convertDataForJson(data);

      final response = await (isEdit 
        ? http.put(url, body: jsonEncode(jsonData), headers: {'Content-Type': 'application/json'})
        : http.post(url, body: jsonEncode(jsonData), headers: {'Content-Type': 'application/json'})
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw "Server Desa merespon dengan error (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      debugPrint("Error submit to local api: $e");
      if (e is TimeoutException) throw "Koneksi ke server desa timeout. Pastikan Anda terhubung ke jaringan desa (VPN jika perlu).";
      rethrow;
    }
  }

  /// Konversi rekursif untuk menangani tipe data non-JSON (Timestamp)
  Map<String, dynamic> _convertDataForJson(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertDataForJson(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) return _convertDataForJson(item);
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}

class JumpResult {
  final String? nextId;
  final bool changed;
  JumpResult(this.nextId, this.changed);
}
