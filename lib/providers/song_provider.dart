import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/vote_model.dart';
import '../services/firestore_service.dart';
import '../services/spotify_service.dart';

class SongProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final SpotifyService _spotify = SpotifyService();

  List<SongModel> _songs = [];
  List<SpotifyTrack> _searchResults = [];
  final Map<String, VoteModel?> _userVotes = {}; // songId → user's vote
  bool _loading = false;
  bool _searching = false;
  String? _error;
  StreamSubscription<List<SongModel>>? _sub;

  List<SongModel> get songs => _songs;
  List<SpotifyTrack> get searchResults => _searchResults;
  Map<String, VoteModel?> get userVotes => _userVotes;
  bool get loading => _loading;
  bool get searching => _searching;
  String? get error => _error;

  void listenToSongs(String sessionId) {
    _sub?.cancel();
    _sub = _fs.songsStream(sessionId).listen((list) {
      _songs = list;
      notifyListeners();
    });
  }

  Future<void> addSong({
    required String sessionId,
    required SpotifyTrack track,
    required String addedBy,
  }) async {
    _setLoading(true);
    try {
      await _fs.addSong(
        sessionId: sessionId,
        spotifyTrackId: track.trackId,
        title: track.title,
        artist: track.artist,
        albumImageUrl: track.albumImageUrl,
        previewUrl: track.previewUrl,
        addedBy: addedBy,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> vote({
    required String sessionId,
    required String songId,
    required String userId,
    required int value,
  }) async {
    try {
      await _fs.castVote(
        sessionId: sessionId,
        songId: songId,
        userId: userId,
        value: value,
      );
      // Refresh this user's vote state for the song.
      _userVotes[songId] =
          await _fs.getUserVote(sessionId, songId, userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadUserVotes(
      String sessionId, String userId, List<String> songIds) async {
    for (final id in songIds) {
      _userVotes[id] = await _fs.getUserVote(sessionId, id, userId);
    }
    notifyListeners();
  }

  Future<void> addMoodTag(
      String sessionId, String songId, String tag) async {
    await _fs.addMoodTagToSong(sessionId, songId, tag);
  }

  Future<void> searchSpotify(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searching = true;
    notifyListeners();
    try {
      _searchResults = await _spotify.searchTracks(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
