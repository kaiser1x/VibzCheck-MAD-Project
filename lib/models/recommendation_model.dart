import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreBreakdown {
  final double voteScore;         // weight 0.45
  final double listeningScore;    // weight 0.35
  final double moodScore;         // weight 0.20
  final double total;

  const ScoreBreakdown({
    required this.voteScore,
    required this.listeningScore,
    required this.moodScore,
    required this.total,
  });

  factory ScoreBreakdown.fromMap(Map<String, dynamic> map) => ScoreBreakdown(
        voteScore: (map['voteScore'] as num?)?.toDouble() ?? 0.0,
        listeningScore: (map['listeningScore'] as num?)?.toDouble() ?? 0.0,
        moodScore: (map['moodScore'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'voteScore': voteScore,
        'listeningScore': listeningScore,
        'moodScore': moodScore,
        'total': total,
      };
}

class RecommendationModel {
  final String recommendationId;
  final String sessionId;
  final String spotifyTrackId;
  final String title;
  final String artist;
  final String? albumImageUrl;
  final ScoreBreakdown scoreBreakdown;
  final String reason; // human-readable explanation
  final DateTime createdAt;

  const RecommendationModel({
    required this.recommendationId,
    required this.sessionId,
    required this.spotifyTrackId,
    required this.title,
    required this.artist,
    this.albumImageUrl,
    required this.scoreBreakdown,
    required this.reason,
    required this.createdAt,
  });

  factory RecommendationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendationModel(
      recommendationId: doc.id,
      sessionId: data['sessionId'] as String? ?? '',
      spotifyTrackId: data['spotifyTrackId'] as String? ?? '',
      title: data['title'] as String? ?? 'Unknown',
      artist: data['artist'] as String? ?? 'Unknown',
      albumImageUrl: data['albumImageUrl'] as String?,
      scoreBreakdown: ScoreBreakdown.fromMap(
          Map<String, dynamic>.from(data['scoreBreakdown'] ?? {})),
      reason: data['reason'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'sessionId': sessionId,
        'spotifyTrackId': spotifyTrackId,
        'title': title,
        'artist': artist,
        if (albumImageUrl != null) 'albumImageUrl': albumImageUrl,
        'scoreBreakdown': scoreBreakdown.toMap(),
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
