import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/mini_player_and_states.dart';
import '../../core/widgets/rich_study_text.dart';
import '../../core/widgets/subject_cover.dart';
import '../../core/widgets/verdict_tag.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';

/// Layar **Arsip (Rak Buku)** dan **Detail Tugas** sesuai Bagian 6.1 PRD & Bagian 7.2, 8 `design.md`:
/// - Arsip adalah rak sampul mapel (`SubjectCover`), bukan grid video.
/// - Mapel yang belum punya tugas tidak ditampilkan.
/// - Menampilkan ringkasan `"X kartu perlu diulang hari ini"`.
/// - Tab `Perlu dicek` muncul hanya bila ada tugas yang menunggu konfirmasi (`confidence < 0.6` atau `needsCheck`).
/// - Ketuk sampul untuk melihat daftar tugas mapel itu dan membuka Detail Tugas (dengan `VerdictTag` yang bisa ditimpa pengguna).
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({
    super.key,
    required this.onNavigateToScan,
    required this.onStartStudyForSubject,
  });

  final VoidCallback onNavigateToScan;
  final ValueChanged<String?> onStartStudyForSubject;

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  bool _showingNeedsCheckTab = false;
  SubjectModel? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final now = DateTime.now();

    final int totalDue = store.totalDueCards(now);
    final List<SubjectModel> activeSubjects = store.activeSubjectsWithStats(
      now,
    );
    final List<TaskItemModel> needsCheckList = store.tasksNeedingCheck;

    // Jika sedang membuka salah satu sampul mapel, tampilkan daftar tugas mapel itu
    if (_selectedSubject != null) {
      return _buildSubjectTaskList(
        context,
        palette,
        store,
        _selectedSubject!,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Arsip + Tombol Cari + Tambah Mapel/Manual
          Row(
            children: [
              Expanded(
                child: Text(
                  'Arsip',
                  style: TsTypography.screenTitle(
                    palette,
                    dyslexiaFriendly: store.dyslexiaFriendlyFont,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchQuery = '';
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: palette.ink,
                  minimumSize: const Size(48, 44),
                ),
                icon: Icon(
                  _isSearching
                      ? PhosphorIconsRegular.x
                      : PhosphorIconsRegular.magnifyingGlass,
                  size: 20,
                ),
                label: Text(
                  _isSearching ? 'Tutup' : 'Cari',
                  style: TsTypography.buttonAndChip(palette),
                ),
              ),
              IconButton(
                onPressed: () => _openAddSubjectDialog(context, palette),
                tooltip: 'Tambah mapel sendiri',
                icon: Icon(
                  PhosphorIconsRegular.folderPlus,
                  color: palette.ink,
                ),
              ),
            ],
          ),

          // Ringkasan jatuh tempo hari ini (Bagian 7.2 design.md)
          Text(
            totalDue > 0
                ? '$totalDue kartu perlu diulang hari ini'
                : 'Semua kartu hari ini sudah diulang.',
            style: TsTypography.caption(palette),
          ),
          const SizedBox(height: 12),

          // Kolom pencarian FTS bila diaktifkan
          if (_isSearching) ...[
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TsTypography.cardAnswer(palette),
              decoration: InputDecoration(
                hintText: 'Cari soal, topik, atau jawaban...',
                hintStyle: TsTypography.caption(palette),
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: palette.pencil,
                ),
                filled: true,
                fillColor: palette.page,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: palette.line),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tab kondisional "Perlu dicek" hanya muncul bila ada tugas yang menunggu konfirmasi (Bagian 7.2 design.md)
          if (needsCheckList.isNotEmpty) ...[
            Row(
              children: [
                SubjectChip(
                  label: 'Rak mapel (${activeSubjects.length})',
                  coverColor: palette.stabilo,
                  isSelected: !_showingNeedsCheckTab,
                  onTap: () => setState(() => _showingNeedsCheckTab = false),
                ),
                const SizedBox(width: 8),
                SubjectChip(
                  label: 'Perlu dicek (${needsCheckList.length})',
                  coverColor: palette.penRed,
                  isSelected: _showingNeedsCheckTab,
                  onTap: () => setState(() => _showingNeedsCheckTab = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Isi utama Arsip
          Expanded(
            child: _searchQuery.trim().isNotEmpty
                ? _buildSearchResults(context, palette, store, _searchQuery)
                : _showingNeedsCheckTab && needsCheckList.isNotEmpty
                ? _buildNeedsCheckList(context, palette, store, needsCheckList)
                : activeSubjects.isEmpty
                ? EmptyState(
                    message:
                        'Belum ada tugas. Foto satu lembar tugasmu untuk mulai.',
                    actionLabel: 'Scan tugas',
                    onAction: widget.onNavigateToScan,
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.32,
                        ),
                    itemCount: activeSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = activeSubjects[index];
                      return SubjectCover(
                        subjectName: subject.name,
                        coverColor: palette.coverColorByKey(subject.colorKey),
                        taskCount: subject.taskCount,
                        dueCardCount: subject.dueCardCount,
                        onTap: () {
                          setState(() => _selectedSubject = subject);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTaskList(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
    SubjectModel subject,
  ) {
    final subjectTasks = store.tasks
        .where((t) => t.subjectId == subject.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedSubject = null),
                tooltip: 'Kembali ke rak buku',
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: palette.ink),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subject.name,
                  style: TsTypography.screenTitle(palette),
                ),
              ),
              FilledButton(
                onPressed: () => widget.onStartStudyForSubject(subject.id),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryAction,
                  foregroundColor: palette.onPrimaryAction,
                  minimumSize: const Size(48, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mulai belajar',
                  style: TsTypography.buttonAndChip(
                    palette,
                    color: palette.onPrimaryAction,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: subjectTasks.isEmpty
                ? EmptyState(
                    message:
                        'Belum ada tugas. Foto satu lembar tugasmu untuk mulai.',
                    actionLabel: 'Scan tugas',
                    onAction: widget.onNavigateToScan,
                  )
                : ListView.separated(
                    itemCount: subjectTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = subjectTasks[index];
                      return _buildTaskCardItem(context, palette, store, task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsCheckList(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
    List<TaskItemModel> list,
  ) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = list[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.stabilo, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfirmasi mapel untuk tugas ini',
                style: TsTypography.caption(palette, color: palette.stabilo),
              ),
              const SizedBox(height: 6),
              RichStudyText(
                text: task.questionText,
                style: TsTypography.cardAnswer(palette),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sub in store.subjects.take(8))
                    SubjectChip(
                      label: sub.name,
                      coverColor: palette.coverColorByKey(sub.colorKey),
                      isSelected: sub.id == task.subjectId,
                      onTap: () {
                        ref
                            .read(appStoreProvider.notifier)
                            .confirmTaskSubject(task.id, sub);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final matched = store.tasks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.questionText.toLowerCase().contains(q) ||
          t.topic.toLowerCase().contains(q) ||
          t.userAnswerText.toLowerCase().contains(q);
    }).toList();

    if (matched.isEmpty) {
      return Center(
        child: Text(
          'Tidak ditemukan tugas dengan kata "$query".',
          style: TsTypography.caption(palette),
        ),
      );
    }

    return ListView.separated(
      itemCount: matched.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildTaskCardItem(context, palette, store, matched[index]),
    );
  }

  Widget _buildTaskCardItem(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
    TaskItemModel task,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openTaskDetailSheet(context, task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${task.topic} · Penguasaan ${task.masteryLabel}',
                      style: TsTypography.caption(palette),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteTask(context, task),
                    tooltip: 'Hapus tugas',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: palette.pencil,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RichStudyText(
                text: task.questionText,
                style: TsTypography.cardAnswer(palette),
              ),
              const SizedBox(height: 12),
              VerdictTag(
                verdict: task.effectiveVerdict,
                isUserOverridden: task.isUserOverridden,
                onOverrideVerdict: (newVerdict) {
                  ref
                      .read(appStoreProvider.notifier)
                      .overrideTaskVerdict(task.id, newVerdict);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTaskDetailSheet(BuildContext context, TaskItemModel task) {
    final palette = context.tsPalette;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final store = ref.watch(appStoreProvider);
        final currentTask = store.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        final taskCards = store.cards
            .where((c) => c.taskId == currentTask.id)
            .toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.50,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Text(
                  currentTask.title,
                  style: TsTypography.sectionTitle(palette),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentTask.subjectName} · ${currentTask.topic}',
                  style: TsTypography.caption(palette),
                ),
                const SizedBox(height: 16),
                Text('Soal', style: TsTypography.caption(palette)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.page,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.line),
                  ),
                  child: RichStudyText(text: currentTask.questionText),
                ),
                const SizedBox(height: 16),
                Text('Jawabanmu', style: TsTypography.caption(palette)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.page,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.line),
                  ),
                  child: RichStudyText(
                    text: currentTask.userAnswerText,
                    style: TsTypography.cardAnswer(palette),
                  ),
                ),
                const SizedBox(height: 16),
                VerdictTag(
                  verdict: currentTask.effectiveVerdict,
                  isUserOverridden: currentTask.isUserOverridden,
                  onOverrideVerdict: (newVerdict) {
                    ref
                        .read(appStoreProvider.notifier)
                        .overrideTaskVerdict(currentTask.id, newVerdict);
                  },
                ),
                if (currentTask.mistakeStep != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.page,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.penRed),
                    ),
                    child: Text(
                      currentTask.mistakeStep!,
                      style: TsTypography.caption(
                        palette,
                        color: palette.penRed,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Kartu belajar dari soal ini (${taskCards.length})',
                  style: TsTypography.buttonAndChip(palette),
                ),
                const SizedBox(height: 8),
                for (final c in taskCards)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.page,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.type.label,
                          style: TsTypography.caption(
                            palette,
                            color: palette.stabilo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichStudyText(
                          text: c.promptText,
                          style: TsTypography.cardAnswer(palette),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      widget.onStartStudyForSubject(currentTask.subjectId);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primaryAction,
                      foregroundColor: palette.onPrimaryAction,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Mulai belajar',
                      style: TsTypography.buttonAndChip(
                        palette,
                        color: palette.onPrimaryAction,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTask(BuildContext context, TaskItemModel task) {
    final palette = context.tsPalette;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: palette.raised,
          title: Text(
            'Hapus tugas ini?',
            style: TsTypography.sectionTitle(palette),
          ),
          content: Text(
            'Menghapus tugas akan ikut menghapus kartu belajar dan catatan terkait.',
            style: TsTypography.caption(palette),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Batal', style: TsTypography.buttonAndChip(palette)),
            ),
            TextButton(
              onPressed: () {
                ref.read(appStoreProvider.notifier).deleteTask(task.id);
                Navigator.of(dialogCtx).pop();
              },
              child: Text(
                'Hapus',
                style: TsTypography.buttonAndChip(
                  palette,
                  color: palette.penRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAddSubjectDialog(BuildContext context, TsPalette palette) {
    final nameController = TextEditingController();
    String selectedColorKey = 'matematika';
    const colorOptions = <({String key, String label})>[
      (key: 'matematika', label: 'Matematika'),
      (key: 'fisika', label: 'Fisika'),
      (key: 'kimia', label: 'Kimia'),
      (key: 'biologi', label: 'Biologi'),
      (key: 'ips', label: 'Rumpun IPS'),
      (key: 'bahasa', label: 'Bahasa'),
      (key: 'agama', label: 'Pendidikan Agama'),
      (key: 'umum', label: 'Lainnya dan Umum'),
    ];

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.raised,
              title: Text(
                'Tambah mapel sendiri',
                style: TsTypography.sectionTitle(palette),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    style: TsTypography.cardAnswer(palette),
                    decoration: InputDecoration(
                      hintText: 'Mis. Bahasa Jepang, Kalkulus',
                      hintStyle: TsTypography.caption(palette),
                      filled: true,
                      fillColor: palette.page,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilih warna sampul',
                    style: TsTypography.caption(palette),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in colorOptions)
                        SubjectChip(
                          label: opt.label,
                          coverColor: palette.coverColorByKey(opt.key),
                          isSelected: selectedColorKey == opt.key,
                          onTap: () => setDialogState(
                            () => selectedColorKey = opt.key,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Batal',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(appStoreProvider.notifier)
                        .addCustomSubject(
                          name: nameController.text,
                          colorKey: selectedColorKey,
                        );
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
