import '../../core/theme/ts_palette.dart';
import '../../core/widgets/verdict_tag.dart';

/// Jenis kartu belajar sesuai Bagian 6.4 PRD & Bagian 7.1 `design.md`.
enum StudyCardType {
  question('question', 'Soal ulang'),
  mistake('mistake', 'Langkah koreksi'),
  concept('concept', 'Konsep'),
  flashcard('flashcard', 'Istilah'),
  variant('variant', 'Latihan serupa'),
  note('note', 'Catatanmu');

  const StudyCardType(this.code, this.label);
  final String code;
  final String label;

  static StudyCardType fromCode(String? code) {
    for (final item in StudyCardType.values) {
      if (item.code == code) return item;
    }
    return StudyCardType.question;
  }
}

/// Model Mapel (bawaan sistem atau buatan pengguna).
class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.colorKey,
    this.iconName,
    this.userId,
    this.taskCount = 0,
    this.dueCardCount = 0,
  });

  final String id;
  final String name;
  final String colorKey;
  final String? iconName;
  final String? userId;
  final int taskCount;
  final int dueCardCount;

  PaperPattern get paperPattern => TsPalette.paperPatternForSubject(colorKey);

  SubjectModel copyWith({
    String? id,
    String? name,
    String? colorKey,
    String? iconName,
    String? userId,
    int? taskCount,
    int? dueCardCount,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      iconName: iconName ?? this.iconName,
      userId: userId ?? this.userId,
      taskCount: taskCount ?? this.taskCount,
      dueCardCount: dueCardCount ?? this.dueCardCount,
    );
  }
}

/// Model satu soal tugas yang sudah selesai dikerjakan (Bagian 6.1 & 10.1 PRD).
class TaskItemModel {
  const TaskItemModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColorKey,
    required this.title,
    required this.questionText,
    required this.userAnswerText,
    required this.topic,
    required this.doneOn,
    required this.questionType,
    required this.difficulty,
    required this.mastery,
    required this.aiVerdict,
    this.mistakeStep,
    this.userVerdict,
    this.aiConfidence = 0.92,
    this.needsCheck = false,
    this.source = 'scan',
    this.imagePath,
    this.lowConfidenceParts = const [],
  });

  final String id;
  final String userId;
  final String subjectId;
  final String subjectName;
  final String subjectColorKey;
  final String title;
  final String questionText;
  final String userAnswerText;
  final String topic;
  final DateTime doneOn;
  final String questionType; // hitungan | pilihan_ganda | isian | uraian | hafalan
  final int difficulty; // 1..5
  final int mastery; // 0 Baru, 1 Lemah, 2 Cukup, 3 Kuat
  final TaskVerdict aiVerdict;
  final String? mistakeStep;
  final TaskVerdict? userVerdict;
  final double aiConfidence;
  final bool needsCheck;
  final String source;
  final String? imagePath;
  final List<String> lowConfidenceParts;

  TaskVerdict get effectiveVerdict => userVerdict ?? aiVerdict;
  bool get isUserOverridden => userVerdict != null;

  String get masteryLabel {
    switch (mastery) {
      case 0:
        return 'Baru';
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
      default:
        return 'Kuat';
    }
  }

  TaskItemModel copyWith({
    String? subjectId,
    String? subjectName,
    String? subjectColorKey,
    String? title,
    String? questionText,
    String? userAnswerText,
    String? topic,
    DateTime? doneOn,
    String? questionType,
    int? difficulty,
    int? mastery,
    TaskVerdict? aiVerdict,
    String? mistakeStep,
    TaskVerdict? userVerdict,
    double? aiConfidence,
    bool? needsCheck,
    List<String>? lowConfidenceParts,
  }) {
    return TaskItemModel(
      id: id,
      userId: userId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectColorKey: subjectColorKey ?? this.subjectColorKey,
      title: title ?? this.title,
      questionText: questionText ?? this.questionText,
      userAnswerText: userAnswerText ?? this.userAnswerText,
      topic: topic ?? this.topic,
      doneOn: doneOn ?? this.doneOn,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      mastery: mastery ?? this.mastery,
      aiVerdict: aiVerdict ?? this.aiVerdict,
      mistakeStep: mistakeStep ?? this.mistakeStep,
      userVerdict: userVerdict ?? this.userVerdict,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      needsCheck: needsCheck ?? this.needsCheck,
      source: source,
      imagePath: imagePath,
      lowConfidenceParts: lowConfidenceParts ?? this.lowConfidenceParts,
    );
  }
}

