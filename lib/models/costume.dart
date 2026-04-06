class Costume {
  final int id;
  final String name;

  Costume({required this.id, required this.name});

  factory Costume.fromJson(Map<String, dynamic> json) {
    return Costume(
      id: (json['id'] as num).toInt(),
      name: '${json['abbreviation'] ?? ''}${json['name'] ?? ''}',
    );
  }

  @override
  String toString() => name;
}
