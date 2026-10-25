import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/ts_palette.dart';
import '../../core/theme/ts_typography.dart';
import '../../core/widgets/subject_cover.dart';
import '../../data/local/models.dart';
import '../../data/repositories/app_store_provider.dart';
import '../ai/ai_service.dart';

/// Tab kategori pemilih musik bergaya Instagram (Bagian 10 `design.md`).
enum MusicPickerTab {
  forYou('Untuk kamu'),
  bySubject('Per mapel'),
  saved('Tersimpan'),
  localFiles('File HP');

  const MusicPickerTab(this.label);
  final String label;
}

/// Membuka Bottom Sheet pemilih musik latar bergaya Instagram (sesuai foto referensi pengguna & Bagian 10 `design.md`):
/// - Drag handle di atas
/// - Search bar bulat (`Cari...`)
/// - 4 Pill filter horizontal (`Untuk kamu`, `Per mapel`, `Tersimpan`, `File HP`) dengan tab aktif berwarna kontras terang
/// - Daftar lagu vertikal: thumbnail kotak kecil 48×48 dp (radius 8 dp) di kiri, judul lagu tebal + `artis/suasana • durasi` di tengah,
///   dan tombol Bookmark (`Tersimpan`) di kanan.
void showMusicPlaylistSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return const _InstagramStyleMusicSheet();
    },
  );
}

class _InstagramStyleMusicSheet extends ConsumerStatefulWidget {
  const _InstagramStyleMusicSheet();

  @override
  ConsumerState<_InstagramStyleMusicSheet> createState() =>
      _InstagramStyleMusicSheetState();
}

