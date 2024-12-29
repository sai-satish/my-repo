import 'package:flutter/material.dart';
import 'package:trip_swift/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trip_swift/theme/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TripSwift());
}

class TripSwift extends StatelessWidget {
  const TripSwift({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripSwift',
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
