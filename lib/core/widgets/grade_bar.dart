import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';

/// Nilai review kartu (mirip SM-2) sesuai Bagian 6.8 PRD & Bagian 7.1, 8, 12 `design.md`.
enum StudyGrade {
  lupa(0, 'Lupa'),
  susah(1, 'Susah'),
  oke(2, 'Oke'),
  mudah(3, 'Mudah');

  const StudyGrade(this.code, this.label);
  final int code;
  final String label;
}

/// Komponen kunci `GradeBar` sesuai Bagian 8 & 12 `design.md`:
/// - Empat tombol sama lebar, tinggi minimal 52 dp, jarak antar tombol minimal 8 dp.
/// - Menampilkan label teks (`Lupa`, `Susah`, `Oke`, `Mudah`) dan estimasi jarak ulang di bawahnya (`Besok`, `2 hari`, `4 hari`, `9 hari`).
/// - Tidak aktif sebelum jawaban dibuka (`enabled = false`).
/// - Umpan haptik ringan hanya saat memberi nilai.
class GradeBar extends StatelessWidget {
  const GradeBar({
    super.key,
    required this.enabled,
    required this.intervalLabels,
    required this.onSelectGrade,
    this.selectedGrade,
  });

  final bool enabled;
  final Map<StudyGrade, String> intervalLabels;
  final ValueChanged<StudyGrade> onSelectGrade;
  final StudyGrade? selectedGrade;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    const grades = StudyGrade.values;

    return Semantics(
      container: true,
      label: enabled
          ? 'Penilaian penguasaan kartu'
          : 'Penilaian belum aktif, buka jawaban terlebih dahulu',
      child: Row(
        children: [
          for (int i = 0; i < grades.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _GradeButton(
                grade: grades[i],
                intervalText: intervalLabels[grades[i]] ?? 'Besok',
                enabled: enabled,
                isSelected: selectedGrade == grades[i],
                palette: palette,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelectGrade(grades[i]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.grade,
    required this.intervalText,
    required this.enabled,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final StudyGrade grade;
  final String intervalText;
  final bool enabled;
  final bool isSelected;
  final TsPalette palette;
  final VoidCallback onTap;

  Color _accentForGrade() {
    switch (grade) {
      case StudyGrade.lupa:
        return palette.penRed;
      case StudyGrade.susah:
        return palette.pencil;
      case StudyGrade.oke:
        return palette.penBlue;
      case StudyGrade.mudah:
        return palette.penGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentForGrade();
    final Color bgColor = !enabled
        ? palette.raised.withValues(alpha: 0.45)
        : isSelected
            ? accent.withValues(alpha: 0.20)
            : palette.raised;
    final Color borderColor = !enabled
        ? palette.line
        : isSelected
            ? accent
            : palette.line;
    final Color textColor = !enabled
        ? palette.pencil.withValues(alpha: 0.5)
        : palette.ink;
    final Color subTextColor = !enabled
        ? palette.pencil.withValues(alpha: 0.4)
        : palette.pencil;

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${grade.label}, diulang $intervalText',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    grade.label,
                    textAlign: TextAlign.center,
                    style: TsTypography.buttonAndChip(
                      palette,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    intervalText,
                    textAlign: TextAlign.center,
                    style: TsTypography.caption(
                      palette,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
