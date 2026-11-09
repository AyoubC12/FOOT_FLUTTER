import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';

/// Registers FCM device tokens with Django. The Firebase SDK is not a
/// Flutter dependency until google-services / FlutterFire options exist.
class NotificationsRepository {
  NotificationsRepository(this._client);

  final ApiClient _client;

  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    if (!_client.hasBaseUrl) return;
    await _client.post<Map<String, dynamic>>(
      ApiPaths.notificationDevices,
      data: {'token': token, 'platform': platform},
    );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
