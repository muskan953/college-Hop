import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/theme.dart';
import 'package:college_hop/screen/splash_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College Hop',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(), 
    );
  }
}
