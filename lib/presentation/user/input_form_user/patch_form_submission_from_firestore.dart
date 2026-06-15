import 'package:cloud_firestore/cloud_firestore.dart';
import 'input_user_model.dart';

// PATCH FormSubmission.fromFirestore di input_user_model.dart atau admin_form_model.dart
// Pastikan id diisi dari doc.id, bukan dari field data['id'] saja.

// Catatan: Ini adalah snippet. Untuk menggunakannya, copy isi fungsi ini 
// ke dalam class FormSubmission di file model Anda.

/// Fungsi pembantu (patch) untuk memetakan dokumen Firestore ke objek [FormSubmission].
/// 
/// Fungsi ini memastikan bahwa properti [id] diambil dari [doc.id] (metadata dokumen),
/// bukan dari data field di dalam dokumen, untuk menjamin konsistensi referensi data.
/// 
/// [doc] adalah snapshot dokumen dari Cloud Firestore.
FormSubmission fromFirestorePatch(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

  return FormSubmission(
    id: doc.id,
    formId: data['formId'] ?? '',
    formTitle: data['formTitle'] ?? '',
    userId: data['userId'] ?? '',
    userName: data['userName'] ?? '',
    submittedAt: data['submittedAt'] as Timestamp? ?? Timestamp.now(),
    answers: (data['answers'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => QuestionAnswer.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(),
  );
}
