import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tipe-tipe pertanyaan yang didukung oleh sistem formulir dinamis.
enum QuestionType {
  /// Input teks singkat.
  text,
  /// Input teks panjang (paragraf).
  paragraph,
  /// Input angka.
  number,
  /// Pemilihan tanggal.
  date,
  /// Pilihan ganda (memilih satu opsi).
  multipleChoice,
  /// Daftar centang (memilih satu atau lebih opsi).
  checkboxes,
  /// Daftar turun bawah (dropdown).
  dropdown,
  /// Input angka dalam format grid/tabel.
  gridNumeric,
  /// Unggah gambar/foto.
  imageUpload,
  /// Pengambilan lokasi GPS.
  location,
}

/// Ekstensi untuk [QuestionType] guna mendukung konversi dari dan ke string.
extension QuestionTypeExtension on QuestionType {
  /// Mengambil nama enum tanpa nama kelasnya (misal: 'text' bukan 'QuestionType.text').
  String toShortString() {
    return toString().split('.').last;
  }

  /// Membuat [QuestionType] dari string. Default ke [QuestionType.text] jika tidak dikenal.
  static QuestionType fromString(String? type) {
    if (type == null) {
      return QuestionType.text;
    }

    final String typeLower = type.toLowerCase();

    for (final QuestionType questionType in QuestionType.values) {
      if (questionType.toShortString().toLowerCase() == typeLower) {
        return questionType;
      }
    }

    debugPrint(
      "Warning: Tipe pertanyaan tidak dikenal '$type', menggunakan default 'text'.",
    );

    return QuestionType.text;
  }
}

/// Operator perbandingan yang digunakan dalam aturan validasi.
enum ComparisonOperatorType {
  /// Tidak ada operator perbandingan.
  none,
  /// Kurang dari (<).
  lessThan,
  /// Kurang dari atau sama dengan (<=).
  lessThanOrEqual,
  /// Sama dengan (==).
  equal,
  /// Tidak sama dengan (!=).
  notEqual,
  /// Lebih dari (>).
  greaterThan,
  /// Lebih dari atau sama dengan (>=).
  greaterThanOrEqual,
}

/// Ekstensi untuk [ComparisonOperatorType] guna mendukung konversi dari dan ke string.
extension ComparisonOperatorTypeExtension on ComparisonOperatorType {
  /// Mengambil nama enum tanpa nama kelasnya.
  String toShortString() {
    return toString().split('.').last;
  }

  /// Membuat [ComparisonOperatorType] dari string. Default ke [ComparisonOperatorType.none].
  static ComparisonOperatorType fromString(String? type) {
    if (type == null) {
      return ComparisonOperatorType.none;
    }

    final String typeLower = type.toLowerCase();

    for (final ComparisonOperatorType operator in ComparisonOperatorType.values) {
      if (operator.toShortString().toLowerCase() == typeLower) {
        return operator;
      }
    }

    return ComparisonOperatorType.none;
  }
}

/// Mendefinisikan aturan validasi untuk sebuah pertanyaan.
class ValidationRule {
  /// Panjang minimum karakter (untuk teks).
  final int? minLength;
  /// Panjang maksimum karakter (untuk teks).
  final int? maxLength;
  /// Nilai angka minimum.
  final num? minValue;
  /// Nilai angka maksimum.
  final num? maxValue;
  /// Pola Regular Expression kustom.
  final String? regex;
  /// Aturan validasi yang sudah didefinisikan sebelumnya (misal: 'email').
  final String? predefinedRule;
  /// Operator perbandingan dengan pertanyaan lain.
  final String? comparisonOperator;
  /// ID pertanyaan yang akan dibandingkan nilainya.
  final String? compareToQuestionId;

  ValidationRule({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,
    this.predefinedRule,
    this.comparisonOperator,
    this.compareToQuestionId,
  });

  /// Membuat instance [ValidationRule] yang kosong.
  ValidationRule.empty()
      : minLength = null,
        maxLength = null,
        minValue = null,
        maxValue = null,
        regex = null,
        predefinedRule = null,
        comparisonOperator = null,
        compareToQuestionId = null;

  /// Mengecek apakah aturan validasi ini efektif kosong (tidak memiliki batasan apapun).
  bool get isEffectivelyEmpty {
    return minLength == null &&
        maxLength == null &&
        minValue == null &&
        maxValue == null &&
        (regex == null || regex!.isEmpty) &&
        (predefinedRule == null ||
            predefinedRule!.isEmpty ||
            predefinedRule == 'none') &&
        (comparisonOperator == null ||
            comparisonOperator!.isEmpty ||
            comparisonOperator ==
                ComparisonOperatorType.none.toShortString()) &&
        (compareToQuestionId == null || compareToQuestionId!.isEmpty);
  }

