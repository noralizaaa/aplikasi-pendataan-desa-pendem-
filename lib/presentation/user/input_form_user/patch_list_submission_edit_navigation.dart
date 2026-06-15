import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';

// PATCH tombol EDIT di halaman list submission
// Letakkan di file list submission kamu pada onPressed tombol Edit.
// Intinya: jangan hanya kirim formId. Wajib kirim formId + submissionId.

void onEditPressedPatch(dynamic submission) {
  Get.toNamed(
    AppRoutes.inputFormUser,
    arguments: {
      'formId': submission.formId,
      'submissionId': submission.id,
    },
  );
}

// Kalau variabel yang tersedia bukan object submission, gunakan pola ini:
//
// Get.toNamed(
//   AppRoutes.INPUT_FORM_USER,
//   arguments: {
//     'formId': formId,
//     'submissionId': submissionId,
//   },
// );
