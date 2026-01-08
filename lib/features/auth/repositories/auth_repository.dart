import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Update check-in time
      if (creds.user != null) {
        await _firestore.collection(FirestoreCollections.users).doc(creds.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'checkInToday': FieldValue.serverTimestamp(),
        });
        return await getUserDetails(creds.user!.uid);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> createEmployee(String email, String password, String name, String role) async {
    try {
      // NOTE: Using general FirebaseAuth instance as requested.
      // WARNING: This will sign out the current user (admin) because createAccount signs in the new user immediately.
      final userCreds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCreds.user != null) {
        final newUser = UserModel(
          uid: userCreds.user!.uid,
          email: email,
          name: name,
          role: role,
          isActive: true,
          lastLogin: DateTime.now(),
          checkInToday: null,
        );
        
        await _firestore.collection(FirestoreCollections.users).doc(newUser.uid).set(newUser.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }
}
