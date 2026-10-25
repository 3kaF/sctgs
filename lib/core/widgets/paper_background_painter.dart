import 'package:flutter/material.dart';
import '../theme/ts_palette.dart';

/// CustomPainter ringan untuk menggambar permukaan halaman buku tulis (Bagian 5 & 14 design.md):
/// - Kertas kotak-kotak (`PaperPattern.grid`): garis 24 dp, opasitas ~6% (untuk mapel hitungan).
/// - Kertas bergaris (`PaperPattern.ruled`): garis horizontal setiap 28 dp (untuk Catatan & Bahasa).
/// - Polos (`PaperPattern.plain`): hanya garis margin vertikal.
/// - Garis margin: satu garis vertikal 2 dp pada jarak 24 dp dari kiri, warna sampul mapel pada opasitas 70%.
class PaperBackgroundPainter extends CustomPainter {
  const PaperBackgroundPainter({
    required this.pattern,
    required this.marginColor,
    required this.inkColor,
    required this.isNight,
    this.gridSpacing = 24.0,
    this.ruledSpacing = 28.0,
    this.marginLeftOffset = 24.0,
  });

  final PaperPattern pattern;
  final Color marginColor;
  final Color inkColor;
  final bool isNight;
  final double gridSpacing;
  final double ruledSpacing;
  final double marginLeftOffset;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar pola garis / kotak-kotak dengan opasitas sangat rendah (~6%)
    final double lineOpacity = isNight ? 0.06 : 0.08;
    final Paint paperLinePaint = Paint()
      ..color = inkColor.withValues(alpha: lineOpacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (pattern == PaperPattern.grid) {
      for (double x = gridSpacing; x < size.width; x += gridSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paperLinePaint);
      }
      for (double y = gridSpacing; y < size.height; y += gridSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paperLinePaint);
      }
    } else if (pattern == PaperPattern.ruled) {
      for (double y = ruledSpacing + 8; y < size.height; y += ruledSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paperLinePaint);
      }
    }

    // 2. Gambar garis margin vertikal 2 dp di 24 dp dari kiri, warna sampul mapel pada 70%
    final Paint marginPaint = Paint()
      ..color = marginColor.withValues(alpha: 0.70)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(marginLeftOffset, 0),
      Offset(marginLeftOffset, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PaperBackgroundPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.marginColor != marginColor ||
        oldDelegate.inkColor != inkColor ||
        oldDelegate.isNight != isNight;
  }
}

/// Painter untuk coretan pulpen koreksi bergelombang (`pen-red`) di bawah langkah yang keliru (Bagian 7.1 design.md).
class WavyUnderlinePainter extends CustomPainter {
  const FreehandWaveConfig();
}

class CorrectionWavePainter extends CustomPainter {
  const CorrectionWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    const double waveLength = 10.0;
    const double amplitude = 2.5;
    final double yBase = size.height - amplitude;

    path.moveTo(0, yBase);
    for (double x = 0; x < size.width; x += waveLength) {
      final double midX = x + waveLength / 2;
      final double endX = (x + waveLength).clamp(0.0, size.width);
      path.quadraticBezierTo(
        midX - waveLength / 4,
        yBase - amplitude,
        midX,
        yBase,
      );
      path.quadraticBezierTo(
        midX + waveLength / 4,
        yBase + amplitude,
        endX,
        yBase,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CorrectionWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
