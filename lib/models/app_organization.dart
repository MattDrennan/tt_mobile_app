/// A squad/unit returned by the get_organizations API action.
class AppOrganization {
  final int id;
  final String name;

  const AppOrganization({required this.id, required this.name});

  factory AppOrganization.fromJson(Map<String, dynamic> json) => AppOrganization(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );

  static const _iconByName = <String, String>{
    'Everglades Squad': 'assets/icons/everglades_icon.png',
    'Makaze Squad':     'assets/icons/makaze_icon.png',
    'Parjai Squad':     'assets/icons/parjai_icon.png',
    'Squad 7':          'assets/icons/squad7_icon.png',
    'Tampa Bay Squad':  'assets/icons/tampabay_icon.png',
  };

  static const fallbackIcon = 'assets/icons/garrison_icon.png';

  String get iconPath => _iconByName[name] ?? fallbackIcon;
}
