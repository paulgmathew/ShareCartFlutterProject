import 'api_client.dart';

class CatalogApiService {
  final ApiClient _apiClient;

  CatalogApiService(this._apiClient);

  Future<List<Map<String, dynamic>>> searchCatalog(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query.trim());
    final response = await _apiClient.getList(
      '/items/catalog?query=$encodedQuery',
    );
    return response
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createCatalogItem(
    String name,
    String? category,
  ) async {
    final body = <String, dynamic>{'name': name};
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }

    return _apiClient.post('/items/catalog', body: body);
  }
}
