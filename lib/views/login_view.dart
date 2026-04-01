import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../widgets/tt_app_bar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Stored to avoid unsafe context.read during dispose()
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    // Listen for navigation side-effects (login success → AccessGateView)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth = context.read<AuthController>();
      _auth!.addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = context.read<AuthController>();
    if (!mounted) return;

    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/access-gate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: buildAppBar(context, 'Troop Tracker'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 200, width: 200),
              const SizedBox(height: 20),
              const Text(
                'Sign in with your Florida Garrison forum account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: auth.isLoading ? null : () => auth.login(),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue with XenForo'),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/terms/')),
                    child: const Text(
                      'Terms and Rules',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/privacy-policy/')),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
