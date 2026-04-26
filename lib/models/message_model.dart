import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.messageId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown',
      photoUrl: data['photoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
