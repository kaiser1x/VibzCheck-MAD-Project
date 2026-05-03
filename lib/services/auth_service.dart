import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);

    final user = UserModel(
      uid: cred.user!.uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      // Fallback: create profile if it somehow doesn't exist
      final user = UserModel(
        uid: cred.user!.uid,
        displayName: cred.user!.displayName ?? 'User',
        email: email,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(user.toFirestore());
      return user;
    }
    return UserModel.fromFirestore(doc);
  }

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateDisplayName(String uid, String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await _db.collection('users').doc(uid).update({'displayName': name});
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
