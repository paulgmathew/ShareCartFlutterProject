import '../models/confirm_prices_request_model.dart';
import '../models/nearby_store_model.dart';
import '../models/price_comparison_model.dart';
import '../models/user_location_model.dart';
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

  Future<PriceComparisonModel> comparePrices(String itemName) async {
    final json = await _apiClient.post(
      '/prices/compare',
      body: {'itemName': itemName.trim()},
    );
    return PriceComparisonModel.fromJson(json);
  }

  Future<List<NearbyStoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
  }) async {
    final path = '/stores/nearby?lat=$latitude&lon=$longitude';
    final response = await _apiClient.getList(path);
    return response
        .whereType<Map>()
        .map((json) => NearbyStoreModel.fromJson(json.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getBestPrices() async {
    final response = await _apiClient.getList('/prices/best-prices');
    return response
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getBestStore({
    required String canonicalItemId,
  }) async {
    final response = await _apiClient.getList(
      '/prices/best-store?canonicalItemId=${Uri.encodeQueryComponent(canonicalItemId)}',
    );
    return response
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> updateMyLocation(UserLocationModel location) async {
    await _apiClient.patch('/users/me/location', body: location.toJson());
  }

  Future<void> deletePriceHistory(String id) {
    return _apiClient.delete('/prices/history/$id');
  }
}
