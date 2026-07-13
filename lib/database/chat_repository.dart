

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

  Future<List<ChatHistory>> getMessages(int conversationId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'id ASC',
    );

    return maps.map((e) => ChatHistory.fromMap(e)).toList();
  }

  Future<ChatHistory?> getLastMessage(int conversationId) async {
  final Database db = await _databaseHelper.database;

  final result = await db.query(
    'chat_messages',
    where: 'conversation_id = ?',
    whereArgs: [conversationId],
    orderBy: 'id DESC',
    limit: 1,
  );

  if (result.isEmpty) {
    return null;
  }

  return ChatHistory.fromMap(result.first);
}

  Future<void> deleteConversationMessages(int conversationId) async {
    final Database db = await _databaseHelper.database;

    await db.delete(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteAllMessages() async {
    final Database db = await _databaseHelper.database;
    await db.delete('chat_messages');
  }
}