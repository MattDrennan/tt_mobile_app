import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/MyHomePage.dart';

class AccessGatePage extends StatefulWidget {
  final int trooperId; // required
  final String? message;

  const AccessGatePage({super.key, required this.trooperId, this.message});

  @override
  State<AccessGatePage> createState() => _AccessGatePageState();
}

class _AccessGatePageState extends State<AccessGatePage> {
  bool _checking = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _statusMsg = widget.message;
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    setState(() => _checking = true);
    try {
      final uri = Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=user_status&trooperid=${widget.trooperId}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        final canAccess = data['canAccess'] == true || data['canAccess'] == 1;
        final isBanned = data['isBanned'] == true || data['isBanned'] == 1;
        final msg = (data['message'] as String?) ??
            (data['error'] as String?) ??
            'You are unable to access the Troop Tracker at this time due to account permissions.';

        if (canAccess && !isBanned) {
          // Allowed in — go home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const MyHomePage(title: 'Troop Tracker')),
          );
          return;
        } else {
          // Blocked — show reason
          setState(() => _statusMsg = msg);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        setState(() => _statusMsg = 'Server returned ${resp.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Error checking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking status: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
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
              Icon(Icons.lock_outline,
                  size: 80, color: _checking ? Colors.amber : Colors.redAccent),
              const SizedBox(height: 20),
              Text(
                'Access Check',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _statusMsg ?? 'Verifying your access…',
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(_checking ? "Checking…" : "Try Again"),
                onPressed: _checking ? null : () => _checkAndRoute(),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text("Logout"),
                onPressed: () => logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
