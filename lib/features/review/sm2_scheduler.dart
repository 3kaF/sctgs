import 'dart:math' as math;
import '../../core/widgets/grade_bar.dart';
import '../../data/local/models.dart';

/// Hasil perhitungan jadwal review berikutnya untuk satu kartu.
class Sm2ScheduleResult {
  const Sm2ScheduleResult({
    required this.intervalDays,
    required this.ease,
    required this.seenCount,
    required this.lapses,
    required this.nextReviewAt,
  });

  final int intervalDays;
  final double ease;
  final int seenCount;
  final int lapses;
  final DateTime nextReviewAt;
}

/// Mesin penjadwal pengulangan berjarak (mirip SM-2) sesuai Bagian 6.8 PRD & Bagian 7.1 `design.md`.
///
/// Aturan:
/// - 4 tombol penilaian: `Lupa (0)`, `Susah (1)`, `Oke (2)`, `Mudah (3)`
/// - Kartu dari jawaban salah mulai dengan jarak 1 hari.
/// - Bila dinilai `Lupa`: interval kembali ke 1 hari (Besok), `lapses` bertambah 1, `ease` berkurang 0.20 (minimum 1.3).
/// - Bila dinilai `Susah`: interval tumbuh lambat ($\approx 1.2\times$, minimal 2 hari), `ease` berkurang 0.15.
/// - Bila dinilai `Oke`: interval tumbuh normal ($\times \text{ease}$, awal 4 hari).
/// - Bila dinilai `Mudah`: interval tumbuh lebih panjang ($\times \text{ease} \times 1.3$, awal 9 hari), `ease` naik 0.15.
class Sm2Scheduler {
  const Sm2Scheduler._();

  static const double minEase = 1.3;
  static const double defaultEase = 2.5;

  /// Menghitung jadwal review baru setelah pengguna menekan salah satu tombol `GradeBar`.
  static Sm2ScheduleResult calculateNext({
    required StudyCardModel card,
    required StudyGrade grade,
    required DateTime now,
  }) {
    final int currentInterval = card.intervalDays;
    final double currentEase = card.ease < minEase ? defaultEase : card.ease;
    final int nextSeenCount = card.seenCount + 1;
    int nextLapses = card.lapses;
    double nextEase = currentEase;
    int nextIntervalDays;

    switch (grade) {
      case StudyGrade.lupa:
        nextLapses += 1;
        nextEase = math.max(minEase, currentEase - 0.20);
        nextIntervalDays = 1; // Besok
      case StudyGrade.susah:
        nextEase = math.max(minEase, currentEase - 0.15);
        if (currentInterval <= 0) {
          nextIntervalDays = 2;
        } else {
          nextIntervalDays = math.max(
            currentInterval + 1,
            (currentInterval * 1.2).round(),
          );
        }
      case StudyGrade.oke:
        if (currentInterval <= 0) {
          nextIntervalDays = card.fromWrongAnswer ? 2 : 4;
        } else if (currentInterval == 1) {
          nextIntervalDays = 4;
        } else {
          nextIntervalDays = math.max(
            currentInterval + 1,
            (currentInterval * currentEase).round(),
          );
        }
      case StudyGrade.mudah:
        nextEase = currentEase + 0.15;
        if (currentInterval <= 0) {
          nextIntervalDays = card.fromWrongAnswer ? 4 : 9;
        } else {
          nextIntervalDays = math.max(
            currentInterval + 2,
            (currentInterval * currentEase * 1.3).round(),
          );
        }
    }

    final DateTime nextReviewAt = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: nextIntervalDays));

    return Sm2ScheduleResult(
      intervalDays: nextIntervalDays,
      ease: double.parse(nextEase.toStringAsFixed(2)),
      seenCount: nextSeenCount,
      lapses: nextLapses,
      nextReviewAt: nextReviewAt,
    );
  }

  /// Menghasilkan teks jarak ulang untuk keempat tombol di `GradeBar`
  /// (mis. `Besok`, `2 hari`, `4 hari`, `9 hari` sesuai Bagian 7.1 `design.md`).
  static Map<StudyGrade, String> previewLabels(
    StudyCardModel card,
    DateTime now,
  ) {
    return {
      for (final grade in StudyGrade.values)
        grade: formatIntervalDays(
          calculateNext(card: card, grade: grade, now: now).intervalDays,
        ),
    };
  }

  static String formatIntervalDays(int days) {
    if (days <= 1) return 'Besok';
    return '$days hari';
  }
}

/// Penyusun antrean kartu untuk Feed Belajar (Bagian 6.5 PRD & Bagian 1, 7.1 `design.md`).
///
/// Urutan prioritas:
/// 1. Kartu jatuh tempo review (`isDue`)
/// 2. Kartu dari jawaban salah (`fromWrongAnswer` / `StudyCardType.mistake`)
/// 3. Kartu baru (`seenCount == 0`)
/// 4. Review acak (latihan bebas bila tidak ada kartu jatuh tempo)
class FeedQueueBuilder {
  const FeedQueueBuilder._();

  static List<StudyCardModel> buildSessionQueue({
    required List<StudyCardModel> allCards,
    required DateTime now,
    String? subjectIdFilter, // null atau 'mixed' = Campuran
    int sessionLimit = 20,
  }) {
    final filtered = allCards.where((card) {
      if (card.reported) return false;
      if (subjectIdFilter == null || subjectIdFilter == 'mixed') return true;
      return card.subjectId == subjectIdFilter;
    }).toList();

    final List<StudyCardModel> dueCards = [];
    final List<StudyCardModel> wrongAnswerCards = [];
    final List<StudyCardModel> newCards = [];
    final List<StudyCardModel> otherReviewCards = [];

    for (final card in filtered) {
      if (card.isDue(now)) {
        dueCards.add(card);
      } else if (card.fromWrongAnswer || card.type == StudyCardType.mistake) {
        wrongAnswerCards.add(card);
      } else if (card.seenCount == 0) {
        newCards.add(card);
      } else {
        otherReviewCards.add(card);
      }
    }

    // Urutkan jatuh tempo dari yang paling mendesak
    dueCards.sort((a, b) {
      final aDate = a.nextReviewAt ?? now;
      final bDate = b.nextReviewAt ?? now;
      return aDate.compareTo(bDate);
    });

    final List<StudyCardModel> combined = [
      ...dueCards,
      ...wrongAnswerCards,
      ...newCards,
      ...otherReviewCards,
    ];

    if (combined.length <= sessionLimit) {
      return combined;
    }
    return combined.sublist(0, sessionLimit);
  }
}
