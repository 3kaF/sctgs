import 'package:drift/drift.dart';

/// Definisi 11 tabel Drift (SQLite) yang identik dengan skema Postgres di Bagian 10.1 PRD.
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Scans extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskImages extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get scanId => text().nullable().references(Scans, #id)();
  IntColumn get pageNo => integer().withDefault(const Constant(1))();
  TextColumn get localPath => text()();
  TextColumn get remotePath => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get scanId => text().nullable().references(Scans, #id)();
  TextColumn get title => text().nullable()();
  TextColumn get questionText => text()();
  TextColumn get userAnswerText => text().nullable()();
  TextColumn get topic => text().nullable()();
  DateTimeColumn get doneOn => dateTime()();
  TextColumn get questionType =>
      text().withDefault(const Constant('hitungan'))();
  IntColumn get difficulty => integer().withDefault(const Constant(2))();
  IntColumn get mastery => integer().withDefault(const Constant(0))();
  TextColumn get aiVerdict => text().withDefault(const Constant('unsure'))();
  TextColumn get mistakeStep => text().nullable()();
  TextColumn get userVerdict => text().nullable()();
  RealColumn get aiConfidence => real().withDefault(const Constant(1.0))();
  BoolColumn get needsCheck => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('scan'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get taskId => text().nullable().references(Tasks, #id)();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get type => text()();
  TextColumn get contentJson => text().named('content')();
  TextColumn get answerJson => text().nullable().named('answer')();
  TextColumn get explanation => text().nullable()();
  TextColumn get generatedBy => text().withDefault(const Constant('ai'))();
  BoolColumn get reported => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CardProgress extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get cardId => text().references(Cards, #id)();
  IntColumn get seenCount => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get lastGrade => integer().nullable()();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get repeatLater => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, cardId},
  ];
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get taskId => text().nullable().references(Tasks, #id)();
  TextColumn get cardId => text().nullable().references(Cards, #id)();
  TextColumn get body => text()();
  BoolColumn get showInFeed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get playlistId => text().references(Playlists, #id)();
  TextColumn get title => text()();
  TextColumn get sourceType => text()();
  TextColumn get uri => text()();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get feedMode => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get cardsViewed => integer().withDefault(const Constant(0))();
  IntColumn get cardsCorrect => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AiJobs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get scanId => text().nullable()();
  TextColumn get taskId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get tokensUsed => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
