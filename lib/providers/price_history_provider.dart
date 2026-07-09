import 'package:flutter/foundation.dart';

import '../models/item_price_model.dart';
import '../services/api_client.dart';
import '../services/price_api_service.dart';

class PriceHistoryProvider extends ChangeNotifier {
  final PriceApiService _priceApiService;

  PriceHistoryProvider(this._priceApiService);

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ItemPriceModel> _items = [];
  List<ItemPriceModel> get items => _items;

  Future<void> loadHistory({String? itemNameFilter}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final rawList = await _priceApiService.getPriceHistory(
        itemName: itemNameFilter,
      );
      _items = rawList
          .map((json) => ItemPriceModel.fromJson(json))
          .toList(growable: false);
    } on ApiException catch (e) {
      _errorMessage = _messageForApiException(e);
    } catch (_) {
      _errorMessage = 'Could not load price history. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _messageForApiException(ApiException exception) {
    if (exception.error.status == 401 || exception.error.status == 403) {
      return 'Your session expired. Please log in again.';
    }
    return exception.error.message;
  }
}
