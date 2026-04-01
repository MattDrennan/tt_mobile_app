import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class ClosedView extends StatelessWidget {
  final String? message;

  const ClosedView({super.key, this.message});

  Future<void> _checkIfOpenAndRoute(BuildContext context) async {
    final auth = context.read<AuthController>();
    await auth.fetchSiteStatus();

    if (!context.mounted) return;

    final status = auth.siteStatus;
    if (status != null && !status.isClosed) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status?.message ?? 'Still closed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'Troop Tracker is Currently Closed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () => _checkIfOpenAndRoute(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
