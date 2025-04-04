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

    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
    AsyncValue<AppUser?> authState,
  ) {
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
        if (authState.asData?.value == null)
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