  /// Membuat instance [ValidationRule] dari Map (biasanya dari Firestore).
  factory ValidationRule.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return ValidationRule.empty();
    }

    return ValidationRule(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      minValue: map['minValue'] as num?,
      maxValue: map['maxValue'] as num?,
      regex: map['regex'] as String?,
      predefinedRule: map['predefinedRule'] as String?,
      comparisonOperator: map['comparisonOperator'] as String?,
      compareToQuestionId: map['compareToQuestionId'] as String?,
    );
  }

  /// Mengonversi objek [ValidationRule] ke dalam format Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};

    if (minLength != null) map['minLength'] = minLength;
    if (maxLength != null) map['maxLength'] = maxLength;
    if (minValue != null) map['minValue'] = minValue;
    if (maxValue != null) map['maxValue'] = maxValue;
    if (regex != null && regex!.isNotEmpty) map['regex'] = regex;
    if (predefinedRule != null && predefinedRule!.isNotEmpty) map['predefinedRule'] = predefinedRule;
    if (comparisonOperator != null &&
        comparisonOperator!.isNotEmpty &&
        comparisonOperator != ComparisonOperatorType.none.toShortString()) {
      map['comparisonOperator'] = comparisonOperator;
    }
    if (compareToQuestionId != null && compareToQuestionId!.isNotEmpty) {
      map['compareToQuestionId'] = compareToQuestionId;
    }

    return map;
  }

  /// Membuat salinan objek dengan perubahan pada properti tertentu (Immutability pattern).
  ValidationRule copyWith({
    int? minLength,
    bool setMinLengthNull = false,
    int? maxLength,
    bool setMaxLengthNull = false,
    num? minValue,
    bool setMinValueNull = false,
    num? maxValue,
    bool setMaxValueNull = false,
    String? regex,
    bool setRegexNull = false,
    String? predefinedRule,
    bool setPredefinedRuleNull = false,
    String? comparisonOperator,
    bool setComparisonOperatorNull = false,
    String? compareToQuestionId,
    bool setCompareToQuestionIdNull = false,
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
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ValidationRule &&
            runtimeType == other.runtimeType &&
            minLength == other.minLength &&
            maxLength == other.maxLength &&
            minValue == other.minValue &&
            maxValue == other.maxValue &&
            regex == other.regex &&
            predefinedRule == other.predefinedRule &&
            comparisonOperator == other.comparisonOperator &&
            compareToQuestionId == other.compareToQuestionId;
  }

  @override
  int get hashCode {
    return minLength.hashCode ^
    maxLength.hashCode ^
    minValue.hashCode ^
    maxValue.hashCode ^
    regex.hashCode ^
    predefinedRule.hashCode ^
    comparisonOperator.hashCode ^
    compareToQuestionId.hashCode;
  }
}

/// Mendefinisikan logika lompatan bersyarat dalam formulir.
class ConditionalJump {
  /// Nilai jawaban yang memicu lompatan.
  final String conditionValue;
  /// ID pertanyaan tujuan lompatan.
  final String jumpToQuestionId;
  /// ID seksi tujuan lompatan (jika melompat ke seksi lain).
  final String? jumpToSectionId;

  ConditionalJump({
    required this.conditionValue,
    required this.jumpToQuestionId,
    this.jumpToSectionId,
  });

  /// Membuat instance [ConditionalJump] dari Map.
  factory ConditionalJump.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ConditionalJump(
        conditionValue: '',
        jumpToQuestionId: '',
      );
    }

    return ConditionalJump(
      conditionValue: map['conditionValue'] as String? ?? '',
      jumpToQuestionId: map['jumpToQuestionId'] as String? ?? '',
      jumpToSectionId: map['jumpToSectionId'] as String?,
    );
  }

  /// Mengonversi objek [ConditionalJump] ke format Map.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'conditionValue': conditionValue,
      'jumpToQuestionId': jumpToQuestionId,
    };

    if (jumpToSectionId != null && jumpToSectionId!.isNotEmpty) {
      map['jumpToSectionId'] = jumpToSectionId;
    }

    return map;
  }

  /// Membuat salinan objek dengan perubahan pada properti tertentu.
  ConditionalJump copyWith({
    String? conditionValue,
    String? jumpToQuestionId,
    String? jumpToSectionId,
    bool setJumpToSectionIdNull = false,
  }) {
    return ConditionalJump(
      conditionValue: conditionValue ?? this.conditionValue,
      jumpToQuestionId: jumpToQuestionId ?? this.jumpToQuestionId,
      jumpToSectionId:
      setJumpToSectionIdNull ? null : (jumpToSectionId ?? this.jumpToSectionId),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConditionalJump &&
            runtimeType == other.runtimeType &&
            conditionValue == other.conditionValue &&
            jumpToQuestionId == other.jumpToQuestionId &&
            jumpToSectionId == other.jumpToSectionId;
  }

  @override
  int get hashCode {
    return conditionValue.hashCode ^
    jumpToQuestionId.hashCode ^
    jumpToSectionId.hashCode;
  }
}

