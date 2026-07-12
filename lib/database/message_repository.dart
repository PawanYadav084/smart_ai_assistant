

import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'chat_history.dart';

class MessageRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveMessage(ChatHistory message) async {
    final db = await _databaseHelper.database;

    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatHistory>> getMessages() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );

    return result.map((e) => ChatHistory.fromMap(e)).toList();
  }

  Future<void> deleteAllMessages() async {
    final db = await _databaseHelper.database;

    await db.delete('chat_messages');
  }
}