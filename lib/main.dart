import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'core/services/reminder_service.dart';
import 'core/widgets/responsive_layout.dart';
// Note: We will import Dashboard screens once created.
// import 'features/dashboard/screens/dashboard_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Background Workers
  final reminderService = ReminderService();
  // In a real app, we might use WorkManager here. For now, we call on app start.
  await reminderService.checkDailyReminders();
  await reminderService.checkEscalations();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<ReminderService>(create: (_) => ReminderService()),
      ],
      child: MaterialApp(
        title: 'Envirotech System',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context);
    return StreamBuilder(
      stream: authRepo.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const DashboardScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
