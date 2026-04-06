/// A single row in an event's attendance roster.
class RosterEntry {
  final String statusFormatted;
  final String trooperName;
  final String tkidFormatted;
  final String costumeName;
  final String backupCostumeName;
  final String signupTime;
  final int? shiftId;

  const RosterEntry({
    required this.statusFormatted,
    required this.trooperName,
    required this.tkidFormatted,
    required this.costumeName,
    required this.backupCostumeName,
    required this.signupTime,
    this.shiftId,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> json) {
    return RosterEntry(
      statusFormatted: json['status_formatted']?.toString() ?? '',
      trooperName: json['trooper_name']?.toString() ?? '',
      tkidFormatted: json['tkid_formatted']?.toString() ?? '',
      costumeName: json['costume_name']?.toString() ?? '',
      backupCostumeName: json['backup_costume_name']?.toString() ?? '',
      signupTime: json['signuptime']?.toString() ?? '',
      shiftId: (json['shift_id'] as num?)?.toInt(),
    );
  }
}
