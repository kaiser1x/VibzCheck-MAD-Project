import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recommendation_model.dart';
import '../models/session_model.dart';
import '../models/song_model.dart';
import '../services/recommendation_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _service = RecommendationService();

  List<RecommendationModel> _recommendations = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<RecommendationModel>>? _sub;

  List<RecommendationModel> get recommendations => _recommendations;
  bool get loading => _loading;
  String? get error => _error;

  void listenToRecommendations(String sessionId) {
    _sub?.cancel();
    _sub = _service.recommendationsStream(sessionId).listen((list) {
      _recommendations = list;
      notifyListeners();
    });
  }

  Future<void> refresh({
    required String sessionId,
    required SessionMood currentMood,
    required List<SongModel> sessionSongs,
    required List<String> groupHistory,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _recommendations = await _service.generateRecommendations(
        sessionId: sessionId,
        currentMood: currentMood,
        sessionSongs: sessionSongs,
        groupListeningHistory: groupHistory,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
