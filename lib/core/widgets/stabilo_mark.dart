import 'package:flutter/material.dart';
import '../theme/ts_palette.dart';

/// Komponen kunci `StabiloMark` sesuai Bagian 3, 7.3, 8, dan 9 `design.md`:
/// - Sapuan stabilo di bawah atau belakang teks: opasitas 25% di Malam dan 70% di Siang.
/// - Dipakai untuk penanda penting (`isActive`) dan bagian ragu hasil scan (`isLowConfidence`, ditambah garis putus-putus).
/// - Momen gerak khas: sapuan stabilo (~350 ms) saat menandai penting, atau fade 120 ms bila sistem mengaktifkan "kurangi animasi".
class StabiloMark extends StatelessWidget {
  const StabiloMark({
    super.key,
    required this.child,
    this.isActive = true,
    this.isLowConfidence = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  final Widget child;
  final bool isActive;
  final bool isLowConfidence;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration duration = reduceMotion
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 350);

    final Color highlightColor = palette.stabilo.withValues(
      alpha: palette.stabiloHighlightOpacity,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isActive ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, animatedChild) {
        return CustomPaint(
          painter: _StabiloSweepPainter(
            color: highlightColor,
            borderColor: palette.stabilo,
            progress: progress,
            reduceMotion: reduceMotion,
            dashedUnderline: isLowConfidence,
          ),
          child: Padding(
            padding: padding,
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _StabiloSweepPainter extends CustomPainter {
  const _StabiloSweepPainter({
    required this.color,
    required this.borderColor,
    required this.progress,
    required this.reduceMotion,
    required this.dashedUnderline,
  });

  final Color color;
  final Color borderColor;
  final double progress;
  final bool reduceMotion;
  final bool dashedUnderline;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final Paint fillPaint = Paint()
      ..color = reduceMotion ? color.withValues(alpha: color.a * progress) : color
      ..style = PaintingStyle.fill;

    final double sweepWidth = reduceMotion ? size.width : size.width * progress;
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 2, sweepWidth, (size.height - 4).clamp(0.0, size.height)),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, fillPaint);

    // Garis putus-putus di bawah untuk bagian ragu hasil scan (Bagian 7.3 design.md)
    if (dashedUnderline && progress > 0.5) {
      final Paint dashPaint = Paint()
        ..color = borderColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      const double dashWidth = 4.0;
      const double dashSpace = 3.0;
      double startX = 0;
      final double y = size.height - 1;
      while (startX < sweepWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashWidth).clamp(0.0, sweepWidth), y),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StabiloSweepPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.dashedUnderline != dashedUnderline;
  }
}