/// Konfigurasi untuk opsi jawaban yang bergantung pada jawaban pertanyaan induk.
class DependentOptionsConfig {
  /// ID pertanyaan induk yang menentukan ketersediaan opsi ini.
  final String parentQuestionId;
  /// Pemetaan nilai jawaban induk ke daftar opsi jawaban anak yang akan ditampilkan.
  final Map<String, List<String>> optionMapping;

  DependentOptionsConfig({
    required this.parentQuestionId,
    this.optionMapping = const {},
  });

  /// Membuat instance [DependentOptionsConfig] dari Map.
  factory DependentOptionsConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return DependentOptionsConfig(
        parentQuestionId: '',
        optionMapping: {},
      );
    }

    final Map<String, List<String>> parsedMapping =
        (map['optionMapping'] as Map<String, dynamic>?)?.map(
              (key, value) {
            if (value is List) {
              return MapEntry(
                key,
                List<String>.from(
                  value.map((item) {
                    return item.toString();
                  }),
                ),
              );
            }

            return MapEntry(key, <String>[]);
          },
        ) ??
            {};

    return DependentOptionsConfig(
      parentQuestionId: map['parentQuestionId'] as String? ?? '',
      optionMapping: parsedMapping,
    );
  }

  /// Mengonversi ke format Map.
  Map<String, dynamic> toMap() {
    return {
      'parentQuestionId': parentQuestionId,
      'optionMapping': optionMapping,
    };
  }

  /// Membuat salinan objek dengan perubahan pada properti tertentu.
  DependentOptionsConfig copyWith({
    String? parentQuestionId,
    Map<String, List<String>>? optionMapping,
  }) {
    return DependentOptionsConfig(
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      optionMapping:
      optionMapping ?? Map<String, List<String>>.from(this.optionMapping),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DependentOptionsConfig &&
            runtimeType == other.runtimeType &&
            parentQuestionId == other.parentQuestionId &&
            mapEquals(optionMapping, other.optionMapping);
  }

  @override
  int get hashCode {
    return parentQuestionId.hashCode ^ _mapHashCode(optionMapping);
  }

  int _mapHashCode(Map<dynamic, dynamic> map) {
    int hash = 0;

    map.forEach((key, value) {
      hash = hash ^ key.hashCode ^ value.hashCode;
    });

    return hash;
  }
}

/// Mewakili satu opsi jawaban dalam pertanyaan bertipe pilihan (dropdown, radio, dll).
class QuestionOption {
  /// Nilai teks dari opsi jawaban.
  final String value;
  /// Deskripsi tambahan untuk opsi ini.
  final String? description;
  /// ID pertanyaan selanjutnya jika opsi ini dipilih (Legacy logic).
  final String? nextQuestionId;
  /// Daftar ID pertanyaan selanjutnya (untuk percabangan logika yang lebih kompleks).
  final List<String> nextQuestionIds;

  const QuestionOption({
    required this.value,
    this.description,
    this.nextQuestionId,
    this.nextQuestionIds = const [],
  });

  /// Membuat instance [QuestionOption] dari Map.
  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      value: map['value'] as String? ?? '',
      description: map['description'] as String?,
      nextQuestionId: map['nextQuestionId'] as String?,
      nextQuestionIds: List<String>.from(map['nextQuestionIds'] ?? []),
    );
  }

  /// Mengonversi ke format Map.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'value': value,
    };

    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (nextQuestionId != null && nextQuestionId!.isNotEmpty) {
      map['nextQuestionId'] = nextQuestionId;
    }
    if (nextQuestionIds.isNotEmpty) {
      map['nextQuestionIds'] = nextQuestionIds;
    }

    return map;
  }

  /// Membuat salinan objek dengan perubahan pada properti tertentu.
  QuestionOption copyWith({
    String? value,
    String? description,
    bool setDescriptionNull = false,
    String? nextQuestionId,
    bool setNextQuestionIdNull = false,
    List<String>? nextQuestionIds,
  }) {
    return QuestionOption(
      value: value ?? this.value,
      description: setDescriptionNull ? null : (description ?? this.description),
      nextQuestionId: setNextQuestionIdNull ? null : (nextQuestionId ?? this.nextQuestionId),
      nextQuestionIds: nextQuestionIds ?? this.nextQuestionIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionOption &&
            runtimeType == other.runtimeType &&
            value == other.value &&
            description == other.description &&
            nextQuestionId == other.nextQuestionId &&
            listEquals(nextQuestionIds, other.nextQuestionIds);
  }

  @override
  int get hashCode {
    return value.hashCode ^ 
           description.hashCode ^ 
           nextQuestionId.hashCode ^ 
           nextQuestionIds.hashCode;
  }
}

