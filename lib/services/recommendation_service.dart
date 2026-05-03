import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/recommendation_model.dart';
import '../models/session_model.dart';
import '../models/song_model.dart';
import 'spotify_service.dart';

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SpotifyService _spotify = SpotifyService();
  final _uuid = const Uuid();

  // ── Scoring weights ───────────────────────────────────────────────────────
  static const double _wVote = 0.45;
  static const double _wHistory = 0.35;
  static const double _wMood = 0.20;

  /// Compute and store recommendation scores for all songs in a session,
  /// then generate Spotify-sourced recommendations.
  Future<List<RecommendationModel>> generateRecommendations({
    required String sessionId,
    required SessionMood currentMood,
    required List<SongModel> sessionSongs,
    required List<String> groupListeningHistory, // spotifyTrackIds
  }) async {
    // Score existing session songs and pick top artists/tracks as seeds.
    final scored = _scoreSongs(
      sessionSongs,
      currentMood,
      groupListeningHistory,
    );

    // Persist updated scores back to Firestore.
    final batch = _db.batch();
    for (final entry in scored.entries) {
      batch.update(
        _db
            .collection('sessions')
            .doc(sessionId)
            .collection('songs')
            .doc(entry.key),
        {'recommendationScore': entry.value.total},
      );
    }
    await batch.commit();

    // Build seed data from top-voted / recently-listened songs.
    final topSongs = sessionSongs.toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    final seedTracks = topSongs
        .take(2)
        .map((s) => s.spotifyTrackId)
        .where((id) => !id.startsWith('mock_'))
        .toList();

    // Fetch Spotify recommendations.
    final spotifyTracks = await _spotify.getRecommendations(
      mood: currentMood.name,
      seedTracks: seedTracks,
    );

    // Build RecommendationModel list with score breakdown + explanation.
    final recommendations =
        spotifyTracks.map((track) {
          final breakdown = _scoreSpotifyTrack(
            track: track,
            currentMood: currentMood,
            sessionSongs: sessionSongs,
            groupListeningHistory: groupListeningHistory,
          );
          return RecommendationModel(
            recommendationId: _uuid.v4(),
            sessionId: sessionId,
            spotifyTrackId: track.trackId,
            title: track.title,
            artist: track.artist,
            albumImageUrl: track.albumImageUrl,
            scoreBreakdown: breakdown,
            reason: _buildReason(breakdown, track.artist, currentMood),
            createdAt: DateTime.now(),
          );
        }).toList()..sort(
          (a, b) => b.scoreBreakdown.total.compareTo(a.scoreBreakdown.total),
        );

    // Persist top recommendations.
    final recBatch = _db.batch();
    for (final rec in recommendations.take(10)) {
      recBatch.set(
        _db.collection('recommendations').doc(rec.recommendationId),
        rec.toFirestore(),
      );
    }
    await recBatch.commit();

    return recommendations;
  }

  // Score all session songs; returns map of songId → ScoreBreakdown.
  Map<String, ScoreBreakdown> _scoreSongs(
    List<SongModel> songs,
    SessionMood mood,
    List<String> history,
  ) {
    if (songs.isEmpty) return {};

    final maxVotes = songs
        .map((s) => s.voteCount)
        .reduce((a, b) => a > b ? a : b);

    return {
      for (final song in songs)
        song.songId: _computeBreakdown(
          voteCount: song.voteCount,
          maxVotes: maxVotes,
          moodTags: song.moodTags,
          currentMood: mood,
          inHistory: history.contains(song.spotifyTrackId),
        ),
    };
  }

  ScoreBreakdown _scoreSpotifyTrack({
    required SpotifyTrack track,
    required SessionMood currentMood,
    required List<SongModel> sessionSongs,
    required List<String> groupListeningHistory,
  }) {
    // For a brand-new Spotify track, vote score is zero by default.
    final inHistory = groupListeningHistory.contains(track.trackId);

    // Check if any session song shares the same artist (loose match).
    final artistMatch = sessionSongs.any(
      (s) =>
          s.artist.toLowerCase().contains(track.artist.toLowerCase()) ||
          track.artist.toLowerCase().contains(s.artist.toLowerCase()),
    );

    return _computeBreakdown(
      voteCount: 0,
      maxVotes: 1,
      moodTags: const [],
      currentMood: currentMood,
      inHistory: inHistory || artistMatch,
    );
  }

  ScoreBreakdown _computeBreakdown({
    required int voteCount,
    required int maxVotes,
    required List<String> moodTags,
    required SessionMood currentMood,
    required bool inHistory,
  }) {
    final voteScore = maxVotes > 0
        ? (voteCount / maxVotes).clamp(0.0, 1.0)
        : 0.0;
    final listeningScore = inHistory ? 1.0 : 0.0;
    final moodScore = moodTags.contains(currentMood.name) ? 1.0 : 0.0;

    final total =
        (voteScore * _wVote) +
        (listeningScore * _wHistory) +
        (moodScore * _wMood);

    return ScoreBreakdown(
      voteScore: voteScore,
      listeningScore: listeningScore,
      moodScore: moodScore,
      total: total,
    );
  }

  String _buildReason(ScoreBreakdown b, String artist, SessionMood mood) {
    final parts = <String>[];

    if (b.listeningScore > 0) {
      parts.add('$artist matches your group\'s listening history');
    }
    if (b.moodScore > 0) {
      parts.add('fits the current ${mood.label} mood');
    }
    if (b.voteScore > 0.5) {
      parts.add('highly voted in this session');
    }

    if (parts.isEmpty) {
      // Fallback explanation when scores are all zero.
      return 'Popular track for the ${mood.label} mood';
    }
    return 'Recommended because ${parts.join(' and ')}.';
  }

  Stream<List<RecommendationModel>> recommendationsStream(String sessionId) =>
      _db
          .collection('recommendations')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => s.docs.map(RecommendationModel.fromFirestore).toList());
}
