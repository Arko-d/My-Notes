import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

//REQUIREMENT: Every mobile device has its own documents directory. We will get hold of that directory and then join that path with our db path
import 'package:path/path.dart' show join;

//Notes Service
class NotesService {
  Database? _db;

  List<DatabaseNote> _notes = []; //cache

  //Making notesService into a singleton so that only one instance is available and new instance are not made every time the app is opened
  static final NotesService _shared = NotesService
      ._sharedInstance(); // NotesService instance named _shared is created where _sharedInstance is being called. Now the _shared is initialized once and will never be re-initialized
  NotesService._sharedInstance() {
    //This will create a private constructor which can only be called from NotesService
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
      //notesStreamController is the name of a box that can hold a list of notes.
      //The box is created using the StreamController class in Dart.
      //The box is set up to be able to send data to multiple listeners at once using the broadcast() constructor.
      //When someone starts listening to the box, the onListen() function is called.
      //Inside the onListen() function, the current list of notes is added to the box using the sink.add() method.
    ); //I want to be able to control a stream of database notes. broadcast() enables us to listen to the stream in the future without throwing any error
  }
  factory NotesService() =>
      _shared; // when I call NotesService() from anywhere in the universe, the _shared instance will be returned, if it exists. Else it will be initialized. Hence initialization is done only once.

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;
  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUserException {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  //Updates a note
  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    DatabaseNote noteToBeUpdated = await getNote(id: note.pkNoteId);
    final updatesCount = await db.update(
      noteTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
      where: 'pk_note_id=?',
      whereArgs: [noteToBeUpdated.pkNoteId],
    );
    if (updatesCount == 0) {
      throw CouldNotUpdateNoteException();
    } else {
      final updatedNote = await getNote(id: note.pkNoteId);
      _notes.removeWhere((note) => note.pkNoteId == updatedNote.pkNoteId);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  //Fetches all notes
  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((note) => DatabaseNote.fromRow(note));
  }

  //Fetches a single note based on its ID
  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'pk_note_id=?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      //refreshing the notes cache with current version of note
      _notes.removeWhere((note) => note.pkNoteId == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  //Purges all data from the note table
  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  //Deletes a note from the database
  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'pk_note_id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      //Stream handling
      _notes.removeWhere((note) => note.pkNoteId == id);
      _notesStreamController.add(_notes);
    }
  }

  //Creates notes
  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //Making sure owner exists in the database with current ID
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUserException();
    }

    const text = '';
    // create the notes
    final noteId = await db.insert(
      noteTable,
      {
        fkUserIdColumn: owner.pkUserId,
        textColumn: text,
        isSyncedWithCloudColumn: 1,
      },
    );

    final note = DatabaseNote(
        pkNoteId: noteId,
        fkUserId: owner.pkUserId,
        text: text,
        isSyncedWithCloud: true);

    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  //Provision to fetch the notes
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  //Creates the user and inserts it into the database
  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }
    final userId = await db.insert(
      userTable,
      {
        emailColumn: email.toLowerCase(),
      },
    );

    return DatabaseUser(pkUserId: userId, email: email);
  }

  //Deletes a user from the database
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  //private getter for the database. Gets the database if open, or throws an exception
  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty, since we want db open
    }
  }

  //Opens the database so that other functions can read data from the database
  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(
          dbPath); //it can create the database for us as well
      _db = db;

      await db.execute(createUserTable);
      await db.execute(createNoteTable);
      await _cacheNotes(); //initializes the notes cache
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }

  //Closes the database
  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }
}

//We need database users
@immutable
class DatabaseUser {
  final int pkUserId;
  final String email;
  const DatabaseUser({
    required this.pkUserId,
    required this.email,
  });
  //When we talk with our database, we will read hash tables. This will be like an object as follows: Map<String,Object?>;
  DatabaseUser.fromRow(Map<String, Object?> map)
      : pkUserId = map[pkUserIdColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $pkUserId, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => pkUserId == other.pkUserId;

  @override
  int get hashCode => pkUserId.hashCode;
}

@immutable
class DatabaseNote {
  final int pkNoteId;
  final int fkUserId;
  final String text;
  final bool isSyncedWithCloud;

  const DatabaseNote({
    required this.pkNoteId,
    required this.fkUserId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : pkNoteId = map[pkNoteIdColumn] as int,
        fkUserId = map[fkUserIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, pk_note_id = $pkNoteId, fk_user_id = $fkUserId, text = $text, is_synced_with_cloud = $isSyncedWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => pkNoteId == other.pkNoteId;

  @override
  int get hashCode => pkNoteId.hashCode;
}

//Constants
//DATABASE NAME
const dbName = 'notes.db';
//TABLE NAMES
const noteTable = 'note';
const userTable = 'user';
//USER TABLE
const pkUserIdColumn = 'pk_user_id';
const emailColumn = 'email';
//NOTES TABLE
const pkNoteIdColumn = 'pk_note_id';
const fkUserIdColumn = 'fk_user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
//CREATE QUERIES
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
	      "pk_user_id"	INTEGER NOT NULL UNIQUE,
	      "email"	TEXT NOT NULL UNIQUE,
	      PRIMARY KEY("pk_user_id" AUTOINCREMENT)
      );''';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
	      "pk_note_id"	INTEGER NOT NULL UNIQUE,
	      "fk_user_id"	INTEGER NOT NULL,
	      "text"	TEXT,
	      "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
	      FOREIGN KEY("fk_user_id") REFERENCES "user"("pk_user_id"),
	      PRIMARY KEY("pk_note_id" AUTOINCREMENT)
      );''';