/// Mewakili satu unit pertanyaan dalam formulir.
class FormQuestion {
  /// ID unik UUID untuk pertanyaan ini.
  final String id;
  /// Teks isi pertanyaan yang ditampilkan ke pengguna.
  final String questionText;
  /// Deskripsi bantuan atau instruksi tambahan untuk pertanyaan ini.
  final String? description;
  /// Jenis masukan data (teks, angka, tanggal, dsb).
  final QuestionType type;
  /// Daftar opsi jawaban (berlaku untuk tipe pilihan).
  final List<QuestionOption> options;
  /// Menentukan apakah pertanyaan ini wajib diisi.
  final bool isRequired;
  /// Menampilkan opsi "Lainnya" pada pertanyaan bertipe pilihan ganda atau centang.
  final bool hasOtherOption;
  /// Aturan validasi masukan untuk pertanyaan ini.
  final ValidationRule validation;
  /// Logika lompatan bersyarat berdasarkan jawaban yang diberikan.
  final List<ConditionalJump> conditionalJumps;
  /// Menentukan apakah responden dapat menambahkan masukan berulang untuk pertanyaan ini.
  final bool repeatable;
  /// Jumlah maksimum pengulangan yang diperbolehkan.
  final int? repeatCount;
  /// Konfigurasi untuk opsi jawaban yang dinamis bergantung pada pertanyaan lain.
  final DependentOptionsConfig? dependentOptions;
  /// Menandakan bahwa pertanyaan angka ini bertindak sebagai penentu jumlah pengulangan untuk grup pertanyaan lain.
  final bool isRepeatableGroupController;
  /// Tag penanda untuk grup pertanyaan yang dikontrol oleh pertanyaan ini.
  final String? controlledGroupTag;
  /// Tag penanda yang menunjukkan pertanyaan ini termasuk dalam grup berulang tertentu.
  final String? belongsToGroupTag;
  /// Daftar label baris untuk pertanyaan bertipe grid.
  final List<String> gridRowLabels;
  /// Daftar label kolom untuk pertanyaan bertipe grid.
  final List<String> gridColumnLabels;
  /// Daftar label sub-kolom (jika ada) untuk pertanyaan bertipe grid.
  final List<String> gridSubColumnLabels;
  /// Menggunakan jawaban pertanyaan ini sebagai judul ringkasan data di dashboard.
  final bool useAsTitle;
  /// Menggunakan jawaban pertanyaan ini sebagai deskripsi ringkasan data di dashboard.
  final bool useAsDescription;
  /// ID pertanyaan atau seksi target lompatan otomatis setelah pertanyaan ini dijawab.
  final String? unconditionalJumpTarget;
  /// Menandakan formulir harus menghitung umur secara otomatis jika pertanyaan ini bertipe tanggal (Tanggal Lahir).
  final bool autoCalculateAge;
  /// ID pertanyaan target tempat menyimpan hasil perhitungan umur otomatis.
  final String? ageTargetQuestionId;
  /// Menandakan responden akan diklasifikasikan ke kelompok usia secara otomatis berdasarkan umur.
  final bool autoClassifyAgeGroup;
  /// ID pertanyaan yang menyimpan data jenis kelamin untuk keperluan klasifikasi usia yang akurat.
  final String? genderSourceQuestionId;
  /// Menandakan kolom input ini hanya dapat dibaca (tidak dapat diubah oleh user di lapangan).
  final bool isReadOnly;
  /// Menandakan pertanyaan ini menyimpan hasil rekapitulasi (agregasi) data otomatis.
  final bool isComputedSummary;
  /// Tipe ringkasan yang digunakan (misal: COUNT, SUM).
  final String? summaryType;
  /// Kunci pengelompokan untuk hasil rekapitulasi data.
  final String? summaryGroupKey;
  /// Menentukan pertanyaan ini hanya muncul untuk kelompok usia tertentu.
  final bool isConditionalByAgeGroup;
  /// Daftar kunci kelompok usia yang diperbolehkan melihat pertanyaan ini.
  final List<String> visibleWhenAgeGroups;
  /// Kunci pengelompokan untuk rekapitulasi bersyarat.
  final String? conditionalSummaryGroupKey;

  FormQuestion({
    required this.id,
    required this.questionText,
    this.description,
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
    this.useAsTitle = false,
    this.useAsDescription = false,
    this.unconditionalJumpTarget,
    this.autoCalculateAge = false,
    this.ageTargetQuestionId,
    this.autoClassifyAgeGroup = false,
    this.genderSourceQuestionId,
    this.isReadOnly = false,
    this.isComputedSummary = false,
    this.summaryType,
    this.summaryGroupKey,
    this.isConditionalByAgeGroup = false,
    this.visibleWhenAgeGroups = const [],
    this.conditionalSummaryGroupKey,
  }) : validation = validation ?? ValidationRule.empty();

