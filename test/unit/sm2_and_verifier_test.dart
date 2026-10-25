import 'package:flutter_test/flutter_test.dart';
import 'package:tugasscroll/core/widgets/grade_bar.dart';
import 'package:tugasscroll/core/widgets/verdict_tag.dart';
import 'package:tugasscroll/data/local/models.dart';
import 'package:tugasscroll/features/ai/ai_cross_verifier.dart';
import 'package:tugasscroll/features/review/sm2_scheduler.dart';

void main() {
  group('Sm2Scheduler (Algoritma Pengulangan Berjarak)', () {
    final baseTime = DateTime(2026, 10, 25, 16, 0);
    const sampleCard = StudyCardModel(
      id: 'c-1',
      taskId: 't-1',
      subjectId: 'sub-math',
      subjectName: 'Matematika',
      subjectColorKey: 'matematika',
      taskTitle: 'Turunan',
      type: StudyCardType.question,
      promptText: r'Turunan dari $3x^2$',
      answerText: r'$6x$',
      seenCount: 0,
      lapses: 0,
      ease: 2.5,
      intervalDays: 0,
    );

    test('Nilai Lupa mengembalikan interval ke 1 hari (Besok) dan menambah lapses', () {
      final res = Sm2Scheduler.calculateNext(
        card: sampleCard.copyWith(intervalDays: 6, seenCount: 3),
        grade: StudyGrade.lupa,
        now: baseTime,
      );
      expect(res.intervalDays, 1);
      expect(res.lapses, 1);
      expect(res.ease, closeTo(2.3, 0.001));
    });

    test('Preview label tombol GradeBar menampilkan Besok, 2 hari, 4 hari, 9 hari pada kartu baru', () {
      final labels = Sm2Scheduler.previewLabels(sampleCard, baseTime);
      expect(labels[StudyGrade.lupa], 'Besok');
      expect(labels[StudyGrade.susah], '2 hari');
      expect(labels[StudyGrade.oke], '4 hari');
      expect(labels[StudyGrade.mudah], '9 hari');
    });
  });

  group('FeedQueueBuilder (Urutan Prioritas Feed)', () {
    final now = DateTime(2026, 10, 25, 16, 0);

    test('Mengurutkan kartu jatuh tempo -> kartu jawaban salah -> kartu baru', () {
      final newCard = StudyCardModel(
        id: 'new',
        taskId: 't1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskTitle: 'Baru',
        type: StudyCardType.question,
        promptText: 'Soal baru',
        answerText: 'Jawab',
        seenCount: 0,
        nextReviewAt: now.add(const Duration(days: 2)),
      );
      final wrongCard = StudyCardModel(
        id: 'wrong',
        taskId: 't1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskTitle: 'Salah',
        type: StudyCardType.mistake,
        promptText: 'Soal salah',
        answerText: 'Jawab',
        seenCount: 1,
        fromWrongAnswer: true,
        nextReviewAt: now.add(const Duration(days: 1)),
      );
      final dueCard = StudyCardModel(
        id: 'due',
        taskId: 't1',
        subjectId: 'sub-math',
        subjectName: 'Matematika',
        subjectColorKey: 'matematika',
        taskTitle: 'Jatuh tempo',
        type: StudyCardType.question,
        promptText: 'Soal jatuh tempo',
        answerText: 'Jawab',
        seenCount: 2,
        nextReviewAt: now.subtract(const Duration(hours: 2)),
      );

      final queue = FeedQueueBuilder.buildSessionQueue(
        allCards: [newCard, wrongCard, dueCard],
        now: now,
        sessionLimit: 20,
      );

      expect(queue.map((c) => c.id).toList(), ['due', 'wrong', 'new']);
    });
  });

  group('AiCrossVerifier (Parser JSON & Verifikasi Silang Hitungan/Kimia)', () {
    test('Mem-parsing keluaran JSON scan_task dengan benar', () {
      const jsonStr = '''
      {
        "items": [
          {
            "question": "Turunan dari f(x) = 3x^2 + 2x adalah ...",
            "user_answer": "f'(x) = 6x + 2",
            "confidence": 0.88,
            "low_confidence_parts": []
          }
        ]
      }
      ''';
      final items = AiCrossVerifier.parseScanResponse(jsonStr);
      expect(items.length, 1);
      expect(items.first.confidence, 0.88);
    });

    test('Mengubah verdict menjadi unsure bila verifikasi hitungan berbeda dari AI', () {
      const aiWrongClaim = GradeClassificationResult(
        subject: 'matematika',
        topic: 'Aritmetika',
        questionType: 'hitungan',
        difficulty: 1,
        verdict: TaskVerdict.correct, // AI mengklaim benar, padahal 4 + 5 = 11 salah
        confidence: 0.90,
      );

      final checked = AiCrossVerifier.verifyGradeResult(
        aiResult: aiWrongClaim,
        questionText: 'Hitung 4 + 5',
        userAnswerText: '4 + 5 = 11',
      );

      expect(checked.verdict, TaskVerdict.unsure);
    });

    test('Memverifikasi kesetimbangan persamaan reaksi kimia sederhana', () {
      expect(
        AiCrossVerifier.verifyChemicalEquationBalance('2H2 + O2 -> 2H2O'),
        isTrue,
      );
      expect(
        AiCrossVerifier.verifyChemicalEquationBalance('H2 + O2 -> H2O'),
        isFalse,
      );
    });
  });
}
