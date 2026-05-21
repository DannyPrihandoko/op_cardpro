import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'deck_builder_screen.dart';
import 'profile_screen.dart';

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: const Color(0xFF0A0F1E), // Matches AppTheme obsidianBg
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF0F172A), // Matches AppTheme surfaceBg
        activeColor: const Color(0xFFFFD700), // Matches AppTheme accentGold
        inactiveColor: const Color(0xFF94A3B8), // Matches AppTheme textSecondary
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1.0,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Sets',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.hammer),
            activeIcon: Icon(CupertinoIcons.hammer_fill),
            label: 'Deck Builder',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: HomeScreen(),
                );
              },
            );
          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: DeckBuilderScreen(),
                );
              },
            );
          case 2:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: ProfileScreen(),
                );
              },
            );
          default:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: HomeScreen(),
                );
              },
            );
        }
      },
    );
  }
}
