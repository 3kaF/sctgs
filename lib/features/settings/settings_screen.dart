import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/subject_cover.dart';
import '../../data/repositories/app_store_provider.dart';

/// Sheet Musik Latar sesuai Bagian 6.7 PRD & Bagian 10 `design.md`:
/// - Playlist per mapel, volume, pengatur waktu tidur (sleep timer).
/// - Tidak ada sampul album besar.
/// - Menampilkan nama sumber dan lisensi track bawaan (bebas royalti).
void showMusicPlaylistSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return const _MusicSheetContent();
    },
  );
}

class _MusicSheetContent extends ConsumerStatefulWidget {
  const _MusicSheetContent();

  @override
  ConsumerState<_MusicSheetContent> createState() => _MusicSheetContentState();
}

class _MusicSheetContentState extends ConsumerState<_MusicSheetContent> {
  double _volume = 0.70;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Musik latar belajar',
                  style: TsTypography.sectionTitle(palette),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(PhosphorIconsRegular.x, color: palette.ink),
                ),
              ],
            ),
            Text(
              'Suara otomatis mengecil saat ada notifikasi atau telepon.',
              style: TsTypography.caption(palette),
            ),
            const SizedBox(height: 16),

            // Daftar Track Bebas Royalti per Mapel
            for (int i = 0; i < store.tracks.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: palette.page,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: store.currentTrackIndex == i
                        ? palette.stabilo
                        : palette.line,
                  ),
                ),
                child: ListTile(
                  onTap: () => notifier.selectTrack(i),
                  leading: Icon(
                    store.currentTrackIndex == i && store.isMusicPlaying
                        ? PhosphorIconsRegular.pauseCircle
                        : PhosphorIconsRegular.playCircle,
                    color: store.currentTrackIndex == i
                        ? palette.stabilo
                        : palette.ink,
                  ),
                  title: Text(
                    store.tracks[i].title,
                    style: TsTypography.buttonAndChip(palette),
                  ),
                  subtitle: Text(
                    '${store.tracks[i].playlistName} · ${store.tracks[i].licenseNote}',
                    style: TsTypography.caption(palette),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Pengatur Volume
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.speakerLow,
                  size: 18,
                  color: palette.pencil,
                ),
                Expanded(
                  child: Slider(
                    value: _volume,
                    activeColor: palette.stabilo,
                    inactiveColor: palette.line,
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.speakerHigh,
                  size: 18,
                  color: palette.pencil,
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Pengatur waktu tidur (berhenti saat sesi selesai)',
              style: TsTypography.caption(palette),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in <int?>[null, 15, 30, 45])
                  SubjectChip(
                    label: minutes == null ? 'Mati' : '$minutes menit',
                    coverColor: palette.stabilo,
                    isSelected: store.sleepTimerMinutes == minutes,
                    onTap: () => notifier.setSleepTimer(minutes),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar **Pengaturan & Profil Belajar** sesuai Bagian 7 & 13 PRD dan Bagian 3, 10, 12 `design.md`:
/// - Pilihan Tema: `Malam` (default), `Siang`, atau `Ikut sistem`.
/// - Aksesibilitas: Font ramah disleksia (`Atkinson Hyperlegible`), tombol navigasi kartu sebelumnya/berikutnya.
/// - Sesi & Pengingat: jumlah kartu per sesi (10, 20, 30), jam pengingat harian, jam tenang.
/// - Privasi & Penyimpanan: lisensi musik bebas royalti, hapus semua data & foto dari perangkat.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Pengaturan',
          style: TsTypography.screenTitle(
            palette,
            dyslexiaFriendly: store.dyslexiaFriendlyFont,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Tampilan & Tema (Bagian 3 design.md)
        _SectionBox(
          title: 'Tema halaman',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SubjectChip(
                    label: 'Malam (default)',
                    coverColor: palette.stabilo,
                    isSelected: store.themeMode == ThemeMode.dark,
                    onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  ),
                  SubjectChip(
                    label: 'Siang',
                    coverColor: palette.penBlue,
                    isSelected: store.themeMode == ThemeMode.light,
                    onTap: () => notifier.setThemeMode(ThemeMode.light),
                  ),
                  SubjectChip(
                    label: 'Ikut sistem',
                    coverColor: palette.pencil,
                    isSelected: store.themeMode == ThemeMode.system,
                    onTap: () => notifier.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Aksesibilitas (Bagian 9 & 12 design.md)
        _SectionBox(
          title: 'Aksesibilitas dan keterbacaan',
          palette: palette,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: store.dyslexiaFriendlyFont,
                activeColor: palette.stabilo,
                onChanged: notifier.setDyslexiaFriendlyFont,
                title: Text(
                  'Font ramah disleksia (Atkinson Hyperlegible)',
                  style: TsTypography.buttonAndChip(palette),
                ),
                subtitle: Text(
                  'Menggantikan Literata dan Plus Jakarta Sans di semua layar.',
                  style: TsTypography.caption(palette),
                ),
              ),
              Divider(color: palette.line),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: store.showAccessibilityNavButtons,
                activeColor: palette.stabilo,
                onChanged: notifier.setShowAccessibilityNavButtons,
                title: Text(
                  'Tampilkan tombol kartu sebelumnya dan berikutnya',
                  style: TsTypography.buttonAndChip(palette),
                ),
                subtitle: Text(
                  'Alternatif selain gestur swipe atas dan bawah di feed.',
                  style: TsTypography.caption(palette),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Sesi Belajar & Pengingat (Bagian 6.5 & 6.8 PRD)
        _SectionBox(
          title: 'Sesi belajar dan pengingat harian',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batas kartu per sesi (feed berujung)',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final limit in const [10, 20, 30])
                    SubjectChip(
                      label: '$limit kartu',
                      coverColor: palette.stabilo,
                      isSelected: store.sessionCardLimit == limit,
                      onTap: () => notifier.setSessionCardLimit(limit),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pengingat harian: pukul ${store.reminderTime} (maksimal 1 per hari bila ada kartu jatuh tempo, dengan jam tenang malam).',
                style: TsTypography.caption(palette),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Musik & Lisensi (Bagian 10 design.md)
        _SectionBox(
          title: 'Musik latar dan lisensi sumber',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final trk in store.tracks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${trk.title}: ${trk.licenseNote}',
                    style: TsTypography.caption(palette),
                  ),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => showMusicPlaylistSheet(context, ref),
                icon: const Icon(PhosphorIconsRegular.musicNotes, size: 18),
                label: const Text('Buka pengaturan musik'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 5. Privasi & Hapus Data (Bagian 13 PRD)
        _SectionBox(
          title: 'Data dan privasi',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua tugas, kartu, dan catatan disimpan secara lokal di perangkatmu. Foto tugas dihapus dari server segera setelah selesai dibaca AI.',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  notifier.clearAllUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Semua tugas, kartu, dan catatan telah dihapus.',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.penRed,
                  side: BorderSide(color: palette.penRed),
                ),
                icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                label: const Text('Hapus semua data dan foto'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({
    required this.title,
    required this.palette,
    required this.child,
  });

  final String title;
  final TsPalette palette;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TsTypography.sectionTitle(palette)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
