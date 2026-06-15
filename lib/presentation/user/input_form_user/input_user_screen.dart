// File: input_user_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:get/get.dart';
import 'input_user_controller.dart'; // Pastikan ini mengarah ke file controller yang benar
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // Untuk QuestionType, ValidationRule, ComparisonOperatorType
import 'package:intl/intl.dart';

// --- AWAL TAMBAHAN: Widget untuk Grup Berulang ---
/// [RepeatableGroupInstanceWidget] adalah komponen UI khusus untuk menampilkan satu instansi
/// dari grup pertanyaan yang berulang (misal: data per anggota keluarga).
/// 
/// Widget ini mengelola navigasi slider (Next/Previous) antar anggota dan 
/// memastikan visibilitas pertanyaan di dalam grup tetap sinkron per indeks.
class RepeatableGroupInstanceWidget extends StatelessWidget {
  final String groupTag;
  final List<FormQuestion> questionsInGroup;
  final InputUserController controller;
  final InputUserScreen screenInstance;

  const RepeatableGroupInstanceWidget({
    super.key,
    required this.groupTag,
    required this.questionsInGroup,
    required this.controller,
    required this.screenInstance,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int totalRepeatCount = controller.repeatableGroupCounts[groupTag] ?? 0;
      final int activeIndex = controller.activeRepeatIndexForGroup[groupTag] ?? 0;

      if (totalRepeatCount == 0 || activeIndex >= totalRepeatCount) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100, width: 0.8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER GRUP (Lebih Rapi) ---
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: InputUserScreen.accentHeaderColor),
                  const SizedBox(width: 6),
                  Text(
                    "DATA KE-${activeIndex + 1} DARI $totalRepeatCount",
                    style: const TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w800, 
                      color: InputUserScreen.accentHeaderColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(thickness: 1, color: InputUserScreen.accentHeaderColor.withValues(alpha: 0.2))),
                ],
              ),
              const SizedBox(height: 16),

              ...questionsInGroup.asMap().entries.map((entry) {
                final int i = entry.key;
                final FormQuestion q = entry.value;

                return Obx(() {
                  // MENGGUNAKAN UNIFIED VISIBILITY PER INDEKS
                  if (!controller.isVisible(q.id, index: activeIndex)) {
                    return const SizedBox.shrink();
                  }

                  // Label bersih tanpa kode teknis
                  String itemTitle = q.questionText;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      screenInstance._buildQuestionLabel(q, itemTitleOverride: itemTitle, isGroupedItem: true),
                      const SizedBox(height: 10),
                      screenInstance._buildQuestionInput(context, q,
                          repeatIndex: activeIndex,
                          keyPrefix: "${q.id}_${groupTag}_$activeIndex"),
                      if (i < questionsInGroup.length - 1)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 14.0),
                           child: Divider(height: 1, thickness: 0.5, color: Colors.blue.shade200.withValues(alpha: 0.7)),
                         ),
                    ],
                  );
                });
              }),
              const SizedBox(height: 20),
              // --- NAVIGASI BAWAH (Icon Based) ---
              Row(
                children: <Widget>[
                  if (activeIndex > 0)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => controller.goToPreviousRepeatableItem(groupTag),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                    child: Text(
                      "${activeIndex + 1} / $totalRepeatCount",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (activeIndex < totalRepeatCount - 1)
                    IconButton.filled(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: () => controller.goToNextRepeatableItem(groupTag),
                      style: IconButton.styleFrom(backgroundColor: InputUserScreen.accentHeaderColor),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
// --- AKHIR TAMBAHAN ---

/// [InputUserScreen] adalah halaman antarmuka utama bagi Petugas untuk mengisi formulir pendataan.
/// 
/// Halaman ini mendukung fitur-fitur kompleks:
/// 1. **Rendering Dinamis**: Membangun UI secara reaktif berdasarkan struktur formulir dari Admin.
/// 2. **Hybrid Layout**: Mendukung pertanyaan mandiri dan grup pertanyaan berulang (Repeatable Groups).
/// 3. **Input Beragam**: Menangani teks, angka, tanggal, dropdown, grid numerik, unggah foto, dan lokasi GPS.
/// 4. **Auto-Validation**: Memberikan feedback validasi langsung saat pengguna berinteraksi.
/// 5. **Lazy Loading**: Mengoptimalkan performa rendering untuk formulir dengan ratusan pertanyaan.
class InputUserScreen extends GetView<InputUserController> {
  const InputUserScreen({super.key});

  /// Skema warna standar untuk halaman pengisian form user.
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color cardBackgroundColor = Colors.white;
  static Color get titleTextColor => Colors.grey.shade800;
  static Color get subtitleTextColor => Colors.grey.shade600;
  static Color get mandatoryAsteriskColor => Colors.red.shade700;
  static const String _kOtherOptionValue = '__other_option_value__';

  /// Mengonversi angka menjadi format Romawi untuk penomoran seksi.
  String _toRoman(int number) {
    if (number < 1 || number > 3999) return number.toString();
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

  /// Menghasilkan dekorasi input teks yang seragam dan modern.
  InputDecoration _modernInputDecoration(
      BuildContext context, {
        String? hintText,
        String? labelText,
        Widget? suffixIcon,
        bool isDense = false,
      }) {
    return InputDecoration(
      hintText: hintText ?? "Masukkan jawaban...",
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      floatingLabelStyle:
      const TextStyle(color: accentHeaderColor, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accentHeaderColor, width: 1.8),
          borderRadius: BorderRadius.circular(10.0)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
          borderRadius: BorderRadius.circular(10.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.8),
          borderRadius: BorderRadius.circular(10.0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: cardBackgroundColor,
      suffixIcon: suffixIcon,
      errorMaxLines: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
      canPop: !controller.hasUnsavedChanges.value && !controller.isLoading.value,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final bool canLeave = await controller.handleBackPressed();

        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: pageBackgroundColor,
        appBar: AppBar(
          elevation: 3.0,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Batal / Kembali',
            onPressed: () {
              // Gunakan maybePop agar memicu logika PopScope secara konsisten
              Navigator.of(context).maybePop();
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentHeaderColor,
                  primaryHeaderColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.3, 0.9],
              ),
            ),
          ),
          title: Obx(() => Text(
            controller.loadedForm.value?.title ?? 'Mengisi Form',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          )),
          actions: [
            Obx(() {
              if (controller.isLoading.value &&
                  controller.loadedForm.value == null) {
                return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5)));
              }

              if (controller.isLockedMode.value) return const SizedBox.shrink();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOMBOL 1: SIMPAN DRAFT (Selalu Tersedia)
                  IconButton(
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    tooltip: 'Simpan sebagai Draft',
                    onPressed: controller.isLoading.value ? null : () => controller.submitForm(status: "draft"),
                  ),
                  
                  // TOMBOL 2: KIRIM / SUBMIT (Pemicu Validasi)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 0.5)
                        ),
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                        // Langsung panggil submitForm dengan status "submitted"
                        // Jika tidak lengkap, controller akan otomatis menampilkan dialog daftar error yang baru kita buat
                        controller.submitForm(status: "submitted");
                      },
                      child: const Text(
                        "KIRIM",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value &&
              controller.loadedForm.value == null) {
            return const Center(
                child: CircularProgressIndicator(color: accentHeaderColor));
          }
          if (controller.errorMessage.value.isNotEmpty &&
              controller.loadedForm.value == null) {
            final currentErrorMessage = controller.errorMessage.value;
            bool isFatalArgumentError = currentErrorMessage
                .contains("Argumen ID Form tidak ditemukan") ||
                currentErrorMessage.contains("Tipe argumen ID Form tidak valid") ||
                currentErrorMessage.contains("ID Form yang diterima kosong") ||
                currentErrorMessage
                    .contains("ID Form kosong atau tidak valid");

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade400, size: 50),
                    const SizedBox(height: 10),
                    Text(currentErrorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (!isFatalArgumentError)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Coba Lagi Memuat Form"),
                        onPressed: () => controller.fetchFormAndPotentialSubmissionData(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: accentHeaderColor,
                            foregroundColor: Colors.white),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text("Kembali"),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }
          if (controller.loadedForm.value == null) {
            return const Center(
                child: Text("Form tidak tersedia atau gagal dimuat."));
          }

          final form = controller.loadedForm.value;
          if (form == null) return const SizedBox.shrink();

          return Form(
            key: controller.formKey,
            child: Stack(
              children: [
                Obx(() {
                  final items = controller.flattenedItems;
                  final displayCount = controller.visibleItemCount.value.clamp(0, items.length);
                  
                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 500) {
                        controller.loadMoreItems();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 70.0),
                      itemCount: displayCount + (displayCount < items.length ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayCount) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        
                        final item = items[index];
                        // Request: Ensure item.section or item.question is not null when accessing
                        switch (item.type) {
                          case FormItemType.header:
                            return _buildFlattenedHeader(context, form);
                          case FormItemType.sectionHeader:
                            if (item.section == null) return const SizedBox.shrink();
                            return _buildFlattenedSectionHeader(item.section!);
                          case FormItemType.question:
                            if (item.question == null) return const SizedBox.shrink();
                            return _buildFlattenedQuestion(context, item.question!);
                          case FormItemType.groupInstance:
                            if (item.section == null || item.groupTag == null) return const SizedBox.shrink();
                            return _buildFlattenedGroup(context, item.section!, item.groupTag!);
                          case FormItemType.divider:
                            return _buildFlattenedDivider(item.id);
                          case FormItemType.sectionFooter:
                            return _buildFlattenedSectionFooter(item.id);
                        }
                      },
                    ),
                  );
                }),
                Obx(() {
                  if (controller.isLoading.value &&
                      controller.loadedForm.value != null) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.6), // Lebih gelap agar fokus
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: accentHeaderColor, strokeWidth: 3),
                                const SizedBox(height: 24),
                                Text(
                                  controller.loadingMessage.value.isEmpty 
                                    ? "Sedang memproses..." 
                                    : controller.loadingMessage.value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Mohon jangan menutup aplikasi agar data tersimpan dengan benar.",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          );
        }),
      ),
    ));
  }

  /// Membangun bagian header formulir yang mencakup judul, deskripsi, 
  /// info periode, lokasi GPS, dan panduan pengisian.
  Widget _buildFlattenedHeader(BuildContext context, FormItem form) {
    return Column(
      children: [
        Obx(() {
          if (controller.loadedSubmission.value?.isAutoGenerated == true && !controller.isLockedMode.value) {
            return Container(
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Data bulan ini telah disalin. Silakan cek dan perbarui jika ada perubahan.",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }
          if (controller.isLockedMode.value) {
            return Container(
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Data periode ini telah dikunci. Anda hanya dapat melihat data dalam mode baca-saja.",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Card(
          key: const ValueKey('form_header'),
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4, top: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          color: cardBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      color: accentHeaderColor.withValues(alpha: 0.9),
                      size: 38.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.title,
                            style: Get.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accentHeaderColor,
                              fontSize: 21,
                            ),
                          ),
                          if (form.description.isNotEmpty) ...[
                            const SizedBox(height: 6.0),
                            Text(
                              form.description,
                              style: Get.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                                height: 1.45,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // --- PILIH DESA (ADMIN ONLY) ---
                Obx(() {
                  final String role = controller.userRole.value;
                  final bool isAdmin = role == 'global_admin' ||
                      role == 'admin' ||
                      role == 'admin_desa' ||
                      role == 'admindesa';

                  if (!isAdmin) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('village_picker_${controller.selectedVillageId.value}'),
                      initialValue: controller.selectedVillageId.value.isEmpty ? null : controller.selectedVillageId.value,
                      decoration: _modernInputDecoration(context, labelText: "Pilih Desa Target"),
                      items: controller.allVillages.map((v) => DropdownMenuItem(
                        value: v.villageId,
                        child: Text(v.villageName),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedVillageId.value = val;
                          controller.markFormAsChanged();
                        }
                      },
                      validator: (val) {
                        if (isAdmin && (val == null || val.isEmpty)) {
                          return "Harap pilih desa target";
                        }
                        return null;
                      },
                    ),
                  );
                }),
                // --- INFO PERIODE DAN LOKASI (JIKA ADA) ---
                Obx(() {
                  final submission = controller.loadedSubmission.value;
                  if (submission == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(Icons.calendar_month, "Periode", submission.period ?? "N/A"),
                        if (submission.latitude != null) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.location_on, "Lokasi", "${submission.latitude}, ${submission.longitude}"),
                          if (submission.locationAddress != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 32, top: 4),
                              child: Text(submission.locationAddress!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              final url = "https://www.google.com/maps/search/?api=1&query=${submission.latitude},${submission.longitude}";
                              if (Get.context != null && Overlay.maybeOf(Get.context!) != null) {
                                Get.snackbar("Link Google Maps", url,
                                  snackPosition: SnackPosition.BOTTOM,
                                  mainButton: TextButton(
                                    onPressed: () {
                                      // Implement copy logic if needed
                                    },
                                    child: const Text("COPY", style: TextStyle(color: Colors.blue)),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.map, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Buka di Google Maps", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  decoration: BoxDecoration(
                      color: primaryHeaderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: primaryHeaderColor.withValues(alpha: 0.3), width: 0.8)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, color: accentHeaderColor.withValues(alpha: 0.85), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.orange.shade900.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: "Petunjuk: Isi semua pertanyaan dengan data yang benar. Pertanyaan dengan tanda "),
                              TextSpan(text: '*', style: TextStyle(color: mandatoryAsteriskColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              const TextSpan(text: " wajib diisi."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun kartu header untuk setiap seksi (Section) dalam formulir.
  Widget _buildFlattenedSectionHeader(FormSection section) {
    final sections = controller.loadedForm.value?.sections ?? [];
    final sectionIndex = sections.indexOf(section);
    String displaySectionTitle = section.title.trim().isEmpty
        ? 'Bagian ${_toRoman(sectionIndex + 1)}'
        : '${_toRoman(sectionIndex + 1)}: ${section.title.trim()}';

    return Obx(() {
      final bool isExpanded =
          controller.expandedSectionId.value == section.id ||
              sections.length == 1;
      final bool hasAnswers = controller.isEditMode &&
          controller.sectionHasAnswers(section.id);

      return Card(
        key: ValueKey('section_header_${section.id}'),
        elevation: 1.8,
        margin: EdgeInsets.only(
            bottom: isExpanded ? 0 : 16,
            left: 4,
            right: 4,
            top: 4),
        shape: RoundedRectangleBorder(
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displaySectionTitle,
                      style: Get.textTheme.titleLarge
                          ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleTextColor,
                          fontSize: 18),
                    ),
                  ),
                  if (hasAnswers && !isExpanded)
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 8.0),
                      child: Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green.shade600,
                          size: 20),
                    ),
                  if (sections.length > 1)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: accentHeaderColor,
                      ),
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => controller.toggleSectionExpansion(section.id),
                    ),
                ],
              ),
              if (section.description != null &&
                  section.description!.isNotEmpty &&
                  !isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  section.description!,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: subtitleTextColor,
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isExpanded && section.description != null && section.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(section.description!,
                    style: Get.textTheme.bodySmall
                        ?.copyWith(
                        color: subtitleTextColor,
                        fontSize: 13,
                        height: 1.4)),
              ],
              if (isExpanded)
                Divider(
                    height: 24,
                    thickness: 0.7,
                    color: Colors.grey.shade300),
            ],
          ),
        ),
      );
    });
  }

  /// Membangun satu unit pertanyaan global (mandiri) yang didukung oleh [Obx] untuk visibilitas dinamis.
  Widget _buildFlattenedQuestion(BuildContext context, FormQuestion question) {
    return Obx(() {
      if (!controller.isVisible(question.id)) return const SizedBox.shrink();
      
      return Container(
        key: ValueKey('question_${question.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.black12, width: 0.5),
              right: BorderSide(color: Colors.black12, width: 0.5),
            )
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionLabel(question),
            const SizedBox(height: 10),
            _buildQuestionInput(context, question, keyPrefix: question.id),
          ],
        ),
      );
    });
  }

  Widget _buildFlattenedGroup(BuildContext context, FormSection section, String groupTag) {
    List<FormQuestion> questionsInThisGroup = section.questions
        .where((q) => q.belongsToGroupTag == groupTag)
        .toList();

    return Container(
      key: ValueKey('group_${groupTag}_${section.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.black12, width: 0.5),
            right: BorderSide(color: Colors.black12, width: 0.5),
          )
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RepeatableGroupInstanceWidget(
        key: ValueKey("group_instance_${groupTag}_${section.id}"),
        groupTag: groupTag,
        questionsInGroup: questionsInThisGroup,
        controller: controller,
        screenInstance: this,
      ),
    );
  }

  Widget _buildFlattenedDivider(String id) {
    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.black12, width: 0.5),
            right: BorderSide(color: Colors.black12, width: 0.5),
          )
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 20, thickness: 0.5, color: Colors.grey.shade200),
    );
  }

  Widget _buildFlattenedSectionFooter(String id) {
    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      height: 10,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 1),
              blurRadius: 1,
            )
          ]
      ),
    );
  }

  /// Membangun label pertanyaan yang mencakup teks, tanda bintang (wajib), dan deskripsi bantuan.
  Widget _buildQuestionLabel(FormQuestion question,
      {String? itemTitleOverride, bool isGroupedItem = false}) {
    final String labelText = itemTitleOverride ?? question.questionText;
    final String? questionDescription = question.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Get.textTheme.bodyLarge?.copyWith(
                      fontSize: isGroupedItem ? 14.5 : 15.5,
                      fontWeight: FontWeight.w500,
                      color: titleTextColor,
                      height: 1.4),
                  children: [
                    TextSpan(text: labelText),
                    if (question.isRequired)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: mandatoryAsteriskColor,
                            fontSize: isGroupedItem ? 15 : 16,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            if (!isGroupedItem) ...[
              const SizedBox(width: 8),
              // Kode Pertanyaan Dihapus dari Tampilan
            ]
          ],
        ),
        if (questionDescription != null && questionDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              questionDescription,
              style: TextStyle(
                fontSize: isGroupedItem ? 12.5 : 13.5,
                color: subtitleTextColor.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper method untuk mendapatkan teks display operator perbandingan
  String _getComparisonOperatorDisplayText(String? operatorShortString) {
    if (operatorShortString == null) return "";
    switch (operatorShortString) {
      case 'lessThan': return 'kurang dari';
      case 'lessThanOrEqual': return 'kurang dari atau sama dengan';
      case 'equal': return 'sama dengan';
      case 'notEqual': return 'tidak sama dengan';
      case 'greaterThan': return 'lebih dari';
      case 'greaterThanOrEqual': return 'lebih dari atau sama dengan';
      default: return operatorShortString; // fallback
    }
  }


  /// Fungsi utama untuk membangun komponen input berdasarkan tipe pertanyaan ([QuestionType]).
  /// 
  /// Mencakup logika validasi internal yang sangat detail untuk setiap tipe input, 
  /// perbandingan antar pertanyaan, serta pola validasi khusus (NIK, Email, dsb).
  Widget _buildQuestionInput(BuildContext context, FormQuestion question,
      {int? repeatIndex, required String keyPrefix}) {
    return Obx(() {
      dynamic initialValue;
      Function(dynamic) onChangedCallback;

      String? initialOtherText;
      if (repeatIndex != null) {
        initialOtherText = controller.repeatableGroupOtherAnswers[question.id]?[repeatIndex];
      } else {
        initialOtherText = controller.userOtherAnswers[question.id];
      }

      void onOtherTextChangedCallback(String text) {
        if (repeatIndex != null) {
          if (!controller.repeatableGroupOtherAnswers.containsKey(question.id)) {
            controller.repeatableGroupOtherAnswers[question.id] = RxMap<int, String>();
          }
          if (!controller.repeatableGroupOtherAnswers[question.id]!.containsKey(repeatIndex)) {
            controller.repeatableGroupOtherAnswers[question.id]![repeatIndex] = '';
          }
          controller.repeatableGroupOtherAnswers[question.id]![repeatIndex] = text;
        } else {
          controller.userOtherAnswers[question.id] = text;
        }
      }

      String fieldKeyId = "${keyPrefix}_${question.type.toShortString()}";

      if (repeatIndex != null) {
        if (!controller.repeatableGroupAnswers.containsKey(question.id) || 
            !controller.repeatableGroupAnswers[question.id]!.containsKey(repeatIndex)) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        initialValue = controller.repeatableGroupAnswers[question.id]![repeatIndex];
        onChangedCallback = (value) => controller.updateRepeatableGroupAnswer(question.id, repeatIndex, value);
      } else {
        if (!controller.userAnswers.containsKey(question.id)) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        
        if (question.isComputedSummary) {
          initialValue = controller.getSummaryValue(question.summaryType, question.summaryGroupKey).toString();
        } else {
          initialValue = controller.userAnswers[question.id];
        }
        onChangedCallback = (value) => controller.updateUserAnswer(question.id, value);
      }

      // Ganti keseluruhan 'validatorFunction' yang ada di dalam '_buildQuestionInput' dengan ini:
      String? validatorFunction(dynamic val) {
        final FormQuestion currentQuestionState =
            controller.findQuestionById(question.id) ?? question;
        final ValidationRule rule = currentQuestionState.validation;
        final String questionLabel =
        (itemTitleOverrideForValidation(currentQuestionState, repeatIndex) ??
            currentQuestionState.questionText)
            .isNotEmpty
            ? (itemTitleOverrideForValidation(currentQuestionState, repeatIndex) ??
            currentQuestionState.questionText)
            : "Isian ini";

        // --- LOGIKA PENENTUAN JAWABAN KOSONG ---
        String effectiveValueString = "";
        bool isEmptyAnswer = true;

        if (val is String) {
          effectiveValueString = val.trim();
          isEmptyAnswer = effectiveValueString.isEmpty;
        } else if (val is List) {
          isEmptyAnswer = val.isEmpty;
        } else if (val == null) {
          isEmptyAnswer = true;
        } else if (val is Map && question.type == QuestionType.gridNumeric) {
          if (val.isEmpty) {
            isEmptyAnswer = true;
          } else {
            // Grid dianggap kosong hanya jika SEMUA selnya kosong
            final gridData = controller.getGridMapForValidation(val);
            isEmptyAnswer = gridData.values.every((colMap) => colMap.values.every(
                    (subColMap) => subColMap.values
                    .every((cellVal) => cellVal == null || cellVal.toString().trim().isEmpty)));
          }
        } else if (val is Map && question.type == QuestionType.imageUpload) {
          final String imageUrl = val['imageUrl']?.toString().trim() ?? '';
          final String localPath = val['localPath']?.toString().trim() ?? '';
          isEmptyAnswer = imageUrl.isEmpty && localPath.isEmpty;
        } else if (val is Map && question.type == QuestionType.location) {
          isEmptyAnswer = val['latitude'] == null || val['longitude'] == null;
        } else if (val is Map) {
          isEmptyAnswer = val.isEmpty;
        }

        // --- VALIDASI WAJIB ISI (REQUIRED) ---
        if (currentQuestionState.isRequired && isEmptyAnswer) {
          bool isOtherSelected = (currentQuestionState.type ==
              QuestionType.multipleChoice &&
              val == _kOtherOptionValue) ||
              (currentQuestionState.type == QuestionType.checkboxes &&
                  (val as List?)?.contains(_kOtherOptionValue) == true);

          if (isOtherSelected) {
            String? otherTextValue;
            if (repeatIndex != null) {
              otherTextValue =
              controller.repeatableGroupOtherAnswers[question.id]?[repeatIndex];
            } else {
              otherTextValue = controller.userOtherAnswers[question.id];
            }
            if (otherTextValue == null || otherTextValue.trim().isEmpty) {
              return 'Isian "Lainnya" untuk $questionLabel wajib diisi.';
            }
          } else {
            return '$questionLabel wajib diisi.';
          }
        }

        // Jika tidak wajib dan jawabannya kosong, tidak perlu validasi lebih lanjut
        if (isEmptyAnswer && !currentQuestionState.isRequired) return null;

        // --- VALIDASI BERDASARKAN ATURAN (ValidationRule) ---
        // A. VALIDASI KHUSUS UNTUK GRID NUMERIK
        if (currentQuestionState.type == QuestionType.gridNumeric && val is Map) {
          final gridData = controller.getGridMapForValidation(val);
          final List<String> rowLabels = currentQuestionState.gridRowLabels.isNotEmpty
              ? currentQuestionState.gridRowLabels
              : [""]; // Handle grid tanpa label baris
          final List<String> colLabels = currentQuestionState.gridColumnLabels;
          final List<String> subColLabels = currentQuestionState.gridSubColumnLabels;

          for (final row in rowLabels) {
            for (final col in colLabels) {
              for (final subCol in subColLabels) {
                final cellValue = gridData[row]?[col]?[subCol];

                // Aturan 1: Cek jika semua sel wajib diisi
                if (rule.predefinedRule == 'gridAllCellsRequired') {
                  if (cellValue == null || cellValue.toString().trim().isEmpty) {
                    return 'Semua sel pada grid "$questionLabel" wajib diisi.';
                  }
                }

                // Aturan 2: Cek min/max untuk setiap sel yang TIDAK kosong
                if (cellValue != null) {
                  if (rule.minValue != null && cellValue < rule.minValue!) {
                    return 'Nilai di grid ($col) minimal ${rule.minValue}.';
                  }
                  if (rule.maxValue != null && cellValue > rule.maxValue!) {
                    return 'Nilai di grid ($col) maksimal ${rule.maxValue}.';
                  }
                }
              }
            }
          }
        }

        // B. VALIDASI UNTUK TIPE TEKS
        if (val is String && val.isNotEmpty) {
          if (rule.minLength != null &&
              effectiveValueString.length < rule.minLength!) {
            return '$questionLabel minimal ${rule.minLength} karakter.';
          }
          if (rule.maxLength != null &&
              effectiveValueString.length > rule.maxLength!) {
            return '$questionLabel maksimal ${rule.maxLength} karakter.';
          }
          if (rule.regex != null &&
              rule.regex!.isNotEmpty &&
              !RegExp(rule.regex!).hasMatch(effectiveValueString)) {
            return 'Format $questionLabel tidak sesuai.';
          }
          if (rule.predefinedRule == 'nik' &&
              !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
            return 'NIK harus tepat 16 digit angka. (Sekarang: ${effectiveValueString.length} digit)';
          }
          if (rule.predefinedRule == 'noKK' &&
              !RegExp(r'^\d{16}$').hasMatch(effectiveValueString)) {
            return 'Nomor KK harus tepat 16 digit angka. (Sekarang: ${effectiveValueString.length} digit)';
          }
          if (rule.predefinedRule == 'email' &&
              !GetUtils.isEmail(effectiveValueString)) {
            return 'Format email untuk $questionLabel tidak valid.';
          }
          if (rule.predefinedRule == 'numbersOnly' &&
              !GetUtils.isNumericOnly(
                  effectiveValueString.replaceAll(',', '').replaceAll('.', ''))) {
            return '$questionLabel hanya boleh berisi angka.';
          }
        }

        // C. VALIDASI UNTUK TIPE ANGKA (non-grid)
        if (currentQuestionState.type == QuestionType.number &&
            val != null &&
            val.toString().isNotEmpty) {
          num? numAnswer = num.tryParse(val.toString().replaceAll(',', '.'));

          if (numAnswer == null && val.toString().isNotEmpty) {
            return '$questionLabel harus berupa angka.';
          }

          if (numAnswer != null) {
            if (rule.minValue != null && numAnswer < rule.minValue!) {
              return '$questionLabel minimal ${rule.minValue}.';
            }
            if (rule.maxValue != null && numAnswer > rule.maxValue!) {
              return '$questionLabel maksimal ${rule.maxValue}.';
            }

            if (rule.comparisonOperator != null &&
                rule.comparisonOperator !=
                    ComparisonOperatorType.none.toShortString() &&
                rule.compareToQuestionId != null &&
                rule.compareToQuestionId!.isNotEmpty) {
              final String compareToQuestionId = rule.compareToQuestionId!;
              final FormQuestion? targetQuestion =
              controller.findQuestionById(compareToQuestionId);

              if (targetQuestion != null) {
                dynamic targetAnswerDynamic;
                if (targetQuestion.belongsToGroupTag != null &&
                    targetQuestion.belongsToGroupTag ==
                        currentQuestionState.belongsToGroupTag &&
                    repeatIndex != null &&
                    controller.repeatableGroupAnswers
                        .containsKey(compareToQuestionId)) {
                  targetAnswerDynamic = controller
                      .repeatableGroupAnswers[compareToQuestionId]![repeatIndex];
                } else if (controller.userAnswers.containsKey(compareToQuestionId)) {
                  targetAnswerDynamic =
                  controller.userAnswers[compareToQuestionId];
                }

                if (targetAnswerDynamic != null &&
                    targetAnswerDynamic.toString().isNotEmpty) {
                  num? targetNumAnswer = num.tryParse(
                      targetAnswerDynamic.toString().replaceAll(',', '.'));

                  if (targetNumAnswer != null) {
                    String operatorText =
                    _getComparisonOperatorDisplayText(rule.comparisonOperator);
                    String targetQuestionLabel = targetQuestion.questionText;

                    bool comparisonResult = false;
                    switch (rule.comparisonOperator) {
                      case 'lessThan':
                        comparisonResult = numAnswer < targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                      case 'lessThanOrEqual':
                        comparisonResult = numAnswer <= targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                      case 'equal':
                        comparisonResult = numAnswer == targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                      case 'notEqual':
                        comparisonResult = numAnswer != targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                      case 'greaterThan':
                        comparisonResult = numAnswer > targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                      case 'greaterThanOrEqual':
                        comparisonResult = numAnswer >= targetNumAnswer;
                        if (!comparisonResult) {
                          return '$questionLabel harus $operatorText ${targetNumAnswer.toString()} (dari: $targetQuestionLabel).';
                        }
                        break;
                    }
                  }
                }
              }
            }
          }
        }

        return null; // Tidak ada error
      }

      switch (question.type) {
        case QuestionType.text:
          final bool isNikOrKk = question.validation.predefinedRule == 'nik' || question.validation.predefinedRule == 'noKK';
          final String currentVal = initialValue as String? ?? '';
          final bool isComplete = isNikOrKk && currentVal.length == 16;
          
          return TextFormField(
            key: ValueKey("${fieldKeyId}_${(question.isReadOnly || question.isComputedSummary) ? currentVal : ''}"),
            initialValue: currentVal,
            enabled: !controller.isLockedMode.value && !question.isReadOnly && !question.isComputedSummary,
            decoration: _modernInputDecoration(context, hintText: "Jawaban teks singkat").copyWith(
              counterText: isNikOrKk ? "${currentVal.length} / 16" : null,
              counterStyle: TextStyle(
                color: isComplete ? Colors.green.shade700 : Colors.grey,
                fontSize: 11,
                fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
              ),
              suffixIcon: isComplete 
                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22) 
                  : null,
              enabledBorder: isComplete 
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.green, width: 1.5))
                  : null,
              focusedBorder: isComplete
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.green, width: 2.0))
                  : null,
              helperText: isComplete ? "Format 16 digit sudah sesuai" : null,
              helperStyle: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            onChanged: (val) {
              onChangedCallback(val);
              if (isNikOrKk) {
                if (repeatIndex != null) {
                  controller.repeatableGroupAnswers.refresh();
                } else {
                  controller.userAnswers.refresh();
                }
              }
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: isNikOrKk
                ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ]
                : (question.validation.predefinedRule == 'numbersOnly')
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            keyboardType: (isNikOrKk || question.validation.predefinedRule == 'numbersOnly')
                ? TextInputType.number
                : TextInputType.text,
          );
        case QuestionType.paragraph:
          return TextFormField(
            key: ValueKey(fieldKeyId),
            initialValue: initialValue as String? ?? '',
            enabled: !controller.isLockedMode.value && !question.isReadOnly, // Respect isReadOnly
            decoration:
            _modernInputDecoration(context, hintText: "Jawaban teks panjang"),
            maxLines: 3,
            minLines: 2,
            onChanged: onChangedCallback,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.number:
          final bool isNikOrKkNum = question.validation.predefinedRule == 'nik' || question.validation.predefinedRule == 'noKK';
          final String currentNumVal = initialValue != null ? initialValue.toString().replaceAll('.', ',') : '';
          final bool isCompleteNum = isNikOrKkNum && currentNumVal.length == 16;
          
          // Tentukan apakah pertanyaan ini butuh tombol Plus/Minus (Stepper)
          // HANYA jika pola validasi khusus 'numberSteppersOnly' dipilih
          final bool showStepper = question.validation.predefinedRule == 'numberSteppersOnly';

          // Gunakan controller untuk field yang reaktif agar nilai update otomatis muncul
          final bool isReactiveNum = question.isReadOnly || question.isComputedSummary || question.autoClassifyAgeGroup || showStepper;

          return TextFormField(
            key: ValueKey("${fieldKeyId}_${isReactiveNum ? currentNumVal : ''}"),
            initialValue: isReactiveNum ? null : currentNumVal,
            controller: isReactiveNum ? TextEditingController(text: currentNumVal) : null,
            // Jika ada stepper, kita bisa buat readOnly agar user hanya pakai tombol (lebih aman)
            readOnly: controller.isLockedMode.value || question.isReadOnly || question.isComputedSummary || showStepper,
            enabled: !controller.isLockedMode.value,
            decoration: _modernInputDecoration(context, hintText: isNikOrKkNum ? "Masukkan 16 digit angka" : "Masukkan angka").copyWith(
              counterText: isNikOrKkNum ? "${currentNumVal.length} / 16" : null,
              counterStyle: TextStyle(
                color: isCompleteNum ? Colors.green.shade700 : Colors.grey,
                fontSize: 11,
                fontWeight: isCompleteNum ? FontWeight.bold : FontWeight.normal,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleteNum)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                    ),
                  if (showStepper && !controller.isLockedMode.value && !question.isReadOnly && !question.isComputedSummary) ...[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 26),
                      onPressed: () {
                        double currentVal = double.tryParse(currentNumVal.replaceAll(',', '.')) ?? 0;
                        if (currentVal > 0) {
                          onChangedCallback((currentVal - 1).toInt().toString());
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 26),
                      onPressed: () {
                        double currentVal = double.tryParse(currentNumVal.replaceAll(',', '.')) ?? 0;
                        onChangedCallback((currentVal + 1).toInt().toString());
                      },
                    ),
                    const SizedBox(width: 8),
                  ]
                ],
              ),
              enabledBorder: isCompleteNum 
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.green, width: 1.5))
                  : null,
              focusedBorder: isCompleteNum
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.green, width: 2.0))
                  : null,
              helperText: isCompleteNum ? "Format 16 digit sudah sesuai" : null,
              helperStyle: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            keyboardType: isNikOrKkNum 
                ? TextInputType.number 
                : const TextInputType.numberWithOptions(signed: false, decimal: true),
            inputFormatters: [
              isNikOrKkNum 
                  ? FilteringTextInputFormatter.digitsOnly 
                  : FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
              if (isNikOrKkNum) LengthLimitingTextInputFormatter(16),
            ],
            onChanged: (value) {
              onChangedCallback(value.replaceAll(',', '.'));
              if (isNikOrKkNum) {
                if (repeatIndex != null) {
                  controller.repeatableGroupAnswers.refresh();
                } else {
                  controller.userAnswers.refresh();
                }
              }
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.date:
          String displayDate = '';
          if (initialValue is DateTime) {
            displayDate = DateFormat('dd/MM/yyyy').format(initialValue);
          } else if (initialValue is String) {
            try {
              if (initialValue.isNotEmpty) {
                DateTime? parsedFromDisplay = DateFormat('dd/MM/yyyy').tryParse(initialValue);
                if (parsedFromDisplay != null) {
                  displayDate = initialValue;
                } else {
                  DateTime? parsedDate = DateTime.tryParse(initialValue);
                  if (parsedDate != null) {
                    displayDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                  } else {
                    displayDate = initialValue;
                  }
                }
              }
            } catch (e) {
              displayDate = initialValue;
            }
          }

          return TextFormField(
            key: ValueKey(fieldKeyId),
            readOnly: true,
            enabled: !controller.isLockedMode.value && !question.isReadOnly, // Respect isReadOnly
            controller: TextEditingController(text: displayDate),
            decoration: _modernInputDecoration(context,
                hintText: "Pilih tanggal",
                suffixIcon: const Icon(Icons.calendar_today_rounded,
                    color: accentHeaderColor)),
            onTap: () async {
              if (controller.isLockedMode.value || question.isReadOnly) return;
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime initialDatePickerDate = DateTime.now();
              if (initialValue is String && initialValue.isNotEmpty) {
                try {
                  initialDatePickerDate = DateFormat('dd/MM/yyyy').parseStrict(initialValue);
                } catch (e) {
                  try {
                    DateTime? parsedInternal = DateTime.tryParse(initialValue);
                    if (parsedInternal != null) initialDatePickerDate = parsedInternal;
                  } catch (e2) { /* biarkan default jika semua parse gagal */ }
                }
              } else if (initialValue is DateTime) {
                initialDatePickerDate = initialValue;
              }

              DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDatePickerDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: accentHeaderColor,
                              onPrimary: Colors.white,
                              onSurface: Colors.black87),
                          textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                  foregroundColor: accentHeaderColor))),
                      child: child!,
                    );
                  });
              if (pickedDate != null) {
                onChangedCallback(DateFormat('dd/MM/yyyy').format(pickedDate));
              }
            },
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        case QuestionType.multipleChoice:
          String? currentGroupValue = initialValue as String?;
          return FormField<String>(
            key: ValueKey("${fieldKeyId}_mc_formfield"),
            initialValue: currentGroupValue,
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<String> field) {
              return IgnorePointer(
                ignoring: controller.isLockedMode.value || question.isReadOnly,
                child: RadioGroup<String>(
                  groupValue: field.value,
                  onChanged: (String? value) {
                    if (value != null) {
                      onChangedCallback(value);
                      field.didChange(value);
                      if (value != _kOtherOptionValue) {
                        onOtherTextChangedCallback('');
                      }
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...question.options.map((option) {
                        return RadioListTile<String>(
                          key: ValueKey("${fieldKeyId}_${option.value.hashCode}_radio"),
                          title: Text(option.value, style: const TextStyle(fontSize: 15.0)),
                          subtitle: (option.description != null && option.description!.isNotEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                                  child: Text(
                                    option.description!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                                  ),
                                )
                              : null,
                          value: option.value,
                          activeColor: accentHeaderColor,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          isThreeLine: (option.description != null && option.description!.isNotEmpty),
                        );
                      }),
                      if (question.hasOtherOption)
                        RadioListTile<String>(
                          key: ValueKey("${fieldKeyId}_other_radio"),
                          title: const Text("Lainnya...", style: TextStyle(fontSize: 15.0)),
                          value: _kOtherOptionValue,
                          activeColor: accentHeaderColor,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (question.hasOtherOption && field.value == _kOtherOptionValue)
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                          child: TextFormField(
                            key: ValueKey("${fieldKeyId}_other_text_${repeatIndex ?? 'single'}"),
                            initialValue: initialOtherText ?? '',
                            enabled: !controller.isLockedMode.value,
                            decoration: _modernInputDecoration(context, hintText: "Sebutkan lainnya", isDense: true)
                                .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                            onChanged: (text) {
                              onOtherTextChangedCallback(text);
                              field.didChange(field.value);
                            },
                            validator: (text) {
                              if (field.value == _kOtherOptionValue && question.isRequired && (text == null || text.trim().isEmpty)) {
                                return 'Isian "Lainnya" tidak boleh kosong.';
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        case QuestionType.checkboxes:
          return FormField<List<String>>(
            key: ValueKey("${fieldKeyId}_checkbox_formfield"),
            initialValue: List<String>.from(initialValue as List<dynamic>? ?? []),
            validator: validatorFunction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<List<String>> field) {
              bool isOtherCurrentlySelected = field.value?.contains(_kOtherOptionValue) ?? false;
              return IgnorePointer(
                ignoring: controller.isLockedMode.value || question.isReadOnly,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...question.options.map((option) {
                      return CheckboxListTile(
                        key: ValueKey("${fieldKeyId}_${option.value.hashCode}_checkbox"),
                        title: Text(option.value, style: const TextStyle(fontSize: 15.0)),
                        subtitle: (option.description != null && option.description!.isNotEmpty)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                                child: Text(
                                  option.description!,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                                ),
                              )
                            : null,
                        value: field.value?.contains(option.value) ?? false,
                        onChanged: (bool? selected) {
                          final latestSelectedValues = List<String>.from(field.value ?? []);
                          if (selected == true) {
                            if (!latestSelectedValues.contains(option.value)) latestSelectedValues.add(option.value);
                          } else {
                            latestSelectedValues.remove(option.value);
                          }
                          onChangedCallback(latestSelectedValues);
                          field.didChange(latestSelectedValues);
                        },
                        activeColor: accentHeaderColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        isThreeLine: (option.description != null && option.description!.isNotEmpty),
                      );
                    }),
                    if (question.hasOtherOption)
                      CheckboxListTile(
                        key: ValueKey("${fieldKeyId}_other_checkbox"),
                        title: const Text("Lainnya...", style: TextStyle(fontSize: 15.0)),
                        value: isOtherCurrentlySelected,
                        onChanged: (bool? selected) {
                          final latestSelectedValues = List<String>.from(field.value ?? []);
                          if (selected == true) {
                            if (!latestSelectedValues.contains(_kOtherOptionValue)) {
                              latestSelectedValues.add(_kOtherOptionValue);
                            }
                          } else {
                            latestSelectedValues.remove(_kOtherOptionValue);
                            onOtherTextChangedCallback('');
                          }
                          onChangedCallback(latestSelectedValues);
                          field.didChange(latestSelectedValues);
                        },
                        activeColor: accentHeaderColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (question.hasOtherOption && isOtherCurrentlySelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 40.0, right: 0.0, bottom: 8.0),
                        child: TextFormField(
                          key: ValueKey("${fieldKeyId}_other_text_checkbox_${repeatIndex ?? 'single'}"),
                          initialValue: initialOtherText ?? '',
                          enabled: !controller.isLockedMode.value,
                          decoration: _modernInputDecoration(context, hintText: "Sebutkan lainnya", isDense: true)
                              .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          onChanged: (text) {
                            onOtherTextChangedCallback(text);
                            field.didChange(field.value);
                          },
                          validator: (text) {
                            if (isOtherCurrentlySelected && question.isRequired && (text == null || text.trim().isEmpty)) {
                              return 'Isian "Lainnya" tidak boleh kosong.';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          );

        case QuestionType.dropdown:
          List<Map<String, String?>> unifiedOptions = [];
          bool isDependent = question.dependentOptions != null && question.dependentOptions!.parentQuestionId.isNotEmpty;
          String? parentAnswer;

          if (isDependent) {
            final config = question.dependentOptions;
            if (config == null || config.parentQuestionId.isEmpty) {
              return const Text("Error: Konfigurasi dropdown dependen tidak valid.");
            }
            final parentQuestionId = config.parentQuestionId;
            if (repeatIndex != null && controller.repeatableGroupAnswers.containsKey(parentQuestionId)) {
              parentAnswer = controller.repeatableGroupAnswers[parentQuestionId]![repeatIndex] as String?;
            } else {
              parentAnswer = controller.userAnswers[parentQuestionId] as String?;
            }

            if (parentAnswer != null && parentAnswer.isNotEmpty) {
              final List<String> dependentOptions = question.dependentOptions!.optionMapping[parentAnswer] ?? [];
              unifiedOptions = dependentOptions.map((opt) => {'value': opt, 'description': null}).toList();
            }
          } else {
            unifiedOptions = question.options.map((opt) => {'value': opt.value, 'description': opt.description}).toList();
          }

          String? effectiveInitialValue = initialValue as String?;
          if (effectiveInitialValue != null && !unifiedOptions.any((opt) => opt['value'] == effectiveInitialValue)) {
            effectiveInitialValue = null;
          }

          if (isDependent && (parentAnswer == null || parentAnswer.isEmpty)) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pilih jawaban untuk pertanyaan induk terlebih dahulu.",
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }
          if (isDependent && parentAnswer != null && parentAnswer.isNotEmpty && unifiedOptions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Tidak ada opsi yang tersedia untuk pilihan '$parentAnswer'.",
                style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic, fontSize: 14),
              ),
            );
          }

          String optionsKeyPart = unifiedOptions.map((e) => e['value']).join(',');
          Key dropdownKey = ValueKey("${fieldKeyId}_${effectiveInitialValue ?? 'null'}_$optionsKeyPart");

          return IgnorePointer(
            ignoring: controller.isLockedMode.value || question.isReadOnly,
            child: DropdownButtonFormField<String>(
              key: dropdownKey,
              initialValue: effectiveInitialValue,
              decoration: _modernInputDecoration(context, labelText: "Pilih salah satu"),
              isExpanded: true,
              items: unifiedOptions.map((option) {
                final String value = option['value']!;
                final String? description = option['description'];
                return DropdownMenuItem<String>(
                  value: value,
                  child: Tooltip(
                    message: description ?? '',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: const TextStyle(fontSize: 15)),
                        if (description != null && description.isNotEmpty)
                          Text(
                            description,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (unifiedOptions.isEmpty && isDependent)
                  ? null
                  : (String? newValue) {
                if (newValue != null) {
                  onChangedCallback(newValue);
                }
              },
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          );
        case QuestionType.imageUpload:
          return _buildImageUploadAnswer(
            question: question,
            currentAnswer: initialValue,
            repeatIndex: repeatIndex,
          );
        case QuestionType.location:
          return _buildLocationAnswer(
            question: question,
            currentAnswer: initialValue,
            repeatIndex: repeatIndex,
          );
        case QuestionType.gridNumeric:
          Map<String, Map<String, Map<String, num?>>> effectiveGridAnswers = {};

          if (initialValue is Map && initialValue.isNotEmpty) {
            final Map<dynamic, dynamic> rawInitialDataMap = initialValue;
            if (question.gridRowLabels.isEmpty) {
              if (rawInitialDataMap.entries.isNotEmpty) {
                MapEntry<dynamic, dynamic> targetEntry = rawInitialDataMap.entries.first;
                if (rawInitialDataMap.containsKey("")) { // Prefer empty string key if exists
                  for (final MapEntry<dynamic, dynamic> entryInLoop in rawInitialDataMap.entries) {
                    if (entryInLoop.key == "") {
                      targetEntry = entryInLoop;
                      break;
                    }
                  }
                }
                final rowDataMap = targetEntry.value;
                if (rowDataMap is Map) {
                  try {
                    effectiveGridAnswers[""] = Map<String, Map<String, num?>>.fromEntries(
                        rowDataMap.entries.map((colEntry) {
                          var subColMapData = colEntry.value;
                          if (subColMapData is! Map) subColMapData = <String, dynamic>{}; // Ensure it's a map
                          return MapEntry(
                              colEntry.key.toString(),
                              Map<String, num?>.fromEntries(
                                  subColMapData.entries.map((subColEntry) {
                                    num? cellValueNum;
                                    if (subColEntry.value == null) {
                                      cellValueNum = null;
                                    } else if (subColEntry.value is num) {
                                      cellValueNum = subColEntry.value as num;
                                    } else {
                                      cellValueNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));
                                    }
                                    return MapEntry(subColEntry.key.toString(), cellValueNum);
                                  })
                              )
                          );
                        })
                    );
                  } catch (e) {
                    debugPrint("Error casting single-row grid data for $fieldKeyId (dalam _buildQuestionInput): $e. rowDataMap: $rowDataMap");
                    effectiveGridAnswers[""] = {}; // Fallback to empty
                  }
                }
              }
            } else { // Multi-row grid
              try {
                effectiveGridAnswers = Map<String, Map<String, Map<String, num?>>>.fromEntries(
                    rawInitialDataMap.entries
                        .where((rowEntry) => question.gridRowLabels.contains(rowEntry.key.toString())) // Only include defined rows
                        .map((rowEntry) {
                      var colMapData = rowEntry.value;
                      if (colMapData is! Map) {
                        colMapData = <String, dynamic>{};
                      } // Ensure it's a map
                      return MapEntry(
                          rowEntry.key.toString(),
                          Map<String, Map<String, num?>>.fromEntries(
                              colMapData.entries.map((colEntry) {
                                var subColMapData = colEntry.value;
                                if (subColMapData is! Map) {
                                  subColMapData = <String, dynamic>{};
                                } // Ensure it's a map
                                return MapEntry(
                                    colEntry.key.toString(),
                                    Map<String, num?>.fromEntries(
                                        subColMapData.entries.map((subColEntry) {
                                          num? valNum;
                                          if (subColEntry.value == null) {
                                            valNum = null;
                                          } else if (subColEntry.value is num) {
                                            valNum = subColEntry.value as num;
                                          } else {
                                            valNum = num.tryParse(subColEntry.value.toString().replaceAll(',', '.'));
                                          }
                                          return MapEntry(subColEntry.key.toString(), valNum);
                                        })
                                    )
                                );
                              })
                          )
                      );
                    })
                );
              } catch (e) {
                debugPrint("Error casting multi-row gridAnswers for $fieldKeyId: $e. InitialValue: $initialValue");
                // Fallback: initialize with defined rows and empty maps to prevent errors
                for (var rowLabel in question.gridRowLabels) {
                  effectiveGridAnswers[rowLabel] = {};
                }
              }
            }
          }


          if (question.gridColumnLabels.isEmpty || question.gridSubColumnLabels.isEmpty) {
            return Text("Grid Numerik: Konfigurasi label 'Kolom' atau 'Sub-Kolom' belum lengkap.", style: TextStyle(color: Colors.red.shade700));
          }

          List<String> superRowsToRender = question.gridRowLabels.isNotEmpty ? question.gridRowLabels : [""]; // "" for single unnamed super-row

          return FormField<Map<String, Map<String, Map<String, num?>>>>(
              key: ValueKey("${fieldKeyId}_grid_formfield_${superRowsToRender.join('_')}_${question.gridColumnLabels.join('_')}_${question.gridSubColumnLabels.join('_')}_modified"),
              initialValue: effectiveGridAnswers,
              validator: validatorFunction,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (FormFieldState<Map<String, Map<String, Map<String, num?>>>> field) {
                num? getSafeCellValue(String superRowLabel, String originalGridColLabel, String originalGridSubColLabel) {
                  // Ensure all keys exist before accessing
                  return field.value?[superRowLabel]?[originalGridColLabel]?[originalGridSubColLabel];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: superRowsToRender.map((uiSuperRowLabel) { // uiSuperRowLabel is the "" or actual label
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (uiSuperRowLabel.isNotEmpty && question.gridRowLabels.isNotEmpty) // Display super-row label if not empty
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0, left: 2.0, top: 8.0),
                                    child: Text(uiSuperRowLabel, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: titleTextColor)),
                                  ),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                                  defaultColumnWidth: const MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(85)), // Min width to prevent squishing
                                  children: [
                                    TableRow( // Header Row for SubColumns
                                      decoration: BoxDecoration(color: Colors.grey.shade100),
                                      children: [
                                        const TableCell(child: Padding(padding: EdgeInsets.all(6.0), child: Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))), // Empty top-left cell
                                        ...question.gridSubColumnLabels.map((originalGridSubColLabel) => TableCell(
                                          verticalAlignment: TableCellVerticalAlignment.middle,
                                          child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0), // Increased padding
                                              child: Text(originalGridSubColLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        )),
                                      ],
                                    ),
                                    // Data Rows (one for each originalGridColLabel)
                                    ...question.gridColumnLabels.map((originalGridColLabel) {
                                      return TableRow(
                                        children: [
                                          TableCell( // Row Header (originalGridColLabel)
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0), // Increased padding
                                                  child: Text(originalGridColLabel, style: const TextStyle(fontSize: 12)))),
                                          // Data Cells (TextFormFields)
                                          ...question.gridSubColumnLabels.map((originalGridSubColLabel) {
                                            // Safely get the cell value for display
                                            num? cellValue = getSafeCellValue(uiSuperRowLabel, originalGridColLabel, originalGridSubColLabel);
                                            String cellKeyIdGrid = "${fieldKeyId}_grid_${uiSuperRowLabel}_${originalGridColLabel}_$originalGridSubColLabel";

                                            return TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.all(2.0),
                                                child: StatefulBuilder(
                                                  builder: (context, setCellState) {
                                                    return TextFormField(
                                                      key: ValueKey(cellKeyIdGrid),
                                                      initialValue: cellValue?.toString().replaceAll('.', ',') ?? '',
                                                      textAlign: TextAlign.center,
                                                      enabled: !controller.isLockedMode.value && !question.isReadOnly, // Respect isReadOnly
                                                      style: const TextStyle(fontSize: 13),
                                                      decoration: InputDecoration(
                                                        border: InputBorder.none,
                                                        contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                                        isDense: true,
                                                        fillColor: Colors.white,
                                                        filled: true,
                                                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                                                        focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
                                                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade200, width: 1)),
                                                      ),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
                                                      onChanged: (value) {
                                                        final String normalizedValue = value.replaceAll(',', '.');
                                                        // Trigger rebuild untuk Sinkronisasi State
                                                        setCellState(() {});

                                                        controller.updateGridAnswer(
                                                            question.id,
                                                            repeatIndex,
                                                            uiSuperRowLabel,
                                                            originalGridColLabel,
                                                            originalGridSubColLabel,
                                                            normalizedValue);

                                                        dynamic currentGridAnswerState;
                                                        if (repeatIndex != null) {
                                                          currentGridAnswerState = controller.repeatableGroupAnswers[question.id]?[repeatIndex];
                                                        } else {
                                                          currentGridAnswerState = controller.userAnswers[question.id];
                                                        }

                                                        if (currentGridAnswerState is Map<String, Map<String, Map<String, num?>>>) {
                                                          field.didChange(Map<String, Map<String, Map<String, num?>>>.from(currentGridAnswerState));
                                                        } else if (currentGridAnswerState is Map) {
                                                          try {
                                                            Map<String, Map<String, Map<String, num?>>> convertedMap = controller.getGridMapForValidation(currentGridAnswerState);
                                                            field.didChange(convertedMap);
                                                          } catch (e) {
                                                            field.didChange({});
                                                          }
                                                        } else {
                                                          field.didChange({});
                                                        }
                                                      },
                                                      validator: (val) {
                                                        if (val != null && val.isNotEmpty && num.tryParse(val.replaceAll(',', '.')) == null) {
                                                          return 'X';
                                                        }
                                                        return null;
                                                      },
                                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                                    );
                                                  }
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (field.hasError && field.errorText != null && field.errorText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 0.0), // Display error below the table
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                );
              }
          );
      }
    });
  }


  /// Membangun komponen input khusus untuk unggah gambar dengan preview dan status upload.
  Widget _buildImageUploadAnswer({
    required FormQuestion question,
    required dynamic currentAnswer,
    int? repeatIndex,
  }) {
    return Obx(() {
      final File? localImageFile = controller.getSelectedImageFile(
        question.id,
        repeatIndex: repeatIndex,
      );

      final String? imageUrl = controller.getAnswerImageUrl(
        question.id,
        repeatIndex: repeatIndex,
      );

      // Ambil status isUploading dari map jawaban spesifik
      final Map<String, dynamic>? answerMap = controller.getImageAnswerMap(
        question.id,
        repeatIndex: repeatIndex,
      );
      final bool isCurrentlyUploading = answerMap?['isUploading'] ?? false;
      final bool hasUploadError = answerMap?['uploadError'] != null;

      final bool hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty;

      Widget imagePreviewWidget;

      if (localImageFile != null && localImageFile.existsSync()) {
        imagePreviewWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                localImageFile,
                key: ValueKey('local_file_${localImageFile.path}'),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              if (isCurrentlyUploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        );
      } else if (hasNetworkImage) {
        imagePreviewWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            key: ValueKey('network_url_$imageUrl'),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 180,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const CircularProgressIndicator(color: accentHeaderColor),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildEmptyImagePlaceholder(),
          ),
        );
      } else {
        imagePreviewWidget = _buildEmptyImagePlaceholder();
      }

      final bool hasImage = (localImageFile != null && localImageFile.existsSync()) || hasNetworkImage;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagePreviewWidget,
          const SizedBox(height: 8),
          
          // --- LABEL STATUS UPLOAD ---
          if (hasImage) ...[
            if (isCurrentlyUploading)
              Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                  const SizedBox(width: 8),
                  Text("🔄 Sedang mengunggah ke Cloud...", style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                ],
              )
            else if (hasUploadError)
              Text("⚠️ Gagal mengunggah: ${answerMap?['uploadError']}", style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))
            else if (hasNetworkImage)
              const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text("✅ Tersimpan di Cloud", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (isCurrentlyUploading || controller.isLockedMode.value || question.isReadOnly)
                      ? null
                      : () => controller.pickAnswerImageFromCamera(questionId: question.id, repeatIndex: repeatIndex),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (isCurrentlyUploading || controller.isLockedMode.value || question.isReadOnly)
                      ? null
                      : () => controller.pickAnswerImageFromGallery(questionId: question.id, repeatIndex: repeatIndex),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          if (hasImage && !controller.isLockedMode.value && !question.isReadOnly)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isCurrentlyUploading
                    ? null
                    : () => controller.removeAnswerImage(questionId: question.id, repeatIndex: repeatIndex),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      );
    });
  }

  /// Membangun komponen input khusus untuk pengambilan lokasi GPS dengan info akurasi.
  Widget _buildLocationAnswer({
    required FormQuestion question,
    required dynamic currentAnswer,
    int? repeatIndex,
  }) {
    return Obx(() {
      final dynamic answer;
      if (repeatIndex != null) {
        final groupMap = controller.repeatableGroupAnswers[question.id];
        answer = groupMap != null ? groupMap[repeatIndex] : null;
      } else {
        answer = controller.userAnswers[question.id];
      }

      final double? latitude = answer is Map
          ? (answer['latitude'] as num?)?.toDouble()
          : null;
      final double? longitude = answer is Map
          ? (answer['longitude'] as num?)?.toDouble()
          : null;
      final double? accuracy = answer is Map
          ? (answer['accuracy'] as num?)?.toDouble()
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (latitude != null && longitude != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Lokasi berhasil diambil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText('Latitude: $latitude'),
                  SelectableText('Longitude: $longitude'),
                  if (accuracy != null)
                    Text('Akurasi: ${accuracy.toStringAsFixed(2)} meter'),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentHeaderColor,
                foregroundColor: Colors.white,
              ),
              onPressed: (controller.isGettingLocation.value || controller.isLockedMode.value || question.isReadOnly)
                  ? null
                  : () {
                controller.getCurrentLocationAnswer(
                  questionId: question.id,
                  repeatIndex: repeatIndex,
                );
              },
              icon: const Icon(Icons.my_location_rounded),
              label: Text(
                controller.isGettingLocation.value
                    ? 'Mengambil Lokasi...'
                    : latitude != null && longitude != null
                    ? 'Ambil Ulang Lokasi'
                    : 'Gunakan Lokasi Saat Ini',
              ),
            ),
          ),
        ],
      );
    });
  }

  String? itemTitleOverrideForValidation(FormQuestion question, int? repeatIndex) {
    if (repeatIndex != null && question.belongsToGroupTag != null) {
      // Disederhanakan agar tidak terlalu panjang di pesan error
      return "${question.questionText} (data ke-${repeatIndex + 1})";
    }
    return question.questionText;
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada gambar yang diunggah',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}



