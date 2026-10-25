import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';

/// Komponen kunci `MiniPlayer` sesuai Bagian 7.1, 8, dan 10 `design.md`:
/// - Pil setinggi 40 dp di atas navigasi bawah: nama track, putar atau jeda.
/// - Ketuk untuk membuka sheet playlist. Bisa disembunyikan.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.trackTitle,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onOpenPlaylistSheet,
    this.onHide,
  });

  final String trackTitle;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpenPlaylistSheet;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;

    return Semantics(
      container: true,
      label: 'Pemutar musik latar: $trackTitle',
      child: Material(
        color: palette.raised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onOpenPlaylistSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.musicNote,
                  size: 18,
                  color: palette.pencil,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TsTypography.caption(palette, color: palette.ink),
                  ),
                ),
                IconButton(
                  onPressed: onTogglePlay,
                  tooltip: isPlaying ? 'Jeda musik' : 'Putar musik',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    isPlaying
                        ? PhosphorIconsRegular.pause
                        : PhosphorIconsRegular.play,
                    size: 18,
                    color: palette.ink,
                  ),
                ),
                if (onHide != null)
                  IconButton(
                    onPressed: onHide,
                    tooltip: 'Sembunyikan pemutar musik',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      size: 16,
                      color: palette.pencil,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Komponen kunci `EmptyState` sesuai Bagian 8 & 11 `design.md`:
/// - Satu kalimat konkret dan satu tombol aksi. Tanpa ilustrasi besar.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TsTypography.cardAnswer(palette),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryAction,
                  foregroundColor: palette.onPrimaryAction,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  actionLabel,
                  style: TsTypography.buttonAndChip(
                    palette,
                    color: palette.onPrimaryAction,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Komponen kunci `SessionEnd` sesuai Bagian 1, 8, dan 11 `design.md`:
/// - Ringkasan sesi (jumlah kartu, berapa yang Lupa), lalu dua pilihan:
///   `Lanjut 10 kartu`, atau `Selesai`.
class SessionEnd extends StatelessWidget {
  const SessionEnd({
    super.key,
    required this.totalReviewed,
    required this.lapsedCount,
    required this.onContinueTenMore,
    required this.onFinish,
  });

  final int totalReviewed;
  final int lapsedCount;
  final VoidCallback onContinueTenMore;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final int masteredInSession = (totalReviewed - lapsedCount).clamp(
      0,
      totalReviewed,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.line, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sudah $totalReviewed kartu. Istirahat sebentar, atau lanjut.',
                style: TsTypography.sectionTitle(palette),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.raised,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.line, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$masteredInSession kartu dijawab lancar',
                      style: TsTypography.cardAnswer(palette),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$lapsedCount kartu ditandai lupa untuk diulang besok',
                      style: TsTypography.caption(palette),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: onFinish,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primaryAction,
                    foregroundColor: palette.onPrimaryAction,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Selesai',
                    style: TsTypography.buttonAndChip(
                      palette,
                      color: palette.onPrimaryAction,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onContinueTenMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.ink,
                    side: BorderSide(color: palette.line, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lanjut 10 kartu',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
