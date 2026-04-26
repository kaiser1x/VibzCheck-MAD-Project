import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionMood { chill, hype, sad, focus, party, romantic }

extension SessionMoodExt on SessionMood {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class SessionModel {
  final String sessionId;
  final String name;
  final String hostId;
  final SessionMood currentMood;
  final DateTime createdAt;
  final List<String> activeUsers; // uids

  const SessionModel({
    required this.sessionId,
    required this.name,
    required this.hostId,
    required this.currentMood,
    required this.createdAt,
    this.activeUsers = const [],
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      sessionId: doc.id,
      name: data['name'] as String? ?? 'Unnamed Session',
      hostId: data['hostId'] as String? ?? '',
      currentMood: SessionMood.values.firstWhere(
        (m) => m.name == (data['currentMood'] as String? ?? 'chill'),
        orElse: () => SessionMood.chill,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activeUsers: List<String>.from(data['activeUsers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'hostId': hostId,
        'currentMood': currentMood.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'activeUsers': activeUsers,
      };

  SessionModel copyWith({
    String? name,
    SessionMood? currentMood,
    List<String>? activeUsers,
  }) =>
      SessionModel(
        sessionId: sessionId,
        name: name ?? this.name,
        hostId: hostId,
        currentMood: currentMood ?? this.currentMood,
        createdAt: createdAt,
        activeUsers: activeUsers ?? this.activeUsers,
      );
}
