import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Untuk listEquals dan mapEquals

// Enum untuk tipe pertanyaan yang didukung
enum QuestionType {
  text,
  paragraph,
  number,
  date,
  multipleChoice,
  checkboxes,
  dropdown,
  gridNumeric, // Untuk tipe grid
}

extension QuestionTypeExtension on QuestionType {
  String toShortString() {
    return toString().split('.').last;
  }

  static QuestionType fromString(String? type) {
    if (type == null) return QuestionType.text;
    String typeLower = type.toLowerCase();
    for (QuestionType qt in QuestionType.values) {
      if (qt.toShortString().toLowerCase() == typeLower) {
        return qt;
      }
    }
    debugPrint("Warning: Tipe pertanyaan tidak dikenal '$type', menggunakan default 'text'.");
    return QuestionType.text;
  }
}

// Enum untuk operator perbandingan
enum ComparisonOperatorType {
  none,
  lessThan,
  lessThanOrEqual,
  equal,
  notEqual,
  greaterThan,
  greaterThanOrEqual,
}

extension ComparisonOperatorTypeExtension on ComparisonOperatorType {
  String toShortString() {
    return toString().split('.').last;
  }

  static ComparisonOperatorType fromString(String? type) {
    if (type == null) return ComparisonOperatorType.none;
    String typeLower = type.toLowerCase();
    for (ComparisonOperatorType op in ComparisonOperatorType.values) {
      if (op.toShortString().toLowerCase() == typeLower) {
        return op;
      }
    }
    return ComparisonOperatorType.none;
  }
}

class ValidationRule {
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? regex;
  final String? predefinedRule;

  final String? comparisonOperator;
  final String? compareToQuestionId;
  final String? compareToQuestionCode;

  ValidationRule({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,
    this.predefinedRule,
    this.comparisonOperator,
    this.compareToQuestionId,
    this.compareToQuestionCode,
  });

  ValidationRule.empty()
      : minLength = null,
        maxLength = null,
        minValue = null,
        maxValue = null,
        regex = null,
        predefinedRule = null,
        comparisonOperator = null,
        compareToQuestionId = null,
        compareToQuestionCode = null;

  bool get isEffectivelyEmpty {
    return minLength == null &&
        maxLength == null &&
        minValue == null &&
        maxValue == null &&
        (regex == null || regex!.isEmpty) &&
        (predefinedRule == null || predefinedRule!.isEmpty || predefinedRule == 'none') &&
        (comparisonOperator == null || comparisonOperator!.isEmpty || comparisonOperator == ComparisonOperatorType.none.toShortString()) &&
        (compareToQuestionId == null || compareToQuestionId!.isEmpty);
  }

  factory ValidationRule.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return ValidationRule.empty();
    return ValidationRule(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      minValue: map['minValue'] as num?,
      maxValue: map['maxValue'] as num?,
      regex: map['regex'] as String?,
      predefinedRule: map['predefinedRule'] as String?,
      comparisonOperator: map['comparisonOperator'] as String?,
      compareToQuestionId: map['compareToQuestionId'] as String?,
      compareToQuestionCode: map['compareToQuestionCode'] as String?,
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
    if (comparisonOperator != null && comparisonOperator!.isNotEmpty && comparisonOperator != ComparisonOperatorType.none.toShortString()) map['comparisonOperator'] = comparisonOperator;
    if (compareToQuestionId != null && compareToQuestionId!.isNotEmpty) map['compareToQuestionId'] = compareToQuestionId;
    if (compareToQuestionCode != null && compareToQuestionCode!.isNotEmpty) map['compareToQuestionCode'] = compareToQuestionCode;
    return map;
  }

