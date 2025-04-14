import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/drawer/about.dart';
import 'package:leaderboard_app/screens/drawer/signinoptions.dart';
import 'package:leaderboard_app/screens/drawer/loggedout.dart';
import 'package:leaderboard_app/screens/drawer/faculty.dart';
import 'package:leaderboard_app/services/auth_service.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (authData) {
        final user = authData?['user'] as AppUser?;
        return _buildDrawer(context, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildDrawer(BuildContext context, AppUser? user) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: Drawer(
        backgroundColor: AppColors.primaryBgColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(user),
            _buildMenuItem(
              icon: Icons.person,
              text: 'Sign In Options',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignInOptions(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.school,
              text: 'Faculty',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FacultyScreen(),
                  ),
                );
              },
            ),
            if (user != null)
              _buildMenuItem(
                icon: Icons.logout,
                text: 'Log Out',
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.signOut();
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoggedOutScreen(),
                    ),
                  );
                },
              ),
            _buildMenuItem(
              icon: Icons.info,
              text: 'About',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const About()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AppUser? user) {
    return DrawerHeader(
      decoration: BoxDecoration(color: AppColors.tertiaryBgColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LeaderBoard',
            style: TextStyle(
              color: AppColors.secondaryAccentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Menu',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 15),
            Container(
              height: 1,
              color: AppColors.primaryTextColor.withAlpha(100),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.email,
                  color: AppColors.secondaryAccentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.email,
                    style: TextStyle(
                      color: AppColors.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: AppColors.primaryBgColor,
      leading: Icon(icon, color: AppColors.secondaryAccentColor),
      title: Text(text),
      onTap: onTap,
    );
  }
}
