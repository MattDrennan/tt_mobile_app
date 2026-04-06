import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/chat_room.dart';

Map<String, dynamic> _chatRoomJson({
  int troopid = 1,
  String name = 'Event Chat',
  dynamic threadId = 42,
  dynamic postId = 5,
  int squad = 3,
  String dateStart = '2024-06-01',
  String dateEnd = '2024-06-01',
  dynamic link = 1,
}) =>
    {
      'troopid': troopid,
      'name': name,
      'thread_id': threadId,
      'post_id': postId,
      'squad': squad,
      'dateStart': dateStart,
      'dateEnd': dateEnd,
      'link': link,
    };

void main() {
  group('ChatRoom.fromJson', () {
    test('parses all fields', () {
      final room = ChatRoom.fromJson(_chatRoomJson());
      expect(room.id, 1);
      expect(room.name, 'Event Chat');
      expect(room.threadId, 42);
      expect(room.postId, 5);
      expect(room.squad, 3);
      expect(room.dateStart, '2024-06-01');
      expect(room.dateEnd, '2024-06-01');
      expect(room.hasLink, isTrue);
    });

    test('falls back to defaults on missing fields', () {
      final room = ChatRoom.fromJson({});
      expect(room.id, 0);
      expect(room.name, '');
      expect(room.threadId, isNull);
      expect(room.postId, isNull);
      expect(room.squad, 0);
      expect(room.dateStart, '');
      expect(room.dateEnd, '');
      expect(room.hasLink, isFalse);
    });

    test('hasLink is false when link is 0', () {
      final room = ChatRoom.fromJson(_chatRoomJson(link: 0));
      expect(room.hasLink, isFalse);
    });

    test('hasLink is false when link is null', () {
      final room = ChatRoom.fromJson(_chatRoomJson(link: null));
      expect(room.hasLink, isFalse);
    });

    test('hasLink is true when link is a positive integer', () {
      final room = ChatRoom.fromJson(_chatRoomJson(link: 5));
      expect(room.hasLink, isTrue);
    });

    test('hasLink is true when link is a positive string', () {
      final room = ChatRoom.fromJson(_chatRoomJson(link: '3'));
      expect(room.hasLink, isTrue);
    });

    test('hasLink is false when link is "0"', () {
      final room = ChatRoom.fromJson(_chatRoomJson(link: '0'));
      expect(room.hasLink, isFalse);
    });

    test('parses thread_id as string', () {
      final room = ChatRoom.fromJson(_chatRoomJson(threadId: '99'));
      expect(room.threadId, 99);
    });

    test('threadId is null when missing', () {
      final room = ChatRoom.fromJson({'troopid': 1, 'name': 'X', 'squad': 0, 'dateStart': '', 'dateEnd': '', 'link': 0});
      expect(room.threadId, isNull);
    });

    test('parses squad as a double', () {
      final room = ChatRoom.fromJson(_chatRoomJson(squad: 2));
      expect(room.squad, 2);
    });
  });
}
