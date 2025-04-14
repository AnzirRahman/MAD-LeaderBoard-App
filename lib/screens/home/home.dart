import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/shared/styled_button.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';

class Home extends ConsumerWidget {
  final VoidCallback onCheckNow;

  const Home({super.key, required this.onCheckNow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBgColor, // Set background color
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/bg-pattern.png',
            ), // Add background pattern
            fit: BoxFit.none, // Make the pattern smaller
            repeat: ImageRepeat.repeat, // Repeat the pattern
            opacity: 0.2, // Increase transparency
            scale: 3.0, // Scale down the pattern
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Added SingleChildScrollView
            padding: const EdgeInsets.all(16.0), // Added padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Center content
              children: [
                _buildWelcomeText(),
                const SizedBox(height: 100),
                _buildActionButtons(context, authState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Welcome to',
          style: TextStyle(
            color: Colors.black,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'LeaderBoard',
          style: TextStyle(
            color: AppColors.secondaryAccentColor,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> authState,
  ) {
    final user = authState.asData?.value?['user'] as AppUser?;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStyledButton(
          text: 'Check Now',
          backgroundColor: AppColors.secondaryAccentColor,
          foregroundColor: AppColors.primaryBgColor,
          onPressed: onCheckNow,
        ),
        const SizedBox(width: 10),
        if (user == null)
          _buildStyledButton(
            text: 'Login',
            backgroundColor: AppColors.primaryBgColor,
            foregroundColor: AppColors.secondaryAccentColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignIn()),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStyledButton({
    required String text,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      child: StyledButton(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        onPressed: onPressed,
        text: text,
      ),
    );
  }
}
