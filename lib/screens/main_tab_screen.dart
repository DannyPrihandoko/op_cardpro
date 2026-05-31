import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'deck_builder_screen.dart';
import 'profile_screen.dart';
import 'tournament/tournament_list_screen.dart';
import 'testing/testing_lab_screen.dart';

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF0F172A),
        activeColor: const Color(0xFFFFD700),
        inactiveColor: const Color(0xFF94A3B8),
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
            icon: Icon(CupertinoIcons.flag),
            activeIcon: Icon(CupertinoIcons.flag_fill),
            label: 'Tournament',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gamecontroller),
            activeIcon: Icon(CupertinoIcons.gamecontroller_fill),
            label: 'Test Lab',
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
              builder: (context) => const CupertinoPageScaffold(
                child: HomeScreen(),
              ),
            );
          case 1:
            return CupertinoTabView(
              builder: (context) => const CupertinoPageScaffold(
                child: DeckBuilderScreen(),
              ),
            );
          case 2:
            return CupertinoTabView(
              builder: (context) => const TournamentListScreen(),
            );
          case 3:
            return CupertinoTabView(
              builder: (context) => const CupertinoPageScaffold(
                child: TestingLabScreen(),
              ),
            );
          case 4:
            return CupertinoTabView(
              builder: (context) => const CupertinoPageScaffold(
                child: ProfileScreen(),
              ),
            );
          default:
            return CupertinoTabView(
              builder: (context) => const CupertinoPageScaffold(
                child: HomeScreen(),
              ),
            );
        }
      },
    );
  }
}
