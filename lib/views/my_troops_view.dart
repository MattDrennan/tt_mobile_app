import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/troop_controller.dart';
import '../models/troop.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';
import 'event_view.dart';

class MyTroopsView extends StatefulWidget {
  const MyTroopsView({super.key});

  @override
  State<MyTroopsView> createState() => _MyTroopsViewState();
}

class _MyTroopsViewState extends State<MyTroopsView> {
  late final TroopController _controller;
  final _unescape = HtmlUnescape();


  @override
  void initState() {
    super.initState();
    _controller = TroopController(context.read<ApiClient>());
    _controller.addListener(_onChanged);
    _controller.fetchOrganizations();
    final userId = context.read<AuthController>().currentUser?.id ?? '';
    _controller.fetchMyTroops(userId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _iconForTroop(Troop troop) => _controller.iconForTroop(troop);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'My Troops'),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.myTroops.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Not signed up for any troops.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _controller.myTroops
                              .map((troop) => _MyTroopButton(
                                    troop: troop,
                                    iconPath: _iconForTroop(troop),
                                    unescape: _unescape,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _MyTroopButton extends StatelessWidget {
  final Troop troop;
  final String iconPath;
  final HtmlUnescape unescape;

  const _MyTroopButton({
    required this.troop,
    required this.iconPath,
    required this.unescape,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventView(troopId: troop.id)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Image.asset(iconPath, width: 24, height: 24),
              ),
              Text(unescape.convert(troop.name)),
              const SizedBox(height: 4),
              ...troop.myShifts.map((shift) => Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${shift['display']} \u2014 ${shift['status']}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
