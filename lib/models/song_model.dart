import 'package:cloud_firestore/cloud_firestore.dart';

class SongModel {
  final String songId;
  final String spotifyTrackId;
  final String title;
  final String artist;
  final String? albumImageUrl;
  final String? previewUrl;
  final String addedBy; // uid
  final int voteCount;
  final List<String> moodTags;
  final DateTime createdAt;
  final double recommendationScore;

  const SongModel({
    required this.songId,
    required this.spotifyTrackId,
    required this.title,
    required this.artist,
    this.albumImageUrl,
    this.previewUrl,
    required this.addedBy,
    this.voteCount = 0,
    this.moodTags = const [],
    required this.createdAt,
    this.recommendationScore = 0.0,
  });

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongModel(
      songId: doc.id,
      spotifyTrackId: data['spotifyTrackId'] as String? ?? '',
      title: data['title'] as String? ?? 'Unknown',
      artist: data['artist'] as String? ?? 'Unknown',
      albumImageUrl: data['albumImageUrl'] as String?,
      previewUrl: data['previewUrl'] as String?,
      addedBy: data['addedBy'] as String? ?? '',
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      moodTags: List<String>.from(data['moodTags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recommendationScore:
          (data['recommendationScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'spotifyTrackId': spotifyTrackId,
        'title': title,
        'artist': artist,
        if (albumImageUrl != null) 'albumImageUrl': albumImageUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        'addedBy': addedBy,
        'voteCount': voteCount,
        'moodTags': moodTags,
        'createdAt': Timestamp.fromDate(createdAt),
        'recommendationScore': recommendationScore,
      };

  SongModel copyWith({
    int? voteCount,
    List<String>? moodTags,
    double? recommendationScore,
  }) =>
      SongModel(
        songId: songId,
        spotifyTrackId: spotifyTrackId,
        title: title,
        artist: artist,
        albumImageUrl: albumImageUrl,
        previewUrl: previewUrl,
        addedBy: addedBy,
        voteCount: voteCount ?? this.voteCount,
        moodTags: moodTags ?? this.moodTags,
        createdAt: createdAt,
        recommendationScore: recommendationScore ?? this.recommendationScore,
      );
}
