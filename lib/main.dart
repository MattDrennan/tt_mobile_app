import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'views/access_gate_view.dart';
import 'views/chat_screen_view.dart';
import 'views/closed_view.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background message received — no UI interaction possible here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('TTMobileApp');

  final storage = StorageService();
  final api = ApiClient(storage);
  final authService = AuthService(storage, api);
  final authController = AuthController(authService, api, storage);

  final notificationService = NotificationService(
    navigatorKey: navigatorKey,
    storage: storage,
    api: api,
  );
  authController.setNotificationService(notificationService);

  await authController.restoreSession();
  await notificationService.requestPermissions();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<ApiClient>.value(value: api),
      ],
      child: TroopTrackerApp(navigatorKey: navigatorKey),
    ),
  );
}

class TroopTrackerApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const TroopTrackerApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Troop Tracker Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(0, 104, 169, 1.0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const _AuthGate(),
            );
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginView());
          case '/access-gate':
            return MaterialPageRoute(builder: (_) => const AccessGateView());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeView());
          case '/closed':
            final message = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => ClosedView(message: message),
            );
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null) return null;
            final auth = navigatorKey.currentContext?.read<AuthController>();
            final api = navigatorKey.currentContext?.read<ApiClient>();
            if (auth?.currentUser == null || api == null) return null;
            return MaterialPageRoute(
              builder: (_) => ChatScreenView(
                troopName: args['troopName'] as String? ?? '',
                threadId: args['threadId'] as int,
                postId: args['postId'] as int,
                currentUser: auth!.currentUser!,
                api: api,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

/// Decides whether to show LoginView or HomeView based on session state.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // Stored to avoid unsafe context.read during dispose()
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth = context.read<AuthController>();
      _auth!.addListener(_onAuthChanged);
      _route();
    });
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => _route();

  void _route() {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    if (auth.isLoggedIn) {
      _auth?.removeListener(_onAuthChanged);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _auth?.removeListener(_onAuthChanged);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
