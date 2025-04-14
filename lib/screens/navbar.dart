import 'package:flutter/material.dart';
import 'package:leaderboard_app/shared/colors.dart';

enum NavBarItem { home, placement, leaderboard, profile }

class CustomBottomNavBar extends StatelessWidget {
  final NavBarItem currentItem;
  final void Function(NavBarItem) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: NavBarItem.values.indexOf(currentItem),
      onTap: (index) => onTap(NavBarItem.values[index]),
      selectedItemColor: AppColors.secondaryAccentColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: AppColors.primaryBgColor,
      type: BottomNavigationBarType.fixed,
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
    );
  }
}