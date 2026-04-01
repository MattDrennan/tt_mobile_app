class Trooper {
  final int id;
  final String name;
  final String tkid;

  Trooper({required this.id, required this.name, required this.tkid});

  factory Trooper.fromJson(Map<String, dynamic> json) {
    return Trooper(
      id: (json['id'] as num).toInt(),
      name: json['display_name']?.toString() ?? '',
      tkid: json['tkid_formatted']?.toString() ?? '',
    );
  }

  @override
  String toString() => '$name - $tkid';
}