  ValidationRule copyWith({
    int? minLength, bool setMinLengthNull = false,
    int? maxLength, bool setMaxLengthNull = false,
    num? minValue, bool setMinValueNull = false,
    num? maxValue, bool setMaxValueNull = false,
    String? regex, bool setRegexNull = false,
    String? predefinedRule, bool setPredefinedRuleNull = false,
    String? comparisonOperator, bool setComparisonOperatorNull = false,
    String? compareToQuestionId, bool setCompareToQuestionIdNull = false,
    String? compareToQuestionCode, bool setCompareToQuestionCodeNull = false,
  }) {
    return ValidationRule(
      minLength: setMinLengthNull ? null : (minLength ?? this.minLength),
      maxLength: setMaxLengthNull ? null : (maxLength ?? this.maxLength),
      minValue: setMinValueNull ? null : (minValue ?? this.minValue),
      maxValue: setMaxValueNull ? null : (maxValue ?? this.maxValue),
      regex: setRegexNull ? null : (regex ?? this.regex),
      predefinedRule: setPredefinedRuleNull ? null : (predefinedRule ?? this.predefinedRule),
      comparisonOperator: setComparisonOperatorNull ? null : (comparisonOperator ?? this.comparisonOperator),
      compareToQuestionId: setCompareToQuestionIdNull ? null : (compareToQuestionId ?? this.compareToQuestionId),
      compareToQuestionCode: setCompareToQuestionCodeNull ? null : (compareToQuestionCode ?? this.compareToQuestionCode),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ValidationRule &&
              runtimeType == other.runtimeType &&
              minLength == other.minLength &&
              maxLength == other.maxLength &&
              minValue == other.minValue &&
              maxValue == other.maxValue &&
              regex == other.regex &&
              predefinedRule == other.predefinedRule &&
              comparisonOperator == other.comparisonOperator &&
              compareToQuestionId == other.compareToQuestionId &&
              compareToQuestionCode == other.compareToQuestionCode;

  @override
  int get hashCode =>
      minLength.hashCode ^
      maxLength.hashCode ^
      minValue.hashCode ^
      maxValue.hashCode ^
      regex.hashCode ^
      predefinedRule.hashCode ^
      comparisonOperator.hashCode ^
      compareToQuestionId.hashCode ^
      compareToQuestionCode.hashCode;
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

  factory ConditionalJump.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ConditionalJump(conditionValue: '', jumpToQuestionId: '');
    return ConditionalJump(
      conditionValue: map['conditionValue'] as String? ?? '',
      jumpToQuestionId: map['jumpToQuestionId'] as String? ?? '',
      jumpToSectionId: map['jumpToSectionId'] as String?,
    );
  }

  // Implementasi toMap yang lengkap
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'conditionValue': conditionValue,
      'jumpToQuestionId': jumpToQuestionId,
    };
    if (jumpToSectionId != null && jumpToSectionId!.isNotEmpty) {
      map['jumpToSectionId'] = jumpToSectionId;
    }
    return map;
  }

  // Implementasi copyWith yang lengkap
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ConditionalJump &&
              runtimeType == other.runtimeType &&
              conditionValue == other.conditionValue &&
              jumpToQuestionId == other.jumpToQuestionId &&
              jumpToSectionId == other.jumpToSectionId;

  @override
  int get hashCode =>
      conditionValue.hashCode ^
      jumpToQuestionId.hashCode ^
      jumpToSectionId.hashCode;
}

class DependentOptionsConfig {
  final String parentQuestionId;
  final Map<String, List<String>> optionMapping;

  DependentOptionsConfig({
    required this.parentQuestionId,
    this.optionMapping = const {},
  });

