import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/subject_cover.dart';
import '../../data/repositories/app_store_provider.dart';

/// Layar **Onboarding 3 Langkah** sesuai Bagian 7 & 13 PRD dan Bagian 2, 11 `design.md`:
/// - Langkah 1: Pilih jenjang pendidikan (SMA, SMK, atau Kuliah tahun awal).
/// - Langkah 2: Pilih mata pelajaran yang paling sering kamu kerjakan.
/// - Langkah 3: Atur jam pengingat harian (maksimal 1 per hari bila ada kartu jatuh tempo).
/// - Aturan Privasi (Bagian 13 PRD): Izin kamera TIDAK diminta di awal onboarding,
///   melainkan baru diminta saat pengguna pertama kali membuka fitur Scan.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _selectedLevel = 'SMA';
  final Set<String> _selectedSubjectIds = {
    'sub-math',
    'sub-phys',
    'sub-chem',
    'sub-hist',
  };
  String _selectedReminderTime = '19:30';

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indikator langkah sederhana (1 dari 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TugasScroll',
                    style: TsTypography.sectionTitle(palette),
                  ),
                  Text(
                    'Langkah ${_step + 1} dari 3',
                    style: TsTypography.caption(palette),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: switch (_step) {
                  0 => _buildStepLevel(palette),
                  1 => _buildStepSubjects(palette, store),
                  _ => _buildStepReminder(palette),
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.ink,
                            side: BorderSide(color: palette.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Kembali',
                            style: TsTypography.buttonAndChip(palette),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            notifier.setReminderTime(_selectedReminderTime);
                            notifier.completeOnboarding(
                              educationLevel: _selectedLevel,
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primaryAction,
                          foregroundColor: palette.onPrimaryAction,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _step < 2 ? 'Lanjut' : 'Mulai belajar',
                          style: TsTypography.buttonAndChip(
                            palette,
                            color: palette.onPrimaryAction,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepLevel(TsPalette palette) {
    const levels = <({String code, String title, String subtitle})>[
      (
        code: 'SMA',
        title: 'SMA / MA',
        subtitle: 'Kelas 10, 11, atau 12 untuk semua mata pelajaran sekolah',
      ),
      (
        code: 'SMK',
        title: 'SMK',
        subtitle: 'Mata pelajaran umum dan kejuruan',
      ),
      (
        code: 'Kuliah',
        title: 'Mahasiswa tahun awal',
        subtitle: 'Kalkulus, fisika dasar, kimia dasar, dan latihan kuis',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih jenjang belajarmu',
          style: TsTypography.screenTitle(palette),
        ),
        const SizedBox(height: 8),
        Text(
          'Tugas yang sudah selesai dikerjakan akan diubah menjadi halaman belajar singkat sebelum ujian.',
          style: TsTypography.cardAnswer(palette),
        ),
        const SizedBox(height: 24),
        for (final item in levels) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: palette.page,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedLevel == item.code
                    ? palette.stabilo
                    : palette.line,
                width: _selectedLevel == item.code ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              onTap: () => setState(() => _selectedLevel = item.code),
              title: Text(
                item.title,
                style: TsTypography.sectionTitle(palette),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.subtitle,
                  style: TsTypography.caption(palette),
                ),
              ),
              trailing: Icon(
                _selectedLevel == item.code
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.circle,
                color: _selectedLevel == item.code
                    ? palette.stabilo
                    : palette.pencil,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepSubjects(TsPalette palette, AppStoreState store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih mapel yang sering kamu pelajari',
          style: TsTypography.screenTitle(palette),
        ),
        const SizedBox(height: 8),
        Text(
          'Kamu tetap bisa menambah mapel sendiri kapan saja dari Arsip.',
          style: TsTypography.cardAnswer(palette),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final sub in store.subjects)
                  SubjectChip(
                    label: sub.name,
                    coverColor: palette.coverColorByKey(sub.colorKey),
                    isSelected: _selectedSubjectIds.contains(sub.id),
                    onTap: () {
                      setState(() {
                        if (_selectedSubjectIds.contains(sub.id)) {
                          _selectedSubjectIds.remove(sub.id);
                        } else {
                          _selectedSubjectIds.add(sub.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepReminder(TsPalette palette) {
    const times = ['16:00', '19:00', '19:30', '20:30'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atur jam pengingat ulang',
          style: TsTypography.screenTitle(palette),
        ),
        const SizedBox(height: 8),
        Text(
          'Pengingat hanya muncul maksimal satu kali sehari bila memang ada kartu yang jatuh tempo.',
          style: TsTypography.cardAnswer(palette),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final time in times)
              SubjectChip(
                label: 'Pukul $time',
                coverColor: palette.stabilo,
                isSelected: _selectedReminderTime == time,
                onTap: () => setState(() => _selectedReminderTime = time),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.shieldCheck,
                color: palette.penGreen,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Izin kamera baru akan diminta saat kamu menekan tombol Scan tugas. Foto tugas disimpan privat di perangkatmu.',
                  style: TsTypography.caption(palette, color: palette.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
