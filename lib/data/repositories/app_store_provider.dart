import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/grade_bar.dart';
import '../../core/widgets/verdict_tag.dart';
import '../../features/ai/ai_cross_verifier.dart';
import '../../features/music/background_audio_controller.dart';
import '../../features/review/daily_reminder_service.dart';
import '../../features/review/sm2_scheduler.dart';
import '../local/local_storage_service.dart';
import '../local/models.dart';

/// State utama aplikasi (Offline-First Repository State).
/// Semua perubahan langsung diperbarui di state lokal dan disimpan ke SQLite/Drift.
class AppStoreState {
  const AppStoreState({
    required this.localUserId,
    required this.onboardingCompleted,
    required this.educationLevel,
    required this.themeMode,
    required this.dyslexiaFriendlyFont,
    required this.showAccessibilityNavButtons,
    required this.reminderTime,
    required this.quietHoursEnabled,
    required this.sessionCardLimit,
    required this.subjects,
    required this.tasks,
    required this.cards,
    required this.notes,
    required this.tracks,
    required this.currentTrackIndex,
    required this.isMusicPlaying,
    required this.isMiniPlayerVisible,
    required this.sleepTimerMinutes,
    required this.offlineAiQueueCount,
  });

  final String localUserId;
  final bool onboardingCompleted;
  final String educationLevel; // SMA / SMK / Kuliah
  final ThemeMode themeMode; // default: ThemeMode.dark (Malam)
  final bool dyslexiaFriendlyFont;
  final bool showAccessibilityNavButtons;
  final String reminderTime; // mis. "19:30"
  final bool quietHoursEnabled;
  final int sessionCardLimit; // 10, 20, atau 30

  final List<SubjectModel> subjects;
  final List<TaskItemModel> tasks;
  final List<StudyCardModel> cards;
  final List<NoteModel> notes;
  final List<MusicTrackModel> tracks;

  final int currentTrackIndex;
  final bool isMusicPlaying;
  final bool isMiniPlayerVisible;
  final int? sleepTimerMinutes;
  final int offlineAiQueueCount;

  MusicTrackModel get currentTrack =>
      tracks[currentTrackIndex.clamp(0, tracks.length - 1)];

  /// Menghitung total kartu yang jatuh tempo hari ini di seluruh mapel.
  int totalDueCards(DateTime now) =>
      cards.where((c) => !c.reported && c.isDue(now)).length;

  /// Menghitung daftar mapel yang sudah punya tugas (sesuai Bagian 7.2 design.md:
  /// "Mapel yang belum punya tugas tidak ditampilkan").
  List<SubjectModel> activeSubjectsWithStats(DateTime now) {
    final List<SubjectModel> result = [];
    for (final s in subjects) {
      final countTasks = tasks.where((t) => t.subjectId == s.id).length;
      if (countTasks == 0) continue;
      final countDue = cards
          .where((c) => c.subjectId == s.id && !c.reported && c.isDue(now))
          .length;
      result.add(
        s.copyWith(taskCount: countTasks, dueCardCount: countDue),
      );
    }
    return result;
  }

  /// Apakah ada tugas yang perlu dikonfirmasi pengguna (`confidence < 0.6` atau `needsCheck`).
  List<TaskItemModel> get tasksNeedingCheck =>
      tasks.where((t) => t.needsCheck || t.aiConfidence < 0.6).toList();

  AppStoreState copyWith({
    bool? onboardingCompleted,
    String? educationLevel,
    ThemeMode? themeMode,
    bool? dyslexiaFriendlyFont,
    bool? showAccessibilityNavButtons,
    String? reminderTime,
    bool? quietHoursEnabled,
    int? sessionCardLimit,
    List<SubjectModel>? subjects,
    List<TaskItemModel>? tasks,
    List<StudyCardModel>? cards,
    List<NoteModel>? notes,
    List<MusicTrackModel>? tracks,
    int? currentTrackIndex,
    bool? isMusicPlaying,
    bool? isMiniPlayerVisible,
    int? sleepTimerMinutes,
    bool clearSleepTimer = false,
    int? offlineAiQueueCount,
  }) {
    return AppStoreState(
      localUserId: localUserId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      educationLevel: educationLevel ?? this.educationLevel,
      themeMode: themeMode ?? this.themeMode,
      dyslexiaFriendlyFont: dyslexiaFriendlyFont ?? this.dyslexiaFriendlyFont,
      showAccessibilityNavButtons:
          showAccessibilityNavButtons ?? this.showAccessibilityNavButtons,
      reminderTime: reminderTime ?? this.reminderTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      sessionCardLimit: sessionCardLimit ?? this.sessionCardLimit,
      subjects: subjects ?? this.subjects,
      tasks: tasks ?? this.tasks,
      cards: cards ?? this.cards,
      notes: notes ?? this.notes,
      tracks: tracks ?? this.tracks,
      currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      isMiniPlayerVisible: isMiniPlayerVisible ?? this.isMiniPlayerVisible,
      sleepTimerMinutes: clearSleepTimer
          ? null
          : (sleepTimerMinutes ?? this.sleepTimerMinutes),
      offlineAiQueueCount: offlineAiQueueCount ?? this.offlineAiQueueCount,
    );
  }
}

