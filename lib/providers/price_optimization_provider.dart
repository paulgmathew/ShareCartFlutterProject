import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/nearby_store_model.dart';
import '../models/price_comparison_model.dart';
import '../models/user_location_model.dart';
import '../services/api_client.dart';
import '../services/price_api_service.dart';

class PriceOptimizationProvider extends ChangeNotifier {
  final PriceApiService _priceApiService;

  PriceOptimizationProvider(this._priceApiService);

  bool _comparisonLoading = false;
  bool get comparisonLoading => _comparisonLoading;

  bool _nearbyLoading = false;
  bool get nearbyLoading => _nearbyLoading;

  bool _locationSaving = false;
  bool get locationSaving => _locationSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PriceComparisonModel? _comparison;
  PriceComparisonModel? get comparison => _comparison;

  List<NearbyStoreModel> _nearbyStores = [];
  List<NearbyStoreModel> get nearbyStores => _nearbyStores;

  UserLocationModel? _savedLocation;
  UserLocationModel? get savedLocation => _savedLocation;

  Future<void> comparePrices(String itemName) async {
    final query = itemName.trim();
    if (query.isEmpty) {
      _errorMessage = 'Enter an item name to compare prices.';
      notifyListeners();
      return;
    }

    _comparisonLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _priceApiService.comparePrices(query);
      _comparison = result;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } catch (_) {
      _errorMessage = 'Could not compare prices. Please try again.';
    } finally {
      _comparisonLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyStores({double? latitude, double? longitude}) async {
    _nearbyLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final coords = await _resolveCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      final stores = await _priceApiService.getNearbyStores(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
      _nearbyStores = stores;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } catch (_) {
      _errorMessage = 'Could not load nearby stores. Please try again.';
    } finally {
      _nearbyLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    _locationSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = UserLocationModel(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      await _priceApiService.updateMyLocation(location);
      _savedLocation = location;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } catch (_) {
      _errorMessage = 'Could not save your location. Please try again.';
    } finally {
      _locationSaving = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    final position = await _resolveCoordinates();
    await saveLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<({double latitude, double longitude})> _resolveCoordinates({
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null && longitude != null) {
      return (latitude: latitude, longitude: longitude);
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }
}
