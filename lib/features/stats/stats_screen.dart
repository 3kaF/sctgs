import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/subject_cover.dart';
import '../../core/widgets/verdict_tag.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';

/// Layar **Statistik & Penguasaan Belajar** sesuai Bagian 6.8 & 7 PRD serta Bagian 11, 12 `design.md`:
/// - Menampilkan ringkasan tenang: jumlah kartu yang sudah dikuasai, kartu yang sedang dipelajari,
///   dan topik yang paling sering salah agar bisa diulang sebelum ujian.
/// - Sesuai aturan Bagian 11 & 12 `design.md`: tidak ada pesan rasa bersalah ("Streakmu hilang!"),
///   tidak ada papan peringkat (leaderboard) publik, dan tidak ada warna dekoratif di luar sistem `TsPalette`.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({
    super.key,
    required this.onStartStudyForSubject,
  });

  final ValueChanged<String?> onStartStudyForSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final now = DateTime.now();

    final int totalCards = store.cards.where((c) => !c.reported).length;
    final int masteredCards = store.cards
        .where((c) => !c.reported && c.intervalDays >= 4)
        .length;
    final int dueToday = store.totalDueCards(now);

    // Cari tugas/topik yang memiliki verdict salah atau sebagian (atau lapses > 0)
    final List<TaskItemModel> weakTasks = store.tasks.where((t) {
      return t.effectiveVerdict == TaskVerdict.wrong ||
          t.effectiveVerdict == TaskVerdict.partial ||
          t.mastery <= 1;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Ringkasan belajar',
          style: TsTypography.screenTitle(
            palette,
            dyslexiaFriendly: store.dyslexiaFriendlyFont,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau bagian mana yang sudah kuat dan topik mana yang perlu dibaca lagi sebelum ujian.',
          style: TsTypography.caption(palette),
        ),
        const SizedBox(height: 16),

        // 1. Tiga metrik utama dalam permukaan halaman
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Kartu dikuasai',
                value: '$masteredCards',
                subtitle: 'dari $totalCards kartu',
                accentColor: palette.penGreen,
                palette: palette,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Perlu diulang',
                value: '$dueToday',
                subtitle: 'jatuh tempo hari ini',
                accentColor: palette.stabilo,
                palette: palette,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Penguasaan per Mapel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Penguasaan per mapel',
                style: TsTypography.sectionTitle(palette),
              ),
              const SizedBox(height: 12),
              for (final subject in store.activeSubjectsWithStats(now)) ...[
                _SubjectProgressRow(
                  subject: subject,
                  cards: store.cards
                      .where((c) => c.subjectId == subject.id && !c.reported)
                      .toList(),
                  palette: palette,
                  onTapStudy: () => onStartStudyForSubject(subject.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Topik yang perlu diperkuat (dari kesalahan di tugas)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Topik yang perlu diperkuat',
                style: TsTypography.sectionTitle(palette),
              ),
              const SizedBox(height: 4),
              Text(
                'Diambil dari soal yang masih keliru atau belum lengkap.',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 12),
              if (weakTasks.isEmpty)
                Text(
                  'Belum ada topik yang tertinggal. Semua tugas tercatat baik.',
                  style: TsTypography.cardAnswer(palette),
                )
              else
                for (final task in weakTasks)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.raised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SubjectChip(
                              label: task.subjectName,
                              coverColor: palette.coverColorByKey(
                                task.subjectColorKey,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  onStartStudyForSubject(task.subjectId),
                              child: Text(
                                'Ulangi topik ini',
                                style: TsTypography.caption(
                                  palette,
                                  color: palette.penBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.topic,
                          style: TsTypography.buttonAndChip(palette),
                        ),
                        if (task.mistakeStep != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.pen,
                                size: 15,
                                color: palette.penRed,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  task.mistakeStep!,
                                  style: TsTypography.caption(
                                    palette,
                                    color: palette.penRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.palette,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final TsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TsTypography.caption(palette)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TsTypography.screenTitle(
              palette,
            ).copyWith(color: accentColor),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TsTypography.caption(palette)),
        ],
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow({
    required this.subject,
    required this.cards,
    required this.palette,
    required this.onTapStudy,
  });

  final SubjectModel subject;
  final List<StudyCardModel> cards;
  final TsPalette palette;
  final VoidCallback onTapStudy;

  @override
  Widget build(BuildContext context) {
    final int total = cards.length;
    final int strong = cards.where((c) => c.intervalDays >= 4).length;
    final double ratio = total == 0 ? 0 : (strong / total).clamp(0.0, 1.0);
    final Color coverColor = palette.coverColorByKey(subject.colorKey);

    return InkWell(
      onTap: onTapStudy,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                      subject.name,
                      style: TsTypography.buttonAndChip(palette),
                    ),
                  ],
                ),
                Text(
                  '$strong/$total kartu kuat',
                  style: TsTypography.caption(palette),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: palette.raised,
                valueColor: AlwaysStoppedAnimation<Color>(coverColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