  /// Membuat instance [FormQuestion] dari format Map (Firestore).
  factory FormQuestion.fromMap(Map<String, dynamic> map) {
    final List<dynamic>? optionsList = map['options'] as List<dynamic>?;
    List<QuestionOption> parsedOptions = [];
    if (optionsList != null) {
      parsedOptions = optionsList.map((opt) => opt is String ? QuestionOption(value: opt) : QuestionOption.fromMap(opt as Map<String, dynamic>)).toList();
    }

    return FormQuestion(
      id: map['id'] as String? ?? '',
      questionText: map['questionText'] as String? ?? 'Pertanyaan Tanpa Teks',
      description: map['description'] as String?,
      type: QuestionTypeExtension.fromString(map['type'] as String?),
      options: parsedOptions,
      isRequired: map['isRequired'] as bool? ?? false,
      hasOtherOption: map['hasOtherOption'] as bool? ?? false,
      validation: ValidationRule.fromMap(map['validation'] as Map<String, dynamic>?),
      conditionalJumps: (map['conditionalJumps'] as List<dynamic>?)?.map((j) => ConditionalJump.fromMap(j as Map<String, dynamic>)).toList() ?? [],
      repeatable: map['repeatable'] as bool? ?? false,
      repeatCount: map['repeatCount'] as int?,
      dependentOptions: map['dependentOptions'] != null ? DependentOptionsConfig.fromMap(map['dependentOptions'] as Map<String, dynamic>?) : null,
      isRepeatableGroupController: map['isRepeatableGroupController'] as bool? ?? false,
      controlledGroupTag: map['controlledGroupTag'] as String?,
      belongsToGroupTag: map['belongsToGroupTag'] as String?,
      gridRowLabels: List<String>.from(map['gridRowLabels'] ?? []),
      gridColumnLabels: List<String>.from(map['gridColumnLabels'] ?? []),
      gridSubColumnLabels: List<String>.from(map['gridSubColumnLabels'] ?? []),
      useAsTitle: map['useAsTitle'] as bool? ?? false,
      useAsDescription: map['useAsDescription'] as bool? ?? false,
      unconditionalJumpTarget: map['unconditionalJumpTarget'] as String?,
      autoCalculateAge: map['autoCalculateAge'] as bool? ?? false,
      ageTargetQuestionId: map['ageTargetQuestionId'] as String?,
      autoClassifyAgeGroup: map['autoClassifyAgeGroup'] as bool? ?? false,
      genderSourceQuestionId: map['genderSourceQuestionId'] as String?,
      isReadOnly: map['isReadOnly'] as bool? ?? false,
      isComputedSummary: map['isComputedSummary'] as bool? ?? false,
      summaryType: map['summaryType'] as String?,
      summaryGroupKey: map['summaryGroupKey'] as String?,
      isConditionalByAgeGroup: map['isConditionalByAgeGroup'] as bool? ?? false,
      visibleWhenAgeGroups: List<String>.from(map['visibleWhenAgeGroups'] ?? []),
      conditionalSummaryGroupKey: map['conditionalSummaryGroupKey'] as String?,
    );
  }

