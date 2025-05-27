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
      default: return QuestionType.text; // Default to text if unknown
    }
  }
}

class ValidationRule {
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? regex;
  final String? predefinedRule; // e.g., "lettersOnly", "numbersOnly", "alphanumeric", "email"

  ValidationRule({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,
    this.predefinedRule,
  });

  factory ValidationRule.fromMap(Map<String, dynamic> map) {
    return ValidationRule(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      minValue: map['minValue'] as num?,
      maxValue: map['maxValue'] as num?,
      regex: map['regex'] as String?,
      predefinedRule: map['predefinedRule'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (minLength != null) map['minLength'] = minLength;
    if (maxLength != null) map['maxLength'] = maxLength;
    if (minValue != null) map['minValue'] = minValue;
    if (maxValue != null) map['maxValue'] = maxValue;
    if (regex != null && regex!.isNotEmpty) map['regex'] = regex;
    if (predefinedRule != null && predefinedRule!.isNotEmpty) map['predefinedRule'] = predefinedRule;
    return map;
  }

  ValidationRule copyWith({
    int? minLength, bool setMinLengthNull = false,
    int? maxLength, bool setMaxLengthNull = false,
    num? minValue, bool setMinValueNull = false,
    num? maxValue, bool setMaxValueNull = false,
    String? regex, bool setRegexNull = false,
    String? predefinedRule, bool setPredefinedRuleNull = false,
  }) {
    return ValidationRule(
      minLength: setMinLengthNull ? null : (minLength ?? this.minLength),
      maxLength: setMaxLengthNull ? null : (maxLength ?? this.maxLength),
      minValue: setMinValueNull ? null : (minValue ?? this.minValue),
      maxValue: setMaxValueNull ? null : (maxValue ?? this.maxValue),
      regex: setRegexNull ? null : (regex ?? this.regex),
      predefinedRule: setPredefinedRuleNull ? null : (predefinedRule ?? this.predefinedRule),
    );
  }
}

class ConditionalJump {
  final String conditionValue;
  final String jumpToQuestionId;
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
    final map = <String, dynamic>{
      'conditionValue': conditionValue,
      'jumpToQuestionId': jumpToQuestionId,
    };
    if (jumpToSectionId != null) map['jumpToSectionId'] = jumpToSectionId;
    return map;
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

class DependentOptionsConfig {
  final String parentQuestionId;
  final Map<String, List<String>> optionMapping;

  DependentOptionsConfig({
    required this.parentQuestionId,
    this.optionMapping = const {},
  });

  factory DependentOptionsConfig.fromMap(Map<String, dynamic> map) {
    return DependentOptionsConfig(
      parentQuestionId: map['parentQuestionId'] as String? ?? '',
      optionMapping: (map['optionMapping'] as Map<String, dynamic>?)?.map(
            (key, value) {
          if (value is List) {
            return MapEntry(key, List<String>.from(value.map((e) => e.toString())));
          }
          return MapEntry(key, <String>[]);
        },
      ) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentQuestionId': parentQuestionId,
      'optionMapping': optionMapping,
    };
  }

  DependentOptionsConfig copyWith({
    String? parentQuestionId,
    Map<String, List<String>>? optionMapping,
  }) {
    return DependentOptionsConfig(
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      optionMapping: optionMapping ?? this.optionMapping,
    );
  }
}

class FormQuestion {
  final String id;
  final String? code;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final bool isRequired;
  final bool hasOtherOption;
  final ValidationRule? validation;
  final List<ConditionalJump> conditionalJumps;
  final bool repeatable;
  final int? repeatCount;
  final DependentOptionsConfig? dependentOptions;

  // Properti untuk grup pertanyaan berulang
  final bool isRepeatableGroupController;
  final String? controlledGroupTag;
  final String? belongsToGroupTag;

  FormQuestion({
    required this.id,
    this.code,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.isRequired = false,
    this.hasOtherOption = false,
    this.validation,
    this.conditionalJumps = const [],
    this.repeatable = false,
    this.repeatCount,
    this.dependentOptions,
    this.isRepeatableGroupController = false,
    this.controlledGroupTag,
    this.belongsToGroupTag,
  });

  factory FormQuestion.fromMap(Map<String, dynamic> map) {
    return FormQuestion(
      id: map['id'] as String? ?? '',
      code: map['code'] as String?,
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
          .toList() ??
          [],
      repeatable: map['repeatable'] as bool? ?? false,
      repeatCount: map['repeatCount'] as int?,
      dependentOptions: map['dependentOptions'] != null
          ? DependentOptionsConfig.fromMap(
          map['dependentOptions'] as Map<String, dynamic>)
          : null,
      isRepeatableGroupController:
      map['isRepeatableGroupController'] as bool? ?? false,
      controlledGroupTag: map['controlledGroupTag'] as String?,
      belongsToGroupTag: map['belongsToGroupTag'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'questionText': questionText,
      'type': type.toShortString(),
      'options': options,
      'isRequired': isRequired,
      'hasOtherOption': hasOtherOption,
      'conditionalJumps': conditionalJumps.map((j) => j.toMap()).toList(),
      'repeatable': repeatable,
      'isRepeatableGroupController': isRepeatableGroupController,
    };
    if (code != null && code!.isNotEmpty) {
      map['code'] = code;
    }
    if (validation != null && validation!.toMap().isNotEmpty) {
      map['validation'] = validation!.toMap();
    }
    if (repeatCount != null) {
      map['repeatCount'] = repeatCount;
    }
    if (dependentOptions != null) {
      map['dependentOptions'] = dependentOptions!.toMap();
    }
    if (controlledGroupTag != null && controlledGroupTag!.isNotEmpty) {
      map['controlledGroupTag'] = controlledGroupTag;
    }
    if (belongsToGroupTag != null && belongsToGroupTag!.isNotEmpty) {
      map['belongsToGroupTag'] = belongsToGroupTag;
    }
    return map;
  }

  FormQuestion copyWith({
    String? id,
    String? code,
    bool setCodeNull = false,
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
    DependentOptionsConfig? dependentOptions,
    bool setDependentOptionsNull = false,
    bool? isRepeatableGroupController,
    String? controlledGroupTag,
    bool setControlledGroupTagNull = false,
    String? belongsToGroupTag,
    bool setBelongsToGroupTagNull = false,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      code: setCodeNull ? null : (code ?? this.code),
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? List<String>.from(this.options),
      isRequired: isRequired ?? this.isRequired,
      hasOtherOption: hasOtherOption ?? this.hasOtherOption,
      validation: setValidationNull ? null : (validation ?? this.validation),
      conditionalJumps:
      conditionalJumps ?? List<ConditionalJump>.from(this.conditionalJumps),
      repeatable: repeatable ?? this.repeatable,
      repeatCount: setRepeatCountNull ? null : (repeatCount ?? this.repeatCount),
      dependentOptions: setDependentOptionsNull
          ? null
          : (dependentOptions ?? this.dependentOptions),
      isRepeatableGroupController:
      isRepeatableGroupController ?? this.isRepeatableGroupController,
      controlledGroupTag: setControlledGroupTagNull
          ? null
          : (controlledGroupTag ?? this.controlledGroupTag),
      belongsToGroupTag: setBelongsToGroupTagNull
          ? null
          : (belongsToGroupTag ?? this.belongsToGroupTag),
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
      title: map['title'] as String? ?? '', // Allow empty title to be handled by UI
      description: map['description'] as String?,
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => FormQuestion.fromMap(q as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
    if (description != null) map['description'] = description;
    return map;
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
      questions: questions ?? List<FormQuestion>.from(this.questions),
    );
  }

  FormSection cleanUpQuestionsBeforeSave() {
    final validQuestions = questions
        .where((q) => q.questionText.trim().isNotEmpty || (q.code != null && q.code!.trim().isNotEmpty))
        .toList();
    return copyWith(questions: validQuestions);
  }
}

class FormItem {
  final String id;
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
      id: doc.id,
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
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUserId': createdByUserId,
      'sections': sections.map((s) => s.toMap()).toList(),
    };
  }
}