// Input_User_model

import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk menyimpan satu jawaban pertanyaan
class QuestionAnswer {
  final String questionId; // ID pertanyaan dari struktur form
  final String questionCode; // Kode pertanyaan (jika ada)
  final String questionText; // Teks pertanyaan (untuk referensi)
  dynamic answer; // Bisa String, int, bool, List<String>, DateTime, dll.
  final String questionType; // Untuk membantu interpretasi jawaban

  QuestionAnswer({
    required this.questionId,
    required this.questionCode,
    required this.questionText,
    this.answer,
    required this.questionType,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionCode': questionCode,
      'questionText': questionText,
      'answer': answer,
      'questionType': questionType,
    };
  }

  factory QuestionAnswer.fromMap(Map<String, dynamic> map) {
    return QuestionAnswer(
      questionId: map['questionId'] ?? '',
      questionCode: map['questionCode'] ?? '',
      questionText: map['questionText'] ?? '',
      answer: map['answer'],
      questionType: map['questionType'] ?? '',
    );
  }
}

// Model untuk menyimpan satu set jawaban untuk sebuah form submission
class FormSubmission {
  String? id; // ID unik untuk submission ini (bisa di-generate Firestore)
  final String formId; // ID dari form yang diisi (dari adminForms)
  final String formTitle; // Judul form yang diisi
  final String userId; // ID pengguna yang mengisi
  final String userName; // Nama pengguna yang mengisi (opsional)
  final Timestamp submittedAt;
  final List<QuestionAnswer> answers; // Daftar jawaban
  // Tambahkan field lain jika perlu, misal lokasi GPS, dll.
  GeoPoint? location; // Contoh

  FormSubmission({
    this.id,
    required this.formId,
    required this.formTitle,
    required this.userId,
    required this.userName,
    required this.submittedAt,
    required this.answers,
    this.location,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'formId': formId,
      'formTitle': formTitle,
      'userId': userId,
      'userName': userName,
      'submittedAt': submittedAt,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      if (location != null) 'location': location,
    };
  }

  factory FormSubmission.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FormSubmission(
      id: doc.id,
      formId: data['formId'] ?? '',
      formTitle: data['formTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
      answers: (data['answers'] as List<dynamic>?)
          ?.map((answerMap) => QuestionAnswer.fromMap(answerMap as Map<String, dynamic>))
          .toList() ?? [],
      location: data['location'] as GeoPoint?,
    );
  }
}