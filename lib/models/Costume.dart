class Costume {
  final int id;
  final String name;

  Costume({required this.id, required this.name});

  @override
  String toString() => name; // For display purposes
}
