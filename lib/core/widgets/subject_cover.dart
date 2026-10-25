import 'package:flutter/material.dart';
import '../theme/ts_palette.dart';
import '../theme/ts_typography.dart';

/// Komponen kunci `SubjectCover` sesuai Bagian 5, 7.2, dan 8 `design.md`:
/// - Sampul buku di layar Arsip: punggung buku 8 dp berwarna sampul mapel,
///   radius 6 dp di sisi kanan dan 2 dp di sisi punggung buku (kiri).
/// - Menampilkan nama mapel, jumlah tugas, dan jumlah kartu yang perlu diulang.
class SubjectCover extends StatelessWidget {
  const SubjectCover({
    super.key,
    required this.subjectName,
    required this.coverColor,
    required this.taskCount,
    required this.dueCardCount,
    required this.onTap,
  });

  final String subjectName;
  final Color coverColor;
  final int taskCount;
  final int dueCardCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    const BorderRadius coverRadius = BorderRadius.only(
      topLeft: Radius.circular(2),
      bottomLeft: Radius.circular(2),
      topRight: Radius.circular(6),
      bottomRight: Radius.circular(6),
    );

    return Semantics(
      button: true,
      label:
          'Sampul $subjectName, $taskCount tugas, $dueCardCount perlu diulang',
      child: ClipRRect(
        borderRadius: coverRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: coverRadius,
            border: Border.all(color: palette.line, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Punggung buku 8 dp berwarna sampul mapel
                  Container(
                    width: 8,
                    color: coverColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subjectName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TsTypography.sectionTitle(palette),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$taskCount tugas',
                                style: TsTypography.caption(palette),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$dueCardCount diulang',
                                style: TsTypography.caption(
                                  palette,
                                  color: dueCardCount > 0
                                      ? palette.ink
                                      : palette.pencil,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

/// Komponen kunci `SubjectChip` sesuai Bagian 5 & 8 `design.md`:
/// - Titik warna sampul 8 dp, nama mapel, latar `raised`, radius 6 dp.
class SubjectChip extends StatelessWidget {
  const SubjectChip({
    super.key,
    required this.label,
    required this.coverColor,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final Color coverColor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: 'Mapel $label',
      child: Material(
        color: palette.raised,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? palette.stabilo : palette.line,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: coverColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TsTypography.buttonAndChip(palette),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
