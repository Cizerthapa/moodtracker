import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as dev;

part 'local_database.g.dart';

// ── Tables ──────────────────────────────────────────────────────────────────

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text()();
  TextColumn get mood => text()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Journals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text()();
  TextColumn get mood => text()();
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get desc => text()();
  TextColumn get imageUrlsJson => text()(); // Store as JSON string
  DateTimeColumn get date => dateTime()();
  BoolColumn get isUnique => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Logger ──────────────────────────────────────────────────────────────────

class DatabaseLogger extends QueryInterceptor {
  Future<void> runBefore(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    dev.log('DB [EXEC]: $statement with args $args', name: 'Drift');
  }
}

// ── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Notes, Journals, Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Helper Methods ───────────────────────────────────────────────────────

  // Notes
  Future<List<Note>> getAllNotes() => select(notes).get();
  Stream<List<Note>> watchAllNotes() => select(notes).watch();
  Future insertNote(Note note) => into(notes).insertOnConflictUpdate(note);
  Future deleteNoteLocal(String id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();

  // Journals
  Future<List<Journal>> getAllJournals() => select(journals).get();
  Stream<List<Journal>> watchAllJournals() => select(journals).watch();
  Future insertJournal(Journal journal) =>
      into(journals).insertOnConflictUpdate(journal);
  Future deleteJournalLocal(String id) =>
      (delete(journals)..where((t) => t.id.equals(id))).go();

  // Memories
  Future<List<Memory>> getAllMemories() => select(memories).get();
  Stream<List<Memory>> watchAllMemories() => select(memories).watch();
  Future insertMemory(Memory memory) =>
      into(memories).insertOnConflictUpdate(memory);
  Future deleteMemoryLocal(String id) =>
      (delete(memories)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(
      file,
    ).interceptWith(DatabaseLogger());
  });
}
