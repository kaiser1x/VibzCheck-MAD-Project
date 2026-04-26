import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  List<MessageModel> _messages = [];
  bool _sending = false;
  String? _error;
  StreamSubscription<List<MessageModel>>? _sub;

  List<MessageModel> get messages => _messages;
  bool get sending => _sending;
  String? get error => _error;

  void listenToMessages(String sessionId) {
    _sub?.cancel();
    _sub = _fs.messagesStream(sessionId).listen((list) {
      _messages = list;
      notifyListeners();
    });
  }

  Future<void> sendMessage({
    required String sessionId,
    required String userId,
    required String displayName,
    String? photoUrl,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    _sending = true;
    notifyListeners();
    try {
      await _fs.sendMessage(
        sessionId: sessionId,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        text: text,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