/// Model Kartu Belajar di Feed + progres SM-2 (`cards` + `card_progress`).
class StudyCardModel {
  const StudyCardModel({
    required this.id,
    required this.taskId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColorKey,
    required this.taskTitle,
    required this.type,
    required this.promptText,
    required this.answerText,
    this.explanationText,
    this.wrongStepText,
    this.correctionMarginNote,
    this.correctStepText,
    this.deepDiveSteps = const [],
    this.seenCount = 0,
    this.lapses = 0,
    this.lastGrade,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.nextReviewAt,
    this.isStarred = false,
    this.fromWrongAnswer = false,
    this.reported = false,
  });

  final String id;
  final String taskId;
  final String subjectId;
  final String subjectName;
  final String subjectColorKey;
  final String taskTitle;
  final StudyCardType type;
  final String promptText;
  final String answerText;
  final String? explanationText;

  // Khusus kartu kesalahan (Bagian 7.1 design.md)
  final String? wrongStepText;
  final String? correctionMarginNote;
  final String? correctStepText;

  // Langkah lengkap untuk panel Dalami (swipe kiri)
  final List<String> deepDiveSteps;

  // Progres pengulangan berjarak (SM-2)
  final int seenCount;
  final int lapses;
  final int? lastGrade;
  final double ease;
  final int intervalDays;
  final DateTime? nextReviewAt;
  final bool isStarred;
  final bool fromWrongAnswer;
  final bool reported;

  bool isDue(DateTime now) {
    if (nextReviewAt == null) return false;
    return !nextReviewAt!.isAfter(now);
  }

  StudyCardModel copyWith({
    int? seenCount,
    int? lapses,
    int? lastGrade,
    double? ease,
    int? intervalDays,
    DateTime? nextReviewAt,
    bool? isStarred,
    bool? reported,
  }) {
    return StudyCardModel(
      id: id,
      taskId: taskId,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectColorKey: subjectColorKey,
      taskTitle: taskTitle,
      type: type,
      promptText: promptText,
      answerText: answerText,
      explanationText: explanationText,
      wrongStepText: wrongStepText,
      correctionMarginNote: correctionMarginNote,
      correctStepText: correctStepText,
      deepDiveSteps: deepDiveSteps,
      seenCount: seenCount ?? this.seenCount,
      lapses: lapses ?? this.lapses,
      lastGrade: lastGrade ?? this.lastGrade,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      isStarred: isStarred ?? this.isStarred,
      fromWrongAnswer: fromWrongAnswer,
      reported: reported ?? this.reported,
    );
  }
}

/// Model Catatan Pribadi (`notes`).
class NoteModel {
  const NoteModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColorKey,
    this.taskId,
    this.cardId,
    this.taskTitle,
    required this.body,
    required this.showInFeed,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final String subjectColorKey;
  final String? taskId;
  final String? cardId;
  final String? taskTitle;
  final String body;
  final bool showInFeed;
  final DateTime updatedAt;

  NoteModel copyWith({
    String? body,
    bool? showInFeed,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectColorKey: subjectColorKey,
      taskId: taskId,
      cardId: cardId,
      taskTitle: taskTitle,
      body: body ?? this.body,
      showInFeed: showInFeed ?? this.showInFeed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model Track Musik Latar (`tracks`).
class MusicTrackModel {
  const MusicTrackModel({
    required this.id,
    required this.title,
    required this.playlistName,
    required this.subjectColorKey,
    required this.sourceType, // bundled | local_file
    required this.uri,
    required this.licenseNote,
    required this.durationSec,
  });

  final String id;
  final String title;
  final String playlistName;
  final String subjectColorKey;
  final String sourceType;
  final String uri;
  final String licenseNote;
  final int durationSec;
}