  factory DependentOptionsConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DependentOptionsConfig(parentQuestionId: '', optionMapping: {});
    return DependentOptionsConfig(
      parentQuestionId: map['parentQuestionId'] as String? ?? '',
      optionMapping: (map['optionMapping'] as Map<String, dynamic>?)?.map(
            (key, value) {
          if (value is List) {
            return MapEntry(key, List<String>.from(value.map((e) => e.toString())));
          }
          return MapEntry(key, <String>[]);
        },
      ) ?? const {},
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
      optionMapping: optionMapping ?? Map<String, List<String>>.from(this.optionMapping),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DependentOptionsConfig &&
              runtimeType == other.runtimeType &&
              parentQuestionId == other.parentQuestionId &&
              mapEquals(optionMapping, other.optionMapping); // Gunakan mapEquals untuk perbandingan map

  @override
  int get hashCode => parentQuestionId.hashCode ^ _mapHashCode(optionMapping);

  // Helper untuk hashCode map
  int _mapHashCode(Map<dynamic, dynamic> map) {
    int hash = 0;
    map.forEach((key, value) {
      hash = hash ^ key.hashCode ^ value.hashCode;
    });
    return hash;
  }
}

class FormQuestion {
  final String id;
  final String? code;
  final String questionText;
  final String? description; // <-- TAMBAHKAN INI
  final QuestionType type;
  final List<String> options;
  final bool isRequired;
  final bool hasOtherOption;
  final ValidationRule validation;
  final List<ConditionalJump> conditionalJumps;
  final bool repeatable;
  final int? repeatCount;
  final DependentOptionsConfig? dependentOptions;
  final bool isRepeatableGroupController;
  final String? controlledGroupTag;
  final String? belongsToGroupTag;
  final List<String> gridRowLabels;
  final List<String> gridColumnLabels;
  final List<String> gridSubColumnLabels;
  final String? unconditionalJumpTarget;

  FormQuestion({
    required this.id,
    this.code,
    required this.questionText,
    this.description, // <-- TAMBAHKAN INI
    required this.type,
    this.options = const [],
    this.isRequired = false,
    this.hasOtherOption = false,
    ValidationRule? validation,
    this.conditionalJumps = const [],
    this.repeatable = false,
    this.repeatCount,
    this.dependentOptions,
    this.isRepeatableGroupController = false,
    this.controlledGroupTag,
    this.belongsToGroupTag,
    this.gridRowLabels = const [],
    this.gridColumnLabels = const [],
    this.gridSubColumnLabels = const [],
    this.unconditionalJumpTarget,
  }) : validation = validation ?? ValidationRule.empty();

