import 'package:flutter/foundation.dart';

import '../models/best_price_summary_model.dart';
import '../services/api_client.dart';
import '../services/price_api_service.dart';

class BestPriceSummaryProvider extends ChangeNotifier {
  final PriceApiService _priceApiService;

  BestPriceSummaryProvider(this._priceApiService);

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<BestPriceSummaryModel> _items = [];
  List<BestPriceSummaryModel> get items => _items;

  Future<void> loadSummary() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawList = await _priceApiService.getBestPrices();
      _items = rawList
          .map((json) => BestPriceSummaryModel.fromJson(json))
          .toList(growable: false);
    } on ApiException catch (e) {
      _errorMessage = _messageForApiException(e);
    } catch (_) {
      _errorMessage = 'Could not load best prices. Please try again.';
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
