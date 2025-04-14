import 'package:flutter/material.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/screens/signin/signinadmin.dart';
import '../../shared/colors.dart';

class SignInOptions extends StatelessWidget {
  const SignInOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBgColor,
      appBar: AppBar(
        title: Text('Sign In Options'),
        backgroundColor: AppColors.primaryAccentColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignIn()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Student Login',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/faculty');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryAccentColor,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Access Faculty',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInAdmin()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkerShade,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Admin Login',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
