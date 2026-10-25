import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/rich_study_text.dart';
import '../../core/widgets/stabilo_mark.dart';
import '../../core/widgets/subject_cover.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';
import '../ai/ai_cross_verifier.dart';

/// Layar **Scan Tugas** dan **Cek Hasil Scan** sesuai Bagian 6.2 PRD & Bagian 7.3 `design.md`:
/// - Layar Kamera: cincin shutter tebal polos berwarna kapur (`ink`), tanpa cahaya neon,
///   saran memotong bagian nama/NIS demi privasi, dukungan tambah halaman (maks 10 foto),
///   serta opsi input ketik/paste sebagai cadangan.
/// - Layar Cek Hasil Scan: foto halaman yang bisa dilipat di atas, daftar soal dan jawaban
///   pengguna di bawah yang bisa diedit, digabung, dipisah, atau dihapus.
/// - Bagian yang diragukan AI (`low_confidence_parts`) diberi tanda `StabiloMark` bergaris putus-putus agar dicek lebih dulu.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    required this.onSavedAndGoToFeed,
  });

  final ValueChanged<String?> onSavedAndGoToFeed;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _inReviewStep = false;
  bool _photoPreviewCollapsed = false;
  int _capturedPageCount = 1;
  String? _selectedSubjectId;
  final TextEditingController _topicController = TextEditingController(
    text: 'Turunan & aplikasi fungsi',
  );
  List<_EditableScanEntry> _entries = [];

  @override
  void dispose() {
    _topicController.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _simulateCaptureAndReadWithAi() {
    for (final e in _entries) {
      e.dispose();
    }
    setState(() {
      _inReviewStep = true;
      _entries = [
        _EditableScanEntry(
          question: r'Turunan dari $f(x) = 3x^2 + 2x$ adalah ...',
          userAnswer: r"$f'(x) = 6x + 2$",
          confidence: 0.92,
          lowConfidenceParts: const [],
        ),
        _EditableScanEntry(
          question: r'Tentukan nilai $f(x) = x^3 - 4x$ saat $x = 2$',
          userAnswer: r'$f(2) = 8 - 8 = 0$',
          confidence: 0.71,
          lowConfidenceParts: const ['x^3 - 4x'],
        ),
      ];
    });
  }

  void _startManualEntry() {
    for (final e in _entries) {
      e.dispose();
    }
    setState(() {
      _inReviewStep = true;
      _photoPreviewCollapsed = true;
      _entries = [
        _EditableScanEntry(
          question: '',
          userAnswer: '',
          confidence: 1.0,
          lowConfidenceParts: const [],
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);

    if (!_inReviewStep) {
      return _buildCameraCaptureStep(context, palette);
    }

    return _buildCheckResultStep(context, palette, store);
  }

  /// Tahap 1: Kamera & Potong Dokumen (Bagian 6.2 PRD & Bagian 7.3 design.md)
  Widget _buildCameraCaptureStep(BuildContext context, TsPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scan tugas', style: TsTypography.screenTitle(palette)),
              TextButton.icon(
                onPressed: _startManualEntry,
                style: TextButton.styleFrom(foregroundColor: palette.penBlue),
                icon: const Icon(PhosphorIconsRegular.keyboard, size: 18),
                label: Text(
                  'Ketik manual',
                  style: TsTypography.buttonAndChip(
                    palette,
                    color: palette.penBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Potong bagian nama atau nomor indukmu sebelum menyimpan foto.',
            style: TsTypography.caption(palette),
          ),
          const SizedBox(height: 12),

          // Viewfinder lembar tugas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.page,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.line, width: 1),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.raised,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: palette.line),
                        ),
                        child: Text(
                          'Halaman $_capturedPageCount dari 10',
                          style: TsTypography.caption(
                            palette,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _capturedPageCount < 10
                            ? () => setState(() => _capturedPageCount++)
                            : null,
                        icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                        label: const Text('Tambah halaman'),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        PhosphorIconsRegular.FileText,
                        size: 48,
                        color: palette.pencil,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Posisikan lembar buku tulis atau kertas ulangan di dalam bingkai.',
                        textAlign: TextAlign.center,
                        style: TsTypography.cardAnswer(palette),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Otomatis dipotong, diluruskan, dan dihapus data lokasi EXIF.',
                        textAlign: TextAlign.center,
                        style: TsTypography.caption(palette),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pilih dari galeri
                      OutlinedButton.icon(
                        onPressed: _simulateCaptureAndReadWithAi,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.ink,
                          minimumSize: const Size(110, 48),
                          side: BorderSide(color: palette.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(PhosphorIconsRegular.image, size: 20),
                        label: Text(
                          'Galeri',
                          style: TsTypography.buttonAndChip(palette),
                        ),
                      ),

                      // Tombol shutter berupa cincin tebal polos berwarna kapur (Bagian 7.3 design.md)
                      Semantics(
                        button: true,
                        label: 'Ambil foto lembar tugas',
                        child: GestureDetector(
                          onTap: _simulateCaptureAndReadWithAi,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.ink,
                                width: 5,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.ink.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Simulasi kondisi offline (antrean AI)
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Foto sudah tersimpan. Akan dibaca saat kamu online.',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.pencil,
                          minimumSize: const Size(110, 48),
                          side: BorderSide(color: palette.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          PhosphorIconsRegular.cloudArrowUp,
                          size: 20,
                        ),
                        label: Text(
                          'Antre',
                          style: TsTypography.caption(
                            palette,
                            color: palette.ink,
                          ),
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
    );
  }

  /// Tahap 2: Layar Cek Hasil Scan (Bagian 6.2 PRD & Bagian 7.3 design.md)
  Widget _buildCheckResultStep(
    BuildContext context,
    TsPalette palette,
    AppStoreState store,
  ) {
    final SubjectModel activeSubject = store.subjects.firstWhere(
      (s) => s.id == (_selectedSubjectId ?? 'sub-math'),
      orElse: () => store.subjects.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Cek hasil scan + Tombol Simpan
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _inReviewStep = false),
                tooltip: 'Ulangi foto',
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: palette.ink),
              ),
              Expanded(
                child: Text(
                  'Cek hasil scan',
                  style: TsTypography.screenTitle(palette),
                ),
              ),
              FilledButton(
                onPressed: () => _saveVerifiedResults(activeSubject),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryAction,
                  foregroundColor: palette.onPrimaryAction,
                  minimumSize: const Size(88, 44),
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
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              children: [
                // 1. Foto halaman (bisa dilipat sesuai Bagian 7.3 design.md)
                Container(
                  decoration: BoxDecoration(
                    color: palette.page,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _photoPreviewCollapsed = !_photoPreviewCollapsed;
                          });
                        },
                        title: Text(
                          'Foto halaman ($_capturedPageCount lembar)',
                          style: TsTypography.buttonAndChip(palette),
                        ),
                        subtitle: Text(
                          _photoPreviewCollapsed
                              ? 'Ketuk untuk melihat foto asli'
                              : 'Bagian bertanda stabilo perlu kamu cek lebih dulu',
                          style: TsTypography.caption(palette),
                        ),
                        trailing: Icon(
                          _photoPreviewCollapsed
                              ? PhosphorIconsRegular.caretDown
                              : PhosphorIconsRegular.caretUp,
                          color: palette.ink,
                        ),
                      ),
                      if (!_photoPreviewCollapsed)
                        Container(
                          height: 110,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.raised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.line),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.imageSquare,
                                size: 36,
                                color: palette.pencil,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pratinjau foto lembar tugas tersimpan di penyimpanan privat perangkat.',
                                  style: TsTypography.caption(palette),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Pilihan Mapel & Topik
                Text('Pilih mapel', style: TsTypography.caption(palette)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in store.subjects.take(10)) ...[
                        SubjectChip(
                          label: s.name,
                          coverColor: palette.coverColorByKey(s.colorKey),
                          isSelected: s.id == activeSubject.id,
                          onTap: () {
                            setState(() => _selectedSubjectId = s.id);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicController,
                  style: TsTypography.cardAnswer(palette),
                  decoration: InputDecoration(
                    labelText: 'Topik tugas',
                    labelStyle: TsTypography.caption(palette),
                    filled: true,
                    fillColor: palette.page,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: palette.line),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Daftar Soal Hasil Bacaan AI (bisa diedit, digabung, ditambah, dihapus)
                for (int i = 0; i < _entries.length; i++) ...[
                  _buildEditableQuestionCard(context, palette, i, _entries[i]),
                  const SizedBox(height: 12),
                ],

                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _entries.add(
                        _EditableScanEntry(
                          question: '',
                          userAnswer: '',
                          confidence: 1.0,
                          lowConfidenceParts: const [],
                        ),
                      );
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.ink,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: palette.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                  label: Text(
                    'Tambah soal lain dari halaman ini',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableQuestionCard(
    BuildContext context,
    TsPalette palette,
    int index,
    _EditableScanEntry entry,
  ) {
    final bool hasLowConfidence = entry.lowConfidenceParts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasLowConfidence ? palette.stabilo : palette.line,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Soal ${index + 1}',
                  style: TsTypography.sectionTitle(palette),
                ),
              ),
              if (hasLowConfidence)
                StabiloMark(
                  isLowConfidence: true,
                  child: Text(
                    'Perlu dicek: ${entry.lowConfidenceParts.join(", ")}',
                    style: TsTypography.caption(palette, color: palette.ink),
                  ),
                ),
              if (index > 0)
                IconButton(
                  onPressed: () => _mergeWithPrevious(index),
                  tooltip: 'Gabung ke soal sebelumnya',
                  icon: Icon(
                    PhosphorIconsRegular.arrowsMerge,
                    size: 18,
                    color: palette.pencil,
                  ),
                ),
              if (_entries.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      final removed = _entries.removeAt(index);
                      removed.dispose();
                    });
                  },
                  tooltip: 'Hapus soal ini',
                  icon: Icon(
                    PhosphorIconsRegular.trash,
                    size: 18,
                    color: palette.penRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.questionController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: TsTypography.cardAnswer(palette),
            decoration: InputDecoration(
              labelText: 'Teks soal (gunakan \$...\$ untuk rumus LaTeX)',
              labelStyle: TsTypography.caption(palette),
              filled: true,
              fillColor: palette.raised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.line),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: entry.answerController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            style: TsTypography.cardAnswer(palette),
            decoration: InputDecoration(
              labelText: 'Jawabanmu',
              labelStyle: TsTypography.caption(palette),
              filled: true,
              fillColor: palette.raised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.line),
              ),
            ),
          ),
          if (entry.questionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Pratinjau rumus dan teks:',
              style: TsTypography.caption(palette),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.line),
              ),
              child: RichStudyText(
                text: entry.questionController.text,
                lowConfidenceParts: entry.lowConfidenceParts,
                style: TsTypography.cardAnswer(palette),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _mergeWithPrevious(int index) {
    if (index <= 0) return;
    setState(() {
      final prev = _entries[index - 1];
      final current = _entries.removeAt(index);
      prev.questionController.text =
          '${prev.questionController.text}\n${current.questionController.text}';
      prev.answerController.text =
          '${prev.answerController.text}\n${current.answerController.text}';
      current.dispose();
    });
  }

  void _saveVerifiedResults(SubjectModel subject) {
    final validItems = _entries
        .where((e) => e.questionController.text.trim().isNotEmpty)
        .map(
          (e) => ScannedQuestionItem(
            question: e.questionController.text.trim(),
            userAnswer: e.answerController.text.trim(),
            confidence: e.confidence,
            lowConfidenceParts: e.lowConfidenceParts,
          ),
        )
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi minimal satu soal sebelum menyimpan.'),
        ),
      );
      return;
    }

    ref.read(appStoreProvider.notifier).saveVerifiedScanItems(
          subject: subject,
          topic: _topicController.text.trim(),
          verifiedItems: validItems,
        );

    // Aturan bahasa antarmuka (Bagian 11 design.md): tombol "Simpan" menghasilkan pesan "Tersimpan"
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tersimpan')),
    );
    widget.onSavedAndGoToFeed(subject.id);
  }
}

class _EditableScanEntry {
  _EditableScanEntry({
    required String question,
    required String userAnswer,
    required this.confidence,
    required this.lowConfidenceParts,
  }) : questionController = TextEditingController(text: question),
       answerController = TextEditingController(text: userAnswer);

  final TextEditingController questionController;
  final TextEditingController answerController;
  final double confidence;
  final List<String> lowConfidenceParts;

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }
}
