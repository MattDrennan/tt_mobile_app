/// A single row in the troop list (used by TroopListView and MyTroopsView).
class Troop {
  final int id;
  final String name;
  final String dateStart;
  final String dateEnd;
  final int squad;
  final bool hasLink;
  final String? notice;
  final int trooperCount;
  // Present only in "my troops" responses
  final List<Map<String, dynamic>> myShifts;

  const Troop({
    required this.id,
    required this.name,
    required this.dateStart,
    required this.dateEnd,
    required this.squad,
    required this.hasLink,
    this.notice,
    this.trooperCount = 0,
    this.myShifts = const [],
  });

  factory Troop.fromJson(Map<String, dynamic> json) {
    final link = json['link'];
    final hasLink = link != null && (link is int ? link > 0 : int.tryParse(link.toString(), radix: 10) != null && int.parse(link.toString()) > 0);
    final rawShifts = json['my_shifts'];
    final shifts = rawShifts is List
        ? rawShifts.map((s) => Map<String, dynamic>.from(s as Map)).toList()
        : <Map<String, dynamic>>[];

    return Troop(
      id: (json['troopid'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      dateStart: json['dateStart']?.toString() ?? '',
      dateEnd: json['dateEnd']?.toString() ?? '',
      squad: (json['squad'] as num?)?.toInt() ?? 0,
      hasLink: hasLink,
      notice: json['notice']?.toString(),
      trooperCount: (json['trooper_count'] as num?)?.toInt() ?? 0,
      myShifts: shifts,
    );
  }
}
