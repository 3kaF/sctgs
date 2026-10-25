import 'dart:convert';
import '../../core/widgets/verdict_tag.dart';

/// Item soal hasil bacaan `scan_task` (Bagian 8 PRD).
class ScannedQuestionItem {
  const ScannedQuestionItem({
    required this.question,
    required this.userAnswer,
    required this.confidence,
    this.lowConfidenceParts = const [],
  });

  final String question;
  final String userAnswer;
  final double confidence;
  final List<String> lowConfidenceParts;

  factory ScannedQuestionItem.fromJson(Map<String, dynamic> json) {
    final rawLowParts = json['low_confidence_parts'];
    return ScannedQuestionItem(
      question: (json['question'] as String? ?? '').trim(),
      userAnswer: (json['user_answer'] as String? ?? '').trim(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      lowConfidenceParts: rawLowParts is List
          ? rawLowParts.map((e) => e.toString()).toList()
          : const [],
    );
  }

  ScannedQuestionItem copyWith({
    String? question,
    String? userAnswer,
    double? confidence,
    List<String>? lowConfidenceParts,
  }) {
    return ScannedQuestionItem(
      question: question ?? this.question,
      userAnswer: userAnswer ?? this.userAnswer,
      confidence: confidence ?? this.confidence,
      lowConfidenceParts: lowConfidenceParts ?? this.lowConfidenceParts,
    );
  }
}

/// Hasil `classify_and_grade` (Bagian 6.3 & 8 PRD).
class GradeClassificationResult {
  const GradeClassificationResult({
    required this.subject,
    required this.topic,
    required this.questionType,
    required this.difficulty,
    required this.verdict,
    required this.confidence,
    this.mistakeStep,
  });

  final String subject;
  final String topic;
  final String questionType;
  final int difficulty;
  final TaskVerdict verdict;
  final double confidence;
  final String? mistakeStep;

  bool get needsSubjectConfirmation => confidence < 0.6;

  factory GradeClassificationResult.fromJson(Map<String, dynamic> json) {
    return GradeClassificationResult(
      subject: (json['subject'] as String? ?? 'umum').trim().toLowerCase(),
      topic: (json['topic'] as String? ?? 'Umum').trim(),
      questionType: (json['question_type'] as String? ?? 'hitungan')
          .trim()
          .toLowerCase(),
      difficulty: ((json['difficulty'] as num?)?.toInt() ?? 2).clamp(1, 5),
      verdict: TaskVerdict.fromCode(json['verdict'] as String?),
      mistakeStep: json['mistake_step'] as String?,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.8).clamp(
        0.0,
        1.0,
      ),
    );
  }

  GradeClassificationResult copyWith({
    TaskVerdict? verdict,
    String? mistakeStep,
    double? confidence,
  }) {
    return GradeClassificationResult(
      subject: subject,
      topic: topic,
      questionType: questionType,
      difficulty: difficulty,
      verdict: verdict ?? this.verdict,
      confidence: confidence ?? this.confidence,
      mistakeStep: mistakeStep ?? this.mistakeStep,
    );
  }
}

/// Parser JSON ketat + Verifikasi Silang (Bagian 6.3, 6.4, dan 8 PRD).
///
/// Aturan Guardrail:
/// 1. Semua keluaran AI dipaksa berformat JSON dan divalidasi skema sebelum disimpan.
/// 2. Soal uraian dan hafalan (terutama Pendidikan Agama) tidak boleh diberi vonis mutlak salah/benar jika meragukan; fokus pada saran kelengkapan.
/// 3. Soal hitungan (Matematika, Fisika, Kimia) diverifikasi silang dengan evaluator ekspresi numerik & kesetimbangan persamaan reaksi kimia sederhana.
///    Bila hasil verifikasi silang berbeda dengan AI, verdict otomatis menjadi `unsure` (`Belum yakin`).
class AiCrossVerifier {
  const AiCrossVerifier._();

  /// Parsing JSON keluaran `scan_task`.
  static List<ScannedQuestionItem> parseScanResponse(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respons scan_task bukan objek JSON valid.');
    }
    final items = decoded['items'];
    if (items is! List) {
      throw const FormatException('Field "items" tidak ditemukan pada respons.');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(ScannedQuestionItem.fromJson)
        .where((item) => item.question.isNotEmpty)
        .toList();
  }

