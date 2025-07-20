import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/form_builder/admin_form_builder_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart'; // Untuk konsistensi warna

class AdminFormBuilderPage extends GetView<AdminFormBuilderController> {
  const AdminFormBuilderPage({Key? key}) : super(key: key);

  static const Color appBarForegroundColor = Colors.white;
  static const Color accentThemeColor = AdminScreen.accentHeaderColor;
  static const Color neutralLabelColor = Colors.grey;
  static const Color defaultTextFieldBorderColor = Colors.black26;
  static const Color pageBgColor = AdminScreen.pageBackgroundColor;
  static const Color cardBgColor = Colors.white;

  // Helper function to convert integer to Roman numeral
  String _toRoman(int number) {
    if (number < 1 || number > 3999) {
      return number.toString(); // Fallback for numbers out of typical Roman numeral range
    }
    const List<String> romanNumerals = [
      "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"
    ];
    const List<int> values = [
      1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1
    ];
    String result = "";
    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        result += romanNumerals[i];
        number -= values[i];
      }
    }
    return result;
  }

  static InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
    bool isDense = false,
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
    // Widget? suffixIcon, // Pastikan parameter suffixIcon ada jika Anda menggunakannya di pemanggilan
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: neutralLabelColor.withOpacity(0.9), fontSize: isDense ? 14 : 15), // neutralLabelColor harus static
      floatingLabelStyle: const TextStyle(color: accentThemeColor, fontWeight: FontWeight.w500), // accentThemeColor harus static
      hintText: hintText ?? 'Masukkan $labelText...',
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)), // defaultTextFieldBorderColor harus static
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: defaultTextFieldBorderColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: accentThemeColor, width: 1.8),
      ),
      filled: true,
      fillColor: cardBgColor, // cardBgColor harus static
      contentPadding: contentPadding ?? (isDense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      // suffixIcon: suffixIcon, // Aktifkan jika Anda menambahkan parameter suffixIcon
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        toolbarHeight: 80.0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Management Form',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Obx(() => Text(
              controller.formTitle.value.isEmpty
                  ? 'Buat Form Baru'
                  : controller.formTitle.value,
              style: TextStyle(fontSize: 14, color: appBarForegroundColor.withOpacity(0.85)),
              overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
        actions: [
          Obx(() => controller.isBusy.value
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: appBarForegroundColor, strokeWidth: 2.5)),
          )
              : IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Simpan Form',
            onPressed: controller.saveForm,
          )),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AdminScreen.primaryHeaderColor, AdminScreen.accentHeaderColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(35.0)),
          ),
        ),
      ),
      body: Obx(() {
        final bool showInitialLoaderForNewForm = controller.isBusy.value &&
            !controller.isEditMode &&
            controller.sections.isEmpty;
        final bool showLoaderForEditing = controller.isBusy.value && controller.isEditMode;

        if (showInitialLoaderForNewForm || showLoaderForEditing) {
          return const Center(child: CircularProgressIndicator(color: accentThemeColor));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),
            Obx(() => Column(
              children: controller.sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                // final section = entry.value; // section diambil dari controller.sections[sectionIndex]
                // Pastikan section diambil dari RxList yang diperbarui
                if (sectionIndex < controller.sections.length) {
                  return _buildSectionCard(controller.sections[sectionIndex].id, sectionIndex);
                }
                return const SizedBox.shrink(); // Fallback jika index out of bounds
              }).toList(),
            )),
            const SizedBox(height: 24),
            _buildAddSectionButton(),
            const SizedBox(height: 70),
          ],
        );
      }),
    );
  }

  Widget _buildFormHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Detail Form Utama",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: accentThemeColor),
              ),
            ),
            TextField(
              controller: controller.titleController,
              decoration: _modernInputDecoration(labelText: 'Judul Form'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: _modernInputDecoration(labelText: 'Deskripsi Form', hintText: 'Deskripsi Form (Opsional)'),
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.addSection,
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Tambah Bagian Baru',
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentThemeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    );
  }


  Widget _buildSectionCard(String sectionIdFromList, int sectionIndex) {
    return Obx(() {
      final section = controller.sections.firstWhere(
            (s) => s.id == sectionIdFromList,
        orElse: () {
          print("ERROR: Section with ID $sectionIdFromList not found in _buildSectionCard. This might indicate a data consistency issue.");
          return FormSection(id: 'error_id_${DateTime.now().millisecondsSinceEpoch}', title: 'Error: Bagian tidak ditemukan', questions: []);
        },
      );
      if (section.id.startsWith('error_id')) {
        return Card(child: ListTile(title: Text(section.title)));
      }

      final ExpansionTileController? tileController = controller.sectionExpansionControllers[section.id];

      String romanNumeral = _toRoman(sectionIndex + 1);
      String displaySectionTitle = section.title.trim().isEmpty
          ? 'Bagian $romanNumeral'
          : '$romanNumeral ${section.title.trim()}';

      if (section.isRepeatable) {
        displaySectionTitle += " (Berulang";
        if (section.repeatTriggerQuestionCode != null && section.repeatTriggerQuestionCode!.isNotEmpty) {
          displaySectionTitle += " - Pemicu: ${section.repeatTriggerQuestionCode}";
        } else if (section.repeatTriggerQuestionId != null) {
          FormQuestion? triggerQ = controller.findQuestionById(section.repeatTriggerQuestionId!);
          if (triggerQ?.code != null && triggerQ!.code!.isNotEmpty) {
            displaySectionTitle += " - Pemicu: ${triggerQ.code}";
          } else if (triggerQ != null) {
            displaySectionTitle += " - Pemicu: ID ${triggerQ.id.substring(0,5)}...";
          }
        }
        displaySectionTitle += ")";
      }
      String titleForDialog = section.title.trim().isEmpty ? "Bagian $romanNumeral" : section.title.trim();

      // Logika untuk menentukan apakah section seharusnya expanded (jika tidak ada controller)
      bool shouldBeInitiallyExpandedIfNoController;
      if (!controller.isEditMode) {
        shouldBeInitiallyExpandedIfNoController = sectionIndex == 0; // Buka section pertama jika form baru
      } else {
        shouldBeInitiallyExpandedIfNoController = false; // Tutup semua jika mode edit
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: cardBgColor,
        child: ExpansionTile(
          key: ValueKey(section.id), // Key penting untuk menjaga state
          controller: tileController, // Controller yang Anda sediakan

          initiallyExpanded: (tileController != null)
              ? false // WAJIB false jika controller ada
              : shouldBeInitiallyExpandedIfNoController,

          onExpansionChanged: (isExpanding) {
            // State ekspansi sudah diatur oleh controller
          },
          backgroundColor: cardBgColor,
          collapsedBackgroundColor: cardBgColor,
          iconColor: accentThemeColor,
          collapsedIconColor: Colors.grey.shade700,
          title: Text(
            displaySectionTitle,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Detail Bagian', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      if (controller.sections.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
                          tooltip: 'Hapus Bagian Ini',
                          onPressed: () {
                            Get.defaultDialog(
                                title: "Konfirmasi Hapus Bagian",
                                middleText: "Anda yakin ingin menghapus bagian '$titleForDialog'?",
                                textConfirm: "Hapus", textCancel: "Batal",
                                confirmTextColor: Colors.white, buttonColor: Colors.red.shade400,
                                cancelTextColor: Colors.grey.shade700,
                                onConfirm: () { controller.removeSection(section.id); Get.back(); }
                            );
                          },
                        ),
                    ],
                  ),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_title'),
                    initialValue: section.title,
                    onChanged: (text) => controller.updateSectionTitle(section.id, text),
                    decoration: _modernInputDecoration(labelText: 'Judul Bagian', hintText: 'Kosongkan untuk nomor Romawi', isDense: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  _PersistentTextField(
                    fieldKey: ValueKey('${section.id}_section_description'),
                    initialValue: section.description ?? '',
                    onChanged: (text) => controller.updateSectionDescription(section.id, text),
                    decoration: _modernInputDecoration(labelText: 'Deskripsi Bagian', hintText: 'Opsional', isDense: true),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildExpansionTileForSettings(
                    "Pengaturan Pengulangan Bagian",
                    [
                      SwitchListTile(
                        title: const Text("Bagian ini dapat diulang?", style: TextStyle(fontSize: 14)),
                        value: section.isRepeatable,
                        onChanged: (bool newValue) {
                          controller.updateSectionRepeatability(
                            sectionId: section.id,
                            isRepeatable: newValue,
                            triggerQuestionId: newValue ? section.repeatTriggerQuestionId : null,
                            triggerQuestionCode: newValue ? section.repeatTriggerQuestionCode : null,
                            minRepeats: newValue ? (section.minRepeats ?? (section.repeatTriggerQuestionId != null ? 0 : 1)) : null,
                            maxRepeats: newValue ? section.maxRepeats : null,
                          );
                        },
                        activeColor: accentThemeColor, dense: true, contentPadding: EdgeInsets.zero,
                      ),
                      if (section.isRepeatable) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: DropdownButtonFormField<String?>(
                            value: section.repeatTriggerQuestionId,
                            decoration: _modernInputDecoration(
                              labelText: 'Ulangi berdasarkan jawaban pertanyaan:',
                              hintText: 'Pilih pertanyaan pemicu (tipe angka)',
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text("(Tidak ada pemicu / Ulangi min. kali)", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13))),
                              ...controller.getAllQuestionsForLinking(numericOnly: true).map((qMap) =>
                                  DropdownMenuItem<String?>(value: qMap['id'], child: Text("${qMap['code']} - ${qMap['text']}", style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))
                              ).toList(),
                            ],
                            onChanged: (String? selectedQId) {
                              FormQuestion? triggerQ = controller.findQuestionById(selectedQId ?? '');
                              controller.updateSectionRepeatability(
                                sectionId: section.id, isRepeatable: true,
                                triggerQuestionId: selectedQId, triggerQuestionCode: triggerQ?.code,
                                minRepeats: section.minRepeats, maxRepeats: section.maxRepeats,
                              );
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _PersistentTextField(
                            fieldKey: ValueKey('${section.id}_min_repeats'),
                            initialValue: section.minRepeats?.toString() ?? (section.repeatTriggerQuestionId != null ? '0' : '1'),
                            decoration: _modernInputDecoration(labelText: 'Min Pengulangan', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => controller.updateSectionRepeatability(
                                sectionId: section.id, isRepeatable: true, triggerQuestionId: section.repeatTriggerQuestionId, triggerQuestionCode: section.repeatTriggerQuestionCode,
                                minRepeats: int.tryParse(val), maxRepeats: section.maxRepeats),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _PersistentTextField(
                            fieldKey: ValueKey('${section.id}_max_repeats'),
                            initialValue: section.maxRepeats?.toString() ?? '',
                            decoration: _modernInputDecoration(labelText: 'Max Pengulangan (Opsional)', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => controller.updateSectionRepeatability(
                                sectionId: section.id, isRepeatable: true, triggerQuestionId: section.repeatTriggerQuestionId, triggerQuestionCode: section.repeatTriggerQuestionCode,
                                minRepeats: section.minRepeats, maxRepeats: int.tryParse(val)),
                          )),
                        ]),
                      ],
                    ],
                    initiallyExpanded: section.isRepeatable,
                  ),
                  const SizedBox(height: 20),
                  Text("Pertanyaan untuk Bagian Ini:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  // --- KODE LAMA DIGANTIKAN DENGAN BLOK DI BAWAH ---
                  if (section.questions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text("Belum ada pertanyaan di bagian ini.", style: TextStyle(color: Colors.grey.shade600))),
                    )
                  else
                  // --- PERBAIKAN: Logika Pengurutan Pertanyaan ---
                    Builder(builder: (context) {
                      // Buat salinan list pertanyaan agar bisa diurutkan.
                      final sortedQuestions = List<FormQuestion>.from(section.questions);

                      // Lakukan pengurutan berdasarkan 'code'.
                      sortedQuestions.sort((a, b) {
                        final codeA = a.code;
                        final codeB = b.code;

                        // Pertanyaan tanpa 'code' atau dengan code kosong diletakkan di akhir.
                        if (codeA == null || codeA.isEmpty) return 1;
                        if (codeB == null || codeB.isEmpty) return -1;

                        // Coba parse ke integer untuk melakukan sorting numerik yang benar (misal: "10" > "2").
                        final numA = int.tryParse(codeA);
                        final numB = int.tryParse(codeB);

                        if (numA != null && numB != null) {
                          return numA.compareTo(numB);
                        }

                        // Jika tidak bisa di-parse sebagai angka, sorting sebagai string biasa.
                        return codeA.compareTo(codeB);
                      });

                      // Gunakan list yang sudah diurutkan untuk membangun widget.
                      return Column(
                        children: sortedQuestions.asMap().entries.map((entry) {
                          final questionIndexInSection = entry.key; // Index ini sekarang dari list yang sudah terurut.
                          final questionItem = entry.value;
                          return _buildQuestionCard(section.id, sectionIndex, questionItem.id, questionIndexInSection);
                        }).toList(),
                      );
                    }),
                  const SizedBox(height: 15),
                  _buildAddQuestionButton(section.id),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(Icons.unfold_less_rounded, color: accentThemeColor.withOpacity(0.8), size: 20),
                      label: Text(
                        'Tutup Bagian Ini',
                        style: TextStyle(color: accentThemeColor.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        if (tileController != null) {
                          tileController.collapse();
                        } else {
                          print("Error: tileController is null for section ${section.id} when trying to collapse.");
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGridNumericSettings(String sectionId, FormQuestion question) {
    bool isGridConfigured = (question.gridRowLabels.isNotEmpty) ||
        (question.gridColumnLabels.isNotEmpty) ||
        (question.gridSubColumnLabels.isNotEmpty);
    return _buildExpansionTileForSettings(
      'Pengaturan Label Grid Numerik', // Judul ExpansionTile
      [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
          child: Text(
            "Masukkan label dipisahkan koma (,). Contoh: Senin,Selasa.\n"
                "- Label Baris: Opsional (misal: 'Sampah Basah,Sampah Kering'). Kosongkan jika grid hanya butuh 1 jenis baris.\n"
                "- Label Kolom: Wajib (misal: 'Senin,Selasa,dst' untuk hari).\n"
                "- Label Sub-Kolom: Wajib (misal: 'Kecil,Sedang,Besar' untuk ukuran).",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
          ),
        ),
        // Menggunakan _PersistentTextField untuk Label Baris
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridRowLabels_persistent'),
          initialValue: question.gridRowLabels.join(', '),
          onChanged: (text) => controller.updateGridRowLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Baris (Pisahkan dengan koma)', hintText: 'Contoh: Baris A,Baris B', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Menggunakan _PersistentTextField untuk Label Kolom
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridColLabels_persistent'),
          initialValue: question.gridColumnLabels.join(', '),
          onChanged: (text) => controller.updateGridColumnLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Kolom (Pisahkan dengan koma)', hintText: 'Contoh: Kolom 1,Kolom 2', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Menggunakan _PersistentTextField untuk Label Sub-Kolom
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_gridSubColLabels_persistent'),
          initialValue: question.gridSubColumnLabels.join(', '),
          onChanged: (text) => controller.updateGridSubColumnLabelsFromString(sectionId, question.id, text),
          decoration: _modernInputDecoration(labelText: 'Label Sub-Kolom (Pisahkan dengan koma)', hintText: 'Contoh: Sub A,Sub B', isDense: true),
          style: const TextStyle(fontSize: 14),
        ),
      ],
      initiallyExpanded: isGridConfigured, // Buka jika sudah ada label yang dikonfigurasi
    );
  }

  // ***** START: NEW WIDGET FOR UNCONDITIONAL JUMP *****
  Widget _buildUnconditionalJumpSetting(String sectionId, FormQuestion question) {
    // Get all possible jump targets
    List<DropdownMenuItem<String?>> allJumpTargets = [ // Made String? to accommodate null value
      const DropdownMenuItem(
        value: null, // Represents "No unconditional jump"
        child: Text("Tidak Ada Lompatan Otomatis", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 14)),
      ),
      // Separator or header for clarity
      const DropdownMenuItem(value: "HEADER_TARGET_UNCONDITIONAL", enabled: false, child: Text('Pilih Tujuan Lompat Otomatis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13))),
    ];

    for (int i = 0; i < controller.sections.length; i++) {
      final sec = controller.sections[i];
      String sectionRoman = _toRoman(i + 1);
      String sectionTitle = '$sectionRoman: ${sec.title.isNotEmpty ? (sec.title.length > 20 ? sec.title.substring(0, 17) + '...' : sec.title) : "Tanpa Judul"}';

      allJumpTargets.add(DropdownMenuItem(
        value: 'section_start_${sec.id}',
        child: Text("Lompat ke Awal Bagian $sectionTitle", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ));

      for (int j = 0; j < sec.questions.length; j++) {
        final q = sec.questions[j];
        if (q.id == question.id) continue; // Cannot jump to itself

        String questionCodeDisplay = q.code != null && q.code!.isNotEmpty ? q.code! : "$sectionRoman.${j+1}";
        allJumpTargets.add(DropdownMenuItem(
          value: 'question_${q.id}',
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('  Lompat ke P: $questionCodeDisplay - ${q.questionText.length > 25 ? q.questionText.substring(0, 22) + '...' : q.questionText}', style: const TextStyle(fontSize: 14)),
          ),
        ));
      }
    }

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_current_section',
      child: Text('Akhir Bagian Ini (Lanjut Bagian Berikutnya)', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
    ));

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_form',
      child: Text('Akhir Form (Selesai)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green, fontSize: 14)),
    ));

    String? currentTarget = question.unconditionalJumpTarget;
    // Validate currentTarget against available options. If not found, set to null.
    bool isCurrentTargetValid = currentTarget == null || allJumpTargets.any((item) => item.value == currentTarget && item.value != "HEADER_TARGET_UNCONDITIONAL");

    if (!isCurrentTargetValid) {
      print("Warning: Unconditional jump target '$currentTarget' for question '${question.id} / ${question.code}' not found in options. Resetting to null.");
      currentTarget = null; // Reset to "Tidak Ada Lompatan Otomatis"
    }

    return _buildExpansionTileForSettings(
      'Lompatan Otomatis (Setelah Pertanyaan Ini)',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
              "Jika diatur, setelah pertanyaan ini dijawab (atau ditampilkan jika tidak memerlukan input), form akan otomatis melompat ke tujuan yang dipilih. Ini akan mengabaikan urutan normal dan logika bersyarat.",
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.3)
          ),
        ),
        DropdownButtonFormField<String?>(
          key: ValueKey('${question.id}_unconditional_jump_dd_${currentTarget ?? "null"}'), // Key to help rebuild if value changes externally
          decoration: _modernInputDecoration(labelText: 'Lompat Otomatis Ke:', isDense: true)
              .copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14)),
          value: currentTarget,
          items: allJumpTargets.where((item) => item.value != "HEADER_TARGET_UNCONDITIONAL").toList(),
          onChanged: (String? selectedValue) {
            controller.updateUnconditionalJump(sectionId, question.id, selectedValue);
          },
          isExpanded: true,
          hint: const Text('Pilih tujuan...'),
        ),
        if (question.type == QuestionType.gridNumeric && question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Untuk Grid Numerik, lompatan ini akan terjadi setelah pengguna selesai dengan interaksi grid dan berlanjut.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
            ),
          ),
        if (question.conditionalJumps.isNotEmpty && question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Peringatan: 'Logika Bersyarat' juga aktif. Lompatan Otomatis ini akan diprioritaskan dan mengabaikan Logika Bersyarat.",
                    style: TextStyle(fontSize: 12.5, color: Colors.orange.shade800, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                ),
              ],
            ),
          )
      ],
      initiallyExpanded: question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty,
    );
  }
  // ***** END: NEW WIDGET FOR UNCONDITIONAL JUMP *****


  Widget _buildQuestionCard(String sectionId, int sectionIndexOverall, String questionIdFromList, int questionIndexInSection) {
    return Obx(() {
      final question = controller.sections
          .firstWhereOrNull((s) => s.id == sectionId)
          ?.questions
          .firstWhereOrNull((q) => q.id == questionIdFromList);

      if (question == null) {
        return Card(margin: const EdgeInsets.only(bottom:16, top:8), child: ListTile(title: Text("Error: Pertanyaan ID $questionIdFromList tidak dapat dimuat.")));
      }

      String displayCode = question.code != null && question.code!.isNotEmpty ? "(${question.code}) " : "";
      String questionTypeString = question.type.toShortString();
      if (questionTypeString.isNotEmpty) {
        questionTypeString = (questionTypeString[0].toUpperCase() + questionTypeString.substring(1));
        if (question.type == QuestionType.gridNumeric) {
          questionTypeString = "Grid Numerik";
        }
      }

      // Judul untuk ExpansionTile Pertanyaan
      Widget questionTileTitle = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan vertikal
        children: [
          Expanded(
            child: Text(
              'Pertanyaan ${questionIndexInSection + 1} $displayCode- $questionTypeString',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600), // Sesuaikan style
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
              icon: Icon(Icons.delete_forever_outlined, color: Colors.red.shade300, size: 22), // Ukuran disesuaikan
              tooltip: 'Hapus Pertanyaan',
              padding: const EdgeInsets.all(4), // Padding agar area tap lebih baik
              constraints: const BoxConstraints(),
              splashRadius: 20,
              onPressed: () {
                Get.defaultDialog(
                    title: "Konfirmasi Hapus Pertanyaan",
                    middleText: "Anda yakin ingin menghapus pertanyaan '${question.questionText.isNotEmpty ? question.questionText : displayCode}'?",
                    textConfirm: "Hapus", textCancel: "Batal",
                    confirmTextColor: Colors.white, buttonColor: Colors.red.shade400,
                    cancelTextColor: Colors.grey.shade700,
                    onConfirm: () { controller.removeQuestion(sectionId, question.id); Get.back(); }
                );
              }
          ),
        ],
      );

      // Konten untuk ExpansionTile Pertanyaan
      List<Widget> questionTileChildren = [
        Padding( // Tambahkan padding untuk konten di dalam ExpansionTile
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0), // Atas 0 karena sudah ada padding dari tile header
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // Jarak dari header tile ke konten pertama
              _PersistentTextField(
                fieldKey: ValueKey('${question.id}_code'),
                initialValue: question.code ?? '',
                onChanged: (text) => controller.updateQuestionCode(sectionId, question.id, text),
                decoration: _modernInputDecoration(
                    labelText: 'Kode Pertanyaan',
                    hintText: 'Otomatis: ${sectionIndexOverall + 1}${(questionIndexInSection + 1).toString().padLeft(2,'0')} atau sesuaikan',
                    isDense: true,
                    prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.tag, size: 18, color: Colors.grey.shade500))
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _PersistentTextField(
                fieldKey: ValueKey('${question.id}_text'),
                initialValue: question.questionText,
                onChanged: (text) => controller.updateQuestionText(sectionId, question.id, text),
                decoration: _modernInputDecoration(labelText: 'Teks Pertanyaan', isDense: true,
                    prefixIcon: Padding(padding: const EdgeInsets.all(10.0), child: Icon(Icons.help_outline_rounded, size: 18, color: Colors.grey.shade500))
                ),
                maxLines: null,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              _PersistentTextField(
                fieldKey: ValueKey('${question.id}_description'),
                initialValue: question.description ?? '',
                onChanged: (text) => controller.updateQuestionDescription(sectionId, question.id, text),
                decoration: _modernInputDecoration(
                  labelText: 'Deskripsi Tambahan (Opsional)',
                  hintText: 'Jelaskan lebih lanjut...',
                  isDense: true,
                ),
                maxLines: null,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              if (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes || question.type == QuestionType.dropdown)
                _buildOptionsSection(sectionId, question),

              if (question.type == QuestionType.gridNumeric)
                _buildGridNumericSettings(sectionId, question),

              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildPredefinedRuleDropdown(sectionId, question),
              ),
              const SizedBox(height: 4),

              if (question.type == QuestionType.number || question.type == QuestionType.gridNumeric)
                _buildNumberValidationSection(sectionId, question),
              if (question.type == QuestionType.text || question.type == QuestionType.paragraph)
                _buildTextValidationSection(sectionId, question),
              if (question.type == QuestionType.date)
                _buildDateValidationSection(sectionId, question),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Wajib diisi', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: question.isRequired,
                    onChanged: (value) => controller.updateQuestionRequired(sectionId, question.id, value),
                    activeColor: accentThemeColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Spacer(), // flex: 1 default
                  if (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes)
                    Flexible(
                      flex: 3, // Anda menggunakan 3, ini bagus
                      child: Row(
                        // --- PERUBAHAN DI SINI ---
                        // 1. Hapus atau komentari mainAxisSize: MainAxisSize.min
                        //    agar Row ini mengambil semua lebar yang diberikan oleh Flexible pembungkusnya.
                        // mainAxisSize: MainAxisSize.min, (Dihapus/dikomentari)

                        // 2. Atur mainAxisAlignment ke MainAxisAlignment.end
                        //    agar anak-anak Row ini (teks dan switch) rata ke kanan.
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Flexible( // Teks tetap Flexible agar bisa mengisi sisa ruang
                            child: Text(
                              'Opsi "Lainnya"',
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: question.hasOtherOption,
                            onChanged: (value) => controller.updateQuestionHasOtherOption(sectionId, question.id, value),
                            activeColor: accentThemeColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              _buildRepeatableSetting(sectionId, question),
              _buildRepeatableGroupSettings(sectionId, question),
              _buildConditionalJumpSetting(sectionId, question), // Conditional jumps
              _buildUnconditionalJumpSetting(sectionId, question), // ***** ADDED UNCONDITIONAL JUMP UI HERE *****
              if (question.type == QuestionType.dropdown)
                _buildDependentOptionsConfigurator(sectionId, question),
            ],
          ),
        ),
      ];

      // Menggunakan Container untuk menjaga shadow dan border luar
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
        decoration: BoxDecoration(
            color: Colors.white, // Warna latar belakang kartu pertanyaan
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey.shade200, width: 1.0),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade100.withOpacity(0.8), blurRadius: 4, offset: const Offset(0,1))
            ]
        ),
        child: ExpansionTile(
          key: ValueKey(question.id), // Key untuk state ExpansionTile
          title: questionTileTitle,
          initiallyExpanded: question.questionText.trim().isEmpty && (question.code ?? '').trim().isEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Padding untuk header tile
          childrenPadding: EdgeInsets.zero, // Padding untuk children diatur oleh Padding di dalam questionTileChildren
          iconColor: accentThemeColor,
          collapsedIconColor: Colors.grey.shade700,
          shape: const Border(top: BorderSide.none, bottom: BorderSide.none),
          collapsedShape: const Border(top: BorderSide.none, bottom: BorderSide.none),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          children: questionTileChildren,
        ),
      );
    });
  }

  Widget _buildRepeatableGroupSettings(String sectionId, FormQuestion question) {
    final String uniqueTagSuggestion = "grup_${question.id.substring(0, 5)}";

    return _buildExpansionTileForSettings(
      'Pengaturan Grup Pertanyaan Berulang',
      [
        // Opsi 1: Pertanyaan ini adalah PENGONTROL grup
        // Hanya boleh tipe Angka
        if (question.type == QuestionType.number)
          CheckboxListTile(
            title: Text("Jadikan Pengontrol Grup?", style: TextStyle(fontSize: 14, fontWeight: question.isRepeatableGroupController ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text("Jawaban pertanyaan ini (angka) akan menentukan berapa kali grup pertanyaan lain diulang.", style: const TextStyle(fontSize: 12)),
            value: question.isRepeatableGroupController,
            onChanged: (bool? value) {
              if (value == true) {
                // Jika belum ada tag, berikan sugesti
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, true, question.controlledGroupTag ?? uniqueTagSuggestion);
              } else {
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, false, null);
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        if (question.isRepeatableGroupController && question.type == QuestionType.number)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
            child: _PersistentTextField( // Ganti ke _PersistentTextField
              fieldKey: ValueKey('${question.id}_controlledGroupTag_persistent'),
              initialValue: question.controlledGroupTag ?? uniqueTagSuggestion,
              decoration: _modernInputDecoration(
                  labelText: 'ID Unik Grup yang Dikontrol',
                  hintText: 'Contoh: ${uniqueTagSuggestion}',
                  isDense: true),
              onChanged: (tag) {
                controller.updateQuestionAsRepeatableGroupController(sectionId, question.id, true, tag.isNotEmpty ? tag : null);
              },
              style: const TextStyle(fontSize: 13),
            ),
          ),

        if (question.type == QuestionType.number && question.isRepeatableGroupController)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Divider(height: 12, color: Colors.grey.shade300),
          ),

        // Opsi 2: Pertanyaan ini adalah ANGGOTA grup
        // Tidak boleh jika pertanyaan ini adalah controller
        if (!question.isRepeatableGroupController) ...[
          CheckboxListTile(
            title: Text("Jadikan Anggota Grup Berulang?", style: TextStyle(fontSize: 14, fontWeight: (question.belongsToGroupTag !=null && question.belongsToGroupTag!.isNotEmpty) ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text("Pertanyaan ini akan diulang berdasarkan jawaban pertanyaan pengontrol.", style: const TextStyle(fontSize: 12)),
            value: (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty),
            onChanged: (bool? value) {
              if (value == true) {
                // Biarkan kosong dulu, user akan pilih dari dropdown
                controller.updateQuestionBelongsToGroupTag(sectionId, question.id, question.belongsToGroupTag); // Mungkin sudah ada nilai sebelumnya
              } else {
                controller.updateQuestionBelongsToGroupTag(sectionId, question.id, null);
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: accentThemeColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty || (question.isRepeatableGroupController == false && Get.find<AdminFormBuilderController>().getAvailableControlledGroupTags(sectionId, question.id).isNotEmpty)) // Tampilkan dropdown jika sudah jadi anggota ATAU ada tag yang bisa dipilih
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
              child: DropdownButtonFormField<String?>(
                value: question.belongsToGroupTag,
                decoration: _modernInputDecoration(labelText: 'Pilih ID Grup Induk', isDense: true),
                hint: const Text('Pilih grup...'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Tidak termasuk grup / Lepaskan", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                  ...controller.getAvailableControlledGroupTags(sectionId, question.id)
                      .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                      .toList(),
                ],
                onChanged: (String? selectedTag) {
                  controller.updateQuestionBelongsToGroupTag(sectionId, question.id, selectedTag);
                },
                isExpanded: true,
              ),
            ),
          if (controller.getAvailableControlledGroupTags(sectionId, question.id).isEmpty && !question.isRepeatableGroupController && (question.belongsToGroupTag == null || question.belongsToGroupTag!.isEmpty) )
            Padding(
              padding: const EdgeInsets.only(left:16.0, top:0.0, bottom: 8.0),
              child: Text("Tidak ada grup pertanyaan yang tersedia. Buat pertanyaan pengontrol terlebih dahulu (tipe Angka).", style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
            ),
        ],

        // Info validasi silang (placeholder)
        if (question.isRepeatableGroupController && question.type == QuestionType.number)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Info Lanjutan (Validasi Silang):",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Untuk validasi seperti 'jawaban pertanyaan ini tidak boleh melebihi jawaban dari pertanyaan X (misal: 112)', akan memerlukan fitur validasi silang antar pertanyaan yang lebih canggih dan saat ini belum terimplementasi di UI builder ini. Namun, nilai min/max untuk pertanyaan ini sendiri dapat diatur di 'Pengaturan Validasi Angka'.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
      ],
      initiallyExpanded: question.isRepeatableGroupController || (question.belongsToGroupTag != null && question.belongsToGroupTag!.isNotEmpty),
    );
  }


  // --- Ganti keseluruhan method _buildOptionsSection Anda dengan kode di bawah ini ---

  Widget _buildOptionsSection(String sectionId, FormQuestion question) {
    // Helper untuk dekorasi input nilai opsi
    InputDecoration optionInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: accentThemeColor)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        isDense: true,
      );
    }

    // Helper untuk dekorasi input deskripsi opsi
    InputDecoration optionDescriptionInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
        border: InputBorder.none, // Dibuat lebih simpel tanpa border bawah
        contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        isDense: true,
      );
    }

    // List untuk menampung semua widget di dalam section ini
    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
        child: Text('Opsi Pilihan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
      ),
    ];

    // Menambahkan setiap opsi yang ada dengan field untuk nilai dan deskripsi
    children.addAll(question.options.asMap().entries.map((entry) {
      int index = entry.key;
      // Asumsikan 'question.options' sekarang adalah 'List<QuestionOption>'
      QuestionOption option = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            // Baris untuk nilai opsi
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    question.type == QuestionType.multipleChoice ? Icons.radio_button_off_rounded :
                    question.type == QuestionType.checkboxes ? Icons.check_box_outline_blank_rounded :
                    Icons.arrow_right_rounded,
                    color: Colors.grey.shade500, size: 18,
                  ),
                ),
                Expanded(
                  child: _PersistentTextField(
                    fieldKey: ValueKey('${question.id}_option_value_$index'),
                    initialValue: option.value,
                    // Panggil metode baru di controller untuk memperbarui nilai
                    onChanged: (text) => controller.updateOptionValue(sectionId, question.id, index, text),
                    decoration: optionInputDecoration('Nilai Opsi ${index + 1}'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 20),
                  onPressed: () => controller.removeOption(sectionId, question.id, index),
                  splashRadius: 16, padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            // TextField baru untuk deskripsi, diletakkan di bawah nilai
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 44, top: 0),
              child: _PersistentTextField(
                fieldKey: ValueKey('${question.id}_option_desc_$index'),
                initialValue: option.description ?? '',
                // Panggil metode baru di controller untuk memperbarui deskripsi
                onChanged: (text) => controller.updateOptionDescription(sectionId, question.id, index, text),
                decoration: optionDescriptionInputDecoration('Deskripsi untuk opsi ini (opsional)'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ),
            // Beri pemisah jika bukan opsi terakhir
            if (index < question.options.length - 1)
              Divider(height: 16, thickness: 0.5, color: Colors.grey.shade200, indent: 24, endIndent: 44),
          ],
        ),
      );
    }).toList());

    // Menambahkan placeholder untuk "Opsi Lainnya" jika aktif
    if (question.hasOtherOption && (question.type == QuestionType.multipleChoice || question.type == QuestionType.checkboxes)) {
      children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    question.type == QuestionType.multipleChoice ? Icons.radio_button_checked_rounded : Icons.check_box_rounded,
                    color: Colors.grey.shade700,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Lainnya...',
                        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                        hintText: 'Kolom input teks akan muncul untuk responden',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400, style: BorderStyle.solid)),
                        disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400, style: BorderStyle.solid)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          )
      );
    }

    // Tombol "Tambah Opsi"
    children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => controller.addOption(sectionId, question.id),
            icon: const Icon(Icons.add_circle_outline_rounded, color: accentThemeColor, size: 20),
            label: const Text('Tambah Opsi', style: TextStyle(color: accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
          ),
        )
    );

    // Divider di akhir section
    children.add(
      const Divider(height: 16, thickness: 0.5),
    );

    // Mengembalikan semua widget dalam satu Column
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }


  Widget _buildExpansionTileForSettings(String title, List<Widget> children, {bool initiallyExpanded = false}) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 0), // Remove default padding
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8), // Padding for children
      initiallyExpanded: initiallyExpanded,
      iconColor: accentThemeColor,
      collapsedIconColor: Colors.grey.shade600,
      shape: const Border(top: BorderSide.none, bottom: BorderSide.none), // No border when expanded
      collapsedShape: const Border(top: BorderSide.none, bottom: BorderSide.none), // No border when collapsed
      children: children,
    );
  }

  Widget _buildTextValidationSection(String sectionId, FormQuestion question) {
    bool isValidationNotEmpty = question.validation != null &&
        (question.validation!.minLength != null ||
            question.validation!.maxLength != null ||
            (question.validation!.regex != null && question.validation!.regex!.isNotEmpty));

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Teks/Paragraf',
      [
        _PersistentTextField( // Ganti ke _PersistentTextField
          fieldKey: ValueKey('${question.id}_validation_minLength_persistent'),
          initialValue: question.validation?.minLength?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, (question.validation ?? ValidationRule()).copyWith(minLength: int.tryParse(value), setMinLengthNull: value.isEmpty)); },
        ),
        const SizedBox(height: 8),
        _PersistentTextField( // Ganti ke _PersistentTextField
          fieldKey: ValueKey('${question.id}_validation_maxLength_persistent'),
          initialValue: question.validation?.maxLength?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Panjang Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId,question.id, (question.validation ?? ValidationRule()).copyWith(maxLength: int.tryParse(value), setMaxLengthNull: value.isEmpty)); },
        ),
        const SizedBox(height: 8),
        _PersistentTextField( // Ganti ke _PersistentTextField
          fieldKey: ValueKey('${question.id}_validation_regex_persistent'),
          initialValue: question.validation?.regex ?? '',
          decoration: _modernInputDecoration(labelText: 'Pola Regex Kustom', hintText: 'Opsional, e.g. ^[A-Z]+\$', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id, (question.validation ?? ValidationRule()).copyWith(regex: value.isEmpty ? null : value, setRegexNull: value.isEmpty)); },
        ),
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

  // Ganti metode _buildNumberValidationSection Anda dengan ini:
  Widget _buildNumberValidationSection(String sectionId, FormQuestion question) {
    // 'question' yang diterima di sini adalah state terbaru dari Obx di _buildQuestionCard
    final ValidationRule validationRule = question.validation;

    bool isBasicNumValidationNotEmpty = validationRule.minValue != null || validationRule.maxValue != null;
    // Cek apakah comparisonOperator ada dan bukan 'none'
    bool isComparisonRuleNotEmpty = (validationRule.comparisonOperator != null &&
        validationRule.comparisonOperator != ComparisonOperatorType.none.toShortString()) &&
        validationRule.compareToQuestionId != null &&
        validationRule.compareToQuestionId!.isNotEmpty;

    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Angka & Perbandingan',
      [
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_minValue'),
          initialValue: validationRule.minValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Min.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id,
              validationRule.copyWith(minValue: num.tryParse(value), setMinValueNull: value.isEmpty));
          },
        ),
        const SizedBox(height: 8),
        _PersistentTextField(
          fieldKey: ValueKey('${question.id}_validation_maxValue'),
          initialValue: validationRule.maxValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _modernInputDecoration(labelText: 'Nilai Max.', hintText: 'Opsional', isDense: true),
          onChanged: (value) { controller.updateValidation(sectionId, question.id,
              validationRule.copyWith(maxValue: num.tryParse(value), setMaxValueNull: value.isEmpty));
          },
        ),
        const SizedBox(height: 16),
        Text("Validasi Perbandingan dengan Pertanyaan Lain:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: validationRule.comparisonOperator ?? ComparisonOperatorType.none.toShortString(),
          decoration: _modernInputDecoration(labelText: 'Operator Perbandingan', isDense: true),
          items: ComparisonOperatorType.values.map((op) {
            String displayText;
            switch(op){
              case ComparisonOperatorType.none: displayText = "Tidak ada perbandingan"; break;
              case ComparisonOperatorType.lessThan: displayText = "Kurang Dari (<)"; break;
              case ComparisonOperatorType.lessThanOrEqual: displayText = "Kurang Dari atau Sama Dengan (<=)"; break;
              case ComparisonOperatorType.equal: displayText = "Sama Dengan (=="; break;
              case ComparisonOperatorType.notEqual: displayText = "Tidak Sama Dengan (!=)"; break;
              case ComparisonOperatorType.greaterThan: displayText = "Lebih Dari (>)"; break;
              case ComparisonOperatorType.greaterThanOrEqual: displayText = "Lebih Dari atau Sama Dengan (>=)"; break;
            }
            return DropdownMenuItem<String?>(
                value: op.toShortString(),
                child: Text(displayText, style: TextStyle(fontSize:14, fontStyle: op == ComparisonOperatorType.none ? FontStyle.italic : FontStyle.normal))
            );
          }).toList(),
          onChanged: (String? selectedOpString) {
            final selectedOperator = selectedOpString == ComparisonOperatorType.none.toShortString() ? null : selectedOpString;
            controller.updateValidation(
              sectionId, question.id,
              validationRule.copyWith(
                comparisonOperator: selectedOperator, setComparisonOperatorNull: selectedOperator == null,
                compareToQuestionId: selectedOperator == null ? null : validationRule.compareToQuestionId,
                setCompareToQuestionIdNull: selectedOperator == null,
                compareToQuestionCode: selectedOperator == null ? null : validationRule.compareToQuestionCode,
                setCompareToQuestionCodeNull: selectedOperator == null,
              ),
            );
          },
          isExpanded: true,
        ),
        // Dropdown untuk memilih pertanyaan pembanding hanya muncul jika operator dipilih
        if (validationRule.comparisonOperator != null && validationRule.comparisonOperator != ComparisonOperatorType.none.toShortString()) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: validationRule.compareToQuestionId,
            decoration: _modernInputDecoration(labelText: 'Bandingkan dengan Pertanyaan:', isDense: true),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text("Pilih pertanyaan...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))),
              ...controller.getAllQuestionsForLinking(currentQuestionIdToExclude: question.id, numericOnly: true) // Hanya pertanyaan numerik
                  .map((qMap) => DropdownMenuItem<String?>(value: qMap['id'], child: Text("${qMap['code']} - ${qMap['text']}", style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)))
                  .toList(),
            ],
            onChanged: (String? selectedTargetId) {
              FormQuestion? targetQ = controller.findQuestionById(selectedTargetId ?? '');
              controller.updateValidation(
                sectionId, question.id,
                validationRule.copyWith(
                    compareToQuestionId: selectedTargetId, setCompareToQuestionIdNull: selectedTargetId == null,
                    compareToQuestionCode: targetQ?.code, setCompareToQuestionCodeNull: selectedTargetId == null || targetQ?.code == null
                ),
              );
            },
            isExpanded: true,
          ),
        ],
      ],
      initiallyExpanded: isBasicNumValidationNotEmpty || isComparisonRuleNotEmpty,
    );
  }

  Widget _buildDateValidationSection(String sectionId, FormQuestion question) {
    // Add specific date validation fields here if needed in the future.
    // For now, it's mostly covered by predefined rules or general validation if any.
    bool isValidationNotEmpty = question.validation != null &&
        (question.validation!.predefinedRule == 'pastDateOnly' ||
            question.validation!.predefinedRule == 'futureDateOnly');
    return _buildExpansionTileForSettings(
      'Pengaturan Validasi Tanggal',
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Gunakan "Pola Validasi Umum" di bawah untuk validasi tanggal (misal: Hanya Tanggal Lalu).', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
        )
      ],
      initiallyExpanded: isValidationNotEmpty,
    );
  }

  Widget _buildPredefinedRuleDropdown(String sectionId, FormQuestion question) {
    final Map<String, String> predefinedRulesDisplay = {
      'none': 'Tidak Ada Pola Khusus',
      'lettersOnly': 'Hanya Huruf',
      'numbersOnly': 'Hanya Angka',
      'alphanumeric': 'Huruf & Angka',
      'email': 'Format Email',
      'url': 'Format URL',
      'phone': 'Nomor Telepon (ID)',
      'nik': 'NIK (16 Digit Angka)',
      'noKK': 'No. KK (16 Digit Angka)',
      // Add more as needed
    };

    if (question.type == QuestionType.gridNumeric) {
      predefinedRulesDisplay['gridAllCellsRequired'] = 'Wajib Isi Semua Sel Grid (Angka)';
    }

    if (question.type == QuestionType.date) {
      predefinedRulesDisplay['pastDateOnly'] = 'Hanya Tanggal Lalu';
      predefinedRulesDisplay['futureDateOnly'] = 'Hanya Tanggal Akan Datang';
    }


    String? currentRule = question.validation?.predefinedRule;
    if (currentRule != null && !predefinedRulesDisplay.containsKey(currentRule)) {
      currentRule = 'none'; // Default if rule from db is not in our map
    }
    if (currentRule == null || currentRule.isEmpty) currentRule = 'none';


    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 8.0), // Reduced top padding
      child: DropdownButtonFormField<String>(
        value: currentRule,
        decoration: _modernInputDecoration(
          labelText: 'Pola Validasi Umum',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: predefinedRulesDisplay.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) {
          controller.updateValidation(
              sectionId,
              question.id,
              (question.validation ?? ValidationRule()).copyWith(
                  predefinedRule: (value == 'none' || value == null || value.isEmpty) ? null : value,
                  setPredefinedRuleNull: (value == 'none' || value == null || value.isEmpty)
              )
          );
        },
        isExpanded: true,
      ),
    );
  }


  Widget _buildRepeatableSetting(String sectionId, FormQuestion question) {
    return _buildExpansionTileForSettings(
      'Pengaturan Ulang Pertanyaan',
      [
        CheckboxListTile(
          title: const Text("Dapat diulang?", style: TextStyle(fontSize: 14)),
          value: question.repeatable,
          onChanged: (bool? value) { controller.updateQuestionRepeatable(sectionId, question.id, value ?? false); },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: accentThemeColor,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (question.repeatable)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: _PersistentTextField( // Ganti ke _PersistentTextField
              fieldKey: ValueKey('${question.id}_repeatCount_persistent'),
              initialValue: question.repeatCount?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: _modernInputDecoration(labelText: 'Jumlah Maks. Pengulangan', hintText: 'Kosongkan untuk tanpa batas', isDense: true),
              onChanged: (value) { controller.updateQuestionRepeatable(sectionId, question.id, true, count: int.tryParse(value)); },
            ),
          ),
      ],
      initiallyExpanded: question.repeatable,
    );
  }

  Widget _buildConditionalJumpSetting(String sectionId, FormQuestion question) {
    bool canHaveJumps = question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.checkboxes ||
        question.type == QuestionType.dropdown ||
        (question.options.isNotEmpty); // Check if options exist, even if not a typical choice type

    // If an unconditional jump is set, conditional jumps are secondary.
    // We might still allow configuring them but show a warning.
    bool hasUnconditionalJump = question.unconditionalJumpTarget != null && question.unconditionalJumpTarget!.isNotEmpty;


    if (!canHaveJumps) {
      return const SizedBox.shrink();
    }

    return _buildExpansionTileForSettings(
      'Logika Bersyarat (Lompat per Jawaban)',
      [
        if(hasUnconditionalJump)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Info: Lompatan Otomatis sudah diatur untuk pertanyaan ini. Pengaturan Logika Bersyarat di sini akan diabaikan jika Lompatan Otomatis aktif.",
                    style: TextStyle(fontSize: 12.5, color: Colors.blue.shade800, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        if (question.conditionalJumps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Belum ada aturan lompat bersyarat.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
        ...question.conditionalJumps.asMap().entries.map((entry) {
          final jump = entry.value; String jumpToTargetText = "...";

          if (jump.jumpToQuestionId == 'END_OF_FORM') jumpToTargetText = 'Akhir Form';
          else if (jump.jumpToQuestionId == 'END_OF_SECTION') { // This implies jump to next section or end of current if it's the last
            // String targetSectionRoman = "";
            FormSection? targetSection;
            int targetSectionIndex = -1;

            if (jump.jumpToSectionId != null && jump.jumpToSectionId!.isNotEmpty) { // Explicitly jumping to a specific section start
              targetSection = controller.sections.firstWhereOrNull((s) => s.id == jump.jumpToSectionId);
              if(targetSection != null) {
                targetSectionIndex = controller.sections.indexOf(targetSection);
              }
            }
            // If jump.jumpToSectionId is null or empty, it means end of CURRENT section, then proceed to next.
            // The display text needs to be clear.

            if (targetSection != null && targetSectionIndex != -1) { // Jumping to a specific section
              String targetSectionRoman = _toRoman(targetSectionIndex + 1);
              jumpToTargetText = 'Awal Bagian: $targetSectionRoman ${targetSection.title.isNotEmpty ? (targetSection.title.length > 15 ? targetSection.title.substring(0,12)+'...' : targetSection.title) : "Tanpa Judul"}';
            } else { // End of current section (implies proceed to next section naturally or end of form if last section)
              jumpToTargetText = 'Bagian Selanjutnya / Akhir Bagian Ini';
            }

          } else if (jump.jumpToQuestionId.isNotEmpty) {
            bool targetFound = false;
            for (var sec_idx = 0; sec_idx < controller.sections.length; sec_idx++) {
              var sec = controller.sections[sec_idx];
              for (var q_idx = 0; q_idx < sec.questions.length; q_idx++) {
                var q_item = sec.questions[q_idx];
                if (q_item.id == jump.jumpToQuestionId) {
                  String qCodeDisplay = q_item.code != null && q_item.code!.isNotEmpty ? q_item.code! : "${_toRoman(sec_idx + 1)}.${q_idx + 1}";
                  jumpToTargetText = 'P: $qCodeDisplay - ${q_item.questionText.length > 20 ? q_item.questionText.substring(0,17)+'...' : q_item.questionText}';
                  targetFound = true;
                  break;
                }
              }
              if (targetFound) break;
            }
            if (!targetFound) {
              jumpToTargetText = 'ID Pertanyaan: ${jump.jumpToQuestionId} (Mungkin terhapus)';
            }
          }

          return ListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: Text('Jika jawaban: "${jump.conditionValue}"', style: const TextStyle(fontSize: 14)),
            subtitle: Text('Lompat ke: $jumpToTargetText', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 20),
              onPressed: () {
                // For conditional jumps, removal is based on the conditionValue and target.
                // A simpler approach is to remove by its instance or a unique aspect if available.
                // If ConditionalJump has its own unique ID, that would be best.
                // For now, assuming the combination of conditionValue and target is unique enough for UI removal.
                // The controller.removeConditionalJump might need adjustment if it relies only on targetId.
                // Let's assume controller.removeConditionalJump can find and remove this specific jump object
                // or by a combination of its properties.
                // A better way: pass the jump object itself or its index.
                // For now, we'll rely on the existing controller.removeConditionalJump structure.
                // This might need a more robust removal mechanism (e.g., by jump object's unique ID if it had one, or by index).
                // The current controller.removeConditionalJump removes by targetId, which is problematic if multiple conditions jump to the same target.
                // This needs a fix in the controller or how jumps are identified for removal.
                // A temporary workaround could be to remove by index if the list is stable.
                // For now, we stick to the provided structure, highlighting this potential issue.
                String idToRemoveForController = jump.jumpToQuestionId; // Default
                if (jump.jumpToQuestionId == 'END_OF_SECTION' && jump.jumpToSectionId != null && jump.jumpToSectionId!.isNotEmpty) {
                  idToRemoveForController = jump.jumpToSectionId!; // if jumpToSectionId is the main part of the target
                }
                // Ideally, the controller.removeConditionalJump should take the specific ConditionalJump object or its unique ID.
                // Since the current one takes `targetIdToRemove`, we need to be careful.
                // A better controller method would be: removeConditionalJump(sectionId, questionId, jumpToRemove: ConditionalJump)
                controller.removeConditionalJump(sectionId, question.id, idToRemoveForController); // This might remove more than intended if not specific enough.
              },
              splashRadius: 18, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showAddConditionalJumpDialog(sectionId, question),
            icon: const Icon(Icons.add_circle_outline_rounded, color: accentThemeColor, size: 20),
            label: const Text('Tambah Aturan Bersyarat', style: TextStyle(color: accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
          ),
        ),
      ],
      initiallyExpanded: question.conditionalJumps.isNotEmpty,
    );
  }


  void _showAddConditionalJumpDialog(String sectionId, FormQuestion question) {
    final TextEditingController conditionController = TextEditingController();
    String? selectedTargetCompositeValue; // e.g., 'question_xyz', 'section_start_abc', 'end_of_form'


    List<DropdownMenuItem<String>> allJumpTargets = [
      const DropdownMenuItem(value: "HEADER_TARGET", enabled: false, child: Text('Pilih Tujuan Lompat:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
    ];

    for (int i = 0; i < controller.sections.length; i++) {
      final sec = controller.sections[i];
      String sectionRoman = _toRoman(i + 1);
      String sectionTitle = '$sectionRoman: ${sec.title.isNotEmpty ? (sec.title.length > 20 ? sec.title.substring(0, 17) + '...' : sec.title) : "Tanpa Judul"}';


      allJumpTargets.add(DropdownMenuItem(
        value: 'section_start_${sec.id}',
        child: Text("Lompat ke Awal Bagian $sectionTitle", style: const TextStyle(fontWeight: FontWeight.w500)),
      ));

      for (int j = 0; j < sec.questions.length; j++) {
        final q = sec.questions[j];
        // Prevent jumping to the question itself in conditional logic as it creates a loop on the same question.
        if (q.id == question.id) continue;

        String questionCodeDisplay = q.code != null && q.code!.isNotEmpty ? q.code! : "$sectionRoman.${j+1}";
        allJumpTargets.add(DropdownMenuItem(
          value: 'question_${q.id}',
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('  P $questionCodeDisplay: ${q.questionText.length > 25 ? q.questionText.substring(0, 22) + '...' : q.questionText}'),
          ),
        ));
      }
    }

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_current_section',
      child: Text('Akhir Bagian Ini (Lanjut Bagian Berikutnya)', style: TextStyle(fontStyle: FontStyle.italic)),
    ));

    allJumpTargets.add(const DropdownMenuItem(
      value: 'end_of_form',
      child: Text('Akhir Form (Selesai)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
    ));


    Get.dialog(
      AlertDialog(
        title: const Text('Tambah Aturan Lompat Bersyarat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jika jawaban untuk "${question.questionText.length > 30 ? question.questionText.substring(0,27) + "..." : question.questionText}" adalah:', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),

              if (question.options.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: _modernInputDecoration(labelText: 'Nilai Jawaban Pemicu', isDense: true),
                  items: question.options.map((opt) => DropdownMenuItem(value: opt.value, child: Text(opt.value))).toList(),
                  onChanged: (val) => conditionController.text = val ?? '',
                  hint: const Text('Pilih dari opsi'),
                )
              else
                _PersistentTextField( // Ganti ke _PersistentTextField
                  fieldKey: ValueKey('${question.id}_conditional_jump_condition_input'),
                  initialValue: '', // Selalu mulai kosong untuk input baru
                  onChanged: (text) => conditionController.text = text,
                  decoration: _modernInputDecoration(labelText: 'Nilai Jawaban Pemicu', hintText: 'Contoh: Ya, Tidak, >10', isDense: true),
                ),

              const SizedBox(height: 16),
              const Text('Maka lompat ke:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _modernInputDecoration(labelText: 'Pilih Tujuan', isDense: true)
                    .copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14)),
                value: selectedTargetCompositeValue,
                items: allJumpTargets.where((item) => item.value != "HEADER_TARGET").toList(),
                onChanged: (valueWithPrefix) {
                  selectedTargetCompositeValue = valueWithPrefix;
                },
                isExpanded: true,
                hint: const Text('Pilih tujuan...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentThemeColor, foregroundColor: Colors.white),
            onPressed: () {
              final conditionValue = conditionController.text.trim();
              if (conditionValue.isNotEmpty && selectedTargetCompositeValue != null && selectedTargetCompositeValue != "HEADER_TARGET") {
                String jumpToQId = '';
                String? jumpToSId; // This will store the ID of the section if the jump is to a section_start

                List<String> parts = selectedTargetCompositeValue!.split('_');
                String type = parts.first;


                if (type == 'question' && parts.length > 1) {
                  jumpToQId = parts.sublist(1).join('_'); // Handle IDs that might contain underscores
                  // jumpToSId remains null
                } else if (type == 'section' && parts.length > 2 && parts[1] == 'start') {
                  jumpToSId = parts.sublist(2).join('_'); // Store the target section ID
                  jumpToQId = 'END_OF_SECTION'; // Special marker, interpreted with jumpToSId
                } else if (selectedTargetCompositeValue == 'end_of_current_section') {
                  jumpToQId = 'END_OF_SECTION'; // Special marker, implies current section end, jumpToSId is null
                  // jumpToSId remains null
                } else if (selectedTargetCompositeValue == 'end_of_form') {
                  jumpToQId = 'END_OF_FORM';
                  // jumpToSId remains null
                } else {
                  Get.snackbar('Peringatan', 'Tujuan lompat tidak valid atau format ID salah.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
                  return;
                }

                controller.addConditionalJump(sectionId, question.id, ConditionalJump(conditionValue: conditionValue, jumpToQuestionId: jumpToQId, jumpToSectionId: jumpToSId));
                Get.back();
              } else {
                Get.snackbar('Peringatan', 'Kondisi dan tujuan lompat harus diisi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade700, colorText: Colors.white);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Widget _buildDependentOptionsConfigurator(String sectionId, FormQuestion questionToList) {
    return Obx(() {
      final question = controller.sections
          .firstWhereOrNull((s) => s.id == sectionId)
          ?.questions
          .firstWhereOrNull((q) => q.id == questionToList.id) ?? questionToList;

      final potentialParents = controller.getPotentialParentQuestions(sectionId, question.id);

      FormQuestion? selectedParentQuestionObj;
      final String? storedParentIdInChild = question.dependentOptions?.parentQuestionId;

      if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty) {
        selectedParentQuestionObj = controller.findQuestionById(storedParentIdInChild);
      }

      final validParentQuestionIdsInDropdown = potentialParents.map((pQ) => pQ.id).toList();
      String? effectiveParentIdForDropdownValue = storedParentIdInChild;
      if (effectiveParentIdForDropdownValue != null && !validParentQuestionIdsInDropdown.contains(effectiveParentIdForDropdownValue)) {
        effectiveParentIdForDropdownValue = null;
      }

      // Kondisi ini sekarang sudah benar, karena `.options` pada parent adalah List<QuestionOption>
      bool showMappingInterface = selectedParentQuestionObj != null && selectedParentQuestionObj.options.isNotEmpty;

      return _buildExpansionTileForSettings(
        'Opsi Bergantung (Cascading)',
        [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String?>(
              key: ValueKey('${question.id}_parent_dd_${effectiveParentIdForDropdownValue ?? "no_parent_selected"}'),
              value: effectiveParentIdForDropdownValue,
              decoration: _modernInputDecoration(
                  labelText: 'Bergantung pada Pertanyaan (Induk)',
                  isDense: true
              ),
              hint: const Text('Pilih Pertanyaan Induk'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text("Tidak Bergantung / Hapus", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
                if (potentialParents.isNotEmpty)
                  ...potentialParents.map((parentQ) {
                    String parentSectionTitle = "Lain Bagian";
                    String parentSectionRoman = "";
                    int parentSectionIndex = controller.sections.indexWhere((s) => s.questions.any((qInS) => qInS.id == parentQ.id));
                    if (parentSectionIndex != -1) {
                      final sec = controller.sections[parentSectionIndex];
                      parentSectionRoman = _toRoman(parentSectionIndex + 1);
                      parentSectionTitle = sec.title.isNotEmpty ? sec.title : "Bagian $parentSectionRoman";
                    }
                    String parentQCodeDisplay = parentQ.code != null && parentQ.code!.isNotEmpty ? parentQ.code! : "N/A";
                    return DropdownMenuItem<String?>(
                      value: parentQ.id,
                      child: Text(
                        '$parentQCodeDisplay - ${parentQ.questionText.length > 15 ? parentQ.questionText.substring(0, 12) + "..." : parentQ.questionText} (di: $parentSectionTitle)',
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList()
                else
                  const DropdownMenuItem<String?>(
                    value: null,
                    enabled: false,
                    child: Text("Tidak ada calon induk tersedia", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
              ],
              onChanged: (String? newParentId) {
                controller.setParentQuestionForDependency(sectionId, question.id, newParentId);
              },
              isExpanded: true,
            ),
          ),

          const SizedBox(height: 10),

          if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty && selectedParentQuestionObj == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Pesan Info: Pertanyaan Induk (ID: $storedParentIdInChild) yang sebelumnya dipilih tidak ditemukan. Mungkin telah dihapus atau ID berubah. Silakan pilih ulang dari daftar di atas.',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),

          if (showMappingInterface) ...[
            Text(
              'Atur opsi anak untuk pertanyaan "${question.questionText}" berdasarkan jawaban dari "${selectedParentQuestionObj!.code ?? "Induk"}" (${selectedParentQuestionObj.questionText}):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedParentQuestionObj.options.length,
              itemBuilder: (context, index) {
                // --- PERBAIKAN DI SINI ---
                // 1. Ambil objek QuestionOption lengkap dari parent.
                final parentOptionObj = selectedParentQuestionObj!.options[index];
                // 2. Ekstrak nilai String-nya untuk digunakan sebagai kunci map dan parameter.
                final String parentOptionValue = parentOptionObj.value;

                // 3. Gunakan nilai String untuk mencari di dalam mapping.
                final currentChildOptions = question.dependentOptions?.optionMapping[parentOptionValue] ?? [];

                // 4. Kirim nilai String ke _buildParentOptionMappingTile.
                return _buildParentOptionMappingTile(
                  sectionId,
                  question.id,
                  parentOptionValue,
                  currentChildOptions,
                );
                // --- AKHIR PERBAIKAN ---
              },
            ),
          ]
          else if (storedParentIdInChild != null && storedParentIdInChild.isNotEmpty && selectedParentQuestionObj != null && selectedParentQuestionObj.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                  'Info: Pertanyaan Induk "${selectedParentQuestionObj.questionText}" (${selectedParentQuestionObj.code ?? selectedParentQuestionObj.id}) TIDAK MEMILIKI OPSI. Harap tambahkan opsi pada pertanyaan induk tersebut agar bisa mengatur dependensi.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12.5, fontStyle: FontStyle.italic)
              ),
            )
        ],
        initiallyExpanded: question.dependentOptions != null && question.dependentOptions!.parentQuestionId.isNotEmpty,
      );
    });
  }

  Widget _buildParentOptionMappingTile(String sectionId, String questionId, String parentOptionValue, List<String> currentChildOptions) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jika jawaban Induk adalah: "$parentOptionValue"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            const SizedBox(height: 6),
            Text(
              'Opsi untuk pertanyaan ini: ${currentChildOptions.isEmpty ? "(Belum diatur - akan menggunakan opsi standar pertanyaan ini)" : currentChildOptions.join(", ")}',
              style: TextStyle(fontSize: 13, color: currentChildOptions.isEmpty ? Colors.grey.shade600 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.edit_note_rounded, size: 20, color: accentThemeColor.withOpacity(0.8)),
                label: Text('Atur Opsi Anak', style: TextStyle(fontSize: 13, color: accentThemeColor.withOpacity(0.9), fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap
                ),
                onPressed: () {
                  _showEditChildOptionsDialog(sectionId, questionId, parentOptionValue, List<String>.from(currentChildOptions));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Di dalam kelas AdminFormBuilderPage

// Metode ini sekarang hanya menampilkan StatefulWidget dialog kustom
  void _showEditChildOptionsDialog(
      String sectionId,
      String questionId,
      String parentOptionValue,
      List<String> initialChildOptions
      ) {
    Get.dialog(
      _EditChildOptionsDialog( // Panggil StatefulWidget dialog kustom Anda
        pageController: controller, // Teruskan AdminFormBuilderController utama
        sectionId: sectionId,
        questionId: questionId,
        parentOptionValue: parentOptionValue,
        initialChildOptions: initialChildOptions,
      ),
      barrierDismissible: false, // Pengguna harus menekan tombol Batal atau Simpan
    );
  }

  Widget _buildAddQuestionButton(String sectionId) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.bottomSheet(
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, -2))]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text("Pilih Tipe Pertanyaan", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      children: QuestionType.values.map((type) {
                        IconData iconData; String typeName;
                        switch(type) {
                          case QuestionType.text: iconData = Icons.short_text_rounded; typeName = "Teks"; break;
                          case QuestionType.paragraph: iconData = Icons.notes_rounded; typeName = "Paragraf"; break;
                          case QuestionType.number: iconData = Icons.pin_outlined; typeName = "Angka"; break;
                          case QuestionType.date: iconData = Icons.date_range_rounded; typeName = "Tanggal"; break;
                          case QuestionType.multipleChoice: iconData = Icons.radio_button_checked_rounded; typeName = "Pilihan Ganda"; break;
                          case QuestionType.checkboxes: iconData = Icons.check_box_rounded; typeName = "Kotak Centang"; break;
                          case QuestionType.dropdown: iconData = Icons.arrow_drop_down_circle_rounded; typeName = "Dropdown"; break;
                          case QuestionType.gridNumeric: iconData = Icons.grid_on_outlined; typeName = "Grid Numerik"; break; // <-- OPSI BARU
                        }
                        return InkWell(
                          onTap: () {
                            controller.addQuestionToSection(sectionId, type);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                                color: accentThemeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentThemeColor.withOpacity(0.3))
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(iconData, color: accentThemeColor, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  typeName,
                                  style: TextStyle(fontSize: 10.5, color: accentThemeColor.withOpacity(0.95), fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              isScrollControlled: true,
            );
          },
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Tambah Pertanyaan',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}


// Di bagian atas file AdminFormBuilderPage.dart, setelah import
// atau di dalam kelas AdminFormBuilderPage sebagai nested class jika mau,
// tapi lebih umum sebagai helper class terpisah di file yang sama.

class _PersistentTextField extends StatefulWidget {
  final String initialValue;
  final ValueKey fieldKey; // Key unik untuk TextField ini berdasarkan data
  final InputDecoration decoration;
  final Function(String) onChanged;
  final TextStyle? style;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _PersistentTextField({
    required this.fieldKey, // Gunakan Key yang lebih spesifik dari pemanggil
    required this.initialValue,
    required this.decoration,
    required this.onChanged,
    this.style,
    this.maxLines = 1, // Default maxLines
    this.keyboardType,
  }) : super(key: fieldKey); // Teruskan fieldKey ke super constructor

  @override
  State<_PersistentTextField> createState() => _PersistentTextFieldState();
}


class _EditChildOptionsDialog extends StatefulWidget {
  final AdminFormBuilderController pageController; // Untuk memanggil updateMappingForParentOption
  final String sectionId;
  final String questionId;
  final String parentOptionValue;
  final List<String> initialChildOptions;

  const _EditChildOptionsDialog({
    // Key? key, // Tidak wajib untuk dialog via Get.dialog
    required this.pageController,
    required this.sectionId,
    required this.questionId,
    required this.parentOptionValue,
    required this.initialChildOptions,
  }); // : super(key: key);

  @override
  State<_EditChildOptionsDialog> createState() => _EditChildOptionsDialogState();
}

class _EditChildOptionsDialogState extends State<_EditChildOptionsDialog> {
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _optionControllers = widget.initialChildOptions
        .map((opt) => TextEditingController(text: opt))
        .toList();
    if (_optionControllers.isEmpty) {
      // Selalu mulai dengan satu field jika kosong
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Dispose semua controller saat dialog ini di-dispose
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    // print("AdminFormBuilderPage: _EditChildOptionsDialog disposed ${_optionControllers.length} controllers.");
    super.dispose();
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    setState(() {
      FocusScope.of(context).unfocus();
      // Controller yang dihapus akan di-dispose secara otomatis oleh metode dispose() utama widget ini
      // ketika dialog ditutup, atau jika Anda ingin langsung dispose di sini:
      // _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      // Jika setelah dihapus menjadi kosong, tambahkan satu field lagi agar tidak pernah benar-benar kosong
      if (_optionControllers.isEmpty) {
        _optionControllers.add(TextEditingController());
      }
    });
  }

  void _saveOptions() {
    final newChildOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    widget.pageController.updateMappingForParentOption(
        widget.sectionId, widget.questionId, widget.parentOptionValue, newChildOptions);

    Get.back(); // Tutup dialog. dispose() akan dipanggil otomatis.
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Atur Opsi Anak untuk Induk: "${widget.parentOptionValue}"',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 0), // Sesuaikan padding
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // Lebar dialog responsif
        child: Column(
          mainAxisSize: MainAxisSize.min, // Agar tinggi dialog menyesuaikan konten
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Opsi anak yang akan muncul jika jawaban induk adalah \"${widget.parentOptionValue}\":",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 15),
            Flexible( // Membuat ListView scrollable jika kontennya melebihi tinggi dialog
              child: ListView.builder(
                shrinkWrap: true, // Penting di dalam Column MainAxisSize.min
                itemCount: _optionControllers.length,
                itemBuilder: (ctx, index) {
                  return Padding(
                    key: ObjectKey(_optionControllers[index]), // Gunakan ObjectKey untuk stabilitas
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: AdminFormBuilderPage._modernInputDecoration( // Akses helper static
                                labelText: 'Opsi Anak ${index + 1}',
                                isDense: true
                            ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                fillColor: Colors.grey.shade50
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade300, size: 22),
                          onPressed: () => _removeOptionField(index),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add_circle_rounded, color: AdminFormBuilderPage.accentThemeColor, size: 20),
                label: Text('Tambah Opsi Anak', style: TextStyle(color: AdminFormBuilderPage.accentThemeColor, fontSize: 14, fontWeight: FontWeight.w500)),
                onPressed: _addOptionField,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0)),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12), // Sesuaikan padding
      actions: [
        OutlinedButton(
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          onPressed: () {
            Get.back(); // Menutup dialog akan memicu dispose() pada _EditChildOptionsDialogState
          },
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Simpan Opsi Ini'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminFormBuilderPage.accentThemeColor, foregroundColor: Colors.white),
          onPressed: _saveOptions,
        ),
      ],
    );
  }
}


class _PersistentTextFieldState extends State<_PersistentTextField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_PersistentTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (_textController.text != widget.initialValue) {
        // _textController.text = widget.initialValue; // This was causing cursor jump
        // Safely update the text and preserve cursor position if possible,
        // or reset to end if text actually changes.
        String newText = widget.initialValue;
        int currentOffset = _textController.selection.baseOffset;
        _textController.value = _textController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length < currentOffset ? newText.length : currentOffset),
          // Or simply: TextSelection.fromPosition(TextPosition(offset: newText.length)) to move to end
        );
        if (newText.length < currentOffset) { // if new text is shorter, move cursor to end
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
        }

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      // Tidak perlu key di sini karena sudah ada di StatefulWidget
      controller: _textController,
      onChanged: widget.onChanged,
      decoration: widget.decoration,
      style: widget.style,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
    );
  }




  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}