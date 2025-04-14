import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/screens/wrapper.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/screens/faculty_dashboard.dart';
import 'package:leaderboard_app/screens/admin_dashboard.dart';
import 'package:leaderboard_app/screens/home/home.dart';
import 'package:leaderboard_app/screens/leaderboard/leaderboard.dart';
import 'package:leaderboard_app/screens/placement/placement.dart';
import 'package:leaderboard_app/screens/profile/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaderboard App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Disable debug banner
      initialRoute: '/wrapper',
      routes: {
        '/wrapper': (context) => const Wrapper(),
        '/signin': (context) => const SignIn(),
        '/home': (context) => Home(
          onCheckNow: () => Navigator.pushReplacementNamed(context, '/placement'),
        ),
        '/faculty': (context) => const FacultyDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/leaderboard': (context) => const Leaderboard(),
        '/placement': (context) => const Placement(),
        '/profile': (context) => const Profile(),
      },
      onUnknownRoute: (settings) {
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const Wrapper());
      },
    );
  }
}