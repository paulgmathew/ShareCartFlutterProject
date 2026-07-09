import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/confirm_prices_request_model.dart';
import '../models/receipt_extraction_model.dart';
import '../services/api_client.dart';
import '../services/price_api_service.dart';
import '../services/receipt_extraction_api_service.dart';

class PriceProvider extends ChangeNotifier {
  final ReceiptExtractionApiService _receiptExtractionApiService;
  final PriceApiService _priceApiService;
  final ImagePicker _imagePicker;

  PriceProvider(
    this._receiptExtractionApiService,
    this._priceApiService, {
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  bool _loading = false;
  bool get loading => _loading;

  String _extractedText = '';
  String get extractedText => _extractedText;

  List<ReceiptExtractionItemModel> _extractedItems = [];
  List<ReceiptExtractionItemModel> get extractedItems => _extractedItems;

  double? _detectedPrice;
  double? get detectedPrice => _detectedPrice;

  String? _storeName;
  String? get storeName => _storeName;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  String? _imagePath;
  String? get imagePath => _imagePath;

  String? _captureId;

  String _itemNameGuess = '';
  String get itemNameGuess => _itemNameGuess;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ReceiptScanType _scanType = ReceiptScanType.receipt;
  ReceiptScanType get scanType => _scanType;

  Future<void> scanImage({
    ReceiptScanType scanType = ReceiptScanType.receipt,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _scanType = scanType;
    _captureId = null;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked == null) {
        _setLoading(false);
        return;
      }

      _imagePath = picked.path;
      await _tryCaptureCurrentPosition();
      final extraction = await _receiptExtractionApiService.extractReceipt(
        imagePath: picked.path,
        scanType: scanType,
        latitude: _latitude,
        longitude: _longitude,
      );

      _applyExtraction(extraction);
      if (!extraction.success) {
        return;
      }
      await _captureExtractionSummary();
    } on ApiException catch (e) {
      _errorMessage = _messageForApiException(e);
    } on FormatException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not capture image. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void _applyExtraction(ReceiptExtractionResultModel extraction) {
    _extractedText = extraction.displayText;
    _extractedItems = extraction.items;
    _scanType = extraction.scanType;
    _storeName = extraction.storeName?.trim();

    if (!extraction.success) {
      _errorMessage =
          extraction.message ?? 'Unable to confidently extract grocery items.';
    }

    final primaryItem = extraction.primaryItem;
    if (primaryItem != null) {
      _itemNameGuess = primaryItem.name.trim();
      _detectedPrice = primaryItem.price;
    } else {
      _itemNameGuess = '';
      double? extractedPrice;
      for (final item in extraction.items) {
        if (item.price != null) {
          extractedPrice = item.price;
          break;
        }
      }
      _detectedPrice = extractedPrice;
    }

    notifyListeners();
  }

  Future<void> confirmPrices({
    required String storeName,
    required List<ConfirmPriceItem> items,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _storeName = storeName.trim();

    try {
      if (_latitude == null || _longitude == null) {
        _errorMessage =
            'Location is required to confirm prices. Please enable location services and try again.';
        return;
      }

      if (items.isEmpty) {
        throw const FormatException('Add at least one valid item to confirm.');
      }

      _captureId ??= await _captureExtractionSummary();
      final captureId = _captureId;
      if (captureId == null || captureId.isEmpty) {
        throw const FormatException(
          'Could not capture AI extraction. Please rescan.',
        );
      }

      final request = ConfirmPricesRequest(
        captureId: captureId,
        scanType: _scanType,
        store: StoreInfo(
          name: _storeName!,
          latitude: _latitude,
          longitude: _longitude,
        ),
        items: items,
        source: items.any((item) => item.edited) ? 'MANUAL' : 'OCR',
        capturedAt: DateTime.now(),
      );

      await _priceApiService.confirmPrices(request);
    } on ApiException catch (e) {
      _errorMessage = _messageForApiException(e);
    } on FormatException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not confirm price. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> _captureRawText() async {
    if (_extractedText.trim().isEmpty) return null;
    final response = await _priceApiService.capturePrice(
      rawText: _extractedText,
      imageUrl: _imagePath,
      latitude: _latitude,
      longitude: _longitude,
    );

    _captureId = (response['captureId'] ?? response['id'] ?? '').toString();
    if (_captureId!.isEmpty) {
      _captureId = null;
    }
    notifyListeners();
    return _captureId;
  }

  Future<String?> _captureExtractionSummary() => _captureRawText();

  Future<void> _tryCaptureCurrentPosition() async {
    try {
      final position = await _getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (_) {
      _latitude = null;
      _longitude = null;
    }
  }

  Future<Position> _getCurrentPosition() async {
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

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _messageForApiException(ApiException exception) {
    if (exception.error.status == 401 || exception.error.status == 403) {
      return 'Your session expired. Please log in again.';
    }

    if (exception.error.status == 400 &&
        exception.error.message.trim().toLowerCase() == 'validation failed') {
      final details = exception.error.details;
      if (details != null && details.isNotEmpty) {
        final entries = details.entries
            .where((entry) => entry.value != null)
            .map((entry) => '${entry.key}: ${entry.value}')
            .toList(growable: false);
        if (entries.isNotEmpty) {
          return entries.join('\n');
        }
      }
    }

    return exception.error.message;
  }
}
