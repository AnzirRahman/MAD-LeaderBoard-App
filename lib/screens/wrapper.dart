import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/screens/navbar.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/screens/faculty_dashboard.dart';
import 'package:leaderboard_app/screens/admin_dashboard.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/home/home.dart';
import 'package:leaderboard_app/screens/placement/placement.dart';
import 'package:leaderboard_app/screens/leaderboard/leaderboard.dart';
import 'package:leaderboard_app/screens/profile/profile.dart';
import 'package:leaderboard_app/screens/appbar.dart';
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

  void navigateTo(NavBarItem item, Map<String, dynamic>? authData) {
    if (_currentItem != item) {
      setState(() => _currentItem = item);
    }
  }

  Map<NavBarItem, Widget> _buildScreens(Map<String, dynamic>? authData) {
    final user = authData?['user'] as AppUser?;
    return {
      NavBarItem.home: const Home(),
      NavBarItem.placement: const Placement(),
      NavBarItem.leaderboard: const Leaderboard(),
      NavBarItem.profile: user == null ? const SignIn() : const Profile(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (authData) {
        print('Wrapper: Auth data: $authData');
        final user = authData?['user'] as AppUser?;
        final currentRoute = ModalRoute.of(context)?.settings.name;

        // Role-based redirection for authenticated users
        if (user != null) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final allowMainMenu = args is Map && args['allowMainMenu'] == true;

          if (user.role == 'faculty' && currentRoute != '/faculty' && !allowMainMenu) {
            print('Wrapper: Navigating to FacultyDashboard');
            return const FacultyDashboard();
          } else if (user.role == 'admin' && currentRoute != '/admin' && !allowMainMenu) {
            print('Wrapper: Navigating to AdminDashboard');
            return const AdminDashboard();
          }
        }

        // Show screens with app bar, drawer, and bottom navigation bar
        return Scaffold(
          backgroundColor: AppColors.primaryBgColor,
          appBar: const CustomAppBar(),
          drawer: const CustomDrawer(),
          body: _buildScreens(authData)[_currentItem],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: NavBarItem.values.indexOf(_currentItem),
            onTap: (index) => navigateTo(NavBarItem.values[index], authData),
            selectedItemColor: AppColors.secondaryAccentColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: 'Placement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      loading: () {
        print('Wrapper: Auth state loading');
        // Show Home with app bar, drawer, and bottom navigation bar while loading
        return Scaffold(
          backgroundColor: AppColors.primaryBgColor,
          appBar: const CustomAppBar(),
          drawer: const CustomDrawer(),
          body: const Home(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: NavBarItem.values.indexOf(_currentItem),
            onTap: (index) => navigateTo(NavBarItem.values[index], null),
            selectedItemColor: AppColors.secondaryAccentColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: 'Placement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      error: (error, _) {
        print('Wrapper: Auth error: $error');
        // Show Home with app bar, drawer, and bottom navigation bar on error
        return Scaffold(
          backgroundColor: AppColors.primaryBgColor,
          appBar: const CustomAppBar(),
          drawer: const CustomDrawer(),
          body: const Home(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: NavBarItem.values.indexOf(_currentItem),
            onTap: (index) => navigateTo(NavBarItem.values[index], null),
            selectedItemColor: AppColors.secondaryAccentColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: 'Placement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}