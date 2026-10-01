import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'auth/views/login_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NextUserApp());
}

class NextUserApp extends StatelessWidget {
  const NextUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next User',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginView(),
    );
  }
}
