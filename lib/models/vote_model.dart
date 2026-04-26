import 'package:cloud_firestore/cloud_firestore.dart';

class VoteModel {
  final String voteId;
  final String userId;
  final String songId;
  final int voteValue; // +1 upvote, -1 downvote
  final DateTime createdAt;

  const VoteModel({
    required this.voteId,
    required this.userId,
    required this.songId,
    required this.voteValue,
    required this.createdAt,
  });

  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoteModel(
      voteId: doc.id,
      userId: data['userId'] as String? ?? '',
      songId: data['songId'] as String? ?? '',
      voteValue: (data['voteValue'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'songId': songId,
        'voteValue': voteValue,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
