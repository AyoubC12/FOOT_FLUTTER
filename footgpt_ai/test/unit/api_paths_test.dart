import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/core/network/api_paths.dart';

void main() {
  test('API paths are versioned under /api/v1 and never include secrets', () {
    expect(ApiPaths.login, '/api/v1/auth/login/');
    expect(ApiPaths.footballPlayers, '/api/v1/football/players/');
    expect(ApiPaths.assistantChat, '/api/v1/assistant/chat/');
    expect(ApiPaths.notificationDevices, '/api/v1/notifications/devices/');
    expect(ApiPaths.login.contains('key'), isFalse);
  });
}
