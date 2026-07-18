import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/chat_history.dart';
import '../../database/chat_repository.dart';
import '../../database/conversation.dart';
import '../../database/conversation_repository.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ChatRepository _chatRepository = ChatRepository();
  final ConversationRepository _conversationRepository = ConversationRepository();

  DateTime? _lastRestoreTime;
  static const String _lastSyncKey = 'last_firestore_sync';

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  CollectionReference<Map<String, dynamic>> get _conversationCollection {
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('conversations');
  }

  CollectionReference<Map<String, dynamic>> messageCollection(
    String conversationId,
  ) {
    return _conversationCollection
        .doc(conversationId)
        .collection('messages');
  }

  Future<void> uploadConversation({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    if (!isLoggedIn) return;

    await _conversationCollection.doc(conversationId).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> uploadMessage({
    required String conversationId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    if (!isLoggedIn) return;

    await messageCollection(conversationId).doc(messageId).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> downloadConversations() async {
    if (!isLoggedIn) {
      throw StateError('User is not logged in.');
    }

    return _conversationCollection.get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> downloadMessages(
    String conversationId,
  ) async {
    if (!isLoggedIn) {
      throw StateError('User is not logged in.');
    }

    return messageCollection(conversationId).get();
  }

  Future<void> restoreFromCloud() async {
    if (!isLoggedIn) return;

    if (_lastRestoreTime != null &&
        DateTime.now().difference(_lastRestoreTime!) < const Duration(seconds: 10)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);

    Query<Map<String, dynamic>> query =
        _conversationCollection.orderBy('updatedAt', descending: false);

    if (lastSync != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: lastSync,
      );
    }

    final conversations = await query.get();

    for (final conversationDoc in conversations.docs) {
      final data = conversationDoc.data();

      // NOTE: This assumes Firestore conversation document IDs are numeric strings.
      // If you later switch to Firestore auto-generated IDs, store the Firestore ID
      // separately instead of parsing it as an int.
      final conversation = Conversation(
        id: int.tryParse(conversationDoc.id) ?? 0,
        title: data['title'] ?? 'New Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Check whether the conversation already exists locally before inserting
      // to avoid duplicate conversations during repeated restores.
      await _conversationRepository.createConversation(conversation);

      final messages = await downloadMessages(conversationDoc.id);

      for (final messageDoc in messages.docs) {
        final msg = messageDoc.data();

        // NOTE: This assumes Firestore message document IDs are numeric strings.
        // If auto-generated IDs are used, introduce a separate cloudId field.
        await _chatRepository.saveMessage(
          ChatHistory(
            id: int.tryParse(messageDoc.id) ?? 0,
            conversationId: conversation.id!,
            message: msg['message'] ?? '',
            isUser: msg['isUser'] ?? false,
            timestamp: DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
            imagePath: msg['imagePath'],
          ),
        );
      }
    }
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toIso8601String(),
    );
    _lastRestoreTime = DateTime.now();
  }
}