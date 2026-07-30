import '../models/confirm_prices_request_model.dart';
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

  Future<Map<String, dynamic>> confirmPrices(
    ConfirmPricesRequest request,
  ) async {
    return _apiClient.post('/prices/confirm', body: request.toJson());
  }

  Future<List<Map<String, dynamic>>> getPriceHistory({String? itemName}) async {
    final hasFilter = itemName != null && itemName.trim().isNotEmpty;
    final query =
        hasFilter
            ? '?itemName=${Uri.encodeQueryComponent(itemName.trim())}'
            : '';

    final response = await _apiClient.getList('/prices/history$query');
    return response
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }
}
