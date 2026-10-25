import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';

/// Status hasil pemeriksaan jawaban sesuai Bagian 6.3 PRD & Bagian 3.3, 6, 8 `design.md`.
/// Aturan mutlak: benar atau salah tidak pernah ditunjukkan hanya dengan warna;
/// selalu ada ikon dan teks. Penanda AI adalah ikon pulpen + teks "Dikoreksi AI", bukan bintang/kilau.
enum TaskVerdict {
  correct('correct', 'Benar'),
  wrong('wrong', 'Salah'),
  partial('partial', 'Sebagian'),
  unsure('unsure', 'Belum yakin');

  const TaskVerdict(this.code, this.label);
  final String code;
  final String label;

  static TaskVerdict fromCode(String? code) {
    switch (code) {
      case 'correct':
      case 'benar':
        return TaskVerdict.correct;
      case 'wrong':
      case 'salah':
        return TaskVerdict.wrong;
      case 'partial':
      case 'sebagian':
        return TaskVerdict.partial;
      default:
        return TaskVerdict.unsure;
    }
  }
}

/// Komponen kunci `VerdictTag` sesuai Bagian 6 & 8 `design.md`:
/// - Ikon centang / silang / tanda tanya + teks (`Benar`, `Salah`, `Sebagian`, `Belum yakin`)
/// - Keterangan `"Dikoreksi AI"` dengan ikon pulpen (atau `"Dikonfirmasi kamu"` bila sudah ditimpa pengguna)
/// - Mendukung aksi timpa (*override*): "Tandai benar menurut guru" / "Memang salah".
class VerdictTag extends StatelessWidget {
  const VerdictTag({
    super.key,
    required this.verdict,
    this.isUserOverridden = false,
    this.onOverrideVerdict,
  });

  final TaskVerdict verdict;
  final bool isUserOverridden;
  final ValueChanged<TaskVerdict>? onOverrideVerdict;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;

    final (IconData icon, Color statusColor) = switch (verdict) {
      TaskVerdict.correct => (PhosphorIconsRegular.checkCircle, palette.penGreen),
      TaskVerdict.wrong => (PhosphorIconsRegular.xCircle, palette.penRed),
      TaskVerdict.partial => (PhosphorIconsRegular.warningCircle, palette.stabilo),
      TaskVerdict.unsure => (PhosphorIconsRegular.question, palette.pencil),
    };

    return Semantics(
      container: true,
      label:
          'Status jawaban: ${verdict.label}. ${isUserOverridden ? "Dikonfirmasi kamu" : "Dikoreksi AI"}',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  verdict.label,
                  style: TsTypography.buttonAndChip(palette, color: palette.ink),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: palette.line),
                const SizedBox(width: 8),
                Icon(
                  PhosphorIconsRegular.pen,
                  size: 15,
                  color: palette.pencil,
                ),
                const SizedBox(width: 4),
                Text(
                  isUserOverridden ? 'Dikonfirmasi kamu' : 'Dikoreksi AI',
                  style: TsTypography.caption(palette),
                ),
              ],
            ),
          ),
          if (onOverrideVerdict != null)
            TextButton.icon(
              onPressed: () => _showOverrideSheet(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: palette.penBlue,
              ),
              icon: const Icon(PhosphorIconsRegular.pencilSimpleLine, size: 18),
              label: Text(
                'Ubah penilaian',
                style: TsTypography.caption(palette, color: palette.penBlue),
              ),
            ),
        ],
      ),
    );
  }

  void _showOverrideSheet(BuildContext context) {
    final palette = context.tsPalette;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sesuaikan dengan penilaian gurumu',
                  style: TsTypography.sectionTitle(palette),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum yakin jawabannya benar. Cek langkahmu, atau tandai benar jika gurumu sudah menilainya.',
                  style: TsTypography.caption(palette),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    PhosphorIconsRegular.checkCircle,
                    color: palette.penGreen,
                  ),
                  title: Text(
                    'Jawaban saya benar menurut guru',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOverrideVerdict?.call(TaskVerdict.correct);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    PhosphorIconsRegular.xCircle,
                    color: palette.penRed,
                  ),
                  title: Text(
                    'Jawaban saya memang salah',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOverrideVerdict?.call(TaskVerdict.wrong);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
