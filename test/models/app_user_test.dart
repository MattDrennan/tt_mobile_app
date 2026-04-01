import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/app_user.dart';

void main() {
  group('AppUser.fromJson', () {
    test('parses all fields', () {
      final json = {
        'user_id': 42,
        'username': 'DarthVader',
        'avatar_urls': {'s': 'https://example.com/avatar.png'},
        'tkid': 'FL-501',
      };
      final user = AppUser.fromJson(json);
      expect(user.id, '42');
      expect(user.username, 'DarthVader');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.tkid, 'FL-501');
    });

    test('handles missing optional fields', () {
      final user = AppUser.fromJson({'user_id': 1, 'username': 'Luke'});
      expect(user.avatarUrl, isNull);
      expect(user.tkid, isNull);
    });

    test('id falls back to empty string when user_id missing', () {
      final user = AppUser.fromJson({'username': 'Yoda'});
      expect(user.id, '');
    });
  });

  group('AppUser.toChatUser', () {
    test('maps all fields to types.User', () {
      final user = AppUser(
        id: '7',
        username: 'Obi-Wan',
        avatarUrl: 'https://example.com/obi.png',
      );
      final chatUser = user.toChatUser();
      expect(chatUser.id, '7');
      expect(chatUser.firstName, 'Obi-Wan');
      expect(chatUser.imageUrl, 'https://example.com/obi.png');
    });
  });
}
