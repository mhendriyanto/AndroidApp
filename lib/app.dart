import 'package:flutter/material.dart';

import 'screens/auth/sign_in_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

class SnapCleanApp extends StatefulWidget {
  const SnapCleanApp({super.key});

  @override
  State<SnapCleanApp> createState() => _SnapCleanAppState();
}

class _SnapCleanAppState extends State<SnapCleanApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController.seeded();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapCleanScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SnapClean',
        theme: buildSnapCleanTheme(),
        home: const SignInScreen(),
      ),
    );
  }
}
