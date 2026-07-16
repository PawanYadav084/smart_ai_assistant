

import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'chat_history.dart';
import '../features/chat/services/chat_service.dart';

class ChatRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final ChatService _chatService = ChatService();

  Future<void> saveMessage(ChatHistory message) async {
    final Database db = await _databaseHelper.database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    try {
      await _chatService.saveMessage(
        conversationId: message.conversationId.toString(),
        messageId: message.id.toString(),
        text: message.message,
        isUser: message.isUser,
        imagePath: message.imagePath,
      );
    } catch (_) {
      // Ignore cloud sync failures so local storage continues to work offline.
    }
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