import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';

import '../controllers/troop_controller.dart';
import '../models/app_organization.dart';
import '../models/troop.dart';
import '../services/api_client.dart';
import '../utils/date_utils.dart' as dt;
import '../widgets/tt_app_bar.dart';
import 'event_view.dart';

class TroopListView extends StatefulWidget {
  const TroopListView({super.key});

  @override
  State<TroopListView> createState() => _TroopListViewState();
}

class _TroopListViewState extends State<TroopListView> {
  late final TroopController _controller;
  final TextEditingController _searchController = TextEditingController();
  final _unescape = HtmlUnescape();


  @override
  void initState() {
    super.initState();
    _controller = TroopController(context.read<ApiClient>());
    _controller.addListener(_onChanged);
    _controller.fetchOrganizations();
    _controller.fetchTroops(0);
    _searchController.addListener(() {
      _controller.setSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _iconForTroop(Troop troop) => _controller.iconForTroop(troop);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Troops'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Troops',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_controller.organizations.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SquadFilterButton(
                    label: 'All',
                    iconPath: AppOrganization.fallbackIcon,
                    selected: _controller.selectedOrgId == 0,
                    onPressed: () => _controller.fetchTroops(0),
                  ),
                  for (final org in _controller.organizations)
                    _SquadFilterButton(
                      label: org.name,
                      iconPath: org.iconPath,
                      selected: _controller.selectedOrgId == org.id,
                      onPressed: () => _controller.fetchTroops(org.id),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.troops.isEmpty
                    ? const Center(child: Text('No troops found!'))
                    : ListView.builder(
                        itemCount: _controller.troops.length,
                        itemBuilder: (context, index) {
                          final troop = _controller.troops[index];
                          return _TroopButton(
                            troop: troop,
                            iconPath: _iconForTroop(troop),
                            unescape: _unescape,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SquadFilterButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool selected;
  final VoidCallback onPressed;

  const _SquadFilterButton({
    required this.label,
    required this.iconPath,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Image.asset(iconPath, width: 18, height: 18),
        label: Text(label),
        style: selected
            ? ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
        onPressed: onPressed,
      ),
    );
  }
}

class _TroopButton extends StatelessWidget {
  final Troop troop;
  final String iconPath;
  final HtmlUnescape unescape;

  const _TroopButton({
    required this.troop,
    required this.iconPath,
    required this.unescape,
  });

  @override
  Widget build(BuildContext context) {
    final name = unescape.convert(troop.name);
    final notice = troop.notice?.trim();
    final hasNotice = notice != null && notice.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EventView(troopId: troop.id)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Image.asset(iconPath, width: 24, height: 24),
              ),
              troop.hasLink
                  ? Text(
                      dt.formatDateWithTime(troop.dateStart, troop.dateEnd),
                      style: const TextStyle(color: Colors.blue),
                    )
                  : Text(dt.formatDate(troop.dateStart)),
              const SizedBox(height: 5),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                hasNotice
                    ? unescape.convert(notice)
                    : '${troop.trooperCount} Troopers Attending',
                style: TextStyle(
                  color: hasNotice
                      ? (troop.trooperCount < 2 ? Colors.red : Colors.green)
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