  factory FormQuestion.fromMap(Map<String, dynamic> map) {
    return FormQuestion(
      id: map['id'] as String? ?? '',
      code: map['code'] as String?,
      questionText: map['questionText'] as String? ?? 'Pertanyaan Tanpa Teks',
      description: map['description'] as String?, // <-- TAMBAHKAN INI
      type: QuestionTypeExtension.fromString(map['type'] as String?),
      options: List<String>.from((map['options'] as List<dynamic>?)?.map((e)=> e.toString()) ?? []),
      isRequired: map['isRequired'] as bool? ?? false,
      hasOtherOption: map['hasOtherOption'] as bool? ?? false,
      validation: ValidationRule.fromMap(map['validation'] as Map<String, dynamic>?),
      conditionalJumps: (map['conditionalJumps'] as List<dynamic>?)
          ?.map((j) => ConditionalJump.fromMap(j as Map<String, dynamic>?))
          .where((j) => j.jumpToQuestionId.isNotEmpty)
          .toList() ?? [],
      repeatable: map['repeatable'] as bool? ?? false,
      repeatCount: map['repeatCount'] as int?,
      dependentOptions: map['dependentOptions'] != null
          ? DependentOptionsConfig.fromMap(map['dependentOptions'] as Map<String, dynamic>?)
          : null,
      isRepeatableGroupController: map['isRepeatableGroupController'] as bool? ?? false,
      controlledGroupTag: map['controlledGroupTag'] as String?,
      belongsToGroupTag: map['belongsToGroupTag'] as String?,
      gridRowLabels: List<String>.from((map['gridRowLabels'] as List<dynamic>?)?.map((e)=> e.toString()) ?? []),
      gridColumnLabels: List<String>.from((map['gridColumnLabels'] as List<dynamic>?)?.map((e)=> e.toString()) ?? []),
      gridSubColumnLabels: List<String>.from((map['gridSubColumnLabels'] as List<dynamic>?)?.map((e)=> e.toString()) ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'questionText': questionText,
      // TAMBAHKAN INI (kondisional agar tidak menyimpan null/empty string jika tidak perlu)
      if (description != null && description!.isNotEmpty) 'description': description,
      'type': type.toShortString(),
      'options': options,
      'isRequired': isRequired,
      'hasOtherOption': hasOtherOption,
      if (!validation.isEffectivelyEmpty) 'validation': validation.toMap(),
      'conditionalJumps': conditionalJumps.map((j) => j.toMap()).toList(),
      'repeatable': repeatable,
      'isRepeatableGroupController': isRepeatableGroupController,
      'gridRowLabels': gridRowLabels,
      'gridColumnLabels': gridColumnLabels,
      'gridSubColumnLabels': gridSubColumnLabels,
    };
    if (code != null && code!.isNotEmpty) map['code'] = code;
    if (repeatCount != null) map['repeatCount'] = repeatCount;
    if (dependentOptions != null) map['dependentOptions'] = dependentOptions!.toMap();
    if (controlledGroupTag != null && controlledGroupTag!.isNotEmpty) map['controlledGroupTag'] = controlledGroupTag;
    if (belongsToGroupTag != null && belongsToGroupTag!.isNotEmpty) map['belongsToGroupTag'] = belongsToGroupTag;
    return map;
  }

  FormQuestion copyWith({
    String? id,
    String? code, bool setCodeNull = false,
    String? questionText,
    String? description, bool setDescriptionNull = false, // <-- TAMBAHKAN INI
    QuestionType? type,
    List<String>? options,
    bool? isRequired,
    bool? hasOtherOption,
    ValidationRule? validation, bool setValidationNull = false,
    List<ConditionalJump>? conditionalJumps,
    bool? repeatable,
    int? repeatCount, bool setRepeatCountNull = false,
    DependentOptionsConfig? dependentOptions, bool setDependentOptionsNull = false,
    bool? isRepeatableGroupController,
    String? controlledGroupTag, bool setControlledGroupTagNull = false,
    String? belongsToGroupTag, bool setBelongsToGroupTagNull = false,
    List<String>? gridRowLabels,
    List<String>? gridColumnLabels,
    List<String>? gridSubColumnLabels,
    String? unconditionalJumpTarget,
    bool setUnconditionalJumpTargetNull = false,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      code: setCodeNull ? null : (code ?? this.code),
      questionText: questionText ?? this.questionText,
      description: setDescriptionNull ? null : (description ?? this.description), // <-- TAMBAHKAN INI
      type: type ?? this.type,
      options: options ?? List<String>.from(this.options),
      isRequired: isRequired ?? this.isRequired,
      hasOtherOption: hasOtherOption ?? this.hasOtherOption,
      validation: setValidationNull ? ValidationRule.empty() : (validation ?? this.validation),
      conditionalJumps: conditionalJumps ?? List<ConditionalJump>.from(this.conditionalJumps),
      repeatable: repeatable ?? this.repeatable,
      repeatCount: setRepeatCountNull ? null : (repeatCount ?? this.repeatCount),
      dependentOptions: setDependentOptionsNull ? null : (dependentOptions ?? this.dependentOptions),
      isRepeatableGroupController: isRepeatableGroupController ?? this.isRepeatableGroupController,
      controlledGroupTag: setControlledGroupTagNull ? null : (controlledGroupTag ?? this.controlledGroupTag),
      belongsToGroupTag: setBelongsToGroupTagNull ? null : (belongsToGroupTag ?? this.belongsToGroupTag),
      gridRowLabels: gridRowLabels ?? List<String>.from(this.gridRowLabels),
      gridColumnLabels: gridColumnLabels ?? List<String>.from(this.gridColumnLabels),
      gridSubColumnLabels: gridSubColumnLabels ?? List<String>.from(this.gridSubColumnLabels),
      unconditionalJumpTarget: setUnconditionalJumpTargetNull ? null : unconditionalJumpTarget ?? this.unconditionalJumpTarget,
    );
  }
}

class FormSection {
  final String id;
  final String title;
  final String? description;
  final List<FormQuestion> questions;
  final bool isRepeatable;
  final String? repeatTriggerQuestionId;
  final String? repeatTriggerQuestionCode;
  final int? minRepeats;
  final int? maxRepeats;

