import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';
import 'confirm_view.dart';
import 'troop_list_view.dart';
import 'my_troops_view.dart';
import 'chat_list_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller;
  // Stored to avoid unsafe context.read during dispose()
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final trooperId = int.tryParse(auth.currentUser?.id ?? '') ?? 0;
    _controller = HomeController(
      context.read<ApiClient>(),
      trooperId: trooperId,
    );
    _controller.addListener(_onControllerChanged);
    _controller.checkUnconfirmedTroops();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth = context.read<AuthController>();
      _auth!.fetchSiteStatus();
      _auth!.addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthController>();

    if (auth.loggedOut) {
      auth.clearLoggedOutFlag();
      _auth?.removeListener(_onAuthChanged);
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final status = auth.siteStatus;
    if (status == null) return;

    if (status.isClosed) {
      _auth?.removeListener(_onAuthChanged);
      Navigator.pushReplacementNamed(context, '/closed',
          arguments: status.message);
    } else if (!status.canAccess || status.isBanned) {
      _auth?.removeListener(_onAuthChanged);
      Navigator.pushReplacementNamed(context, '/access-gate');
    }
  }

  Future<void> _refreshConfirmTroops() async {
    await _controller.checkUnconfirmedTroops();
  }

  int? get _trooperId {
    final auth = context.read<AuthController>();
    return int.tryParse(auth.currentUser?.id ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: buildAppBar(context, 'Troop Tracker'),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 200, width: 200),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TroopListView()),
                  );
                },
                child: const Text('View Troops'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyTroopsView()),
                  ).then((_) => _refreshConfirmTroops());
                },
                child: const Text('My Troops'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatListView()),
                  ).then((_) => _refreshConfirmTroops());
                },
                child: const Text('Chat'),
              ),
            ),
            if (_controller.hasUnconfirmedTroops) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final trooperId = _trooperId;
                    if (trooperId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmView(trooperId: trooperId),
                      ),
                    ).then((_) => _refreshConfirmTroops());
                  },
                  child: const Text('Confirm Troops'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => auth.logout(),
                child: const Text('Log Out'),
              ),
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
    );
  }
}
