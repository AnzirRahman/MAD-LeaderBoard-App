import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/screens/faculty_dashboard.dart';
import 'package:leaderboard_app/screens/admin_dashboard.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/home/home.dart';
import 'package:leaderboard_app/screens/placement/placement.dart';
import 'package:leaderboard_app/screens/leaderboard/leaderboard.dart';
import 'package:leaderboard_app/screens/profile/profile.dart';
import 'package:leaderboard_app/screens/appbar.dart';
import 'package:leaderboard_app/screens/navbar.dart';
import 'package:leaderboard_app/screens/drawer/drawer.dart';

class Wrapper extends ConsumerStatefulWidget {
  const Wrapper({super.key});

  static const String routeName = '/wrapper';

  @override
  ConsumerState<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends ConsumerState<Wrapper> {
  NavBarItem _currentItem = NavBarItem.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is NavBarItem) {
        setState(() {
          _currentItem = args;
        });
      } else if (args is Map && args['item'] is NavBarItem) {
        setState(() {
          _currentItem = args['item'] as NavBarItem;
        });
      }
    });
  }

  void navigateTo(NavBarItem item) {
    if (_currentItem != item) {
      setState(() => _currentItem = item);
    }
  }

  Map<NavBarItem, Widget> _buildScreens() {
    return {
      NavBarItem.home: Home(
        onCheckNow: () {
          print('Wrapper: Home onCheckNow, navigating to placement');
          navigateTo(NavBarItem.placement);
        },
      ),
      NavBarItem.placement: const Placement(),
      NavBarItem.leaderboard: const Leaderboard(),
      NavBarItem.profile: const Profile(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (authData) {
        print('Wrapper: Auth data: $authData');
        if (authData == null || authData['user'] == null) {
          print('Wrapper: No user data, redirecting to SignIn');
          return const SignIn();
        }

        final user = authData['user'] as AppUser;
        print('Wrapper: User role: ${user.role}');
        final args = ModalRoute.of(context)?.settings.arguments;
        final allowMainMenu = args is Map && args['allowMainMenu'] == true;

        // Allow main menu for admins/faculty if flagged
        if (allowMainMenu) {
          print('Wrapper: Allowing main menu for role ${user.role}');
          return Scaffold(
            backgroundColor: AppColors.primaryBgColor,
            appBar: const CustomAppBar(),
            drawer: const CustomDrawer(),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg-pattern.png'),
                  fit: BoxFit.none,
                  repeat: ImageRepeat.repeat,
                  opacity: 0.2,
                  scale: 3.0,
                ),
              ),
              child: _buildScreens()[_currentItem],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentItem: _currentItem,
              onTap: navigateTo,
            ),
          );
        }

        // Role-based dashboard redirection
        if (user.role == 'faculty' && ModalRoute.of(context)?.settings.name != '/faculty') {
          print('Wrapper: Navigating to FacultyDashboard');
          return const FacultyDashboard();
        } else if (user.role == 'admin' && ModalRoute.of(context)?.settings.name != '/admin') {
          print('Wrapper: Navigating to AdminDashboard');
          return const AdminDashboard();
        } else {
          print('Wrapper: Navigating to student screens');
          return Scaffold(
            backgroundColor: AppColors.primaryBgColor,
            appBar: const CustomAppBar(),
            drawer: const CustomDrawer(),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg-pattern.png'),
                  fit: BoxFit.none,
                  repeat: ImageRepeat.repeat,
                  opacity: 0.2,
                  scale: 3.0,
                ),
              ),
              child: _buildScreens()[_currentItem],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentItem: _currentItem,
              onTap: navigateTo,
            ),
          );
        }
      },
      loading: () {
        print('Wrapper: Auth state loading');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) {
        print('Wrapper: Auth error: $error');
        return Center(child: Text('Error: $error'));
      },
    );
  }
}