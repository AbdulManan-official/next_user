import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'services/auth_routing_helper.dart';
import 'utils/app_theme.dart';
import 'utils/app_theme_styles.dart';
import 'widgets/animation_helper.dart';
import 'auth/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // google_sign_in v7 requires explicit initialization
  await GoogleSignIn.instance.initialize();
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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: FirebaseAuth.instance.currentUser != null
          ? const AuthGate()
          : const LoginView(),
    );
  }
}

/// Initial root gate that ensures cold-start launches verify profile completeness.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        routeAfterAuth(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackgroundOrbs(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/app_logo.png',
                width: 96,
                height: 96,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
