import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'core/theme/ts_palette.dart';
import 'core/theme/ts_typography.dart';
import 'core/widgets/mini_player_and_states.dart';
import 'data/repositories/app_store_provider.dart';
import 'features/archive/archive_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/notes/notes_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_screen.dart';

/// Root widget aplikasi **TugasScroll** sesuai `prd.md` (v2.0) dan `design.md` (v1.0).
class TugasScrollApp extends ConsumerWidget {
  const TugasScrollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);

    return MaterialApp(
      title: 'TugasScroll',
      debugShowCheckedModeBanner: false,
      themeMode: store.themeMode,
      theme: TsTypography.buildTheme(
        palette: TsPalette.siang,
        dyslexiaFriendly: store.dyslexiaFriendlyFont,
      ),
      darkTheme: TsTypography.buildTheme(
        palette: TsPalette.malam,
        dyslexiaFriendly: store.dyslexiaFriendlyFont,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      home: store.onboardingCompleted
          ? const TugasScrollShell()
          : const OnboardingScreen(),
    );
  }
}

/// Navigasi utama sesuai Bagian 7.1, 7.2, dan 7.3 `design.md`:
/// - Bar bawah: `Arsip` · `Scan` (sedikit lebih besar dan berwarna `stabilo`) · `Belajar` · `Catatan`
/// - Ditambah akses Pengaturan di pojok kanan atas dan `MiniPlayer` musik di atas bar bawah.
class TugasScrollShell extends ConsumerStatefulWidget {
  const TugasScrollShell({super.key});

  @override
  ConsumerState<TugasScrollShell> createState() => _TugasScrollShellState();
}

class _TugasScrollShellState extends ConsumerState<TugasScrollShell> {
  int _selectedTabIndex = 2; // Default langsung ke Feed Belajar (tab ke-2)
  String? _feedSubjectFilter;

  void _navigateToScan() {
    setState(() => _selectedTabIndex = 1);
  }

  void _navigateToFeedWithSubject(String? subjectId) {
    setState(() {
      _feedSubjectFilter = subjectId;
      _selectedTabIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.tsPalette;
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final Widget activeScreen = switch (_selectedTabIndex) {
      0 => ArchiveScreen(
        onNavigateToScan: _navigateToScan,
        onStartStudyForSubject: _navigateToFeedWithSubject,
      ),
      1 => ScanScreen(
        onSavedAndGoToFeed: _navigateToFeedWithSubject,
      ),
      2 => FeedScreen(
        initialSubjectId: _feedSubjectFilter,
        onNavigateToScan: _navigateToScan,
      ),
      3 => const NotesScreen(),
      4 => const SettingsScreen(),
      _ => FeedScreen(
        initialSubjectId: _feedSubjectFilter,
        onNavigateToScan: _navigateToScan,
      ),
    };

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        titleSpacing: 20,
        // Wordmark sementara "TugasScroll" dalam Plus Jakarta Sans 700 (Bagian 15 design.md)
        title: Text(
          'TugasScroll',
          style: TsTypography.screenTitle(
            palette,
            dyslexiaFriendly: store.dyslexiaFriendlyFont,
          ),
        ),
        actions: [
          if (!store.isMiniPlayerVisible)
            IconButton(
              onPressed: () => notifier.setMiniPlayerVisible(true),
              tooltip: 'Tampilkan pemutar musik',
              icon: Icon(
                PhosphorIconsRegular.musicNote,
                color: palette.pencil,
              ),
            ),
          IconButton(
            onPressed: () => setState(() => _selectedTabIndex = 4),
            tooltip: 'Pengaturan',
            icon: Icon(
              PhosphorIconsRegular.gear,
              color: _selectedTabIndex == 4 ? palette.stabilo : palette.ink,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: activeScreen),

            // MiniPlayer melayang di atas navigasi bawah (Bagian 7.1, 8, 10 design.md)
            if (store.isMiniPlayerVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: MiniPlayer(
                  trackTitle: store.currentTrack.title,
                  isPlaying: store.isMusicPlaying,
                  onTogglePlay: notifier.toggleMusicPlay,
                  onOpenPlaylistSheet: () =>
                      showMusicPlaylistSheet(context, ref),
                  onHide: () => notifier.setMiniPlayerVisible(false),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _TsBottomBar(
        selectedIndex: _selectedTabIndex,
        palette: palette,
        onSelectTab: (index) {
          setState(() => _selectedTabIndex = index);
        },
      ),
    );
  }
}

/// Bar navigasi bawah tanpa efek kaca/blur dan tanpa glow neon (Bagian 2, 7.1, 7.3, 13 `design.md`):
/// - `Arsip` · `Scan` (sedikit lebih besar dan berwarna `stabilo`) · `Belajar` · `Catatan`
class _TsBottomBar extends StatelessWidget {
  const _TsBottomBar({
    required this.selectedIndex,
    required this.palette,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final TsPalette palette;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(top: BorderSide(color: palette.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _NavBarItem(
                  icon: PhosphorIconsRegular.books,
                  label: 'Arsip',
                  isSelected: selectedIndex == 0,
                  palette: palette,
                  onTap: () => onSelectTab(0),
                ),
              ),

              // Tombol Scan: sedikit lebih besar dari tab lain dan berwarna `stabilo` (Bagian 7.3 design.md)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Semantics(
                  button: true,
                  selected: selectedIndex == 1,
                  label: 'Scan tugas',
                  child: Material(
                    color: palette.stabilo,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onSelectTab(1),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsRegular.camera,
                              size: 22,
                              color: palette.bg,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Scan',
                              style: TsTypography.buttonAndChip(
                                palette,
                                color: palette.bg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _NavBarItem(
                  icon: PhosphorIconsRegular.cards,
                  label: 'Belajar',
                  isSelected: selectedIndex == 2,
                  palette: palette,
                  onTap: () => onSelectTab(2),
                ),
              ),
              Expanded(
                child: _NavBarItem(
                  icon: PhosphorIconsRegular.notepad,
                  label: 'Catatan',
                  isSelected: selectedIndex == 3,
                  palette: palette,
                  onTap: () => onSelectTab(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final TsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = isSelected ? palette.ink : palette.pencil;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                style: TsTypography.caption(palette, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
