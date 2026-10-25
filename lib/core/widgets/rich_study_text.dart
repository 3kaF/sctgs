import 'package:flutter/material.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';
import 'stabilo_mark.dart';

/// Komponen perender teks pintar untuk kartu, catatan, dan layar Cek Hasil (Bagian 6.4 & 12 PRD, Bagian 4 & 12 design.md):
/// - Merender blok rumus LaTeX di antara `$...$` atau `$$...$$` menjadi tampilan simbolik matematika/kimia yang bersih
///   (pangkat superscript, indeks kimia subscript, pecahan, integral, panah reaksi, dsb.) tanpa bergantung pada paket render eksternal yang usang.
/// - Mendeteksi paragraf bertulisan Arab (Unicode 0600–06FF) dan merendernya dengan `NotoNaskhArabic` (24/42, kanan-ke-kiri / RTL).
/// - Menandai potongan teks yang ada di `lowConfidenceParts` atau `highlightedParts` dengan `StabiloMark`.
class RichStudyText extends StatelessWidget {
  const RichStudyText({
    super.key,
    required this.text,
    this.style,
    this.lowConfidenceParts = const [],
    this.highlightedParts = const [],
    this.dyslexiaFriendly = false,
  });

  final String text;
  final TextStyle? style;
  final List<String> lowConfidenceParts;
  final List<String> highlightedParts;
  final bool dyslexiaFriendly;

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _latexTokenRegex = RegExp(
    r'(\$\$[\s\S]+?\$\$|\$[^\$]+?\$)',
  );

  static bool containsArabic(String input) => _arabicRegex.hasMatch(input);

  /// Mengubah sintaks LaTeX umum (`\frac{a}{b}`, `x^2`, `\text{H}_2\text{O}`, `\rightarrow`, `\int`)
  /// menjadi notasi tipografi matematika/kimia Unicode yang rapi dan ringan (60 fps).
  static String formatLatexToReadableMath(String rawLatex) {
    String s = rawLatex.trim();

    // Hapus \text{...} -> isi di dalamnya
    s = s.replaceAllMapped(
      RegExp(r'\\text\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );

    // Pecahan \frac{a}{b} -> (a)/(b) atau a/b
    s = s.replaceAllMapped(
      RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
      (m) => '${m.group(1)}/${m.group(2)}',
    );

    // Integral \int_a^b -> ∫ₐᵇ
    s = s.replaceAll(r'\int_0^2', '∫₀²');
    s = s.replaceAll(r'\int', '∫');

    // Simbol operator & panah kimia/matematika
    s = s
        .replaceAll(r'\rightarrow', '→')
        .replaceAll(r'\leftarrow', '←')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\Sigma', 'Σ')
        .replaceAll(r'\dots', '…')
        .replaceAll(r'\,', ' ');

    // Superscript pangkat ^{...} atau ^n
    const Map<String, String> supMap = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
      'n': 'ⁿ',
    };
    s = s.replaceAllMapped(RegExp(r'\^\{([^}]*)\}'), (m) {
      final inner = m.group(1) ?? '';
      return inner.split('').map((c) => supMap[c] ?? c).join();
    });
    s = s.replaceAllMapped(RegExp(r'\^([0-9n+\-])'), (m) {
      final ch = m.group(1)!;
      return supMap[ch] ?? '^$ch';
    });

    // Subscript kimia/indeks _{...} atau _n
    const Map<String, String> subMap = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };
    s = s.replaceAllMapped(RegExp(r'_\{([^}]*)\}'), (m) {
      final inner = m.group(1) ?? '';
      return inner.split('').map((c) => subMap[c] ?? c).join();
    });
    s = s.replaceAllMapped(RegExp(r'_([0-9])'), (m) {
      final ch = m.group(1)!;
      return subMap[ch] ?? '_$ch';
    });

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final TextStyle defaultStyle =
        style ??
        TsTypography.cardQuestion(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        );

    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildLine(context, lines[i], defaultStyle, palette),
        ],
      ],
    );
  }

  Widget _buildLine(
    BuildContext context,
    String line,
    TextStyle baseStyle,
    TsPalette palette,
  ) {
    final bool isRtlLine = containsArabic(line);
    final TextStyle effectiveStyle = isRtlLine
        ? TsTypography.arabicCardText(palette)
        : baseStyle;

    final bool hasLatex = _latexTokenRegex.hasMatch(line);
    final bool hasLowConfidence = lowConfidenceParts.any(
      (part) => part.isNotEmpty && line.contains(part),
    );
    final bool hasHighlight = highlightedParts.any(
      (part) => part.isNotEmpty && line.contains(part),
    );

    if (!hasLatex && !hasLowConfidence && !hasHighlight) {
      return Directionality(
        textDirection: isRtlLine ? TextDirection.rtl : TextDirection.ltr,
        child: Text(
          line,
          style: effectiveStyle,
          textAlign: isRtlLine ? TextAlign.right : TextAlign.left,
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final match in _latexTokenRegex.allMatches(line)) {
      if (match.start > currentIndex) {
        final plainSegment = line.substring(currentIndex, match.start);
        spans.addAll(
          _buildPlainOrHighlightedSpans(plainSegment, effectiveStyle),
        );
      }

      final rawFormula = match.group(0)!;
      final cleanFormula = rawFormula.startsWith(r'$$')
          ? rawFormula.substring(2, rawFormula.length - 2).trim()
          : rawFormula.substring(1, rawFormula.length - 1).trim();
      final formattedMath = formatLatexToReadableMath(cleanFormula);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: palette.raised.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formattedMath,
              style: effectiveStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < line.length) {
      spans.addAll(
        _buildPlainOrHighlightedSpans(
          line.substring(currentIndex),
          effectiveStyle,
        ),
      );
    }

    return Directionality(
      textDirection: isRtlLine ? TextDirection.rtl : TextDirection.ltr,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: isRtlLine ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  List<InlineSpan> _buildPlainOrHighlightedSpans(
    String segment,
    TextStyle effectiveStyle,
  ) {
    for (final part in lowConfidenceParts) {
      if (part.isNotEmpty && segment.contains(part)) {
        final idx = segment.indexOf(part);
        return [
          if (idx > 0)
            TextSpan(text: segment.substring(0, idx), style: effectiveStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StabiloMark(
              isLowConfidence: true,
              child: Text(part, style: effectiveStyle),
            ),
          ),
          if (idx + part.length < segment.length)
            TextSpan(
              text: segment.substring(idx + part.length),
              style: effectiveStyle,
            ),
        ];
      }
    }

    for (final part in highlightedParts) {
      if (part.isNotEmpty && segment.contains(part)) {
        final idx = segment.indexOf(part);
        return [
          if (idx > 0)
            TextSpan(text: segment.substring(0, idx), style: effectiveStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StabiloMark(
              child: Text(part, style: effectiveStyle),
            ),
          ),
          if (idx + part.length < segment.length)
            TextSpan(
              text: segment.substring(idx + part.length),
              style: effectiveStyle,
            ),
        ];
      }
    }

    return [TextSpan(text: segment, style: effectiveStyle)];
  }
}
