import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
    FirebaseApp? secondaryApp;
    try {
      // 1. Initialize a secondary app instance to create user without logging out the admin
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      // 2. Create the user in Auth
      final userCreds = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Create User Document in Firestore (using main app instance)
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
      // print("Error creating user: $e");
      rethrow;
    } finally {
      // 4. Clean up secondary app
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }
}
