import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'screen/myevent.dart';
import 'screen/groups_screen.dart';
import 'screen/messages_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/new_event_submission.dart';
import 'bottom_nav_bar.dart';

class MainnScreen extends StatefulWidget {
  const MainnScreen({super.key});

  @override
  State<MainnScreen> createState() => _MainnScreenState();
}

class _MainnScreenState extends State<MainnScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DefaultMainScreen(),
    const GroupsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: "main_event_fab",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubmitEventScreen(),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
