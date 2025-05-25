// lib/presentation/admin/formpage/admin_form_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum untuk tipe pertanyaan yang didukung
enum QuestionType {
  text, paragraph, number, date, multipleChoice, checkboxes, dropdown,
}

extension QuestionTypeExtension on QuestionType {
  String toShortString() {
    return toString().split('.').last;
  }

  static QuestionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text': return QuestionType.text;
      case 'paragraph': return QuestionType.paragraph;
      case 'number': return QuestionType.number;
      case 'date': return QuestionType.date;
      case 'multiplechoice': return QuestionType.multipleChoice;
      case 'checkboxes': return QuestionType.checkboxes;
      case 'dropdown': return QuestionType.dropdown;
      default: return QuestionType.text;
    }
  }
}

class ValidationRule {
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? regex;

  ValidationRule({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,
  });

  factory ValidationRule.fromMap(Map<String, dynamic> map) {
    return ValidationRule(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      minValue: map['minValue'] as num?,
      maxValue: map['maxValue'] as num?,
      regex: map['regex'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (regex != null) 'regex': regex,
    };
  }

  ValidationRule copyWith({
    int? minLength,
    int? maxLength,
    num? minValue,
    num? maxValue,
    String? regex,
    bool setMinLengthNull = false, // Flag untuk menghapus nilai
    bool setMaxLengthNull = false,
    bool setMinValueNull = false,
    bool setMaxValueNull = false,
    bool setRegexNull = false,
  }) {
    return ValidationRule(
      minLength: setMinLengthNull ? null : (minLength ?? this.minLength),
      maxLength: setMaxLengthNull ? null : (maxLength ?? this.maxLength),
      minValue: setMinValueNull ? null : (minValue ?? this.minValue),
      maxValue: setMaxValueNull ? null : (maxValue ?? this.maxValue),
      regex: setRegexNull ? null : (regex ?? this.regex),
    );
  }
}

class ConditionalJump {
  final String conditionValue;
  final String jumpToQuestionId; // Bisa ID pertanyaan, 'END_OF_SECTION', atau 'END_OF_FORM'
  final String? jumpToSectionId;

  ConditionalJump({
    required this.conditionValue,
    required this.jumpToQuestionId,
    this.jumpToSectionId,
  });

  factory ConditionalJump.fromMap(Map<String, dynamic> map) {
    return ConditionalJump(
      conditionValue: map['conditionValue'] as String? ?? '',
      jumpToQuestionId: map['jumpToQuestionId'] as String? ?? '',
      jumpToSectionId: map['jumpToSectionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conditionValue': conditionValue,
      'jumpToQuestionId': jumpToQuestionId,
      if (jumpToSectionId != null) 'jumpToSectionId': jumpToSectionId,
    };
  }

  ConditionalJump copyWith({
    String? conditionValue,
    String? jumpToQuestionId,
    String? jumpToSectionId,
    bool setJumpToSectionIdNull = false,
  }) {
    return ConditionalJump(
      conditionValue: conditionValue ?? this.conditionValue,
      jumpToQuestionId: jumpToQuestionId ?? this.jumpToQuestionId,
      jumpToSectionId: setJumpToSectionIdNull ? null : (jumpToSectionId ?? this.jumpToSectionId),
    );
  }
}

class FormQuestion {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final bool isRequired;
  final bool hasOtherOption;
  final ValidationRule? validation;
  final List<ConditionalJump> conditionalJumps;
  final bool repeatable;
  final int? repeatCount;

  FormQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.isRequired = false,
    this.hasOtherOption = false,
    this.validation,
    this.conditionalJumps = const [],
    this.repeatable = false,
    this.repeatCount,
  });

  factory FormQuestion.fromMap(Map<String, dynamic> map) {
    return FormQuestion(
      id: map['id'] as String? ?? '',
      questionText: map['questionText'] as String? ?? 'Pertanyaan Tanpa Teks',
      type: QuestionTypeExtension.fromString(map['type'] as String? ?? 'text'),
      options: List<String>.from(map['options'] as List<dynamic>? ?? []),
      isRequired: map['isRequired'] as bool? ?? false,
      hasOtherOption: map['hasOtherOption'] as bool? ?? false,
      validation: map['validation'] != null
          ? ValidationRule.fromMap(map['validation'] as Map<String, dynamic>)
          : null,
      conditionalJumps: (map['conditionalJumps'] as List<dynamic>?)
          ?.map((j) => ConditionalJump.fromMap(j as Map<String, dynamic>))
          .toList() ?? [],
      repeatable: map['repeatable'] as bool? ?? false,
      repeatCount: map['repeatCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.toShortString(),
      'options': options,
      'isRequired': isRequired,
      'hasOtherOption': hasOtherOption,
      if (validation != null) 'validation': validation!.toMap(),
      'conditionalJumps': conditionalJumps.map((j) => j.toMap()).toList(),
      'repeatable': repeatable,
      if (repeatCount != null) 'repeatCount': repeatCount,
    };
  }

  FormQuestion copyWith({
    String? id,
    String? questionText,
    QuestionType? type,
    List<String>? options,
    bool? isRequired,
    bool? hasOtherOption,
    ValidationRule? validation,
    bool setValidationNull = false,
    List<ConditionalJump>? conditionalJumps,
    bool? repeatable,
    int? repeatCount,
    bool setRepeatCountNull = false,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      isRequired: isRequired ?? this.isRequired,
      hasOtherOption: hasOtherOption ?? this.hasOtherOption,
      validation: setValidationNull ? null : (validation ?? this.validation),
      conditionalJumps: conditionalJumps ?? this.conditionalJumps,
      repeatable: repeatable ?? this.repeatable,
      repeatCount: setRepeatCountNull ? null : (repeatCount ?? this.repeatCount),
    );
  }
}

class FormSection {
  final String id;
  final String title;
  final String? description;
  final List<FormQuestion> questions;

  FormSection({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
  });

  factory FormSection.fromMap(Map<String, dynamic> map) {
    return FormSection(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Bagian Tanpa Judul',
      description: map['description'] as String?,
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => FormQuestion.fromMap(q as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  FormSection copyWith({
    String? id,
    String? title,
    String? description,
    bool setDescriptionNull = false,
    List<FormQuestion>? questions,
  }) {
    return FormSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: setDescriptionNull ? null : (description ?? this.description),
      questions: questions ?? this.questions,
    );
  }

  // Metode untuk membersihkan pertanyaan yang teksnya kosong sebelum disimpan
  FormSection cleanUpQuestionsBeforeSave() {
    final validQuestions = questions.where((q) => q.questionText.trim().isNotEmpty).toList();
    return copyWith(questions: validQuestions);
  }
}

class FormItem {
  final String id; // Ini akan menjadi Firestore Document ID
  final String title;
  final String description;
  final DateTime createdAt;
  final String createdByUserId;
  final List<FormSection> sections;

  FormItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.createdByUserId,
    this.sections = const [],
  });

  factory FormItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormItem(
      id: doc.id, // Menggunakan ID dokumen Firestore
      title: data['title'] as String? ?? 'Tanpa Judul',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUserId: data['createdByUserId'] as String? ?? 'unknown',
      sections: (data['sections'] as List<dynamic>?)
          ?.map((s) => FormSection.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // ID tidak perlu dimasukkan di sini karena akan menjadi ID dokumen
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUserId': createdByUserId,
      'sections': sections.map((s) => s.toMap()).toList(),
    };
  }
}