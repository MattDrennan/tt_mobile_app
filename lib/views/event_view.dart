import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart' hide ColorTag, UrlTag;
import 'package:html_unescape/html_unescape.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../custom/info_row.dart';
import '../custom/limit_row.dart';
import '../custom/location_widget.dart';
import '../models/event_detail.dart';
import '../models/roster_entry.dart';
import '../services/api_client.dart';
import '../tags/color_tag.dart';
import '../tags/size_tag.dart';
import '../tags/url_tag.dart';
import '../utils/date_utils.dart' as dt;
import '../widgets/tt_app_bar.dart';
import 'add_friend_view.dart';
import 'add_guest_view.dart';
import 'chat_screen_view.dart';
import 'sign_up_view.dart';

class EventView extends StatefulWidget {
  final int troopId;

  const EventView({super.key, required this.troopId});

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  late final EventController _controller;
  final _unescape = HtmlUnescape();
  late final BBStylesheet _bbStylesheet;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _controller = EventController(
      context.read<ApiClient>(),
      eventId: widget.troopId,
      userId: auth.currentUser?.id ?? '',
    );
    _controller.addListener(_onChanged);
    _controller.fetchAll();
    _bbStylesheet = defaultBBStylesheet(
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
    ).addTag(SizeTag()).replaceTag(ColorTag()).replaceTag(UrlTag());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_controller.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.actionError!)),
      );
      _controller.clearActionError();
    }
    setState(() {});
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';
    try {
      final parsed = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
      return DateFormat('MM/dd/yyyy h:mm a').format(parsed);
    } catch (_) {
      final parsed = DateTime.tryParse(dateTime)?.toLocal();
      if (parsed == null) return 'N/A';
      return DateFormat('MM/dd/yyyy h:mm a').format(parsed);
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(s);
    } catch (_) {
      return DateTime.tryParse(s)?.toLocal();
    }
  }

  void _addToCalendar() {
    final event = _controller.event;
    if (event == null) return;
    final start = _parseDate(event.dateStart);
    final end = _parseDate(event.dateEnd);
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid event date.')),
      );
      return;
    }
    final calEvent = Event(
      title: _unescape.convert(event.name),
      description: _unescape.convert(event.comments ?? ''),
      location: event.location ?? 'Location not specified',
      startDate: start,
      endDate: end,
      allDay: false,
    );
    Add2Calendar.addEvent2Cal(calEvent).then((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  success ? 'Loading calendar...' : 'Failed to add event.')),
        );
      }
    });
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    // imageQuality forces JPEG conversion on iOS (handles HEIC photos)
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;
    await _controller.uploadPhoto(file);
    // Error/success is shown via _onChanged → no additional snackbar needed here
  }

  Future<void> _cancelSignup() async {
    final success = await _controller.cancelTroop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'You have canceled the signup.'
          : (_controller.actionError ?? 'Something went wrong.')),
    ));
  }

  Future<void> _cancelShift(int shiftId) async {
    await _controller.cancelShift(shiftId);
  }

  Future<void> _cancelGuest(int guestId) async {
    await _controller.cancelGuest(guestId);
  }

  Future<void> _cancelFriend(int friendTrooperId, int shiftId) async {
    await _controller.cancelFriendShift(friendTrooperId, shiftId);
  }

  void _openChat() {
    final event = _controller.event;
    if (event == null) return;
    final raw = event.data;
    final threadId = _asInt(raw['thread_id']);
    final postId = _asInt(raw['post_id']);
    if (threadId == null || postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No discussion thread is available for this troop.')),
      );
      return;
    }
    final auth = context.read<AuthController>();
    final api = context.read<ApiClient>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreenView(
          troopName: _unescape.convert(event.name),
          threadId: threadId,
          postId: postId,
          currentUser: auth.currentUser!,
          api: api,
        ),
      ),
    );
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final event = _controller.event;
    final auth = context.read<AuthController>();
    final api = context.read<ApiClient>();

    return Scaffold(
      appBar: buildAppBar(
          context,
          event != null
              ? _unescape.convert(event.name)
              : ''),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Failed to load event.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _unescape.convert(event.venue),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      LocationWidget(location: event.location),
                      const Divider(),

                      // Shifts or date range
                      if (event.shifts.isEmpty) ...[
                        InfoRow(
                            label: 'Start',
                            value: _formatDate(event.dateStart)),
                        InfoRow(
                            label: 'End',
                            value: _formatDate(event.dateEnd)),
                      ] else ...[
                        const Text('Shifts',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...event.shifts.map((shift) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                  shift['display']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14)),
                            )),
                        const Divider(),
                      ],

                      InfoRow(
                          label: 'Website',
                          value: (event.website?.isEmpty ?? true)
                              ? 'N/A'
                              : event.website),
                      const SizedBox(height: 10),

                      // Attendance
                      const Text('Attendance Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      InfoRow(
                          label: 'Attendees',
                          value: event.numberOfAttend?.toString() ?? 'N/A'),
                      InfoRow(
                          label: 'Requested',
                          value:
                              event.requestedNumber?.toString() ?? 'N/A'),
                      InfoRow(
                          label: 'Requested Characters',
                          value:
                              event.requestedCharacter?.toString() ?? 'N/A'),
                      const SizedBox(height: 10),

                      // Amenities
                      const Text('Amenities',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      InfoRow(
                          label: 'Restrooms',
                          value: event.amenities ?? 'N/A'),
                      InfoRow(
                          label: 'Secure Changing Area',
                          value: event.secureChanging ? 'Yes' : 'No'),
                      InfoRow(
                          label: 'Blasters Allowed',
                          value: event.blasters ? 'Yes' : 'No'),
                      InfoRow(
                          label: 'Lightsabers Allowed',
                          value: event.lightsabers ? 'Yes' : 'No'),
                      InfoRow(
                          label: 'Parking Available',
                          value: event.parking ? 'Yes' : 'No'),
                      InfoRow(
                          label: 'Mobility Accessible',
                          value: event.mobility ? 'Yes' : 'No'),
                      const SizedBox(height: 10),

                      // POC
                      const Text('Points of Contact',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      InfoRow(
                          label: 'Referred By',
                          value: event.referred ?? ''),
                      const SizedBox(height: 10),

                      // Comments
                      const Text('Additional Information',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      BBCodeText(
                        data: _unescape.convert(event.comments ?? ''),
                        stylesheet: _bbStylesheet,
                      ),

                      // Limited event
                      if (event.isLimited) ...[
                        const SizedBox(height: 10),
                        const Text('Limited Event Info',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Divider(),
                        LimitRow(
                          total: event.limitTotal != null
                              ? 'This event is limited to ${event.limitTotal} troopers.'
                              : null,
                          clubs: event.limitClubs,
                          extra: event.limitAll,
                        ),
                        if (event.isManualSelection) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.yellow[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Reminder: This event has been set as a manual selection event. '
                              'When a trooper needs to make a change to their attending status '
                              'or costume, troopers must comment below what changes need to be made, '
                              'and command staff will make the changes. Please note, this only applies '
                              'to manual selection events.',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],

                      // Roster
                      if (_controller.roster.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 6),
                        if (event.shifts.length > 1)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: event.shifts.map((shift) {
                                final id = (shift['id'] as num).toInt();
                                final selected =
                                    _controller.selectedRosterShiftId == id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(
                                        shift['display']?.toString() ??
                                            'Shift'),
                                    selected: selected,
                                    onSelected: (_) =>
                                        _controller.setRosterShiftFilter(id),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 6),
                        _buildRosterTable(_controller.filteredRoster),
                      ] else ...[
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text('No roster data available.'),
                      ],

                      // Photos
                      if (_controller.photoList.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text('Event Photos',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: _controller.photoList.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final photo = _controller.photoList[index];
                            return GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(
                                      'Uploaded by ${photo['uploaded_by']}'),
                                  content:
                                      Image.network(photo['full_url']),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      photo['thumbnail_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (photo['admin'] == 1)
                                    const Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Icon(Icons.school,
                                          color: Colors.green, size: 20),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      const Divider(),
                      const SizedBox(height: 10),

                      // Sign-up / cancel controls
                      if (!event.isClosed) ...[
                        if (event.shifts.length > 1)
                          _buildMultiShiftControls(event, auth, api)
                        else
                          _buildSingleShiftControls(event, auth, api),
                      ],

                      // My Friends
                      if (_controller.myFriends.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 6),
                        const Text('My Friends',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ..._controller.myFriends.map((friend) {
                          final friendTrooperId =
                              (friend['trooper_id'] as num).toInt();
                          final shiftId =
                              (friend['shift_id'] as num).toInt();
                          final name = friend['trooper_name']?.toString() ??
                              'Unknown';
                          final status =
                              friend['status_formatted']?.toString() ?? '';
                          final shiftDisplay =
                              friend['shift_display']?.toString() ?? '';
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 14)),
                                      if (event.shifts.length > 1)
                                        Text(shiftDisplay,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54)),
                                    ],
                                  ),
                                ),
                                Text(status,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.green)),
                                if (!event.isClosed &&
                                    !event.isManualSelection) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    onPressed: () => _cancelFriend(
                                        friendTrooperId, shiftId),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      // My Guests
                      if (_controller.myGuests.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 6),
                        const Text('My Guests',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ..._controller.myGuests.map((guest) {
                          final guestId = (guest['id'] as num).toInt();
                          final name =
                              guest['name']?.toString() ?? 'Unknown';
                          final status =
                              guest['status_formatted']?.toString() ?? '';
                          final shiftDisplay =
                              guest['shift_display']?.toString() ?? '';
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 14)),
                                      if (event.shifts.length > 1)
                                        Text(shiftDisplay,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54)),
                                    ],
                                  ),
                                ),
                                Text(status,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.green)),
                                if (!event.isClosed &&
                                    !event.isManualSelection) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    onPressed: () => _cancelGuest(guestId),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      const Divider(),
                      const SizedBox(height: 10),

                      // Calendar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Add to Calendar'),
                          onPressed: _addToCalendar,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Discussion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble, size: 20),
                          label: const Text('Go To Discussion'),
                          onPressed: _openChat,
                        ),
                      ),

                      const Divider(),
                      const SizedBox(height: 10),

                      // Upload
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          onPressed: _controller.isActionInProgress
                              ? null
                              : _uploadImage,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMultiShiftControls(
      EventDetail event, AuthController auth, ApiClient api) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shifts',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        ...event.shifts.map((shift) {
          final shiftId = (shift['id'] as num).toInt();
          final status = _controller.myShiftStatuses[shiftId];
          final isSignedUp = status != null;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(shift['display']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14)),
                ),
                if (isSignedUp) ...[
                  Text(status,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.green)),
                  const SizedBox(width: 8),
                  if (!event.isManualSelection)
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () => _cancelShift(shiftId),
                      child: const Text('Cancel'),
                    ),
                ] else
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignUpView(
                          troopId: widget.troopId,
                          userId: auth.currentUser?.id ?? '',
                          limitedEvent: event.limitedEvent,
                          allowTentative: event.allowTentative,
                          api: api,
                          shifts: [shift],
                        ),
                      ),
                    ).then((_) => _controller.refreshAll()),
                    child: const Text('Sign Up'),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_controller.isInRoster) ...[
          if (event.friendsAllowed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add Friend'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFriendView(
                      troopId: widget.troopId,
                      addedByUserId: auth.currentUser?.id ?? '',
                      limitedEvent: event.limitedEvent,
                      allowTentative: event.allowTentative,
                      shifts: event.shifts,
                    ),
                  ),
                ).then((_) => _controller.refreshAll()),
              ),
            ),
          if (event.guestsAllowed) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add),
                label: const Text('Add Guest'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddGuestView(
                      troopId: widget.troopId,
                      userId: auth.currentUser?.id ?? '',
                      api: api,
                      shifts: event.shifts,
                    ),
                  ),
                ).then((_) => _controller.refreshAll()),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSingleShiftControls(
      EventDetail event, AuthController auth, ApiClient api) {
    if (!_controller.isInRoster) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SignUpView(
                troopId: widget.troopId,
                userId: auth.currentUser?.id ?? '',
                limitedEvent: event.limitedEvent,
                allowTentative: event.allowTentative,
                api: api,
                shifts: event.shifts,
              ),
            ),
          ).then((_) => _controller.refreshAll()),
          child: const Text('Go To Sign Up'),
        ),
      );
    }

    return Column(
      children: [
        if (!event.isManualSelection)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _cancelSignup,
              child: const Text('Cancel Signup'),
            ),
          ),
        if (event.friendsAllowed) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFriendView(
                    troopId: widget.troopId,
                    addedByUserId: auth.currentUser?.id ?? '',
                    limitedEvent: event.limitedEvent,
                    allowTentative: event.allowTentative,
                    shifts: event.shifts,
                  ),
                ),
              ).then((_) => _controller.refreshAll()),
            ),
          ),
        ],
        if (event.guestsAllowed) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text('Add Guest'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddGuestView(
                    troopId: widget.troopId,
                    userId: auth.currentUser?.id ?? '',
                    api: api,
                    shifts: event.shifts,
                  ),
                ),
              ).then((_) => _controller.refreshAll()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRosterTable(List<RosterEntry> rows) {
    return Card(
      color: Colors.grey[900],
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.grey[800]),
            columns: const [
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Trooper Name')),
              DataColumn(label: Text('TKID')),
              DataColumn(label: Text('Costume')),
              DataColumn(label: Text('Backup Costume')),
              DataColumn(label: Text('Signup Time')),
            ],
            rows: rows.map((m) {
              final status = m.statusFormatted.toLowerCase();
              final isCanceled = status == 'canceled';
              final isTentative = status == 'tentative';
              final isStandBy = status == 'stand by';
              final style = TextStyle(
                color: isCanceled
                    ? Colors.red
                    : isTentative
                        ? Colors.purple
                        : isStandBy
                            ? Colors.orange
                            : null,
                decoration:
                    isCanceled ? TextDecoration.lineThrough : null,
              );
              return DataRow(cells: [
                DataCell(Text(m.statusFormatted, style: style)),
                DataCell(Text(m.trooperName, style: style)),
                DataCell(Text(m.tkidFormatted, style: style)),
                DataCell(Text(m.costumeName, style: style)),
                DataCell(Text(m.backupCostumeName, style: style)),
                DataCell(Text(dt.formatDate(m.signupTime), style: style)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
