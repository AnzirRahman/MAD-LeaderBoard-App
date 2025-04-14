import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/screens/wrapper.dart'; // Wrapper screen
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:leaderboard_app/screens/drawer/faculty.dart'; // Import FacultyScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized for async operations

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  runApp(
    const ProviderScope(child: MyApp()),
  ); // Use Riverpod's ProviderScope for state management
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable debug banner
      title: 'LeaderBoard App', // App title
      theme: ThemeData(primarySwatch: Colors.blue), // Set theme
      initialRoute: Wrapper.routeName, // Initial route
      routes: {
        Wrapper.routeName: (context) => const Wrapper(), // Wrapper route
        '/signin': (context) => const SignIn(), // Sign-in route
        '/faculty': (context) => const FacultyScreen(), // Faculty route
      },
    );
  }
}
