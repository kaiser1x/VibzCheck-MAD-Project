import 'dart:convert';
import 'package:http/http.dart' as http;

const _functionsBase =
    'https://us-central1-vibzcheck-8fda7.cloudfunctions.net';

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
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final uri = Uri.parse(
        '$_functionsBase/spotifySearch?q=${Uri.encodeComponent(query)}');
    final resp = await http.get(uri).timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = data['tracks']?['items'] as List<dynamic>? ?? [];
      return items
          .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Spotify search failed (${resp.statusCode}): ${resp.body}');
  }

  Future<List<SpotifyTrack>> getRecommendations({
    required String mood,
    List<String> seedArtists = const [],
    List<String> seedTracks = const [],
  }) async {
    final params = {
      'mood': mood,
      if (seedArtists.isNotEmpty) 'seed_artists': seedArtists.join(','),
      if (seedTracks.isNotEmpty) 'seed_tracks': seedTracks.join(','),
    };
    final uri = Uri.parse('$_functionsBase/spotifyRecommend')
        .replace(queryParameters: params);
    final resp = await http.get(uri).timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = data['tracks'] as List<dynamic>? ?? [];
      return items
          .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Recommendations failed (${resp.statusCode}): ${resp.body}');
  }

}
