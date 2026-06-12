import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as dev;

part 'local_database.g.dart';

/// Drift is a powerful database library for Flutter that interacts with SQLite 
/// (the database engine running locally on your device).
///
/// In your app, Drift is configured in this file. It is primarily used to provide 
/// local storage and offline capabilities for the following three main features:
///
/// - Notes: It stores a local copy of your note entries (including the text, mood, image URL, and date).
/// - Journals: It stores your journal entries (text, mood, date, and whether the entry is encrypted).
/// - Memories: It stores your special memory logs (title, description, image URLs, and date).
///
/// Why is this important?
/// Notice that every table has a pendingSync column (a boolean true/false value).
///
/// This means your app uses Drift to allow users to create Notes, Journals, and 
/// Memories even if they don't have an internet connection. The app saves these 
/// entries locally to the Drift database first (with pendingSync set to true). 
/// Then, when the device reconnects to the internet, the app can safely read 
/// these pending local entries and upload them to your Firebase database in the cloud!
///
/// This is what makes your app feel instantly responsive—because saving locally 
/// via Drift happens instantly!

// ── Tables ──────────────────────────────────────────────────────────────────

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text().nullable()();
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
  TextColumn get textContent => text().nullable()();
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // We use alterTable to recreate the table with the new nullable constraint.
          // This is the most reliable way to change column constraints in SQLite.
          await m.alterTable(TableMigration(notes));
          await m.alterTable(TableMigration(journals));
        }
      },
    );
  }

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
