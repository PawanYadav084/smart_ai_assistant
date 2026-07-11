

import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'chat_history.dart';

class ChatRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveMessage(ChatHistory message) async {
    final Database db = await _databaseHelper.database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatHistory>> getMessages() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      orderBy: 'id ASC',
    );

    return maps.map((e) => ChatHistory.fromMap(e)).toList();
  }

  Future<void> deleteAllMessages() async {
    final Database db = await _databaseHelper.database;
    await db.delete('chat_messages');
  }
}