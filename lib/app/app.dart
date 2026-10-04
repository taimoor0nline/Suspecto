import 'package:flutter/material.dart';
import 'package:suspecto/app/theme/app_theme.dart';
import 'package:suspecto/features/home/presentation/home_screen.dart';

class SuspectoApp extends StatelessWidget {
  const SuspectoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suspecto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
