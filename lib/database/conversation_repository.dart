

import 'package:sqflite/sqflite.dart';

import 'conversation.dart';
import 'database_helper.dart';

class ConversationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> createConversation(Conversation conversation) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> createNewConversation() async {
    final now = DateTime.now();

    return createConversation(
      Conversation(
        title: 'New Chat',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<Conversation>> getAllConversations() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );

    return result.map((e) => Conversation.fromMap(e)).toList();
  }

  Future<void> renameConversation(int id, String title) async {
    final Database db = await _databaseHelper.database;

    await db.update(
      'conversations',
      {
        'title': title,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  Future<void> updateTitleIfNeeded(int id, String firstMessage) async {
  final conversation = await getConversation(id);

  if (conversation == null) return;

  if (conversation.title != 'New Chat') return;

  String title = firstMessage.trim();

  if (title.length > 40) {
    title = '${title.substring(0, 40)}...';
  }

  await renameConversation(id, title);
  }




  Future<void> updateConversation(int id) async {
    final Database db = await _databaseHelper.database;

    await db.update(
      'conversations',
      {
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Conversation?> getConversation(int id) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Conversation.fromMap(result.first);
  }

  Future<bool> isConversationEmpty(int id) async {
    final Database db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM chat_messages WHERE conversation_id = ?',
      [id],
    );

    final count = (result.first['count'] as int?) ?? 0;
    return count == 0;
  }

  Future<void> deleteConversation(int id) async {
    final Database db = await _databaseHelper.database;

    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteIfEmpty(int id) async {
    if (await isConversationEmpty(id)) {
      await deleteConversation(id);
    }
  }
}