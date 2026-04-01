import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class AccessGateView extends StatefulWidget {
  const AccessGateView({super.key});

  @override
  State<AccessGateView> createState() => _AccessGateViewState();
}

class _AccessGateViewState extends State<AccessGateView> {
  bool _checking = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRoute());
  }

  Future<void> _checkAndRoute() async {
    final auth = context.read<AuthController>();
    final trooperId = int.tryParse(auth.currentUser?.id ?? '');
    if (trooperId == null) {
      setState(() => _statusMsg = 'Invalid session. Please log in again.');
      return;
    }

    setState(() => _checking = true);
    try {
      final status = await auth.checkUserAccess(trooperId);
      if (!mounted) return;

      if (status.canAccess && !status.isBanned) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _statusMsg = status.message ??
            'You are unable to access the Troop Tracker at this time due to account permissions.');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_statusMsg!)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Error checking status: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_statusMsg!)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: _checking ? Colors.amber : Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Access Check',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _statusMsg ?? 'Verifying your access\u2026',
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(_checking ? 'Checking\u2026' : 'Try Again'),
                onPressed: _checking ? null : _checkAndRoute,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: auth.isLoading ? null : () => auth.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
