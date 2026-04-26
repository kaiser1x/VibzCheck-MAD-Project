import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

// TODO: After deploying Cloud Functions, replace with your real URL:
// https://us-central1-<YOUR_PROJECT_ID>.cloudfunctions.net
const _functionsBase =
    'https://us-central1-TODO_PROJECT_ID.cloudfunctions.net';

class SpotifyTrack {
  final String trackId;
  final String title;
  final String artist;
  final String? albumImageUrl;
  final String? previewUrl;

  const SpotifyTrack({
    required this.trackId,
    required this.title,
    required this.artist,
    this.albumImageUrl,
    this.previewUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) => SpotifyTrack(
        trackId: json['id'] as String,
        title: json['name'] as String,
        artist: (json['artists'] as List<dynamic>)
            .map((a) => a['name'] as String)
            .join(', '),
        albumImageUrl: (json['album']?['images'] as List<dynamic>?)
            ?.firstOrNull?['url'] as String?,
        previewUrl: json['preview_url'] as String?,
      );
}

class SpotifyService {
  final _db = FirebaseFirestore.instance;

  /// Search Spotify tracks via Cloud Function proxy.
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    try {
      final uri = Uri.parse(
          '$_functionsBase/spotifySearch?q=${Uri.encodeComponent(query)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = data['tracks']?['items'] as List<dynamic>? ?? [];
        return items
            .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      return _cachedSearch(query);
    } catch (_) {
      return _cachedSearch(query);
    }
  }

  /// Get mood-based recommendations via Cloud Function proxy.
  Future<List<SpotifyTrack>> getRecommendations({
    required String mood,
    List<String> seedArtists = const [],
    List<String> seedTracks = const [],
  }) async {
    try {
      final params = {
        'mood': mood,
        if (seedArtists.isNotEmpty) 'seed_artists': seedArtists.join(','),
        if (seedTracks.isNotEmpty) 'seed_tracks': seedTracks.join(','),
      };
      final uri = Uri.parse('$_functionsBase/spotifyRecommend')
          .replace(queryParameters: params);
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = data['tracks'] as List<dynamic>? ?? [];
        return items
            .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      return _mockTracks(mood);
    } catch (_) {
      return _mockTracks(mood);
    }
  }

  // Fallback: search existing songs in Firestore when Spotify is down.
  Future<List<SpotifyTrack>> _cachedSearch(String query) async {
    try {
      final snap = await _db
          .collectionGroup('songs')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query')
          .limit(10)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return SpotifyTrack(
          trackId: data['spotifyTrackId'] as String? ?? d.id,
          title: data['title'] as String? ?? 'Unknown',
          artist: data['artist'] as String? ?? 'Unknown',
          albumImageUrl: data['albumImageUrl'] as String?,
          previewUrl: data['previewUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      return _mockTracks(query);
    }
  }

  // Demo-safe hardcoded tracks when Spotify creds are not yet configured.
  List<SpotifyTrack> _mockTracks(String hint) => const [
        SpotifyTrack(
          trackId: 'mock_1',
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          albumImageUrl:
              'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
        ),
        SpotifyTrack(
          trackId: 'mock_2',
          title: 'As It Was',
          artist: 'Harry Styles',
          albumImageUrl:
              'https://i.scdn.co/image/ab67616d0000b273b46f74097655d7f353caab14',
        ),
        SpotifyTrack(
          trackId: 'mock_3',
          title: 'Stay',
          artist: 'The Kid LAROI, Justin Bieber',
          albumImageUrl:
              'https://i.scdn.co/image/ab67616d0000b273e2e352d89826aef6dbd5ff8f',
        ),
        SpotifyTrack(
          trackId: 'mock_4',
          title: 'Heat Waves',
          artist: 'Glass Animals',
          albumImageUrl:
              'https://i.scdn.co/image/ab67616d0000b2739e495fb707973f3390850eea',
        ),
        SpotifyTrack(
          trackId: 'mock_5',
          title: 'Levitating',
          artist: 'Dua Lipa',
          albumImageUrl:
              'https://i.scdn.co/image/ab67616d0000b2730c471c36970b9406abcabe15',
        ),
      ];
}