  /// Mengonversi objek [FormQuestion] ke dalam format Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      if (description?.isNotEmpty == true) 'description': description,
      'type': type.toShortString(),
      'options': options.map((option) => option.toMap()).toList(),
      'isRequired': isRequired,
      'hasOtherOption': hasOtherOption,
      if (!validation.isEffectivelyEmpty) 'validation': validation.toMap(),
      'conditionalJumps': conditionalJumps.map((jump) => jump.toMap()).toList(),
      'repeatable': repeatable,
      'isRepeatableGroupController': isRepeatableGroupController,
      'gridRowLabels': gridRowLabels,
      'gridColumnLabels': gridColumnLabels,
      'gridSubColumnLabels': gridSubColumnLabels,
      'useAsTitle': useAsTitle,
      'useAsDescription': useAsDescription,
      if (unconditionalJumpTarget?.isNotEmpty == true) 'unconditionalJumpTarget': unconditionalJumpTarget,
      'autoCalculateAge': autoCalculateAge,
      if (ageTargetQuestionId != null) 'ageTargetQuestionId': ageTargetQuestionId,
      'autoClassifyAgeGroup': autoClassifyAgeGroup,
      if (genderSourceQuestionId != null) 'genderSourceQuestionId': genderSourceQuestionId,
      'isReadOnly': isReadOnly,
      'isComputedSummary': isComputedSummary,
      if (summaryType != null) 'summaryType': summaryType,
      if (summaryGroupKey != null) 'summaryGroupKey': summaryGroupKey,
      'isConditionalByAgeGroup': isConditionalByAgeGroup,
      'visibleWhenAgeGroups': visibleWhenAgeGroups,
      if (conditionalSummaryGroupKey != null) 'conditionalSummaryGroupKey': conditionalSummaryGroupKey,
      if (repeatCount != null) 'repeatCount': repeatCount,
      if (dependentOptions != null) 'dependentOptions': dependentOptions!.toMap(),
      if (controlledGroupTag != null) 'controlledGroupTag': controlledGroupTag,
      if (belongsToGroupTag != null) 'belongsToGroupTag': belongsToGroupTag,
    };
  }

  /// Membuat salinan objek [FormQuestion] dengan perubahan pada properti tertentu.
  FormQuestion copyWith({
    String? id,
    String? questionText,
    String? description,
    bool setDescriptionNull = false,
    QuestionType? type,
    List<QuestionOption>? options,
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
    List<String>? gridRowLabels,
    List<String>? gridColumnLabels,
    List<String>? gridSubColumnLabels,
    bool? useAsTitle,
    bool? useAsDescription,
    String? unconditionalJumpTarget,
    bool setUnconditionalJumpTargetNull = false,
    bool? autoCalculateAge,
    String? ageTargetQuestionId,
    bool setAgeTargetQuestionIdNull = false,
    bool? autoClassifyAgeGroup,
    String? genderSourceQuestionId,
    bool setGenderSourceQuestionIdNull = false,
    bool? isReadOnly,
    bool? isComputedSummary,
    String? summaryType,
    bool setSummaryTypeNull = false,
    String? summaryGroupKey,
    bool setSummaryGroupKeyNull = false,
    bool? isConditionalByAgeGroup,
    List<String>? visibleWhenAgeGroups,
    String? conditionalSummaryGroupKey,
    bool setConditionalSummaryGroupKeyNull = false,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      description: setDescriptionNull ? null : (description ?? this.description),
      type: type ?? this.type,
      options: options ?? List<QuestionOption>.from(this.options),
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
      useAsTitle: useAsTitle ?? this.useAsTitle,
      useAsDescription: useAsDescription ?? this.useAsDescription,
      unconditionalJumpTarget: setUnconditionalJumpTargetNull ? null : (unconditionalJumpTarget ?? this.unconditionalJumpTarget),
      autoCalculateAge: autoCalculateAge ?? this.autoCalculateAge,
      ageTargetQuestionId: setAgeTargetQuestionIdNull ? null : (ageTargetQuestionId ?? this.ageTargetQuestionId),
      autoClassifyAgeGroup: autoClassifyAgeGroup ?? this.autoClassifyAgeGroup,
      genderSourceQuestionId: setGenderSourceQuestionIdNull ? null : (genderSourceQuestionId ?? this.genderSourceQuestionId),
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isComputedSummary: isComputedSummary ?? this.isComputedSummary,
      summaryType: setSummaryTypeNull ? null : (summaryType ?? this.summaryType),
      summaryGroupKey: setSummaryGroupKeyNull ? null : (summaryGroupKey ?? this.summaryGroupKey),
      isConditionalByAgeGroup: isConditionalByAgeGroup ?? this.isConditionalByAgeGroup,
      visibleWhenAgeGroups: visibleWhenAgeGroups ?? List<String>.from(this.visibleWhenAgeGroups),
      conditionalSummaryGroupKey: setConditionalSummaryGroupKeyNull ? null : (conditionalSummaryGroupKey ?? this.conditionalSummaryGroupKey),
    );
  }
}

/// Mewakili satu bagian (seksi) dalam formulir yang mengelompokkan beberapa pertanyaan.
class FormSection {
  /// ID unik seksi.
  final String id;
  /// Judul seksi yang ditampilkan ke pengguna.
  final String title;
  /// Deskripsi atau instruksi tambahan untuk seksi ini.
  final String? description;
  /// Daftar pertanyaan yang ada di dalam seksi ini.
  final List<FormQuestion> questions;
  /// Menandakan seksi ini dapat diulang oleh responden.
  final bool isRepeatable;
  /// ID pertanyaan yang menentukan jumlah pengulangan seksi ini.
  final String? repeatTriggerQuestionId;
  /// Jumlah pengulangan minimum untuk seksi ini.
  final int? minRepeats;
  /// Jumlah pengulangan maksimum untuk seksi ini.
  final int? maxRepeats;

  FormSection({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
    this.isRepeatable = false,
    this.repeatTriggerQuestionId,
    this.minRepeats,
    this.maxRepeats,
  });

  /// Membuat instance [FormSection] dari format Map (Firestore).
  factory FormSection.fromMap(Map<String, dynamic> map) {
    return FormSection(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      questions: (map['questions'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((questionMap) {
        return FormQuestion.fromMap(questionMap);
      })
          .toList() ??
          [],
      isRepeatable: map['isRepeatable'] as bool? ?? false,
      repeatTriggerQuestionId: map['repeatTriggerQuestionId'] as String?,
      minRepeats: map['minRepeats'] as int?,
      maxRepeats: map['maxRepeats'] as int?,
    );
  }

  /// Mengonversi objek [FormSection] ke format Map untuk Firestore.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'title': title,
      'questions': questions.map((question) {
        return question.toMap();
      }).toList(),
      'isRepeatable': isRepeatable,
    };

    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }

    if (isRepeatable) {
      if (repeatTriggerQuestionId != null &&
          repeatTriggerQuestionId!.isNotEmpty) {
        map['repeatTriggerQuestionId'] = repeatTriggerQuestionId;
      }

      if (minRepeats != null) {
        map['minRepeats'] = minRepeats;
      }

      if (maxRepeats != null) {
        map['maxRepeats'] = maxRepeats;
      }
    }

