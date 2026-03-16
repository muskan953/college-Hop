import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class ConnectionSuccessScreen extends StatefulWidget {
  const ConnectionSuccessScreen({super.key});

  @override
  State<ConnectionSuccessScreen> createState() => _ConnectionSuccessScreenState();
}

class _ConnectionSuccessScreenState extends State<ConnectionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for 5 seconds as requested
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.pop(context, true); // Go back after success, signalling to open sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              color: Colors.green, // Green checkmark
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}

