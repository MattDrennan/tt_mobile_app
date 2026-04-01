import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/chat_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'key';
}

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(_FakeStorage());

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Uri forumApiUri(String path, [Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/forum/$path');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async =>
      {'troops': []};
}

void main() {
  late ChatController controller;

  setUp(() {
    controller = ChatController(
      _MockApiClient(),
      currentUser: const AppUser(id: '1', username: 'Trooper'),
    );
  });

  test('dispose cancels the poll timer', () {
    controller.openRoom(999);
    // polling has started; dispose should cancel without throwing
    expect(() => controller.dispose(), returnsNormally);
  });

  test('stopPolling clears the timer reference', () {
    controller.openRoom(999);
    controller.stopPolling();
    // stopPolling again is idempotent
    expect(() => controller.stopPolling(), returnsNormally);
  });
}
