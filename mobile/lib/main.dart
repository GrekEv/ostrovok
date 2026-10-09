import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final state = await AppState.create();
  runApp(OstrovokApp(state: state));
}

class OstrovokApp extends StatelessWidget {
  const OstrovokApp({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Островок',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedBuilder(
        animation: state,
        builder: (context, _) => state.preferences.onboardingCompleted
            ? HomeScreen(state: state)
            : OnboardingScreen(state: state),
      ),
    );
  }
}
