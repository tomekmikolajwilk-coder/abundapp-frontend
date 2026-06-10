import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';

class AbundApp extends StatelessWidget {
  const AbundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abundapp',
      theme: buildAppTheme(),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
