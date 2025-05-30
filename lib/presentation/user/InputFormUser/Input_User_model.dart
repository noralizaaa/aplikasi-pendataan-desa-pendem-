// File: input_user_model.dart (Pastikan ini adalah isi file Anda)

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart'; // Hanya jika ada Rx type di model ini

// Model untuk menyimpan satu jawaban pertanyaan
class QuestionAnswer {
  final String questionId;
  final String questionCode;
  final String questionText;
  dynamic answer;
  final String questionType;

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
  String? id;
  final String formId;
  final String formTitle;
  final String userId;
  final String userName;
  final Timestamp submittedAt;
  final List<QuestionAnswer> answers;
  GeoPoint? location;
  Timestamp? updatedAt; // Jika Anda memutuskan untuk menggunakan ini juga

  // --- PASTIKAN FIELD INI ADA ---
  final String? namaKepalaRumahTangga;
  // --- AKHIR PENGECEKAN FIELD ---

  FormSubmission({
    this.id,
    required this.formId,
    required this.formTitle,
    required this.userId,
    required this.userName,
    required this.submittedAt,
    required this.answers,
    this.location,
    this.updatedAt, // Jika Anda pakai updatedAt
    this.namaKepalaRumahTangga, // --- PASTIKAN ADA DI KONSTRUKTOR ---
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
      if (updatedAt != null) 'updatedAt': updatedAt,
      // namaKepalaRumahTangga tidak perlu disimpan ulang di sini karena sudah ada di 'answers'
    };
  }

  factory FormSubmission.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final List<QuestionAnswer> allAnswers = (data['answers'] as List<dynamic>?)
        ?.map((answerMap) =>
        QuestionAnswer.fromMap(answerMap as Map<String, dynamic>))
        .toList() ??
        [];

    // --- LOGIKA UNTUK MENGISI namaKepalaRumahTangga ---
    String? extractedNamaKRT;
    const String targetQuestionCodeForKRT = "106"; // Sesuai contoh Anda

    try {
      // Menggunakan firstWhereOrNull dari GetX atau package collection jika tersedia
      // Jika tidak, try-catch adalah cara yang aman.
      final krtAnswerObject = allAnswers.firstWhere(
            (ans) => (ans.questionCode == targetQuestionCodeForKRT || ans.questionId == targetQuestionCodeForKRT) &&
            ans.answer != null && ans.answer.toString().isNotEmpty,
        // Jika tidak ada 'orElse', firstWhere akan throw error jika tidak ditemukan.
      );
      extractedNamaKRT = krtAnswerObject.answer?.toString();
    } catch (e) {
      // Jika jawaban tidak ditemukan, extractedNamaKRT akan tetap null (atau nilai default awal)
      // print('Info: Jawaban untuk Nama KRT (kode ${targetQuestionCodeForKRT}) tidak ditemukan pada submission ${doc.id}');
    }
    // --- AKHIR LOGIKA ---

    return FormSubmission(
      id: doc.id,
      formId: data['formId'] ?? '',
      formTitle: data['formTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      submittedAt: data['submittedAt'] as Timestamp? ?? Timestamp.now(),
      answers: allAnswers,
      location: data['location'] as GeoPoint?,
      updatedAt: data['updatedAt'] as Timestamp?, // Jika Anda pakai updatedAt
      namaKepalaRumahTangga: extractedNamaKRT, // --- PASTIKAN DI-ASSIGN DI SINI ---
    );
  }
}