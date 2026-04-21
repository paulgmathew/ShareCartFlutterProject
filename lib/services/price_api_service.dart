import 'api_client.dart';

class PriceApiService {
  final ApiClient _apiClient;

  PriceApiService(this._apiClient);

  Future<Map<String, dynamic>> capturePrice({
    required String rawText,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'rawText': rawText};
    if (imageUrl != null && imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    return _apiClient.post('/prices/capture', body: body);
  }

  Future<Map<String, dynamic>> confirmPrice({
    required String captureId,
    required String itemName,
    required double price,
    required String unit,
    required String storeName,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'captureId': captureId,
      'itemName': itemName,
      'price': price,
      'unit': unit,
      'storeName': storeName,
    };
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    return _apiClient.post('/prices/confirm', body: body);
  }

  Future<Map<String, dynamic>> comparePrice(Map<String, dynamic> body) {
    return _apiClient.post('/prices/compare', body: body);
  }

  Future<List<Map<String, dynamic>>> getNearbyStores({
    required double latitude,
    required double longitude,
  }) async {
    final encodedLat = Uri.encodeQueryComponent(latitude.toString());
    final encodedLon = Uri.encodeQueryComponent(longitude.toString());
    final list = await _apiClient.getList(
      '/stores/nearby?lat=$encodedLat&lon=$encodedLon',
    );

    return list
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }
}
