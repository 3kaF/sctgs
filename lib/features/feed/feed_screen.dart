import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/grade_bar.dart';
import '../../core/widgets/mini_player_and_states.dart';
import '../../core/widgets/page_card.dart';
import '../../core/widgets/paper_background_painter.dart';
import '../../core/widgets/rich_study_text.dart';
import '../../core/widgets/stabilo_mark.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';
import '../review/sm2_scheduler.dart';

/// Layar utama **Feed Belajar** sesuai Bagian 6.5 PRD & Bagian 7.1, 8, 9, 12 `design.md`:
/// - Tab mapel di atas yang bisa digeser + garis bawah `stabilo`.
/// - Konteks di atas kartu: `"Soal 7 dari 20, tugas Turunan"`.
/// - Satu kartu satu layar (`PageView` vertikal, 280 ms ease-out).
/// - Dua aksi samping saja di kanan: `Catatan` dan `Tandai`.
/// - Penilaian `Lupa`, `Susah`, `Oke`, `Mudah` di zona jempol, baru aktif setelah jawaban dibuka.
/// - Kartu kesalahan memakai garis bergelombang `pen-red` dan catatan margin.
/// - Panel **Dalami** dibuka dengan swipe ke kiri atau tombol `Dalami`.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({
    super.key,
    this.initialSubjectId,
    required this.onNavigateToScan,
  });

  final String? initialSubjectId;
  final VoidCallback onNavigateToScan;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late String _selectedFilter; // 'mixed' atau subjectId
  late PageController _pageController;
  int _currentIndex = 0;
  final Set<String> _revealedCardIds = <String>{};
  final Map<String, StudyGrade> _sessionGrades = <String, StudyGrade>{};
  int _extraSessionAllowance = 0;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialSubjectId ?? 'mixed';
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubjectId != null &&
        widget.initialSubjectId != oldWidget.initialSubjectId) {
      setState(() {
        _selectedFilter = widget.initialSubjectId!;
        _currentIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToCard(int targetIndex, int totalCount) {
    if (targetIndex < 0 || targetIndex >= totalCount) return;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    setState(() => _currentIndex = targetIndex);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetIndex,
        duration: Duration(milliseconds: reduceMotion ? 120 : 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);
    final now = DateTime.now();

    final int effectiveLimit =
        store.sessionCardLimit + _extraSessionAllowance;
    final List<StudyCardModel> queue = FeedQueueBuilder.buildSessionQueue(
      allCards: store.cards,
      now: now,
      subjectIdFilter: _selectedFilter,
      sessionLimit: effectiveLimit,
    );

    // Tab mapel yang punya kartu + Campuran
    final activeSubjects = store.subjects.where((s) {
      return store.cards.any((c) => c.subjectId == s.id && !c.reported);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tab Mapel di atas (bisa digeser, garis bawah = stabilo)
        _buildSubjectTabs(palette, activeSubjects),

        // 2. Isi Utama: EmptyState / SessionEnd / Kartu Feed
        Expanded(
          child: queue.isEmpty
              ? EmptyState(
                  message:
                      'Belum ada tugas. Foto satu lembar tugasmu untuk mulai.',
                  actionLabel: 'Scan tugas',
                  onAction: widget.onNavigateToScan,
                )
              : _currentIndex >= queue.length
              ? SessionEnd(
                  totalReviewed: queue.length,
                  lapsedCount: _sessionGrades.values
                      .where((g) => g == StudyGrade.lupa)
                      .length,
                  onContinueTenMore: () {
                    setState(() {
                      _extraSessionAllowance += 10;
                    });
                  },
                  onFinish: () {
                    setState(() {
                      _currentIndex = 0;
                      _sessionGrades.clear();
                    });
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  },
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Konteks urutan & asal tugas + tombol navigasi aksesibilitas opsional
                      _buildContextHeader(
                        palette,
                        queue[_currentIndex.clamp(0, queue.length - 1)],
                        _currentIndex,
                        queue.length,
                        store.showAccessibilityNavButtons,
                      ),
                      const SizedBox(height: 10),

                      // PageView Vertikal
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: queue.length + 1,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) {
                            if (index >= queue.length) {
                              return SessionEnd(
                                totalReviewed: queue.length,
                                lapsedCount: _sessionGrades.values
                                    .where((g) => g == StudyGrade.lupa)
                                    .length,
                                onContinueTenMore: () {
                                  setState(() {
                                    _extraSessionAllowance += 10;
                                  });
                                },
                                onFinish: () => _goToCard(0, queue.length),
                              );
                            }

                            final card = queue[index];
                            final bool isRevealed = _revealedCardIds.contains(
                              card.id,
                            );
                            final Color coverColor = palette.coverColorByKey(
                              card.subjectColorKey,
                            );
                            final PaperPattern pattern =
                                TsPalette.paperPatternForSubject(
                                  card.subjectColorKey,
                                  isNote: card.type == StudyCardType.note,
                                );

                            return GestureDetector(
                              // Swipe ke kiri membuka panel Dalami (Bagian 7.1 & 9 design.md)
                              onHorizontalDragEnd: (details) {
                                if ((details.primaryVelocity ?? 0) < -250) {
                                  _openDalamiPanel(context, card, store);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 6,
                                  bottom: 8,
                                ),
                                child: PageCard(
                                  subjectCoverColor: coverColor,
                                  pattern: pattern,
                                  semanticLabel:
                                      'Kartu ${card.subjectName}, ${card.taskTitle}',
                                  onTap: () {
                                    setState(() {
                                      _revealedCardIds.add(card.id);
                                    });
                                  },
                                  onLongPress: () {
                                    notifier.toggleStarCard(card.id);
                                  },
                                  sideActions: _buildTwoSideActions(
                                    context,
                                    palette,
                                    card,
                                    store,
                                    notifier,
                                  ),
                                  footer: _buildCardFooter(
                                    context,
                                    palette,
                                    card,
                                    isRevealed,
                                    store,
                                  ),
                                  child: _buildCardBody(
                                    context,
                                    palette,
                                    card,
                                    isRevealed,
                                    store.dyslexiaFriendlyFont,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // GradeBar di zona jempol (aktif setelah jawaban dibuka)
                      if (_currentIndex < queue.length)
                        GradeBar(
                          enabled: _revealedCardIds.contains(
                            queue[_currentIndex].id,
                          ),
                          selectedGrade:
                              _sessionGrades[queue[_currentIndex].id],
                          intervalLabels: Sm2Scheduler.previewLabels(
                            queue[_currentIndex],
                            now,
                          ),
                          onSelectGrade: (grade) {
                            final currentCard = queue[_currentIndex];
                            setState(() {
                              _sessionGrades[currentCard.id] = grade;
                            });
                            notifier.gradeCard(currentCard.id, grade);
                            Future<void>.delayed(
                              const Duration(milliseconds: 160),
                              () {
                                if (!mounted) return;
                                _goToCard(
                                  _currentIndex + 1,
                                  queue.length + 1,
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectTabs(
    TsPalette palette,
    List<SubjectModel> activeSubjects,
  ) {
    final tabs = <({String id, String label})>[
      for (final s in activeSubjects) (id: s.id, label: s.name),
      (id: 'mixed', label: 'Campuran'),
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line, width: 1)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final bool isSelected = _selectedFilter == tab.id;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = tab.id;
                _currentIndex = 0;
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      tab.label,
                      style: TsTypography.buttonAndChip(
                        palette,
                        color: isSelected ? palette.ink : palette.pencil,
                      ),
                    ),
                  ),
                ),
                // Garis bawah = stabilo (Bagian 7.1 design.md)
                Container(
                  height: 3,
                  width: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? palette.stabilo : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContextHeader(
    TsPalette palette,
    StudyCardModel card,
    int index,
    int total,
    bool showNavButtons,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Soal ${index + 1} dari $total, tugas ${card.taskTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TsTypography.caption(palette),
          ),
        ),
        if (showNavButtons) ...[
          IconButton(
            onPressed: index > 0 ? () => _goToCard(index - 1, total) : null,
            tooltip: 'Kartu sebelumnya',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: Icon(
              PhosphorIconsRegular.caretUp,
              size: 20,
              color: index > 0 ? palette.ink : palette.pencil,
            ),
          ),
          IconButton(
            onPressed: () => _goToCard(index + 1, total + 1),
            tooltip: 'Kartu berikutnya',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: Icon(
              PhosphorIconsRegular.caretDown,
              size: 20,
              color: palette.ink,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardBody(
    BuildContext context,
    TsPalette palette,
    StudyCardModel card,
    bool isRevealed,
    bool dyslexiaFriendly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label jenis kartu & mapel dalam sentence case
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.raised,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.line, width: 1),
              ),
              child: Text(
                '${card.subjectName} · ${card.type.label}',
                style: TsTypography.caption(palette, color: palette.ink),
              ),
            ),
            if (card.isStarred)
              StabiloMark(
                child: Text(
                  'Ditandai penting',
                  style: TsTypography.caption(palette, color: palette.ink),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Teks soal utama (Literata 21/32 atau Noto Naskh Arabic 24/42)
        if (card.isStarred)
          StabiloMark(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: RichStudyText(
              text: card.promptText,
              dyslexiaFriendly: dyslexiaFriendly,
            ),
          )
        else
          RichStudyText(
            text: card.promptText,
            dyslexiaFriendly: dyslexiaFriendly,
          ),

        const SizedBox(height: 20),

        // Khusus Kartu Kesalahan: tampilkan langkah yang keliru dengan garis gelombang `pen-red` dan catatan margin
        if (card.type == StudyCardType.mistake &&
            card.wrongStepText != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.penRed, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.xCircle,
                      size: 18,
                      color: palette.penRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        card.correctionMarginNote ?? 'Langkah yang keliru',
                        style: TsTypography.caption(
                          palette,
                          color: palette.penRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomPaint(
                  painter: CorrectionWavePainter(color: palette.penRed),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichStudyText(
                      text: card.wrongStepText!,
                      style: TsTypography.cardAnswer(
                        palette,
                        dyslexiaFriendly: dyslexiaFriendly,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Bagian Jawaban & Pembahasan (muncul setelah ketuk kartu atau tombol "Lihat jawaban")
        if (isRevealed) ...[
          Divider(color: palette.line, height: 24),
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.checkCircle,
                size: 18,
                color: palette.penGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Jawaban dan langkah benar',
                style: TsTypography.caption(palette, color: palette.penGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichStudyText(
            text: card.correctStepText ?? card.answerText,
            style: TsTypography.cardAnswer(
              palette,
              dyslexiaFriendly: dyslexiaFriendly,
            ),
          ),
          if (card.explanationText != null &&
              card.explanationText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              card.explanationText!,
              style: TsTypography.caption(palette, color: palette.pencil),
            ),
          ],
        ],
      ],
    );
  }

  /// Dua aksi samping di kanan sesuai Bagian 7.1 `design.md`: `Catatan` dan `Tandai`.
  Widget _buildTwoSideActions(
    BuildContext context,
    TsPalette palette,
    StudyCardModel card,
    AppStoreState store,
    AppStoreNotifier notifier,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideActionButton(
          icon: PhosphorIconsRegular.notePencil,
          label: 'Catatan',
          isActive: false,
          palette: palette,
          onTap: () => _openQuickNoteSheet(context, card, store, notifier),
        ),
        const SizedBox(height: 12),
        _SideActionButton(
          icon: PhosphorIconsRegular.highlighterCircle,
          label: 'Tandai',
          isActive: card.isStarred,
          palette: palette,
          onTap: () => notifier.toggleStarCard(card.id),
        ),
      ],
    );
  }

  /// Footer di dalam kartu: tombol alternatif untuk membuka jawaban dan membuka panel Dalami (Bagian 9 design.md).
  Widget _buildCardFooter(
    BuildContext context,
    TsPalette palette,
    StudyCardModel card,
    bool isRevealed,
    AppStoreState store,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isRevealed)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _revealedCardIds.add(card.id);
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: palette.ink,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: palette.raised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: palette.line),
              ),
            ),
            icon: const Icon(PhosphorIconsRegular.eye, size: 18),
            label: Text(
              'Lihat jawaban',
              style: TsTypography.buttonAndChip(palette),
            ),
          )
        else
          Text(
            'Nilai kartu di bawah untuk lanjut',
            style: TsTypography.caption(palette),
          ),
        TextButton.icon(
          onPressed: () => _openDalamiPanel(context, card, store),
          style: TextButton.styleFrom(
            foregroundColor: palette.penBlue,
            minimumSize: const Size(48, 44),
          ),
          icon: const Icon(PhosphorIconsRegular.bookOpenText, size: 18),
          label: Text(
            'Dalami',
            style: TsTypography.buttonAndChip(palette, color: palette.penBlue),
          ),
        ),
      ],
    );
  }

  /// Panel **Dalami** (Bagian 7.1 `design.md`): langkah penyelesaian lengkap, asal tugas, catatan terkait, dan opsi lapor kartu salah.
  void _openDalamiPanel(
    BuildContext context,
    StudyCardModel card,
    AppStoreState store,
  ) {
    final palette = context.tsPalette;
    final relatedNotes = store.notes
        .where((n) => n.taskId == card.taskId || n.cardId == card.id)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dalami langkah penyelesaian',
                      style: TsTypography.sectionTitle(palette),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      tooltip: 'Tutup panel Dalami',
                      icon: Icon(PhosphorIconsRegular.x, color: palette.ink),
                    ),
                  ],
                ),
                Text(
                  'Asal tugas: ${card.subjectName} · ${card.taskTitle}',
                  style: TsTypography.caption(palette),
                ),
                const SizedBox(height: 16),
                if (card.deepDiveSteps.isNotEmpty) ...[
                  for (final step in card.deepDiveSteps) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.page,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.line),
                      ),
                      child: RichStudyText(
                        text: step,
                        style: TsTypography.cardAnswer(palette),
                      ),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.page,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.line),
                    ),
                    child: RichStudyText(
                      text: card.explanationText ?? card.answerText,
                      style: TsTypography.cardAnswer(palette),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Catatanmu di tugas ini',
                  style: TsTypography.buttonAndChip(palette),
                ),
                const SizedBox(height: 8),
                if (relatedNotes.isEmpty)
                  Text(
                    'Belum ada catatan untuk kartu ini.',
                    style: TsTypography.caption(palette),
                  )
                else
                  for (final note in relatedNotes)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.page,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.line),
                      ),
                      child: Text(
                        note.body,
                        style: TsTypography.noteBody(palette),
                      ),
                    ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(appStoreProvider.notifier).reportCard(card.id);
                      Navigator.of(sheetCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kartu dilaporkan dan disembunyikan dari feed.',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: palette.penRed,
                    ),
                    icon: const Icon(PhosphorIconsRegular.flag, size: 18),
                    label: const Text('Laporkan kartu salah'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openQuickNoteSheet(
    BuildContext context,
    StudyCardModel card,
    AppStoreState store,
    AppStoreNotifier notifier,
  ) {
    final palette = context.tsPalette;
    final controller = TextEditingController();
    bool showInFeed = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tulis catatan untuk kartu ini',
                    style: TsTypography.sectionTitle(palette),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${card.subjectName} · ${card.taskTitle}',
                    style: TsTypography.caption(palette),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    style: TsTypography.noteBody(palette),
                    decoration: InputDecoration(
                      hintText:
                          'Tulis rumus kunci atau pengingat langkah yang sering terlupa...',
                      hintStyle: TsTypography.caption(palette),
                      filled: true,
                      fillColor: palette.page,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: palette.line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showInFeed,
                    onChanged: (val) =>
                        setSheetState(() => showInFeed = val ?? false),
                    title: Text(
                      'Tampilkan catatan ini sebagai kartu di feed',
                      style: TsTypography.caption(palette, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final subject = store.subjects.firstWhere(
                          (s) => s.id == card.subjectId,
                          orElse: () => store.subjects.last,
                        );
                        notifier.saveNote(
                          subject: subject,
                          body: controller.text,
                          showInFeed: showInFeed,
                          taskId: card.taskId,
                          cardId: card.id,
                          taskTitle: card.taskTitle,
                        );
                        Navigator.of(sheetCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tersimpan')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primaryAction,
                        foregroundColor: palette.onPrimaryAction,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Simpan',
                        style: TsTypography.buttonAndChip(
                          palette,
                          color: palette.onPrimaryAction,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final TsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: Material(
        color: isActive
            ? palette.stabilo.withValues(alpha: palette.stabiloHighlightOpacity)
            : palette.raised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? palette.stabilo : palette.line,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? palette.stabilo : palette.ink,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TsTypography.caption(palette, color: palette.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