    return map;
  }

  /// Membuat salinan objek [FormSection] dengan perubahan pada properti tertentu.
  FormSection copyWith({
    String? id,
    String? title,
    String? description,
    bool setDescriptionNull = false,
    List<FormQuestion>? questions,
    bool? isRepeatable,
    String? repeatTriggerQuestionId,
    bool setRepeatTriggerQuestionIdNull = false,
    int? minRepeats,
    bool setMinRepeatsNull = false,
    int? maxRepeats,
    bool setMaxRepeatsNull = false,
  }) {
    return FormSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: setDescriptionNull ? null : (description ?? this.description),
      questions: questions ?? List<FormQuestion>.from(this.questions),
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatTriggerQuestionId: setRepeatTriggerQuestionIdNull
          ? null
          : (repeatTriggerQuestionId ?? this.repeatTriggerQuestionId),
      minRepeats: setMinRepeatsNull ? null : (minRepeats ?? this.minRepeats),
      maxRepeats: setMaxRepeatsNull ? null : (maxRepeats ?? this.maxRepeats),
    );
  }

  /// Membersihkan daftar pertanyaan dari item yang tidak memiliki teks sebelum disimpan.
  FormSection cleanUpQuestionsBeforeSave() {
    final List<FormQuestion> validQuestions = questions.where((question) {
      return question.questionText.trim().isNotEmpty;
    }).toList();

    return copyWith(questions: validQuestions);
  }
}

/// Mendefinisikan konfigurasi kelompok usia penduduk untuk proses klasifikasi otomatis.
class AgeGroupConfig {
  /// ID unik untuk kriteria kelompok usia ini.
  final String id;
  /// Kunci pengenal unik (misal: 'balita', 'lansia').
  final String key;
  /// Label tampilan untuk kelompok usia (misal: 'Balita (0-5 Thn)').
  final String label;
  /// Usia minimum dalam tahun.
  final int minAge;
  /// Usia maksimum dalam tahun.
  final int maxAge;
  /// Filter berdasarkan jenis kelamin ('Semua', 'Laki-laki', 'Perempuan').
  final String gender;
  /// ID pertanyaan tambahan yang bertindak sebagai pemicu kondisi kelompok ini.
  final String? triggerQuestionId;
  /// Nilai jawaban dari pertanyaan pemicu yang harus terpenuhi.
  final String? triggerAnswerValue;

  AgeGroupConfig({
    required this.id,
    required this.key,
    required this.label,
    required this.minAge,
    required this.maxAge,
    this.gender = 'Semua',
    this.triggerQuestionId,
    this.triggerAnswerValue,
  });

  /// Membuat instance [AgeGroupConfig] dari format Map (Firestore).
  factory AgeGroupConfig.fromMap(Map<String, dynamic> map) {
    return AgeGroupConfig(
      id: map['id'] as String? ?? (map['key'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      key: map['key'] as String? ?? '',
      label: map['label'] as String? ?? '',
      minAge: map['minAge'] as int? ?? 0,
      maxAge: map['maxAge'] as int? ?? 100,
      gender: map['gender'] as String? ?? 'Semua',
      triggerQuestionId: map['triggerQuestionId'] as String?,
      triggerAnswerValue: map['triggerAnswerValue'] as String?,
    );
  }

  /// Mengonversi objek [AgeGroupConfig] ke format Map untuk Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'label': label,
      'minAge': minAge,
      'maxAge': maxAge,
      'gender': gender,
      if (triggerQuestionId != null) 'triggerQuestionId': triggerQuestionId,
      if (triggerAnswerValue != null) 'triggerAnswerValue': triggerAnswerValue,
    };
  }

  /// Membuat salinan objek [AgeGroupConfig] dengan perubahan pada properti tertentu.
  AgeGroupConfig copyWith({
    String? id,
    String? key,
    String? label,
    int? minAge,
    int? maxAge,
    String? gender,
    String? triggerQuestionId,
    bool setTriggerQuestionIdNull = false,
    String? triggerAnswerValue,
    bool setTriggerAnswerValueNull = false,
  }) {
    return AgeGroupConfig(
      id: id ?? this.id,
      key: key ?? this.key,
      label: label ?? this.label,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: gender ?? this.gender,
      triggerQuestionId: setTriggerQuestionIdNull ? null : (triggerQuestionId ?? this.triggerQuestionId),
      triggerAnswerValue: setTriggerAnswerValueNull ? null : (triggerAnswerValue ?? this.triggerAnswerValue),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AgeGroupConfig &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            key == other.key &&
            label == other.label &&
            minAge == other.minAge &&
            maxAge == other.maxAge &&
            gender == other.gender &&
            triggerQuestionId == other.triggerQuestionId &&
            triggerAnswerValue == other.triggerAnswerValue;
  }

  @override
  int get hashCode {
    return id.hashCode ^ key.hashCode ^ label.hashCode ^ minAge.hashCode ^ maxAge.hashCode ^ gender.hashCode ^ triggerQuestionId.hashCode ^ triggerAnswerValue.hashCode;
  }
}

/// Mewakili satu dokumen formulir pendataan lengkap.
class FormItem {
  /// ID dokumen unik di Firestore.
  final String id;
  /// Judul utama formulir.
  final String title;
  /// Deskripsi atau petunjuk singkat mengenai formulir ini.
  final String description;
  /// Periode berlakunya formulir (format YYYY-MM).
  final String? period;
  /// ID Desa asal formulir (null jika formulir bersifat umum untuk semua desa).
  final String? villageId;
  /// Nama Desa asal formulir.
  final String? villageName;
  /// Tanggal formulir dibuat.
  final DateTime createdAt;
  /// Tanggal terakhir formulir diperbarui.
  final DateTime? updatedAt;
  /// ID user yang membuat formulir ini.
  final String createdByUserId;
  /// Daftar seksi (sections) yang ada di dalam formulir ini.
  final List<FormSection> sections;
  /// Nomor versi formulir.
  final String? formVersion;

