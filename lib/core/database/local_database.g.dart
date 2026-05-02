// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    textContent,
    mood,
    imageUrl,
    date,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String? title;
  final String textContent;
  final String mood;
  final String? imageUrl;
  final DateTime date;
  final bool pendingSync;
  const Note({
    required this.id,
    this.title,
    required this.textContent,
    required this.mood,
    this.imageUrl,
    required this.date,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['text_content'] = Variable<String>(textContent);
    map['mood'] = Variable<String>(mood);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['date'] = Variable<DateTime>(date);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      textContent: Value(textContent),
      mood: Value(mood),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      date: Value(date),
      pendingSync: Value(pendingSync),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      textContent: serializer.fromJson<String>(json['textContent']),
      mood: serializer.fromJson<String>(json['mood']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      date: serializer.fromJson<DateTime>(json['date']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'textContent': serializer.toJson<String>(textContent),
      'mood': serializer.toJson<String>(mood),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'date': serializer.toJson<DateTime>(date),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  Note copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    String? textContent,
    String? mood,
    Value<String?> imageUrl = const Value.absent(),
    DateTime? date,
    bool? pendingSync,
  }) => Note(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    textContent: textContent ?? this.textContent,
    mood: mood ?? this.mood,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    date: date ?? this.date,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      mood: data.mood.present ? data.mood.value : this.mood,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      date: data.date.present ? data.date.value : this.date,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('mood: $mood, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, textContent, mood, imageUrl, date, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.textContent == this.textContent &&
          other.mood == this.mood &&
          other.imageUrl == this.imageUrl &&
          other.date == this.date &&
          other.pendingSync == this.pendingSync);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String> textContent;
  final Value<String> mood;
  final Value<String?> imageUrl;
  final Value<DateTime> date;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.mood = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.date = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required String textContent,
    required String mood,
    this.imageUrl = const Value.absent(),
    required DateTime date,
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textContent = Value(textContent),
       mood = Value(mood),
       date = Value(date);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? textContent,
    Expression<String>? mood,
    Expression<String>? imageUrl,
    Expression<DateTime>? date,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (textContent != null) 'text_content': textContent,
      if (mood != null) 'mood': mood,
      if (imageUrl != null) 'image_url': imageUrl,
      if (date != null) 'date': date,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<String>? textContent,
    Value<String>? mood,
    Value<String?>? imageUrl,
    Value<DateTime>? date,
    Value<bool>? pendingSync,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      mood: mood ?? this.mood,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('mood: $mood, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalsTable extends Journals with TableInfo<$JournalsTable, Journal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedMeta = const VerificationMeta(
    'encrypted',
  );
  @override
  late final GeneratedColumn<bool> encrypted = GeneratedColumn<bool>(
    'encrypted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("encrypted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    textContent,
    mood,
    encrypted,
    date,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Journal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('encrypted')) {
      context.handle(
        _encryptedMeta,
        encrypted.isAcceptableOrUnknown(data['encrypted']!, _encryptedMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Journal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Journal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      encrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}encrypted'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $JournalsTable createAlias(String alias) {
    return $JournalsTable(attachedDatabase, alias);
  }
}

class Journal extends DataClass implements Insertable<Journal> {
  final String id;
  final String? title;
  final String textContent;
  final String mood;
  final bool encrypted;
  final DateTime date;
  final bool pendingSync;
  const Journal({
    required this.id,
    this.title,
    required this.textContent,
    required this.mood,
    required this.encrypted,
    required this.date,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['text_content'] = Variable<String>(textContent);
    map['mood'] = Variable<String>(mood);
    map['encrypted'] = Variable<bool>(encrypted);
    map['date'] = Variable<DateTime>(date);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  JournalsCompanion toCompanion(bool nullToAbsent) {
    return JournalsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      textContent: Value(textContent),
      mood: Value(mood),
      encrypted: Value(encrypted),
      date: Value(date),
      pendingSync: Value(pendingSync),
    );
  }

  factory Journal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Journal(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      textContent: serializer.fromJson<String>(json['textContent']),
      mood: serializer.fromJson<String>(json['mood']),
      encrypted: serializer.fromJson<bool>(json['encrypted']),
      date: serializer.fromJson<DateTime>(json['date']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'textContent': serializer.toJson<String>(textContent),
      'mood': serializer.toJson<String>(mood),
      'encrypted': serializer.toJson<bool>(encrypted),
      'date': serializer.toJson<DateTime>(date),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  Journal copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    String? textContent,
    String? mood,
    bool? encrypted,
    DateTime? date,
    bool? pendingSync,
  }) => Journal(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    textContent: textContent ?? this.textContent,
    mood: mood ?? this.mood,
    encrypted: encrypted ?? this.encrypted,
    date: date ?? this.date,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  Journal copyWithCompanion(JournalsCompanion data) {
    return Journal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      mood: data.mood.present ? data.mood.value : this.mood,
      encrypted: data.encrypted.present ? data.encrypted.value : this.encrypted,
      date: data.date.present ? data.date.value : this.date,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Journal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('mood: $mood, ')
          ..write('encrypted: $encrypted, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, textContent, mood, encrypted, date, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Journal &&
          other.id == this.id &&
          other.title == this.title &&
          other.textContent == this.textContent &&
          other.mood == this.mood &&
          other.encrypted == this.encrypted &&
          other.date == this.date &&
          other.pendingSync == this.pendingSync);
}

class JournalsCompanion extends UpdateCompanion<Journal> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String> textContent;
  final Value<String> mood;
  final Value<bool> encrypted;
  final Value<DateTime> date;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const JournalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.mood = const Value.absent(),
    this.encrypted = const Value.absent(),
    this.date = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required String textContent,
    required String mood,
    this.encrypted = const Value.absent(),
    required DateTime date,
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textContent = Value(textContent),
       mood = Value(mood),
       date = Value(date);
  static Insertable<Journal> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? textContent,
    Expression<String>? mood,
    Expression<bool>? encrypted,
    Expression<DateTime>? date,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (textContent != null) 'text_content': textContent,
      if (mood != null) 'mood': mood,
      if (encrypted != null) 'encrypted': encrypted,
      if (date != null) 'date': date,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalsCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<String>? textContent,
    Value<String>? mood,
    Value<bool>? encrypted,
    Value<DateTime>? date,
    Value<bool>? pendingSync,
    Value<int>? rowid,
  }) {
    return JournalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      mood: mood ?? this.mood,
      encrypted: encrypted ?? this.encrypted,
      date: date ?? this.date,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (encrypted.present) {
      map['encrypted'] = Variable<bool>(encrypted.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('mood: $mood, ')
          ..write('encrypted: $encrypted, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoriesTable extends Memories with TableInfo<$MemoriesTable, Memory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descMeta = const VerificationMeta('desc');
  @override
  late final GeneratedColumn<String> desc = GeneratedColumn<String>(
    'desc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlsJsonMeta = const VerificationMeta(
    'imageUrlsJson',
  );
  @override
  late final GeneratedColumn<String> imageUrlsJson = GeneratedColumn<String>(
    'image_urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUniqueMeta = const VerificationMeta(
    'isUnique',
  );
  @override
  late final GeneratedColumn<bool> isUnique = GeneratedColumn<bool>(
    'is_unique',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unique" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    desc,
    imageUrlsJson,
    date,
    isUnique,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Memory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('desc')) {
      context.handle(
        _descMeta,
        desc.isAcceptableOrUnknown(data['desc']!, _descMeta),
      );
    } else if (isInserting) {
      context.missing(_descMeta);
    }
    if (data.containsKey('image_urls_json')) {
      context.handle(
        _imageUrlsJsonMeta,
        imageUrlsJson.isAcceptableOrUnknown(
          data['image_urls_json']!,
          _imageUrlsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_imageUrlsJsonMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_unique')) {
      context.handle(
        _isUniqueMeta,
        isUnique.isAcceptableOrUnknown(data['is_unique']!, _isUniqueMeta),
      );
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Memory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      desc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}desc'],
      )!,
      imageUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls_json'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isUnique: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unique'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $MemoriesTable createAlias(String alias) {
    return $MemoriesTable(attachedDatabase, alias);
  }
}

class Memory extends DataClass implements Insertable<Memory> {
  final String id;
  final String title;
  final String desc;
  final String imageUrlsJson;
  final DateTime date;
  final bool isUnique;
  final bool pendingSync;
  const Memory({
    required this.id,
    required this.title,
    required this.desc,
    required this.imageUrlsJson,
    required this.date,
    required this.isUnique,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['desc'] = Variable<String>(desc);
    map['image_urls_json'] = Variable<String>(imageUrlsJson);
    map['date'] = Variable<DateTime>(date);
    map['is_unique'] = Variable<bool>(isUnique);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  MemoriesCompanion toCompanion(bool nullToAbsent) {
    return MemoriesCompanion(
      id: Value(id),
      title: Value(title),
      desc: Value(desc),
      imageUrlsJson: Value(imageUrlsJson),
      date: Value(date),
      isUnique: Value(isUnique),
      pendingSync: Value(pendingSync),
    );
  }

  factory Memory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memory(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      desc: serializer.fromJson<String>(json['desc']),
      imageUrlsJson: serializer.fromJson<String>(json['imageUrlsJson']),
      date: serializer.fromJson<DateTime>(json['date']),
      isUnique: serializer.fromJson<bool>(json['isUnique']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'desc': serializer.toJson<String>(desc),
      'imageUrlsJson': serializer.toJson<String>(imageUrlsJson),
      'date': serializer.toJson<DateTime>(date),
      'isUnique': serializer.toJson<bool>(isUnique),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  Memory copyWith({
    String? id,
    String? title,
    String? desc,
    String? imageUrlsJson,
    DateTime? date,
    bool? isUnique,
    bool? pendingSync,
  }) => Memory(
    id: id ?? this.id,
    title: title ?? this.title,
    desc: desc ?? this.desc,
    imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
    date: date ?? this.date,
    isUnique: isUnique ?? this.isUnique,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  Memory copyWithCompanion(MemoriesCompanion data) {
    return Memory(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      desc: data.desc.present ? data.desc.value : this.desc,
      imageUrlsJson: data.imageUrlsJson.present
          ? data.imageUrlsJson.value
          : this.imageUrlsJson,
      date: data.date.present ? data.date.value : this.date,
      isUnique: data.isUnique.present ? data.isUnique.value : this.isUnique,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memory(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('desc: $desc, ')
          ..write('imageUrlsJson: $imageUrlsJson, ')
          ..write('date: $date, ')
          ..write('isUnique: $isUnique, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, desc, imageUrlsJson, date, isUnique, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memory &&
          other.id == this.id &&
          other.title == this.title &&
          other.desc == this.desc &&
          other.imageUrlsJson == this.imageUrlsJson &&
          other.date == this.date &&
          other.isUnique == this.isUnique &&
          other.pendingSync == this.pendingSync);
}

class MemoriesCompanion extends UpdateCompanion<Memory> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> desc;
  final Value<String> imageUrlsJson;
  final Value<DateTime> date;
  final Value<bool> isUnique;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const MemoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.desc = const Value.absent(),
    this.imageUrlsJson = const Value.absent(),
    this.date = const Value.absent(),
    this.isUnique = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoriesCompanion.insert({
    required String id,
    required String title,
    required String desc,
    required String imageUrlsJson,
    required DateTime date,
    this.isUnique = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       desc = Value(desc),
       imageUrlsJson = Value(imageUrlsJson),
       date = Value(date);
  static Insertable<Memory> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? desc,
    Expression<String>? imageUrlsJson,
    Expression<DateTime>? date,
    Expression<bool>? isUnique,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (desc != null) 'desc': desc,
      if (imageUrlsJson != null) 'image_urls_json': imageUrlsJson,
      if (date != null) 'date': date,
      if (isUnique != null) 'is_unique': isUnique,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? desc,
    Value<String>? imageUrlsJson,
    Value<DateTime>? date,
    Value<bool>? isUnique,
    Value<bool>? pendingSync,
    Value<int>? rowid,
  }) {
    return MemoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
      date: date ?? this.date,
      isUnique: isUnique ?? this.isUnique,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (desc.present) {
      map['desc'] = Variable<String>(desc.value);
    }
    if (imageUrlsJson.present) {
      map['image_urls_json'] = Variable<String>(imageUrlsJson.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isUnique.present) {
      map['is_unique'] = Variable<bool>(isUnique.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('desc: $desc, ')
          ..write('imageUrlsJson: $imageUrlsJson, ')
          ..write('date: $date, ')
          ..write('isUnique: $isUnique, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $JournalsTable journals = $JournalsTable(this);
  late final $MemoriesTable memories = $MemoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    journals,
    memories,
  ];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      Value<String?> title,
      required String textContent,
      required String mood,
      Value<String?> imageUrl,
      required DateTime date,
      Value<bool> pendingSync,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String?> title,
      Value<String> textContent,
      Value<String> mood,
      Value<String?> imageUrl,
      Value<DateTime> date,
      Value<bool> pendingSync,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                textContent: textContent,
                mood: mood,
                imageUrl: imageUrl,
                date: date,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                required String textContent,
                required String mood,
                Value<String?> imageUrl = const Value.absent(),
                required DateTime date,
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                textContent: textContent,
                mood: mood,
                imageUrl: imageUrl,
                date: date,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$JournalsTableCreateCompanionBuilder =
    JournalsCompanion Function({
      required String id,
      Value<String?> title,
      required String textContent,
      required String mood,
      Value<bool> encrypted,
      required DateTime date,
      Value<bool> pendingSync,
      Value<int> rowid,
    });
typedef $$JournalsTableUpdateCompanionBuilder =
    JournalsCompanion Function({
      Value<String> id,
      Value<String?> title,
      Value<String> textContent,
      Value<String> mood,
      Value<bool> encrypted,
      Value<DateTime> date,
      Value<bool> pendingSync,
      Value<int> rowid,
    });

class $$JournalsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get encrypted => $composableBuilder(
    column: $table.encrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get encrypted => $composableBuilder(
    column: $table.encrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<bool> get encrypted =>
      $composableBuilder(column: $table.encrypted, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$JournalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalsTable,
          Journal,
          $$JournalsTableFilterComposer,
          $$JournalsTableOrderingComposer,
          $$JournalsTableAnnotationComposer,
          $$JournalsTableCreateCompanionBuilder,
          $$JournalsTableUpdateCompanionBuilder,
          (Journal, BaseReferences<_$AppDatabase, $JournalsTable, Journal>),
          Journal,
          PrefetchHooks Function()
        > {
  $$JournalsTableTableManager(_$AppDatabase db, $JournalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<bool> encrypted = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion(
                id: id,
                title: title,
                textContent: textContent,
                mood: mood,
                encrypted: encrypted,
                date: date,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                required String textContent,
                required String mood,
                Value<bool> encrypted = const Value.absent(),
                required DateTime date,
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion.insert(
                id: id,
                title: title,
                textContent: textContent,
                mood: mood,
                encrypted: encrypted,
                date: date,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalsTable,
      Journal,
      $$JournalsTableFilterComposer,
      $$JournalsTableOrderingComposer,
      $$JournalsTableAnnotationComposer,
      $$JournalsTableCreateCompanionBuilder,
      $$JournalsTableUpdateCompanionBuilder,
      (Journal, BaseReferences<_$AppDatabase, $JournalsTable, Journal>),
      Journal,
      PrefetchHooks Function()
    >;
typedef $$MemoriesTableCreateCompanionBuilder =
    MemoriesCompanion Function({
      required String id,
      required String title,
      required String desc,
      required String imageUrlsJson,
      required DateTime date,
      Value<bool> isUnique,
      Value<bool> pendingSync,
      Value<int> rowid,
    });
typedef $$MemoriesTableUpdateCompanionBuilder =
    MemoriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> desc,
      Value<String> imageUrlsJson,
      Value<DateTime> date,
      Value<bool> isUnique,
      Value<bool> pendingSync,
      Value<int> rowid,
    });

class $$MemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get desc => $composableBuilder(
    column: $table.desc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnique => $composableBuilder(
    column: $table.isUnique,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get desc => $composableBuilder(
    column: $table.desc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnique => $composableBuilder(
    column: $table.isUnique,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get desc =>
      $composableBuilder(column: $table.desc, builder: (column) => column);

  GeneratedColumn<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isUnique =>
      $composableBuilder(column: $table.isUnique, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$MemoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoriesTable,
          Memory,
          $$MemoriesTableFilterComposer,
          $$MemoriesTableOrderingComposer,
          $$MemoriesTableAnnotationComposer,
          $$MemoriesTableCreateCompanionBuilder,
          $$MemoriesTableUpdateCompanionBuilder,
          (Memory, BaseReferences<_$AppDatabase, $MemoriesTable, Memory>),
          Memory,
          PrefetchHooks Function()
        > {
  $$MemoriesTableTableManager(_$AppDatabase db, $MemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> desc = const Value.absent(),
                Value<String> imageUrlsJson = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isUnique = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion(
                id: id,
                title: title,
                desc: desc,
                imageUrlsJson: imageUrlsJson,
                date: date,
                isUnique: isUnique,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String desc,
                required String imageUrlsJson,
                required DateTime date,
                Value<bool> isUnique = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion.insert(
                id: id,
                title: title,
                desc: desc,
                imageUrlsJson: imageUrlsJson,
                date: date,
                isUnique: isUnique,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoriesTable,
      Memory,
      $$MemoriesTableFilterComposer,
      $$MemoriesTableOrderingComposer,
      $$MemoriesTableAnnotationComposer,
      $$MemoriesTableCreateCompanionBuilder,
      $$MemoriesTableUpdateCompanionBuilder,
      (Memory, BaseReferences<_$AppDatabase, $MemoriesTable, Memory>),
      Memory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db, _db.journals);
  $$MemoriesTableTableManager get memories =>
      $$MemoriesTableTableManager(_db, _db.memories);
}
