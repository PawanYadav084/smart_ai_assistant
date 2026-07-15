import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_ai_assistant.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.insert('conversations', {
          'title': 'New Chat',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            image_path TEXT,
            FOREIGN KEY(conversation_id)
            REFERENCES conversations(id)
            ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE conversations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.insert('conversations', {
            'title': 'New Chat',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          try {
            await db.execute(
              'ALTER TABLE chat_messages ADD COLUMN conversation_id INTEGER DEFAULT 1',
            );
          } catch (_) {
            // Column already exists.
          }
          await db.execute(
            'UPDATE chat_messages SET conversation_id = 1 WHERE conversation_id IS NULL',
          );
        }

        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE chat_messages ADD COLUMN image_path TEXT',
            );
          } catch (_) {
            // Column already exists.
          }
        }
        final existing = await db.query(
          'conversations',
          where: 'id = ?',
          whereArgs: [1],
        );
        if (existing.isEmpty) {
          await db.insert('conversations', {
            'id': 1,
            'title': 'New Chat',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      },
    );
  }
}
