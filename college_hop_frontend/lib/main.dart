import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:college_hop/theme/theme.dart';
import 'package:college_hop/screen/splash_screen.dart';
import 'package:college_hop/screen/public_profile_screen.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/signup_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/providers/event_provider.dart';
import 'package:college_hop/providers/message_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed (often expected on Web without options): $e');
  }

  // Detect deep link BEFORE building any widgets
  String? initialDeepLink;
  if (kIsWeb) {
    final path = Uri.base.path; // e.g. "/profile/5db68562-..."
    final match = RegExp(r'^/profile/([^/]+)$').firstMatch(path);
    if (match != null) {
      initialDeepLink = '/profile/${match.group(1)}';
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final auth = AuthProvider();
          // Set deep link synchronously BEFORE SplashScreen reads it
          if (initialDeepLink != null) {
            auth.pendingDeepLink = initialDeepLink;
          }
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College Hop',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      // Always start at SplashScreen — it handles auth checks and deep link routing
      home: const SplashScreen(),
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
