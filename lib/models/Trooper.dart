class Trooper {
  final int id;
  final String name;
  final String tkid;

  Trooper({required this.id, required this.name, required this.tkid});

  @override
  String toString() => name + ' - ' + tkid; // For display purposes
}
