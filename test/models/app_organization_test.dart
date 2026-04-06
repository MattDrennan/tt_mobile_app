import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/app_organization.dart';

void main() {
  group('AppOrganization.fromJson', () {
    test('parses id and name', () {
      final org = AppOrganization.fromJson({'id': 3, 'name': 'Makaze Squad'});
      expect(org.id, 3);
      expect(org.name, 'Makaze Squad');
    });

    test('handles numeric id as double', () {
      final org = AppOrganization.fromJson({'id': 7.0, 'name': 'Squad 7'});
      expect(org.id, 7);
    });

    test('falls back to 0 and empty string on missing fields', () {
      final org = AppOrganization.fromJson({});
      expect(org.id, 0);
      expect(org.name, '');
    });

    test('handles null values gracefully', () {
      final org = AppOrganization.fromJson({'id': null, 'name': null});
      expect(org.id, 0);
      expect(org.name, '');
    });
  });

  group('AppOrganization.iconPath', () {
    test('returns correct icon for Everglades Squad', () {
      final org = AppOrganization(id: 1, name: 'Everglades Squad');
      expect(org.iconPath, 'assets/icons/everglades_icon.png');
    });

    test('returns correct icon for Makaze Squad', () {
      final org = AppOrganization(id: 2, name: 'Makaze Squad');
      expect(org.iconPath, 'assets/icons/makaze_icon.png');
    });

    test('returns correct icon for Parjai Squad', () {
      final org = AppOrganization(id: 3, name: 'Parjai Squad');
      expect(org.iconPath, 'assets/icons/parjai_icon.png');
    });

    test('returns correct icon for Squad 7', () {
      final org = AppOrganization(id: 4, name: 'Squad 7');
      expect(org.iconPath, 'assets/icons/squad7_icon.png');
    });

    test('returns correct icon for Tampa Bay Squad', () {
      final org = AppOrganization(id: 5, name: 'Tampa Bay Squad');
      expect(org.iconPath, 'assets/icons/tampabay_icon.png');
    });

    test('returns fallback icon for unknown squad', () {
      final org = AppOrganization(id: 99, name: 'Unknown Squad');
      expect(org.iconPath, AppOrganization.fallbackIcon);
    });

    test('fallbackIcon is the garrison icon', () {
      expect(AppOrganization.fallbackIcon, 'assets/icons/garrison_icon.png');
    });
  });
}