  FormSection({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
    this.isRepeatable = false,
    this.repeatTriggerQuestionId,
    this.repeatTriggerQuestionCode,
    this.minRepeats,
    this.maxRepeats,
  });

  factory FormSection.fromMap(Map<String, dynamic> map) {
    return FormSection(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => FormQuestion.fromMap(q as Map<String, dynamic>))
          .toList() ?? [],
      isRepeatable: map['isRepeatable'] as bool? ?? false,
      repeatTriggerQuestionId: map['repeatTriggerQuestionId'] as String?,
      repeatTriggerQuestionCode: map['repeatTriggerQuestionCode'] as String?,
      minRepeats: map['minRepeats'] as int?,
      maxRepeats: map['maxRepeats'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isRepeatable': isRepeatable,
    };
    if (description != null && description!.isNotEmpty) map['description'] = description;
    if (isRepeatable) {
      if (repeatTriggerQuestionId != null && repeatTriggerQuestionId!.isNotEmpty) map['repeatTriggerQuestionId'] = repeatTriggerQuestionId;
      if (repeatTriggerQuestionCode != null && repeatTriggerQuestionCode!.isNotEmpty) map['repeatTriggerQuestionCode'] = repeatTriggerQuestionCode;
      if (minRepeats != null) map['minRepeats'] = minRepeats;
      if (maxRepeats != null) map['maxRepeats'] = maxRepeats;
    }
    return map;
  }

  FormSection copyWith({
    String? id,
    String? title,
    String? description, bool setDescriptionNull = false,
    List<FormQuestion>? questions,
    bool? isRepeatable,
    String? repeatTriggerQuestionId, bool setRepeatTriggerQuestionIdNull = false,
    String? repeatTriggerQuestionCode, bool setRepeatTriggerQuestionCodeNull = false,
    int? minRepeats, bool setMinRepeatsNull = false,
    int? maxRepeats, bool setMaxRepeatsNull = false,
  }) {
    return FormSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: setDescriptionNull ? null : (description ?? this.description),
      questions: questions ?? List<FormQuestion>.from(this.questions),
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatTriggerQuestionId: setRepeatTriggerQuestionIdNull ? null : (repeatTriggerQuestionId ?? this.repeatTriggerQuestionId),
      repeatTriggerQuestionCode: setRepeatTriggerQuestionCodeNull ? null : (repeatTriggerQuestionCode ?? this.repeatTriggerQuestionCode),
      minRepeats: setMinRepeatsNull ? null : (minRepeats ?? this.minRepeats),
      maxRepeats: setMaxRepeatsNull ? null : (maxRepeats ?? this.maxRepeats),
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
  final DateTime? updatedAt;
  final String createdByUserId;
  final List<FormSection> sections;
  final String? formVersion;

  FormItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    required this.createdByUserId,
    this.sections = const [],
    this.formVersion = "1.0",
  });

  factory FormItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdByUserId: data['createdByUserId'] as String? ?? 'unknown',
      sections: (data['sections'] as List<dynamic>?)
          ?.map((s) => FormSection.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      formVersion: data['formVersion'] as String? ?? "1.0",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByUserId': createdByUserId,
      'sections': sections.map((s) => s.toMap()).toList(),
      'formVersion': formVersion,
    };
  }
}

// HAPUS BARIS-BARIS DI BAWAH INI KARENA SUDAH ADA DI DALAM KELAS DependentOptionsConfig
// factory DependentOptionsConfig.fromMap(Map<String, dynamic>? map) { /* ... implementasi Anda ... */ return DependentOptionsConfig(parentQuestionId: ''); }
// Map<String, dynamic> toMap() { /* ... implementasi Anda ... */ return {}; }
// DependentOptionsConfig copyWith({ /* ... */ }) { return this; }