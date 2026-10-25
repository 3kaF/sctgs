import 'package:flutter/material.dart';
import '../theme/ts_palette.dart';
import 'paper_background_painter.dart';

/// Komponen kunci `PageCard` sesuai Bagian 5, 8, 12, dan 14 `design.md`:
/// - Satu kartu feed = satu halaman buku tulis.
/// - Radius 10 dp (seperti sudut kertas), border tipis `line` 1 dp.
/// - Tanpa bayangan blur (`boxShadow` tidak dipakai).
/// - Kedalaman dibuat dengan tumpukan halaman: dua lembar di belakang kartu aktif,
///   bergeser 4 dp dan 8 dp, warna `raised` dan `page` yang makin pudar.
/// - Isi kartu mulai 32 dp dari tepi kiri (setelah garis margin 24 dp).
/// - Bila isi kartu melebihi layar, isi bisa digulir di dalam kartu dan pindah kartu
///   baru terjadi saat gulir sudah di ujung atas atau bawah.
class PageCard extends StatelessWidget {
  const PageCard({
    super.key,
    required this.child,
    required this.subjectCoverColor,
    this.pattern = PaperPattern.plain,
    this.showStackedPages = true,
    this.onTap,
    this.onLongPress,
    this.footer,
    this.sideActions,
    this.semanticLabel,
  });

  final Widget child;
  final Color subjectCoverColor;
  final PaperPattern pattern;
  final bool showStackedPages;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? footer;
  final Widget? sideActions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final BorderRadius cardRadius = BorderRadius.circular(10);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lembar ke-2 di belakang (bergeser 8 dp, warna page memudar)
          if (showStackedPages)
            Positioned.fill(
              top: 8,
              left: 8,
              right: -4,
              bottom: -8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.page.withValues(alpha: 0.45),
                    borderRadius: cardRadius,
                    border: Border.all(color: palette.line, width: 1),
                  ),
                ),
              ),
            ),

          // Lembar ke-1 di belakang (bergeser 4 dp, warna raised memudar)
          if (showStackedPages)
            Positioned.fill(
              top: 4,
              left: 4,
              right: -2,
              bottom: -4,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.raised.withValues(alpha: 0.70),
                    borderRadius: cardRadius,
                    border: Border.all(color: palette.line, width: 1),
                  ),
                ),
              ),
            ),

          // Halaman utama aktif
          ClipRRect(
            borderRadius: cardRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.page,
                borderRadius: cardRadius,
                border: Border.all(color: palette.line, width: 1),
              ),
              child: CustomPaint(
                painter: PaperBackgroundPainter(
                  pattern: pattern,
                  marginColor: subjectCoverColor,
                  inkColor: palette.ink,
                  isNight: palette.isNight,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    splashColor: palette.stabilo.withValues(alpha: 0.08),
                    highlightColor: Colors.transparent,
                    child: Stack(
                      children: [
                        // Isi halaman mulai 32 dp dari tepi kiri (setelah garis margin 24 dp)
                        Positioned.fill(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    32,
                                    24,
                                    sideActions != null ? 72 : 20,
                                    24,
                                  ),
                                  child: child,
                                ),
                              ),
                              if (footer != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    0,
                                    20,
                                    16,
                                  ),
                                  child: footer!,
                                ),
                            ],
                          ),
                        ),

                        // Dua aksi samping di kanan (Catatan, Tandai)
                        if (sideActions != null)
                          Positioned(
                            right: 8,
                            bottom: footer != null ? 72 : 24,
                            child: sideActions!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
