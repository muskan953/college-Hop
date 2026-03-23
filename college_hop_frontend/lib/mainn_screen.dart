import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/event_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveEvent = context.watch<EventProvider>().hasActiveEvent;

    // Conditionally swap Tab 0 between MyEvent and DefaultMainScreen
    final screens = <Widget>[
      hasActiveEvent ? const MyEvent() : const DefaultMainScreen(),
      const GroupsScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

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
        children: screens,
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
