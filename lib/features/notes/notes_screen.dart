import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/mini_player_and_states.dart';
import '../../core/widgets/page_card.dart';
import '../../core/widgets/rich_study_text.dart';
import '../../core/widgets/stabilo_mark.dart';
import '../../core/widgets/subject_cover.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';

/// Layar **Catatan** sesuai Bagian 6.6 PRD & Bagian 5, 7, 11 `design.md`:
/// - Kertas bergaris (`PaperPattern.ruled`) untuk catatan.
/// - Pencarian dan filter per mapel.
/// - Catatan yang ditandai `showInFeed` otomatis ikut muncul sebagai kartu di Feed Belajar.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';
  String? _selectedSubjectFilter;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final filteredNotes = store.notes.where((note) {
      if (_selectedSubjectFilter != null &&
          note.subjectId != _selectedSubjectFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return note.body.toLowerCase().contains(q) ||
            note.subjectName.toLowerCase().contains(q) ||
            (note.taskTitle?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Catatan',
                  style: TsTypography.screenTitle(
                    palette,
                    dyslexiaFriendly: store.dyslexiaFriendlyFont,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    _openNoteEditorSheet(context, palette, store, notifier),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryAction,
                  foregroundColor: palette.onPrimaryAction,
                  minimumSize: const Size(48, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                label: Text(
                  'Tulis catatan',
                  style: TsTypography.buttonAndChip(
                    palette,
                    color: palette.onPrimaryAction,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kolom pencarian catatan
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: TsTypography.cardAnswer(palette),
            decoration: InputDecoration(
              hintText: 'Cari isi catatan atau nama mapel...',
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
          const SizedBox(height: 10),

          // Filter mapel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SubjectChip(
                  label: 'Semua mapel',
                  coverColor: palette.stabilo,
                  isSelected: _selectedSubjectFilter == null,
                  onTap: () => setState(() => _selectedSubjectFilter = null),
                ),
                const SizedBox(width: 8),
                for (final s in store.subjects.take(8)) ...[
                  SubjectChip(
                    label: s.name,
                    coverColor: palette.coverColorByKey(s.colorKey),
                    isSelected: _selectedSubjectFilter == s.id,
                    onTap: () => setState(() => _selectedSubjectFilter = s.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: filteredNotes.isEmpty
                ? EmptyState(
                    message:
                        'Belum ada catatan. Tulis rangkuman rumus atau langkah yang sering terlupa.',
                    actionLabel: 'Tulis catatan',
                    onAction: () => _openNoteEditorSheet(
                      context,
                      palette,
                      store,
                      notifier,
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return SizedBox(
                        height: 185,
                        child: PageCard(
                          subjectCoverColor: palette.coverColorByKey(
                            note.subjectColorKey,
                          ),
                          pattern: PaperPattern.ruled,
                          showStackedPages: false,
                          onTap: () => _openNoteEditorSheet(
                            context,
                            palette,
                            store,
                            notifier,
                            existingNote: note,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${note.subjectName} · ${note.taskTitle ?? "Catatan bebas"}',
                                      style: TsTypography.caption(palette),
                                    ),
                                  ),
                                  if (note.showInFeed)
                                    StabiloMark(
                                      child: Text(
                                        'Tampil di feed',
                                        style: TsTypography.caption(
                                          palette,
                                          color: palette.ink,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () =>
                                        notifier.deleteNote(note.id),
                                    tooltip: 'Hapus catatan',
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
                              const SizedBox(height: 8),
                              RichStudyText(
                                text: note.body,
                                style: TsTypography.noteBody(
                                  palette,
                                  dyslexiaFriendly: store.dyslexiaFriendlyFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openNoteEditorSheet(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
    AppStoreNotifier notifier, {
    NoteModel? existingNote,
  }) {
    final controller = TextEditingController(text: existingNote?.body ?? '');
    String selectedSubjectId =
        existingNote?.subjectId ?? store.subjects.first.id;
    bool showInFeed = existingNote?.showInFeed ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedSubject = store.subjects.firstWhere(
              (s) => s.id == selectedSubjectId,
              orElse: () => store.subjects.first,
            );
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
                    existingNote == null ? 'Tulis catatan' : 'Edit catatan',
                    style: TsTypography.sectionTitle(palette),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in store.subjects.take(8)) ...[
                          SubjectChip(
                            label: s.name,
                            coverColor: palette.coverColorByKey(s.colorKey),
                            isSelected: s.id == selectedSubjectId,
                            onTap: () => setSheetState(
                              () => selectedSubjectId = s.id,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    autofocus: true,
                    style: TsTypography.noteBody(palette),
                    decoration: InputDecoration(
                      hintText:
                          'Tulis catatan dengan bahasamu sendiri. Gunakan \$...\$ bila ingin menulis rumus...',
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
                    onChanged: (v) =>
                        setSheetState(() => showInFeed = v ?? false),
                    title: Text(
                      'Tampilkan di feed belajar',
                      style: TsTypography.caption(palette, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        notifier.saveNote(
                          noteId: existingNote?.id,
                          subject: selectedSubject,
                          body: controller.text,
                          showInFeed: showInFeed,
                          taskId: existingNote?.taskId,
                          cardId: existingNote?.cardId,
                          taskTitle: existingNote?.taskTitle,
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
