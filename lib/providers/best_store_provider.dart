import 'package:flutter/foundation.dart';

import '../models/best_store_option_model.dart';
import '../services/api_client.dart';
import '../services/price_api_service.dart';

class BestStoreProvider extends ChangeNotifier {
  final PriceApiService _priceApiService;

  BestStoreProvider(this._priceApiService);

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<BestStoreOptionModel> _items = [];
  List<BestStoreOptionModel> get items => _items;

  Future<void> loadBestStores(String canonicalItemId) async {
    if (canonicalItemId.trim().isEmpty) {
      _errorMessage = 'Missing item identifier.';
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawList = await _priceApiService.getBestStore(
        canonicalItemId: canonicalItemId,
      );
      _items = rawList
          .map((json) => BestStoreOptionModel.fromJson(json))
          .toList(growable: false);
    } on ApiException catch (e) {
      _errorMessage = _messageForApiException(e);
    } catch (_) {
      _errorMessage = 'Could not load best store results. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _messageForApiException(ApiException exception) {
    if (exception.error.status == 401 || exception.error.status == 403) {
      return 'Your session expired. Please log in again.';
    }
    return exception.error.message;
  }
}
