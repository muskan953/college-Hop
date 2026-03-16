import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appBar,
      // FIX: If the passed FAB doesn't have a heroTag, we give it a unique one
      // to prevent the "Multiple Heroes" crash during navigation.
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // Note: AppScaffold handles SafeArea, so remove it from your 
          // screen-level widgets to avoid double padding!
          SafeArea(
            child: body,
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (floatingActionButton is FloatingActionButton) {
      final fab = floatingActionButton as FloatingActionButton;
      // If no tag is manually set, we use a unique one per scaffold instance
      return FloatingActionButton(
        key: fab.key,
        onPressed: fab.onPressed,
        heroTag: fab.heroTag ?? UniqueKey(), 
        backgroundColor: fab.backgroundColor,
        child: fab.child,
      );
    }
    return floatingActionButton;
  }
}
