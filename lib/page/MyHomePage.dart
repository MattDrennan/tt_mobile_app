import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/main.dart';
import 'package:tt_mobile_app/page/ChatPage.dart';
import 'package:tt_mobile_app/page/ConfirmPage.dart';
import 'package:tt_mobile_app/page/TroopPage.dart';
import 'package:tt_mobile_app/page/myTroops.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<bool> confirmTroopsFuture;

  @override
  void initState() {
    super.initState();
    confirmTroopsFuture = fetchConfirmTroops(int.parse(user.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSiteStatus(context);
      fetchUserStatus(context, trooperId: int.parse(user.id));
    });
  }

  void refreshConfirmTroops() {
    setState(() {
      confirmTroopsFuture = fetchConfirmTroops(int.parse(user.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/logo.png',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TroopPage()),
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
                    MaterialPageRoute(builder: (context) => const myTroops()),
                  ).then((_) => refreshConfirmTroops()); // Refresh on return
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
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  ).then((_) => refreshConfirmTroops()); // Refresh on return
                },
                child: const Text('Chat'),
              ),
            ),
            /*const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const myTroops()),
                  ).then((_) => refreshConfirmTroops()); // Refresh on return
                },
                child: const Text('Profile'),
              ),
            ),*/
            const SizedBox(height: 20),
            // Confirm Troops Button (conditionally displayed)
            FutureBuilder<bool>(
              future: confirmTroopsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfirmPage(
                                  trooperId: int.parse(user.id),
                                ),
                              ),
                            ).then((_) =>
                                refreshConfirmTroops()); // Refresh on return
                          },
                          child: const Text('Confirm Troops'),
                        ),
                      ),
                      const SizedBox(height: 20), // Add some spacing
                    ],
                  );
                } else {
                  return const SizedBox.shrink(); // Don't render anything
                }
              },
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => logout(context),
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 50), // Space between button and links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/terms/'));
                  },
                  child: const Text(
                    'Terms and Rules',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Space between links
                GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/privacy-policy/'));
                  },
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
