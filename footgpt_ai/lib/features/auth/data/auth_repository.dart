import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';
import '../domain/auth_gateway.dart';

class AuthRepository implements AuthGateway {
  AuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> login({required String email, required String password}) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.login,
      data: {'email': email.trim(), 'password': password},
    );
    final data = response.data ?? {};
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || refresh == null) {
      throw const ApiException('Login did not return tokens.');
    }
    await _client.tokens.save(access: access, refresh: refresh);
  }

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.register,
      data: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirm': password,
      },
    );
    final data = response.data ?? {};
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || refresh == null) {
      throw const ApiException('Registration did not return tokens.');
    }
    await _client.tokens.save(access: access, refresh: refresh);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
