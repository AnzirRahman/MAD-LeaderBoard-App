import 'package:flutter/material.dart';
import 'package:leaderboard_app/screens/navbar.dart';
import 'package:leaderboard_app/shared/colors.dart';

class LoginSuccessScreen extends StatelessWidget {
  const LoginSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/wrapper',
            arguments: NavBarItem.profile, // Navigate to profile using wrapper
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.check_circle,
                color: AppColors.secondaryAccentColor,
                size: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Logged In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryAccentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