/// Notifier utama yang mengelola state Offline-First aplikasi TugasScroll.
class AppStoreNotifier extends StateNotifier<AppStoreState> {
  AppStoreNotifier()
      : _audioController = BackgroundAudioController(),
        super(_createInitialSeededState());

  final BackgroundAudioController _audioController;

  static AppStoreState _createInitialSeededState() {
    final now = DateTime.now();
    const localUid = '00000000-0000-4000-8000-000000000001';

    // 15 Mapel bawaan + Umum sesuai Bagian 6.3 PRD & Bagian 3.3 design.md
    const subjects = <SubjectModel>[
      SubjectModel(id: 'sub-math', name: 'Matematika', colorKey: 'matematika'),
      SubjectModel(id: 'sub-phys', name: 'Fisika', colorKey: 'fisika'),
      SubjectModel(id: 'sub-chem', name: 'Kimia', colorKey: 'kimia'),
      SubjectModel(id: 'sub-bio', name: 'Biologi', colorKey: 'biologi'),
      SubjectModel(
        id: 'sub-ind',
        name: 'Bahasa Indonesia',
        colorKey: 'bahasa',
      ),
      SubjectModel(id: 'sub-eng', name: 'Bahasa Inggris', colorKey: 'bahasa'),
      SubjectModel(id: 'sub-hist', name: 'Sejarah', colorKey: 'ips'),
      SubjectModel(id: 'sub-geo', name: 'Geografi', colorKey: 'ips'),
      SubjectModel(id: 'sub-econ', name: 'Ekonomi', colorKey: 'ips'),
      SubjectModel(id: 'sub-soc', name: 'Sosiologi', colorKey: 'ips'),
      SubjectModel(id: 'sub-ppkn', name: 'PPKn', colorKey: 'ips'),
      SubjectModel(
        id: 'sub-rel',
        name: 'Pendidikan Agama',
        colorKey: 'agama',
      ),
      SubjectModel(id: 'sub-inf', name: 'Informatika', colorKey: 'umum'),
      SubjectModel(id: 'sub-art', name: 'Seni', colorKey: 'umum'),
      SubjectModel(id: 'sub-pjok', name: 'PJOK', colorKey: 'umum'),
      SubjectModel(id: 'sub-gen', name: 'Umum', colorKey: 'umum'),
    ];

    // Contoh tugas nyata yang sudah di-scan (Matematika, Fisika, Kimia, Sejarah, Pendidikan Agama)
    final tasks = <TaskItemModel>[
      TaskItemModel(
        id: 'task-math-1',
        userId: localUid,
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        title: 'Turunan fungsi aljabar',
        questionText: r'Turunan pertama dari $f(x) = 3x^2 - 5x + 4$ adalah ...',
        userAnswerText: r"$f'(x) = 6x + 5$",
        topic: 'Turunan fungsi',
        doneOn: now.subtract(const Duration(days: 1)),
        questionType: 'hitungan',
        difficulty: 2,
        mastery: 1,
        aiVerdict: TaskVerdict.wrong,
        mistakeStep: 'Langkah 2: tanda negatif pada -5x berubah menjadi +5',
        aiConfidence: 0.94,
      ),
      TaskItemModel(
        id: 'task-math-2',
        userId: localUid,
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        title: 'Integral tentu sederhana',
        questionText: r'Hitung nilai dari $\int_0^2 (3x^2 + 2x)\,dx$',
        userAnswerText: r'$[x^3 + x^2]_0^2 = 8 + 4 = 12$',
        topic: 'Integral tentu',
        doneOn: now.subtract(const Duration(days: 2)),
        questionType: 'hitungan',
        difficulty: 3,
        mastery: 3,
        aiVerdict: TaskVerdict.correct,
        aiConfidence: 0.96,
      ),
      TaskItemModel(
        id: 'task-chem-1',
        userId: localUid,
        subjectId: 'sub-chem',
        subjectName: 'Kimia',
        subjectColorKey: 'kimia',
        title: 'Penyetaraan reaksi pembakaran metana',
        questionText:
            r'Setarakan persamaan reaksi pembakaran sempurna gas metana: $\text{CH}_4 + \text{O}_2 \rightarrow \text{CO}_2 + \text{H}_2\text{O}$',
        userAnswerText: r'$\text{CH}_4 + 2\text{O}_2 \rightarrow \text{CO}_2 + 2\text{H}_2\text{O}$',
        topic: 'Stoikiometri & persamaan reaksi',
        doneOn: now.subtract(const Duration(days: 1)),
        questionType: 'hitungan',
        difficulty: 2,
        mastery: 2,
        aiVerdict: TaskVerdict.correct,
        aiConfidence: 0.91,
      ),
      TaskItemModel(
        id: 'task-phys-1',
        userId: localUid,
        subjectId: 'sub-phys',
        subjectName: 'Fisika',
        subjectColorKey: 'fisika',
        title: 'Hukum II Newton pada bidang datar',
        questionText:
            r'Balok bermassa $4\text{ kg}$ ditarik gaya mendatar $20\text{ N}$ di lantai licin. Berapa percepatan balok?',
        userAnswerText: r'$a = \frac{F}{m} = \frac{20}{4} = 5\text{ m/s}^2$',
        topic: 'Dinamika partikel',
        doneOn: now.subtract(const Duration(days: 3)),
        questionType: 'hitungan',
        difficulty: 1,
        mastery: 2,
        aiVerdict: TaskVerdict.correct,
        aiConfidence: 0.95,
      ),
      TaskItemModel(
        id: 'task-rel-1',
        userId: localUid,
        subjectId: 'sub-rel',
        subjectName: 'Pendidikan Agama',
        subjectColorKey: 'agama',
        title: 'Hukum bacaan tajwid nun mati',
        questionText:
            'Tuliskan potongan lafaz dari tugasmu dan jelaskan hukum bacaan ketika nun sukun bertemu huruf ba:\nمِنْ بَعْدِ',
        userAnswerText:
            'Hukum bacaannya adalah Iqlab, suara nun mati berubah menjadi mim disertai dengung.',
        topic: 'Tajwid nun mati dan tanwin',
        doneOn: now.subtract(const Duration(days: 2)),
        questionType: 'hafalan',
        difficulty: 2,
        mastery: 2,
        aiVerdict: TaskVerdict.correct,
        aiConfidence: 0.90,
      ),
      TaskItemModel(
        id: 'task-hist-1',
        userId: localUid,
        subjectId: 'sub-hist',
        subjectName: 'Sejarah',
        subjectColorKey: 'ips',
        title: 'Peristiwa Rengasdengklok',
        questionText:
            'Mengapa golongan muda membawa Soekarno dan Hatta ke Rengasdengklok pada 16 Agustus 1945?',
        userAnswerText:
            'Agar proklamasi kemerdekaan segera dilaksanakan di luar pengaruh Jepang.',
        topic: 'Proklamasi kemerdekaan Indonesia',
        doneOn: now.subtract(const Duration(days: 1)),
        questionType: 'uraian',
        difficulty: 2,
        mastery: 1,
        aiVerdict: TaskVerdict.partial,
        mistakeStep:
            'Saran kelengkapan: tambahkan konteks kekosongan kekuasaan setelah Jepang menyerah kepada Sekutu pada 15 Agustus 1945.',
        aiConfidence: 0.55,
        needsCheck: true,
      ),
    ];

    // Kartu-kartu belajar yang dihasilkan dari tugas di atas
    final cards = <StudyCardModel>[
      StudyCardModel(
        id: 'card-1',
        taskId: 'task-math-1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskTitle: 'Turunan fungsi aljabar',
        type: StudyCardType.mistake,
        promptText:
            r'Pada tugasmu, untuk $f(x) = 3x^2 - 5x + 4$, di langkah mana jawabanmu keliru?',
        answerText: r"Turunan yang benar adalah $f'(x) = 6x - 5$",
        wrongStepText: r"$f'(x) = 6x + 5$",
        correctionMarginNote: 'Langkah 2: tanda negatif pada -5x berubah',
        correctStepText: r"$f'(x) = 2\cdot 3x^{2-1} - 1\cdot 5x^{1-1} + 0 = 6x - 5$",
        explanationText:
            r'Turunan dari suku linear $-5x$ mempertahankan tanda negatifnya menjadi $-5$, sedangkan konstanta $4$ turunannya $0$.',
        deepDiveSteps: const [
          r'1. Gunakan aturan pangkat: $\frac{d}{dx}(ax^n) = n\cdot ax^{n-1}$.',
          r'2. Turunkan suku pertama: $\frac{d}{dx}(3x^2) = 6x$.',
          r'3. Turunkan suku kedua (perhatikan tanda minus): $\frac{d}{dx}(-5x) = -5$.',
          r'4. Turunkan konstanta: $\frac{d}{dx}(4) = 0$.',
        ],
        seenCount: 1,
        lapses: 1,
        intervalDays: 1,
        nextReviewAt: now.subtract(const Duration(hours: 2)), // Jatuh tempo hari ini
        fromWrongAnswer: true,
      ),
      StudyCardModel(
        id: 'card-2',
        taskId: 'task-math-1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskTitle: 'Turunan fungsi aljabar',
        type: StudyCardType.variant,
        promptText:
            r'Latihan serupa dengan angka berbeda: Tentukan turunan pertama dari $g(x) = 4x^2 - 7x + 9$',
        answerText: r"$g'(x) = 8x - 7$",
        explanationText:
            r'Kalikan pangkat $2$ dengan koefisien $4$ menjadi $8x$, dan turunan dari $-7x$ adalah $-7$.',
        deepDiveSteps: const [
          r'1. $g(x) = 4x^2 - 7x + 9$',
          r"2. $g'(x) = 2(4)x^{2-1} - 7x^{1-1} + 0$",
          r"3. $g'(x) = 8x - 7$",
        ],
        seenCount: 0,
        intervalDays: 0,
        nextReviewAt: now.subtract(const Duration(hours: 1)),
      ),
      StudyCardModel(
        id: 'card-3',
        taskId: 'task-chem-1',
        subjectId: 'sub-chem',
        subjectName: 'Kimia',
        subjectColorKey: 'kimia',
        taskTitle: 'Penyetaraan reaksi pembakaran metana',
        type: StudyCardType.question,
        promptText:
            r'Berapa koefisien $\text{O}_2$ dan $\text{H}_2\text{O}$ agar reaksi berikut setara?'
            '\n'
            r'$\text{CH}_4 + \dots\,\text{O}_2 \rightarrow \text{CO}_2 + \dots\,\text{H}_2\text{O}$',
        answerText:
            r'Koefisien $\text{O}_2 = 2$ dan $\text{H}_2\text{O} = 2$'
            '\n'
            r'$\text{CH}_4 + 2\text{O}_2 \rightarrow \text{CO}_2 + 2\text{H}_2\text{O}$',
        explanationText:
            'Di ruas kiri ada 4 atom H pada CH₄, sehingga butuh 2 molekul H₂O di kanan. Total atom O di kanan menjadi 2 + 2 = 4, sehingga butuh 2 molekul O₂ di kiri.',
        deepDiveSteps: const [
          '1. Setarakan atom C: 1 di kiri (CH₄) dan 1 di kanan (CO₂).',
          '2. Setarakan atom H: 4 di kiri (CH₄), maka beri koefisien 2 pada H₂O di kanan.',
          '3. Hitung atom O di kanan: 2 (dari CO₂) + 2×1 (dari 2H₂O) = 4 atom O.',
          '4. Beri koefisien 2 pada O₂ di kiri agar jumlah atom O sama-sama 4.',
        ],
        seenCount: 2,
        intervalDays: 2,
        nextReviewAt: now.subtract(const Duration(minutes: 30)),
      ),
      StudyCardModel(
        id: 'card-4',
        taskId: 'task-rel-1',
        subjectId: 'sub-rel',
        subjectName: 'Pendidikan Agama',
        subjectColorKey: 'agama',
        taskTitle: 'Hukum bacaan tajwid nun mati',
        type: StudyCardType.flashcard,
        promptText:
            'Apa hukum bacaan tajwid pada potongan lafaz dari tugasmu berikut ini?\nمِنْ بَعْدِ',
        answerText:
            'Iqlab (إِقْلَاب) — nun sukun bertemu huruf ba (ب), dibaca melebur menjadi bunyi mim disertai dengung 2 harakat.',
        explanationText:
            'Kutipan sesuai lembar tugas pengguna. Huruf Iqlab hanya ada satu, yaitu ba (ب).',
        deepDiveSteps: const [
          '1. Perhatikan huruf nun sukun (نْ) pada kata مِنْ.',
          '2. Huruf setelahnya adalah ba (ب) pada kata بَعْدِ.',
          '3. Bunyi nun sukun dibaca membalik menjadi mim (م) dengan dengung.',
        ],
        seenCount: 1,
        intervalDays: 1,
        nextReviewAt: now.subtract(const Duration(hours: 3)),
      ),
      StudyCardModel(
        id: 'card-5',
        taskId: 'task-phys-1',
        subjectId: 'sub-phys',
        subjectName: 'Fisika',
        subjectColorKey: 'fisika',
        taskTitle: 'Hukum II Newton pada bidang datar',
        type: StudyCardType.concept,
        promptText:
            r'Bagaimana hubungan antara resultan gaya ($\Sigma F$), massa ($m$), dan percepatan ($a$) pada Hukum II Newton?',
        answerText: r'$a = \frac{\Sigma F}{m}$ atau $\Sigma F = m \cdot a$',
        explanationText:
            'Percepatan benda berbanding lurus dengan resultan gaya yang bekerja padanya dan berbanding terbalik dengan massanya.',
        deepDiveSteps: const [
          r'1. Satuan gaya ($F$) dalam SI adalah Newton ($\text{N} = \text{kg}\cdot\text{m/s}^2$).',
          r'2. Jika massa tetap dan gaya diperbesar 2 kali, percepatan ikut menjadi 2 kali semula.',
        ],
        seenCount: 1,
        intervalDays: 4,
        nextReviewAt: now,
      ),
      StudyCardModel(
        id: 'card-6',
        taskId: 'task-hist-1',
        subjectId: 'sub-hist',
        subjectName: 'Sejarah',
        subjectColorKey: 'ips',
        taskTitle: 'Peristiwa Rengasdengklok',
        type: StudyCardType.question,
        promptText:
            'Sebutkan alasan utama golongan muda mengamankan Soekarno dan Hatta ke Rengasdengklok pada 16 Agustus 1945.',
        answerText:
            'Mendesak agar proklamasi kemerdekaan segera diumumkan oleh bangsa Indonesia sendiri setelah Jepang menyerah kepada Sekutu, tanpa melalui PPKI bentukan Jepang.',
        explanationText:
            'Pada 15 Agustus 1945 terjadi kekosongan kekuasaan (vacuum of power) setelah Jepang menyerah tanpa syarat kepada Sekutu.',
        deepDiveSteps: const [
          '1. 15 Agustus 1945: Jepang menyerah kepada Sekutu.',
          '2. Golongan muda (Wikana, Chaerul Saleh, Sukarni) mendesak proklamasi segera di luar skenario Jepang.',
          '3. 16 Agustus 1945 dini hari: Soekarno-Hatta dibawa ke Rengasdengklok hingga tercapai kesepakatan bersama Ahmad Soebardjo.',
        ],
        seenCount: 0,
        intervalDays: 1,
        nextReviewAt: now.subtract(const Duration(hours: 4)),
        fromWrongAnswer: true,
      ),
    ];

    final notes = <NoteModel>[
      NoteModel(
        id: 'note-1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskId: 'task-math-1',
        cardId: 'card-1',
        taskTitle: 'Turunan fungsi aljabar',
        body:
            'Ingat: sebelum menurunkan suku aljabar, lingkari tanda minus di depan koefisien supaya tidak berubah jadi plus saat langkah kedua.',
        showInFeed: true,
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      NoteModel(
        id: 'note-2',
        subjectId: 'sub-chem',
        subjectName: 'Kimia',
        subjectColorKey: 'kimia',
        taskId: 'task-chem-1',
        taskTitle: 'Penyetaraan reaksi pembakaran metana',
        body:
            'Urutan menyetarakan reaksi pembakaran hidrokarbon: setarakan C dulu, lalu H, dan terakhir O.',
        showInFeed: false,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    // Track musik bebas royalti bawaan per mapel (Bagian 6.7 PRD & Bagian 10 design.md)
    const tracks = <MusicTrackModel>[
      MusicTrackModel(
        id: 'trk-1',
        title: 'Lo-fi malam (Matematika)',
        playlistName: 'Matematika · Lo-fi tenang',
        subjectColorKey: 'matematika',
        sourceType: 'bundled',
        uri: 'assets/audio/lofi_malam.wav',
        licenseNote: 'CC0 1.0 Public Domain Dedication — TugasScroll Studio',
        durationSec: 164,
      ),
      MusicTrackModel(
        id: 'trk-2',
        title: 'Hujan di jendela (Kimia)',
        playlistName: 'Kimia · Ambient fokus',
        subjectColorKey: 'kimia',
        sourceType: 'bundled',
        uri: 'assets/audio/hujan_ambient.wav',
        licenseNote: 'CC0 1.0 Public Domain Dedication — TugasScroll Studio',
        durationSec: 192,
      ),
      MusicTrackModel(
        id: 'trk-3',
        title: 'Perpustakaan sore (Sejarah & Bahasa)',
        playlistName: 'Membaca panjang · Akustik',
        subjectColorKey: 'ips',
        sourceType: 'bundled',
        uri: 'assets/audio/perpustakaan_sore.wav',
        licenseNote: 'CC0 1.0 Public Domain Dedication — TugasScroll Studio',
        durationSec: 148,
      ),
    ];

    return AppStoreState(
      localUserId: localUid,
      onboardingCompleted: true,
      educationLevel: 'SMA',
      themeMode: ThemeMode.dark, // Default Malam sesuai design.md
      dyslexiaFriendlyFont: false,
      showAccessibilityNavButtons: false,
      reminderTime: '19:30',
      quietHoursEnabled: true,
      sessionCardLimit: 20,
      subjects: subjects,
      tasks: tasks,
      cards: cards,
      notes: notes,
      tracks: tracks,
      currentTrackIndex: 0,
      isMusicPlaying: false,
      isMiniPlayerVisible: true,
      sleepTimerMinutes: null,
      offlineAiQueueCount: 0,
    );
  }

  /// Menilai kartu di Feed Belajar menggunakan algoritma SM-2 (`Sm2Scheduler`).
  void gradeCard(String cardId, StudyGrade grade) {
    final now = DateTime.now();
    final updatedCards = state.cards.map((card) {
      if (card.id != cardId) return card;
      final schedule = Sm2Scheduler.calculateNext(
        card: card,
        grade: grade,
        now: now,
      );
      return card.copyWith(
        seenCount: schedule.seenCount,
        lapses: schedule.lapses,
        lastGrade: grade.code,
        ease: schedule.ease,
        intervalDays: schedule.intervalDays,
        nextReviewAt: schedule.nextReviewAt,
      );
    }).toList();

    state = state.copyWith(cards: updatedCards);
    LocalStorageService.saveCardProgress(updatedCards);
  }

  /// Menandai atau melepas tanda stabilo penting pada kartu (`isStarred`).
  void toggleStarCard(String cardId) {
    final updatedCards = state.cards.map((card) {
      if (card.id != cardId) return card;
      return card.copyWith(isStarred: !card.isStarred);
    }).toList();
    state = state.copyWith(cards: updatedCards);
    LocalStorageService.saveCardProgress(updatedCards);
  }

  /// Melaporkan kartu yang keliru agar disembunyikan dari feed dan dicatat untuk perbaikan prompt.
  void reportCard(String cardId) {
    final updatedCards = state.cards.map((card) {
      if (card.id != cardId) return card;
      return card.copyWith(reported: true);
    }).toList();
    state = state.copyWith(cards: updatedCards);
    LocalStorageService.saveCardProgress(updatedCards);
  }

  /// Menimpa verdict AI oleh pengguna ("Jawaban saya benar menurut guru" / "Memang salah").
  void overrideTaskVerdict(String taskId, TaskVerdict userVerdict) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(
        userVerdict: userVerdict,
        needsCheck: false,
      );
    }).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  /// Mengonfirmasi mapel untuk tugas di tab "Perlu dicek".
  void confirmTaskSubject(String taskId, SubjectModel subject) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(
        subjectId: subject.id,
        subjectName: subject.name,
        subjectColorKey: subject.colorKey,
        needsCheck: false,
        aiConfidence: 1.0,
      );
    }).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  /// Menyimpan daftar soal yang sudah dikonfirmasi di layar **Cek Hasil Scan**
  /// lalu otomatis membuat kartu belajar untuk setiap soal.
  void saveVerifiedScanItems({
    required SubjectModel subject,
    required String topic,
    required List<ScannedQuestionItem> verifiedItems,
    String source = 'scan',
  }) {
    final now = DateTime.now();
    final List<TaskItemModel> newTasks = [...state.tasks];
    final List<StudyCardModel> newCards = [...state.cards];

    for (int i = 0; i < verifiedItems.length; i++) {
      final item = verifiedItems[i];
      final String taskId =
          'task-${now.millisecondsSinceEpoch}-$i';
      final String title = item.question.length > 42
          ? '${item.question.substring(0, 42)}...'
          : item.question;

      // Jalankan verifikasi silang sederhana
      final initialGrade = GradeClassificationResult(
        subject: subject.colorKey,
        topic: topic.isEmpty ? 'Latihan ${subject.name}' : topic,
        questionType:
            (subject.colorKey == 'matematika' ||
                subject.colorKey == 'fisika' ||
                subject.colorKey == 'kimia')
            ? 'hitungan'
            : 'uraian',
        difficulty: 2,
        verdict: item.userAnswer.isNotEmpty
            ? TaskVerdict.correct
            : TaskVerdict.unsure,
        confidence: item.confidence,
      );

      final verifiedGrade = AiCrossVerifier.verifyGradeResult(
        aiResult: initialGrade,
        questionText: item.question,
        userAnswerText: item.userAnswer,
      );

      final taskModel = TaskItemModel(
        id: taskId,
        userId: state.localUserId,
        subjectId: subject.id,
        subjectName: subject.name,
        subjectColorKey: subject.colorKey,
        title: title,
        questionText: item.question,
        userAnswerText: item.userAnswer,
        topic: verifiedGrade.topic,
        doneOn: now,
        questionType: verifiedGrade.questionType,
        difficulty: verifiedGrade.difficulty,
        mastery: 0,
        aiVerdict: verifiedGrade.verdict,
        aiConfidence: verifiedGrade.confidence,
        needsCheck: verifiedGrade.needsSubjectConfirmation,
        source: source,
        lowConfidenceParts: const [],
      );
      newTasks.insert(0, taskModel);

      // Buat kartu Soal Ulang & Konsep otomatis untuk soal ini
      newCards.insert(
        0,
        StudyCardModel(
          id: 'card-$taskId-q',
          taskId: taskId,
          subjectId: subject.id,
          subjectName: subject.name,
          subjectColorKey: subject.colorKey,
          taskTitle: title,
          type: StudyCardType.question,
          promptText: item.question,
          answerText: item.userAnswer.isEmpty
              ? 'Belum ada jawaban tertulis. Buka catatan atau tulis langkah penyelesaianmu.'
              : item.userAnswer,
          explanationText:
              'Soal dari tugas ${subject.name} ($topic) yang sudah kamu konfirmasi di layar Cek hasil scan.',
          deepDiveSteps: [
            'Soal asli: ${item.question}',
            if (item.userAnswer.isNotEmpty)
              'Jawabanmu di buku: ${item.userAnswer}',
          ],
          seenCount: 0,
          intervalDays: verifiedGrade.verdict == TaskVerdict.wrong ? 1 : 0,
          nextReviewAt: now,
          fromWrongAnswer: verifiedGrade.verdict == TaskVerdict.wrong,
        ),
      );
    }

    state = state.copyWith(tasks: newTasks, cards: newCards);
  }

  /// Menghapus tugas beserta kartu dan catatan terkait (Bagian 6.1 PRD).
  void deleteTask(String taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
      cards: state.cards.where((c) => c.taskId != taskId).toList(),
      notes: state.notes.where((n) => n.taskId != taskId).toList(),
    );
  }

  /// Menambah mapel buatan pengguna sendiri (Bagian 6.3 PRD & Bagian 3.3 design.md).
  void addCustomSubject({required String name, required String colorKey}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final newSub = SubjectModel(
      id: 'sub-custom-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      colorKey: colorKey,
      userId: state.localUserId,
    );
    state = state.copyWith(subjects: [...state.subjects, newSub]);
  }

  /// Menyimpan atau memperbarui catatan pribadi, serta menyinkronkannya ke Feed bila `showInFeed` aktif.
  void saveNote({
    String? noteId,
    required SubjectModel subject,
    required String body,
    required bool showInFeed,
    String? taskId,
    String? cardId,
    String? taskTitle,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();

    final String effectiveId =
        noteId ?? 'note-${now.millisecondsSinceEpoch}';
    final existingIdx = state.notes.indexWhere((n) => n.id == effectiveId);

    final noteModel = NoteModel(
      id: effectiveId,
      subjectId: subject.id,
      subjectName: subject.name,
      subjectColorKey: subject.colorKey,
      taskId: taskId,
      cardId: cardId,
      taskTitle: taskTitle ?? 'Catatan ${subject.name}',
      body: trimmed,
      showInFeed: showInFeed,
      updatedAt: now,
    );

    final updatedNotes = [...state.notes];
    if (existingIdx >= 0) {
      updatedNotes[existingIdx] = noteModel;
    } else {
      updatedNotes.insert(0, noteModel);
    }

    // Sinkronkan kartu bertipe `note` di feed (Bagian 6.4 & 6.6 PRD)
    final String noteCardId = 'card-from-$effectiveId';
    final updatedCards = state.cards.where((c) => c.id != noteCardId).toList();
    if (showInFeed) {
      updatedCards.insert(
        0,
        StudyCardModel(
          id: noteCardId,
          taskId: taskId ?? 'manual-note',
          subjectId: subject.id,
          subjectName: subject.name,
          subjectColorKey: subject.colorKey,
          taskTitle: taskTitle ?? 'Catatan pribadi',
          type: StudyCardType.note,
          promptText: trimmed,
          answerText: 'Catatan pribadimu pada mapel ${subject.name}.',
          seenCount: 0,
          intervalDays: 1,
          nextReviewAt: now,
        ),
      );
    }

    state = state.copyWith(notes: updatedNotes, cards: updatedCards);
    LocalStorageService.saveNotes(updatedNotes);
  }

  void deleteNote(String noteId) {
    final String noteCardId = 'card-from-$noteId';
    state = state.copyWith(
      notes: state.notes.where((n) => n.id != noteId).toList(),
      cards: state.cards.where((c) => c.id != noteCardId).toList(),
    );
  }

  // Kontrol Musik Latar (Bagian 6.7 PRD & Bagian 10 design.md)
  void toggleMusicPlay() {
    final bool nextPlaying = !state.isMusicPlaying;
    state = state.copyWith(
      isMusicPlaying: nextPlaying,
      isMiniPlayerVisible: true,
    );
    if (nextPlaying) {
      _audioController.playTrack(state.currentTrack);
    } else {
      _audioController.pause();
    }
  }

  void selectTrack(int index) {
    if (index < 0 || index >= state.tracks.length) return;
    state = state.copyWith(
      currentTrackIndex: index,
      isMusicPlaying: true,
      isMiniPlayerVisible: true,
    );
    _audioController.playTrack(state.tracks[index]);
  }

  void setMiniPlayerVisible(bool visible) {
    state = state.copyWith(isMiniPlayerVisible: visible);
  }

  void setSleepTimer(int? minutes) {
    if (minutes == null) {
      state = state.copyWith(clearSleepTimer: true);
    } else {
      state = state.copyWith(sleepTimerMinutes: minutes);
    }
  }

  // Pengaturan Tema, Font Disleksia, dan Aksesibilitas (Bagian 12 design.md)
  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setDyslexiaFriendlyFont(bool enabled) =>
      state = state.copyWith(dyslexiaFriendlyFont: enabled);

  void setShowAccessibilityNavButtons(bool enabled) =>
      state = state.copyWith(showAccessibilityNavButtons: enabled);

  void setSessionCardLimit(int limit) =>
      state = state.copyWith(sessionCardLimit: limit);

  void setReminderTime(String time) {
    state = state.copyWith(reminderTime: time);
    DailyReminderService.scheduleOrShowDueReminder(
      dueCardCount: state.totalDueCards(DateTime.now()),
      quietHoursEnabled: state.quietHoursEnabled,
    );
  }

  void completeOnboarding({required String educationLevel}) {
    state = state.copyWith(
      onboardingCompleted: true,
      educationLevel: educationLevel,
    );
  }

  void resetOnboarding() {
    state = state.copyWith(onboardingCompleted: false);
  }

  /// Menghapus semua data lokal (tugas, kartu, catatan) sesuai Bagian 13 PRD.
  void clearAllUserData() {
    state = state.copyWith(
      tasks: const [],
      cards: const [],
      notes: const [],
      offlineAiQueueCount: 0,
    );
    LocalStorageService.clearAll();
  }
}

final appStoreProvider =
    StateNotifierProvider<AppStoreNotifier, AppStoreState>((ref) {
      return AppStoreNotifier();
    });
