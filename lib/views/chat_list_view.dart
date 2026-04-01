import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/app_user.dart';
import '../models/chat_room.dart';
import '../services/api_client.dart';
import '../utils/date_utils.dart' as dt;
import '../widgets/tt_app_bar.dart';
import 'chat_screen_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late final ChatController _controller;
  final _unescape = HtmlUnescape();

  static const _squadIcons = [
    'assets/icons/garrison_icon.png',
    'assets/icons/everglades_icon.png',
    'assets/icons/makaze_icon.png',
    'assets/icons/parjai_icon.png',
    'assets/icons/squad7_icon.png',
    'assets/icons/tampabay_icon.png',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final user = auth.currentUser!;
    _controller = ChatController(
      context.read<ApiClient>(),
      currentUser: user,
    );
    _controller.addListener(_onChanged);
    _controller.fetchRooms();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'My Troops: Chat'),
      body: _controller.isLoadingRooms
          ? const Center(child: CircularProgressIndicator())
          : _controller.rooms.isEmpty
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
                          children: _controller.rooms
                              .map((room) => _RoomButton(
                                    room: room,
                                    unescape: _unescape,
                                    squadIcons: _squadIcons,
                                    currentUser:
                                        context
                                            .read<AuthController>()
                                            .currentUser!,
                                    api: context.read<ApiClient>(),
                                    onNoThread: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'No discussion thread is available for this troop.'),
                                        ),
                                      );
                                    },
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

class _RoomButton extends StatelessWidget {
  final ChatRoom room;
  final HtmlUnescape unescape;
  final List<String> squadIcons;
  final AppUser currentUser;
  final ApiClient api;
  final VoidCallback onNoThread;

  const _RoomButton({
    required this.room,
    required this.unescape,
    required this.squadIcons,
    required this.currentUser,
    required this.api,
    required this.onNoThread,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (room.threadId == null || room.postId == null) {
              onNoThread();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreenView(
                  troopName: unescape.convert(room.name),
                  threadId: room.threadId!,
                  postId: room.postId!,
                  currentUser: currentUser,
                  api: api,
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Image.asset(
                  squadIcons[room.squad.clamp(0, 5)],
                  width: 24,
                  height: 24,
                ),
              ),
              room.hasLink
                  ? Text(
                      dt.formatDateWithTime(room.dateStart, room.dateEnd),
                    )
                  : Text(dt.formatDate(room.dateStart)),
              const SizedBox(height: 5),
              Text(unescape.convert(room.name)),
            ],
          ),
        ),
      ),
    );
  }
}
