import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/event_detail.dart';

void main() {
  group('EventDetail mission brief flags', () {
    test('missionBriefRequired parses common truthy values', () {
      expect(
        EventDetail.fromJson({'missionBriefRequired': true})
            .missionBriefRequired,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'missionBriefRequired': 1}).missionBriefRequired,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'missionBriefRequired': '1'})
            .missionBriefRequired,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'missionBriefRequired': 'true'})
            .missionBriefRequired,
        isTrue,
      );
    });

    test('missionBriefRequired falls back to false', () {
      expect(
        EventDetail.fromJson({}).missionBriefRequired,
        isFalse,
      );
      expect(
        EventDetail.fromJson({'missionBriefRequired': 0}).missionBriefRequired,
        isFalse,
      );
      expect(
        EventDetail.fromJson({'missionBriefRequired': 'no'})
            .missionBriefRequired,
        isFalse,
      );
    });

    test('hasMissionBriefAck parses common truthy values', () {
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': true}).hasMissionBriefAck,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': 1}).hasMissionBriefAck,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': '1'}).hasMissionBriefAck,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': 'true'}).hasMissionBriefAck,
        isTrue,
      );
    });

    test('hasMissionBriefAck falls back to false', () {
      expect(
        EventDetail.fromJson({}).hasMissionBriefAck,
        isFalse,
      );
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': 0}).hasMissionBriefAck,
        isFalse,
      );
      expect(
        EventDetail.fromJson({'hasMissionBriefAck': 'no'}).hasMissionBriefAck,
        isFalse,
      );
    });
  });
}
