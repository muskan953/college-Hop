import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/theme.dart';
import 'package:college_hop/screen/splash_screen.dart';
import 'package:college_hop/screen/public_profile_screen.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/signup_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/providers/event_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// On web, detect if the browser URL is /profile/:id and return that userId.
  String? _initialProfileId() {
    if (!kIsWeb) return null;
    final path = Uri.base.path; // e.g. "/profile/5db68562-..."
    final match = RegExp(r'^/profile/([^/]+)$').firstMatch(path);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final initialUserId = _initialProfileId();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College Hop',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      // If opened on a /profile/:id URL go directly to the public profile page.
      home: initialUserId != null
          ? PublicProfileScreen(userId: initialUserId)
          : const SplashScreen(),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null) {
          final match = RegExp(r'^/profile/([^/]+)$').firstMatch(uri.path);
          if (match != null) {
            final userId = match.group(1)!;
            return MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: userId),
              settings: settings,
            );
          }
        }
        return null; // fall through to home
      },
    );
  }
}