  /// Memvalidasi dan memverifikasi silang hasil `classify_and_grade`.
  static GradeClassificationResult verifyGradeResult({
    required GradeClassificationResult aiResult,
    required String questionText,
    required String userAnswerText,
  }) {
    // Guardrail 1: untuk uraian dan hafalan, jangan pernah memberi vonis mutlak jika confidence < 0.85
    if (aiResult.questionType == 'uraian' ||
        aiResult.questionType == 'hafalan') {
      if (aiResult.verdict == TaskVerdict.wrong) {
        return aiResult.copyWith(verdict: TaskVerdict.partial);
      }
    }

    // Guardrail 2: Verifikasi silang persamaan numerik sederhana (mis. "2 + 3 = 5" atau nilai akhir di jawaban)
    if (aiResult.questionType == 'hitungan') {
      final bool? numericCheck = verifySimpleEquationInAnswer(userAnswerText);
      if (numericCheck != null) {
        final bool aiSaysCorrect = aiResult.verdict == TaskVerdict.correct;
        if (numericCheck != aiSaysCorrect) {
          // Bila hasil verifikasi silang beda dari AI, verdict wajib menjadi `unsure` (Belum yakin)
          return aiResult.copyWith(verdict: TaskVerdict.unsure);
        }
      }

      // Guardrail 3: Untuk Kimia, cek kesetimbangan atom sederhana jika berupa persamaan reaksi `->` atau `→`
      if (aiResult.subject.contains('kimia') &&
          (userAnswerText.contains('->') || userAnswerText.contains('→'))) {
        final bool? balanced = verifyChemicalEquationBalance(userAnswerText);
        if (balanced != null) {
          final bool aiSaysCorrect = aiResult.verdict == TaskVerdict.correct;
          if (balanced != aiSaysCorrect) {
            return aiResult.copyWith(verdict: TaskVerdict.unsure);
          }
        }
      }
    }

    return aiResult;
  }

  /// Mengecek apakah persamaan aritmetika dasar `LHS = RHS` di baris terakhir jawaban bernilai benar.
  /// Mengembalikan `null` jika jawaban mengandung variabel aljabar (mis. `x`) yang tidak bisa dievaluasi langsung sebagai angka murni.
  static bool? verifySimpleEquationInAnswer(String answerText) {
    final clean = answerText.replaceAll('\$', '').trim();
    if (!clean.contains('=')) return null;

    // Jika mengandung huruf variabel (selain spasi, angka, operator dasar), lewati ke verifikasi simbolik/AI
    final parts = clean.split('=');
    if (parts.length < 2) return null;

    final lhsRaw = parts[parts.length - 2].trim();
    final rhsRaw = parts.last.trim();

    final lhsVal = _evaluatePureArithmetic(lhsRaw);
    final rhsVal = _evaluatePureArithmetic(rhsRaw);
    if (lhsVal == null || rhsVal == null) return null;

    return (lhsVal - rhsVal).abs() < 1e-6;
  }

  static double? _evaluatePureArithmetic(String expr) {
    final normalized = expr.replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-*/.]+$').hasMatch(normalized)) return null;

    try {
      // Evaluasi penjumlahan/pengurangan dari suku perkalian/pembagian
      final tokens = <String>[];
      final buffer = StringBuffer();
      for (int i = 0; i < normalized.length; i++) {
        final ch = normalized[i];
        if ((ch == '+' || ch == '-') && i > 0) {
          tokens.add(buffer.toString());
          tokens.add(ch);
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
      if (buffer.isNotEmpty) tokens.add(buffer.toString());

      double total = _evalMulDiv(tokens.first);
      for (int i = 1; i < tokens.length - 1; i += 2) {
        final op = tokens[i];
        final val = _evalMulDiv(tokens[i + 1]);
        if (op == '+') {
          total += val;
        } else {
          total -= val;
        }
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  static double _evalMulDiv(String term) {
    if (term.contains('*')) {
      return term
          .split('*')
          .map(double.parse)
          .reduce((a, b) => a * b);
    }
    if (term.contains('/')) {
      return term
          .split('/')
          .map(double.parse)
          .reduce((a, b) => a / b);
    }
    return double.parse(term);
  }

  /// Mengecek kesetimbangan jumlah atom kiri & kanan untuk reaksi kimia sederhana,
  /// contoh: `2H2 + O2 -> 2H2O`.
  static bool? verifyChemicalEquationBalance(String reaction) {
    final normalized = reaction
        .replaceAll('→', '->')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('₄', '4');
    final sides = normalized.split('->');
    if (sides.length != 2) return null;

    final leftAtoms = _countAtomsInSide(sides[0]);
    final rightAtoms = _countAtomsInSide(sides[1]);
    if (leftAtoms.isEmpty || rightAtoms.isEmpty) return null;
    if (leftAtoms.length != rightAtoms.length) return false;

    for (final entry in leftAtoms.entries) {
      if (rightAtoms[entry.key] != entry.value) return false;
    }
    return true;
  }

  static Map<String, int> _countAtomsInSide(String side) {
    final Map<String, int> counts = {};
    final speciesList = side.split('+');
    final coeffRegex = RegExp(r'^(\d+)?([A-Za-z0-9]+)$');
    final elementRegex = RegExp(r'([A-Z][a-z]?)(\d*)');

    for (final rawSpecies in speciesList) {
      final species = rawSpecies.trim();
      final match = coeffRegex.firstMatch(species);
      if (match == null) continue;
      final int coeff = int.tryParse(match.group(1) ?? '1') ?? 1;
      final String formula = match.group(2) ?? '';

      for (final elemMatch in elementRegex.allMatches(formula)) {
        final String elem = elemMatch.group(1)!;
        final int sub = int.tryParse(elemMatch.group(2) ?? '1') ?? 1;
        counts[elem] = (counts[elem] ?? 0) + coeff * sub;
      }
    }
    return counts;
  }
}
