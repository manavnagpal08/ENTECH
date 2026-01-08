import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  // IGNORE FIREBASE AUTH FOR THIS TRIAL
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock Stream for Auth State
  final _controller = StreamController<firebase_auth.User?>.broadcast();
  
  // We need to emit an initial value. 
  // In a real app we'd check shared prefs, but for this trial, start logged out.
  Stream<firebase_auth.User?> get authStateChanges => _controller.stream;

  // Mock Login
  Future<UserModel?> login(String username, String password) async {
    // 1. HARDCODED PASSWORD CHECK
    if (password != '123456') {
      throw Exception('Invalid Password. Use 123456 for trial.');
    }

    // 2. DETERMINE ROLE BASED ON USERNAME (Case insensitive)
    String role = 'employee';
    String lowerName = username.toLowerCase();
    
    if (lowerName.contains('admin')) role = 'admin';
    else if (lowerName.contains('sales')) role = 'sales';
    else if (lowerName.contains('service') || lowerName.contains('tech')) role = 'technician';

    // 3. CREATE MOCK USER (No Firebase backend call for auth)
    final mockUser = UserModel(
      uid: 'mock_${lowerName}_id', 
      email: '$lowerName@envirotech.trial',
      name: username.toUpperCase(), 
      role: role,
      isActive: true,
      lastLogin: DateTime.now(),
      checkInToday: DateTime.now(),
    );

    // 4. EMIT TO STREAM (Simulates Firebase Auth State Change - bit tricky since we need a User object)
    // Since our app uses StreamBuilder<User?>, we explicitly need a User object or we change the app to use UserModel stream.
    // Changing main.dart is risky. Let's try to fake it or just modify main.dart to listen to a different stream?
    // EASIER: Just modify main.dart to check a simple boolean or use a local provider.
    // BUT user wants quick changes.
    // Let's actually NOT emit to the stream for now and just return the user, 
    // AND we will update LoginScreen to navigate manually on success. 
    // The main.dart AuthWrapper might keep showing LoginScreen if stream is null.
    // SO, we should simulate a successful stream event? 
    // We cannot easily instantiate a firebase_auth.User.
    
    // ALTERNATIVE: We won't use AuthWrapper for this trial. 
    // LoginScreen will pushReplacement to Dashboard.
    
    return mockUser;
  }

  Future<void> logout() async {
    // _controller.add(null);
  }

  Future<void> createEmployee(String email, String password, String name, String role) async {
    throw Exception("Registration disabled for Trial Mode.");
  }
}

