/// A squad/unit returned by the get_organizations API action.
class AppOrganization {
  final int id;
  final String name;

  const AppOrganization({required this.id, required this.name});

  factory AppOrganization.fromJson(Map<String, dynamic> json) => AppOrganization(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}
