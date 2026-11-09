import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';

/// Server favorites. The local [favoritesProvider] remains the UI cache until wired.
class FavoritesRepository {
  FavoritesRepository(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    if (!_client.hasBaseUrl) return const [];
    final response = await _client.get<Map<String, dynamic>>(ApiPaths.favorites);
    final results = (response.data?['results'] as List?) ?? const [];
    return results.cast<Map<String, dynamic>>();
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(apiClientProvider));
});
