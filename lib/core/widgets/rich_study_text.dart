import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';
import 'stabilo_mark.dart';

/// Komponen perender teks pintar untuk kartu, catatan, dan layar Cek Hasil (Bagian 6.4 & 12 PRD, Bagian 4 & 12 design.md):
/// - Merender blok rumus LaTeX di antara `$...$` atau `$$...$$` memakai `flutter_math_fork`.
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
  static final RegExp _latexTokenRegex = RegExp(r'(\$\$[\s\S]+?\$\$|\$[^\$]+?\$)');

  static bool containsArabic(String input) => _arabicRegex.hasMatch(input);

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

    // Jika tidak ada LaTeX dan tidak ada bagian stabilo, render langsung dengan Directionality yang tepat
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

    // Pecah berdasarkan token LaTeX `$...$`
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
      final cleanFormula = rawFormula.startsWith('$\$')
          ? rawFormula.substring(2, rawFormula.length - 2).trim()
          : rawFormula.substring(1, rawFormula.length - 1).trim();

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Math.tex(
              cleanFormula,
              textStyle: effectiveStyle,
              onErrorFallback: (err) => Text(
                rawFormula,
                style: effectiveStyle.copyWith(color: palette.penRed),
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