  /// Fitur: Duplikasi otomatis formulir setiap bulan.
  final bool autoDuplicateMonthly;
  /// Fitur: Mengunci entri periode sebelumnya agar tidak dapat diubah lagi.
  final bool lockPreviousPeriod;
  /// Sumber data dari mana formulir ini diduplikasi.
  final String? duplicateSource;

  /// Daftar aturan kelompok usia yang berlaku pada formulir ini.
  final List<AgeGroupConfig> ageGroups;

  FormItem({
    required this.id,
    required this.title,
    required this.description,
    this.period,
    this.villageId,
    this.villageName,
    required this.createdAt,
    this.updatedAt,
    required this.createdByUserId,
    this.sections = const [],
    this.formVersion = '1.0',
    this.autoDuplicateMonthly = false,
    this.lockPreviousPeriod = true,
    this.duplicateSource = 'previous_period',
    this.ageGroups = const [],
  });

  /// Digunakan untuk halaman detail/edit (Membaca seluruh struktur formulir termasuk pertanyaan).
  factory FormItem.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>? ?? {};

    return FormItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      description: data['description'] as String? ?? '',
      period: data['period'] as String?,
      villageId: data['villageId'] as String?,
      villageName: data['villageName'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseNullableDateTime(data['updatedAt']),
      createdByUserId: data['createdByUserId'] as String? ?? 'unknown',
      sections: (data['sections'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((sectionMap) {
        return FormSection.fromMap(sectionMap);
      })
          .toList() ??
          [],
      formVersion: data['formVersion'] as String? ?? '1.0',
      autoDuplicateMonthly: data['autoDuplicateMonthly'] as bool? ?? false,
      lockPreviousPeriod: data['lockPreviousPeriod'] as bool? ?? true,
      duplicateSource: data['duplicateSource'] as String? ?? 'previous_period',
      ageGroups: (data['ageGroups'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((ageGroupMap) => AgeGroupConfig.fromMap(ageGroupMap))
          .toList() ?? [],
    );
  }

  /// Digunakan untuk halaman daftar formulir (Lebih ringan karena tidak membaca daftar pertanyaan).
  factory FormItem.fromFirestoreSummary(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>? ?? {};

    return FormItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      description: data['description'] as String? ?? '',
      period: data['period'] as String?,
      villageId: data['villageId'] as String?,
      villageName: data['villageName'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseNullableDateTime(data['updatedAt']),
      createdByUserId: data['createdByUserId'] as String? ?? 'unknown',
      sections: const [],
      formVersion: data['formVersion'] as String? ?? '1.0',
      autoDuplicateMonthly: data['autoDuplicateMonthly'] as bool? ?? false,
      lockPreviousPeriod: data['lockPreviousPeriod'] as bool? ?? true,
      duplicateSource: data['duplicateSource'] as String? ?? 'previous_period',
      ageGroups: (data['ageGroups'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((ageGroupMap) => AgeGroupConfig.fromMap(ageGroupMap))
          .toList() ?? [],
    );
  }

  /// Mengonversi objek [FormItem] ke format Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      if (period != null) 'period': period,
      if (villageId != null) 'villageId': villageId,
      if (villageName != null) 'villageName': villageName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByUserId': createdByUserId,
      'sections': sections.map((section) {
        return section.toMap();
      }).toList(),
      'formVersion': formVersion,
      'autoDuplicateMonthly': autoDuplicateMonthly,
      'lockPreviousPeriod': lockPreviousPeriod,
      'duplicateSource': duplicateSource,
      'ageGroups': ageGroups.map((group) => group.toMap()).toList(),
    };
  }

  /// Helper internal untuk memproses nilai masukan waktu dari Firestore.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  /// Helper internal untuk memproses nilai masukan waktu dari Firestore yang bisa null.
  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
