import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _conversationCollection {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('conversations');
  }

  Future<void> saveConversation({
    required String conversationId,
    required String title,
  }) async {
    await _conversationCollection.doc(conversationId).set({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> renameConversation({
    required String conversationId,
    required String title,
  }) async {
    await _conversationCollection.doc(conversationId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    await _conversationCollection.doc(conversationId).delete();
  }

  Future<void> saveMessage({
    required String conversationId,
    required String messageId,
    required String text,
    required bool isUser,
    String? imagePath,
  }) async {
    await _conversationCollection
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set({
      'message': text,
      'isUser': isUser,
      'imagePath': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> conversationsStream() {
    return _conversationCollection.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String conversationId) {
    return _conversationCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}