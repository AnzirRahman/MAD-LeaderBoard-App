import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/screens/navbar.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/shared/styled_button.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/screens/wrapper.dart'; // Import Wrapper to access NavBarItem

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg-pattern.png'),
          fit: BoxFit.none,
          repeat: ImageRepeat.repeat,
          opacity: 0.2,
          scale: 3.0,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWelcomeText(),
              const SizedBox(height: 100),
              _buildActionButtons(context, authState),
            ],
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
          onPressed: () {
            // Navigate to Placement within Wrapper's scaffold
            Navigator.pushNamed(
              context,
              '/wrapper',
              arguments: NavBarItem.placement,
            );
          },
        ),
        if (user == null) ...[
          const SizedBox(width: 10),
          _buildStyledButton(
            text: 'Login',
            backgroundColor: AppColors.primaryBgColor,
            foregroundColor: AppColors.secondaryAccentColor,
            onPressed: () {
              Navigator.pushNamed(context, '/signin');
            },
          ),
        ],
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