import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../models/song_model.dart';
import '../models/vote_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Sessions ──────────────────────────────────────────────────────────────

  Future<SessionModel> createSession({
    required String name,
    required String hostId,
    SessionMood mood = SessionMood.chill,
  }) async {
    final id = _uuid.v4();
    final session = SessionModel(
      sessionId: id,
      name: name,
      hostId: hostId,
      currentMood: mood,
      createdAt: DateTime.now(),
      activeUsers: [hostId],
    );
    await _db.collection('sessions').doc(id).set(session.toFirestore());
    return session;
  }

  Stream<List<SessionModel>> sessionsStream() => _db
      .collection('sessions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SessionModel.fromFirestore).toList());

  Future<SessionModel?> fetchSession(String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }

  Future<void> joinSession(String sessionId, String uid) => _db
      .collection('sessions')
      .doc(sessionId)
      .update({
        'activeUsers': FieldValue.arrayUnion([uid])
      });

  Future<void> leaveSession(String sessionId, String uid) => _db
      .collection('sessions')
      .doc(sessionId)
      .update({
        'activeUsers': FieldValue.arrayRemove([uid])
      });

  Future<void> updateSessionMood(String sessionId, SessionMood mood) =>
      _db.collection('sessions').doc(sessionId).update({
        'currentMood': mood.name,
      });

  // ─── Songs ─────────────────────────────────────────────────────────────────

  Stream<List<SongModel>> songsStream(String sessionId) => _db
      .collection('sessions')
      .doc(sessionId)
      .collection('songs')
      .orderBy('recommendationScore', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SongModel.fromFirestore).toList());

  Future<SongModel> addSong({
    required String sessionId,
    required String spotifyTrackId,
    required String title,
    required String artist,
    String? albumImageUrl,
    String? previewUrl,
    required String addedBy,
  }) async {
    final id = _uuid.v4();
    final song = SongModel(
      songId: id,
      spotifyTrackId: spotifyTrackId,
      title: title,
      artist: artist,
      albumImageUrl: albumImageUrl,
      previewUrl: previewUrl,
      addedBy: addedBy,
      createdAt: DateTime.now(),
    );
    await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('songs')
        .doc(id)
        .set(song.toFirestore());
    return song;
  }

  Future<void> addMoodTagToSong(
    String sessionId,
    String songId,
    String tag,
  ) =>
      _db
          .collection('sessions')
          .doc(sessionId)
          .collection('songs')
          .doc(songId)
          .update({
            'moodTags': FieldValue.arrayUnion([tag])
          });

  Future<void> updateSongScore(
    String sessionId,
    String songId,
    double score,
  ) =>
      _db
          .collection('sessions')
          .doc(sessionId)
          .collection('songs')
          .doc(songId)
          .update({'recommendationScore': score});

  // ─── Votes ─────────────────────────────────────────────────────────────────

  // Use a transaction to prevent race conditions when multiple users vote.
  Future<void> castVote({
    required String sessionId,
    required String songId,
    required String userId,
    required int value, // +1 or -1
  }) async {
    final voteRef = _db
        .collection('sessions')
        .doc(sessionId)
        .collection('votes')
        .doc('${userId}_$songId');

    final songRef = _db
        .collection('sessions')
        .doc(sessionId)
        .collection('songs')
        .doc(songId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(voteRef);
      int delta = value;

      if (existing.exists) {
        final prev = (existing.data()!['voteValue'] as num).toInt();
        if (prev == value) {
          // Toggling off: remove vote and reverse delta
          tx.delete(voteRef);
          delta = -prev;
        } else {
          // Switching vote direction: net change is 2× value
          tx.set(voteRef, {
            'userId': userId,
            'songId': songId,
            'voteValue': value,
            'createdAt': FieldValue.serverTimestamp(),
          });
          delta = value - prev;
        }
      } else {
        tx.set(voteRef, {
          'userId': userId,
          'songId': songId,
          'voteValue': value,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(songRef, {'voteCount': FieldValue.increment(delta)});
    });
  }

  Future<VoteModel?> getUserVote(
    String sessionId,
    String songId,
    String userId,
  ) async {
    final doc = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('votes')
        .doc('${userId}_$songId')
        .get();
    if (!doc.exists) return null;
    return VoteModel.fromFirestore(doc);
  }

  // ─── Chat ──────────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> messagesStream(String sessionId) => _db
      .collection('sessions')
      .doc(sessionId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(MessageModel.fromFirestore).toList());

  Future<void> sendMessage({
    required String sessionId,
    required String userId,
    required String displayName,
    String? photoUrl,
    required String text,
  }) async {
    final id = _uuid.v4();
    final msg = MessageModel(
      messageId: id,
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .doc(id)
        .set(msg.toFirestore());
  }

  // ─── Listening history ─────────────────────────────────────────────────────

  Future<void> recordListenedTrack(String uid, String spotifyTrackId) => _db
      .collection('users')
      .doc(uid)
      .update({
        'listeningHistory': FieldValue.arrayUnion([spotifyTrackId])
      });
}
