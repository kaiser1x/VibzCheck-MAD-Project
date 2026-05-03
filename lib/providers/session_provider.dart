import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/firestore_service.dart';

class SessionProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  SessionModel? _current;
  List<SessionModel> _sessions = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<SessionModel>>? _sessionsSub;
  StreamSubscription<SessionModel?>? _currentSub;

  SessionModel? get current => _current;
  List<SessionModel> get sessions => _sessions;
  bool get loading => _loading;
  String? get error => _error;

  // ── Sessions list ──────────────────────────────────────────────────────────

  void listenToSessions() {
    _sessionsSub?.cancel();
    _sessionsSub = _service.sessionsStream().listen((list) {
      _sessions = list;
      notifyListeners();
    });
  }

  // ── Current session — real-time so mood/activeUsers stay in sync ───────────

  void _listenToCurrentSession(String sessionId) {
    _currentSub?.cancel();
    _currentSub = _service.sessionStream(sessionId).listen((session) {
      if (session != null) {
        _current = session;
        notifyListeners();
      }
    });
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> createSession({
    required String name,
    required String hostId,
    SessionMood mood = SessionMood.chill,
  }) async {
    _setLoading(true);
    try {
      _current = await _service.createSession(
        name: name,
        hostId: hostId,
        mood: mood,
      );
      _error = null;
      _listenToCurrentSession(_current!.sessionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> joinSession(String sessionId, String uid) async {
    _setLoading(true);
    try {
      final session = await _service.fetchSession(sessionId);
      if (session == null) {
        _error = 'Session not found.';
        return false;
      }
      await _service.joinSession(sessionId, uid);
      _current = session;
      _error = null;
      _listenToCurrentSession(sessionId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> leaveSession(String uid) async {
    if (_current == null) return;
    await _service.leaveSession(_current!.sessionId, uid);
    _currentSub?.cancel();
    _currentSub = null;
    _current = null;
    notifyListeners();
  }

  Future<void> updateMood(SessionMood mood) async {
    if (_current == null) return;
    // Optimistic update; live listener will confirm.
    _current = _current!.copyWith(currentMood: mood);
    notifyListeners();
    await _service.updateSessionMood(_current!.sessionId, mood);
  }

  void setCurrentSession(SessionModel session) {
    _current = session;
    _listenToCurrentSession(session.sessionId);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    _currentSub?.cancel();
    super.dispose();
  }
}