class _InstagramStyleMusicSheetState
    extends ConsumerState<_InstagramStyleMusicSheet> {
  MusicPickerTab _activeTab = MusicPickerTab.forYou;
  String _searchQuery = '';
  String? _selectedSubjectColorKey;
  double _volume = 0.75;
  bool _showAudioControls = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final List<MusicTrackModel> filteredTracks = store.tracks.where((track) {
      // Filter berdasarkan tab pill
      switch (_activeTab) {
        case MusicPickerTab.forYou:
          break;
        case MusicPickerTab.bySubject:
          if (_selectedSubjectColorKey != null &&
              track.subjectColorKey != _selectedSubjectColorKey) {
            return false;
          }
        case MusicPickerTab.saved:
          if (!track.isBookmarked) return false;
        case MusicPickerTab.localFiles:
          if (track.sourceType != 'local_file') return false;
      }

      // Filter pencarian teks
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return track.title.toLowerCase().contains(q) ||
            track.artist.toLowerCase().contains(q) ||
            track.playlistName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.50,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: palette.line, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag handle di tengah atas (persis foto referensi Instagram)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.pencil.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Search Bar bulat ("Cari...") + tombol volume/sleep timer ringkas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.raised,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TsTypography.cardAnswer(palette),
                          decoration: InputDecoration(
                            hintText: 'Cari...',
                            hintStyle: TsTypography.cardAnswer(
                              palette,
                            ).copyWith(color: palette.pencil),
                            prefixIcon: Icon(
                              PhosphorIconsRegular.magnifyingGlass,
                              color: palette.pencil,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(
                          () => _showAudioControls = !_showAudioControls,
                        );
                      },
                      tooltip: 'Pengatur volume dan waktu tidur',
                      style: IconButton.styleFrom(
                        backgroundColor: _showAudioControls
                            ? palette.stabilo
                            : palette.raised,
                      ),
                      icon: Icon(
                        PhosphorIconsRegular.slidersHorizontal,
                        size: 20,
                        color: _showAudioControls ? palette.bg : palette.ink,
                      ),
                    ),
                  ],
                ),
              ),

              // Panel ringkas Volume & Sleep Timer bila tombol slider diketuk
              if (_showAudioControls)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.page,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              onChanged: (v) {
                                setState(() => _volume = v);
                                notifier.setMusicVolume(v);
                              },
                            ),
                          ),
                          Icon(
                            PhosphorIconsRegular.speakerHigh,
                            size: 18,
                            color: palette.pencil,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Waktu tidur:',
                            style: TsTypography.caption(palette),
                          ),
                          for (final minutes in <int?>[null, 15, 30, 45])
                            SubjectChip(
                              label: minutes == null
                                  ? 'Mati'
                                  : '$minutes menit',
                              coverColor: palette.stabilo,
                              isSelected: store.sleepTimerMinutes == minutes,
                              onTap: () => notifier.setSleepTimer(minutes),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // 3. Baris 4 Pill Filter Horizontal (Untuk kamu | Per mapel | Tersimpan | File HP)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: MusicPickerTab.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = MusicPickerTab.values[index];
                    final bool isSelected = _activeTab == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          // Pill aktif berwarna kontras terang (ink) dengan teks gelap (bg) seperti foto Instagram
                          color: isSelected ? palette.ink : palette.raised,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab.label,
                          style: TsTypography.buttonAndChip(
                            palette,
                            color: isSelected ? palette.bg : palette.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Sub-filter mapel saat tab "Per mapel" dipilih
              if (_activeTab == MusicPickerTab.bySubject) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SubjectChip(
                        label: 'Semua mapel',
                        coverColor: palette.stabilo,
                        isSelected: _selectedSubjectColorKey == null,
                        onTap: () =>
                            setState(() => _selectedSubjectColorKey = null),
                      ),
                      const SizedBox(width: 8),
                      for (final cluster in const [
                        ('matematika', 'Matematika'),
                        ('fisika', 'Fisika'),
                        ('kimia', 'Kimia'),
                        ('biologi', 'Biologi'),
                        ('ips', 'Sejarah & IPS'),
                        ('bahasa', 'Bahasa'),
                        ('agama', 'Pendidikan Agama'),
                      ]) ...[
                        SubjectChip(
                          label: cluster.$2,
                          coverColor: palette.coverColorByKey(cluster.$1),
                          isSelected: _selectedSubjectColorKey == cluster.$1,
                          onTap: () => setState(
                            () => _selectedSubjectColorKey = cluster.$1,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],

              // Tombol "+ Tambah lagu dari HP" saat di tab "File HP"
              if (_activeTab == MusicPickerTab.localFiles)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddLocalFileDialog(context, palette, notifier),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.ink,
                      minimumSize: const Size.fromHeight(44),
                      side: BorderSide(color: palette.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.folderOpen, size: 18),
                    label: Text(
                      'Tambah file audio dari penyimpanan HP',
                      style: TsTypography.buttonAndChip(palette),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // 4. Daftar Lagu Vertikal bergaya Instagram
              Expanded(
                child: filteredTracks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _activeTab == MusicPickerTab.saved
                                ? 'Belum ada musik yang disimpan. Ketuk ikon markah di kanan lagu untuk menyimpan.'
                                : _activeTab == MusicPickerTab.localFiles
                                ? 'Belum ada file audio dari HP. Ketuk tombol di atas untuk menambahkan.'
                                : 'Tidak ditemukan lagu yang cocok.',
                            textAlign: TextAlign.center,
                            style: TsTypography.caption(palette),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredTracks.length,
                        itemBuilder: (context, index) {
                          final track = filteredTracks[index];
                          final int originalIndex = store.tracks.indexWhere(
                            (t) => t.id == track.id,
                          );
                          final bool isCurrentTrack =
                              originalIndex == store.currentTrackIndex;
                          final bool isPlayingNow =
                              isCurrentTrack && store.isMusicPlaying;
                          final Color coverAccent = palette.coverColorByKey(
                            track.subjectColorKey,
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (originalIndex >= 0) {
                                if (isCurrentTrack) {
                                  notifier.toggleMusicPlay();
                                } else {
                                  notifier.selectTrack(originalIndex);
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  // Kiri: Thumbnail kotak membulat 48×48 dp dengan aksen sampul mapel
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: palette.raised,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrentTrack
                                            ? palette.stabilo
                                            : coverAccent.withValues(
                                                alpha: 0.65,
                                              ),
                                        width: isCurrentTrack ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 5,
                                            decoration: BoxDecoration(
                                              color: coverAccent,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    left: Radius.circular(6),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isPlayingNow
                                              ? PhosphorIconsRegular.pause
                                              : PhosphorIconsRegular.musicNotes,
                                          size: 22,
                                          color: isCurrentTrack
                                              ? palette.stabilo
                                              : palette.ink,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Tengah: Judul lagu tebal + "artis/suasana • durasi"
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TsTypography.buttonAndChip(
                                            palette,
                                            color: isCurrentTrack
                                                ? palette.stabilo
                                                : palette.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${track.artist} • ${track.formattedDuration}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TsTypography.caption(palette),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Kanan: Ikon Bookmark ("Tersimpan") persis seperti Instagram
                                  IconButton(
                                    onPressed: () =>
                                        notifier.toggleBookmarkTrack(track.id),
                                    tooltip: track.isBookmarked
                                        ? 'Hapus dari Tersimpan'
                                        : 'Simpan musik ini',
                                    icon: Icon(
                                      track.isBookmarked
                                          ? PhosphorIconsFill.bookmarkSimple
                                          : PhosphorIconsRegular.bookmarkSimple,
                                      color: track.isBookmarked
                                          ? palette.stabilo
                                          : palette.ink,
                                      size: 22,
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
      },
    );
  }

  void _showAddLocalFileDialog(
    BuildContext context,
    TsPalette palette,
    AppStoreNotifier notifier,
  ) {
    final titleCtrl = TextEditingController();
    final pathCtrl = TextEditingController(
      text: '/sdcard/Music/',
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: palette.raised,
          title: Text(
            'Tambah musik dari HP',
            style: TsTypography.sectionTitle(palette),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TsTypography.cardAnswer(palette),
                decoration: InputDecoration(
                  labelText: 'Judul lagu',
                  labelStyle: TsTypography.caption(palette),
                  hintText: 'Mis. Lagu belajar favoritku',
                  filled: true,
                  fillColor: palette.page,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pathCtrl,
                style: TsTypography.cardAnswer(palette),
                decoration: InputDecoration(
                  labelText: 'Lokasi file (.mp3 / .wav / .m4a)',
                  labelStyle: TsTypography.caption(palette),
                  filled: true,
                  fillColor: palette.page,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Batal', style: TsTypography.buttonAndChip(palette)),
            ),
            FilledButton(
              onPressed: () {
                notifier.addLocalAudioTrack(
                  title: titleCtrl.text,
                  filePath: pathCtrl.text,
                );
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

/// Layar **Pengaturan & Konfigurasi OpenRouter AI** sesuai Bagian 7, 8, 13 PRD dan Bagian 3, 10, 12 `design.md`:
/// - **OpenRouter AI Multi-Model:** Input API Key (`sk-or-v1-...`), pilihan cepat model Vision gratis/murah
///   (`Gemini 2.0 Flash Free`, `Qwen 2.5 VL 72B Free`, `Llama 3.2 Vision Free`, `GPT-4o mini`),
///   input ID model bebas, serta model cadangan otomatis saat model utama kena limit.
/// - **Tema Halaman:** `Malam` (default), `Siang`, atau `Ikut sistem`.
/// - **Aksesibilitas:** Font ramah disleksia (`Atkinson Hyperlegible`), tombol navigasi kartu.
/// - **Sesi & Pengingat:** 10/20/30 kartu per sesi, jam pengingat harian.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  late TextEditingController _primaryModelController;
  late TextEditingController _fallbackModelController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final store = ref.read(appStoreProvider);
    _primaryModelController = TextEditingController(
      text: store.openRouterModel,
    );
    _fallbackModelController = TextEditingController(
      text: store.openRouterFallbackModel,
    );
    _loadSavedKey();
  }

  Future<void> _loadSavedKey() async {
    final key = await AiService.loadOpenRouterApiKey();
    if (!mounted || key == null || key.isEmpty) return;
    setState(() {
      _apiKeyController.text = key;
    });
    ref
        .read(appStoreProvider.notifier)
        .setOpenRouterConfig(
          primaryModel: _primaryModelController.text,
          fallbackModel: _fallbackModelController.text,
          hasKey: true,
        );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _primaryModelController.dispose();
    _fallbackModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        // 1. Konfigurasi Model AI OpenRouter (bebas ganti model saat limit)
        _SectionBox(
          title: 'Model AI (OpenRouter)',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gunakan OpenRouter agar kamu bebas mengganti model AI kapan saja. Jika model utama terkena batas kuota, aplikasi otomatis beralih ke model cadangan.',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                style: TsTypography.cardAnswer(palette),
                decoration: InputDecoration(
                  labelText: 'OpenRouter API Key (sk-or-v1-...)',
                  labelStyle: TsTypography.caption(palette),
                  filled: true,
                  fillColor: palette.raised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: palette.line),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                    icon: Icon(
                      _obscureApiKey
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                      color: palette.pencil,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih cepat model utama (atau ketik ID model OpenRouter di bawah):',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in OpenRouterModelPreset.presets)
                    SubjectChip(
                      label: preset.label,
                      coverColor: palette.stabilo,
                      isSelected:
                          _primaryModelController.text.trim() == preset.id,
                      onTap: () {
                        setState(() {
                          _primaryModelController.text = preset.id;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _primaryModelController,
                style: TsTypography.cardAnswer(palette),
                decoration: InputDecoration(
                  labelText: 'ID model utama OpenRouter',
                  labelStyle: TsTypography.caption(palette),
                  hintText: 'google/gemini-2.0-flash-exp:free',
                  filled: true,
                  fillColor: palette.raised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: palette.line),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fallbackModelController,
                style: TsTypography.cardAnswer(palette),
                decoration: InputDecoration(
                  labelText: 'ID model cadangan otomatis (saat limit 429)',
                  labelStyle: TsTypography.caption(palette),
                  hintText: 'qwen/qwen2.5-vl-72b-instruct:free',
                  filled: true,
                  fillColor: palette.raised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: palette.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () async {
                    await AiService.saveOpenRouterApiKey(
                      _apiKeyController.text,
                    );
                    notifier.setOpenRouterConfig(
                      primaryModel: _primaryModelController.text,
                      fallbackModel: _fallbackModelController.text,
                      hasKey: _apiKeyController.text.trim().isNotEmpty,
                    );
                    if (!context.mounted) return;
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
                  icon: const Icon(PhosphorIconsRegular.check, size: 18),
                  label: Text(
                    'Simpan pengaturan AI',
                    style: TsTypography.buttonAndChip(
                      palette,
                      color: palette.onPrimaryAction,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Musik Latar Bergaya Instagram
        _SectionBox(
          title: 'Musik latar dan lisensi sumber',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih lagu belajar, simpan lagu favoritmu ke tab Tersimpan, atau tambahkan file audio dari penyimpanan HP.',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => showMusicPlaylistSheet(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.ink,
                    side: BorderSide(color: palette.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(PhosphorIconsRegular.musicNotes, size: 18),
                  label: Text(
                    'Pilih musik latar (${store.tracks.length} lagu)',
                    style: TsTypography.buttonAndChip(palette),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Tampilan & Tema (Bagian 3 design.md)
        _SectionBox(
          title: 'Tema halaman',
          palette: palette,
          child: Wrap(
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
        ),
        const SizedBox(height: 14),

        // 4. Aksesibilitas (Bagian 9 & 12 design.md)
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

        // 5. Sesi Belajar & Pengingat (Bagian 6.5 & 6.8 PRD)
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

        // 6. Privasi & Hapus Data (Bagian 13 PRD)
        _SectionBox(
          title: 'Data dan privasi',
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua tugas, kartu, dan catatan disimpan secara lokal di perangkatmu. Kunci API OpenRouter disimpan terenkripsi di perangkat.',
                style: TsTypography.caption(palette),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  notifier.resetOnboarding();
                },
                icon: const Icon(PhosphorIconsRegular.compass, size: 18),
                label: const Text('Buka ulang onboarding (3 langkah)'),
              ),
              const SizedBox(height: 8),
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
