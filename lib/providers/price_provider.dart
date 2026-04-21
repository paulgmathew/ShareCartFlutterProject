import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/price_api_service.dart';

class NearbyStoreOption {
  final String name;
  final String? distanceLabel;

  const NearbyStoreOption({required this.name, this.distanceLabel});
}

double? extractPrice(String text) {
  final regex = RegExp(r'\$?\d+(\.\d{1,2})?');
  final match = regex.firstMatch(text);
  if (match == null) return null;

  final raw = match.group(0)?.replaceAll(r'$', '');
  if (raw == null) return null;
  return double.tryParse(raw);
}

class PriceProvider extends ChangeNotifier {
  final PriceApiService _priceApiService;
  final ImagePicker _imagePicker;

  PriceProvider(this._priceApiService, {ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  bool _loading = false;
  bool get loading => _loading;

  String _ocrText = '';
  String get ocrText => _ocrText;

  double? _detectedPrice;
  double? get detectedPrice => _detectedPrice;

  String? _selectedStore;
  String? get selectedStore => _selectedStore;

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

  String? _compareMessage;
  String? get compareMessage => _compareMessage;

  List<NearbyStoreOption> _nearbyStores = [];
  List<NearbyStoreOption> get nearbyStores => _nearbyStores;

  Future<void> scanImage() async {
    _setLoading(true);
    _errorMessage = null;
    _compareMessage = null;

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
      await runOCR();
      parsePrice();
      await fetchNearbyStores();
      await _captureRawText();
    } catch (_) {
      _errorMessage = 'Could not capture image. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> runOCR() async {
    final imagePath = _imagePath;
    if (imagePath == null || imagePath.isEmpty) return;

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await recognizer.processImage(inputImage);
      _ocrText = recognizedText.text.trim();
      _itemNameGuess = _guessItemName(_ocrText);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'OCR failed. Please retake the photo.';
      notifyListeners();
    } finally {
      recognizer.close();
    }
  }

  void parsePrice() {
    _detectedPrice = extractPrice(_ocrText);
    notifyListeners();
  }

  Future<void> fetchNearbyStores() async {
    try {
      final position = await _getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      final stores = await _priceApiService.getNearbyStores(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _nearbyStores = stores
          .map(
            (json) => NearbyStoreOption(
              name: (json['name'] ?? json['storeName'] ?? 'Unknown').toString(),
              distanceLabel: _distanceLabelFrom(json),
            ),
          )
          .where((s) => s.name.trim().isNotEmpty)
          .toList(growable: false);

      if (_nearbyStores.isNotEmpty && _selectedStore == null) {
        _selectedStore = _nearbyStores.first.name;
      }
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      notifyListeners();
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Could not fetch nearby stores.';
      notifyListeners();
    }
  }

  Future<void> confirmPrice({
    required String itemName,
    required String priceText,
    required String unit,
    required String storeName,
    bool compareAfterConfirm = true,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _compareMessage = null;

    try {
      final parsedPrice = double.tryParse(priceText.trim());
      if (parsedPrice == null) {
        throw const FormatException('Please enter a valid numeric price.');
      }

      _captureId ??= await _captureRawText();
      final captureId = _captureId;
      if (captureId == null || captureId.isEmpty) {
        throw const FormatException(
          'Could not capture OCR text. Please rescan.',
        );
      }

      await _priceApiService.confirmPrice(
        captureId: captureId,
        itemName: itemName.trim(),
        price: parsedPrice,
        unit: unit.trim(),
        storeName: storeName.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (compareAfterConfirm) {
        final compareResponse = await _priceApiService.comparePrice({
          'itemName': itemName.trim(),
          'price': parsedPrice,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
        });

        final isCheapest = compareResponse['isCheapest'];
        if (isCheapest == true) {
          _compareMessage = 'This is the cheapest price so far.';
        } else {
          final bestPrice = compareResponse['bestPrice'];
          _compareMessage =
              bestPrice != null
                  ? 'Best known price is $bestPrice.'
                  : 'Price comparison completed.';
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
    } on FormatException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not confirm price. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedStore(String? store) {
    _selectedStore = store;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> _captureRawText() async {
    if (_ocrText.trim().isEmpty) return null;
    final response = await _priceApiService.capturePrice(
      rawText: _ocrText,
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

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PermissionDeniedException(
        'Location services are disabled. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission denied. Please allow location access.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  String _guessItemName(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    for (final line in lines) {
      final hasAlphabet = RegExp(r'[A-Za-z]').hasMatch(line);
      final hasPrice = RegExp(r'\$?\d+(\.\d{1,2})?').hasMatch(line);
      if (hasAlphabet && !hasPrice && line.length <= 60) {
        return line;
      }
    }

    return lines.isNotEmpty ? lines.first : '';
  }

  String? _distanceLabelFrom(Map<String, dynamic> json) {
    final distance = json['distance'];
    if (distance is num) {
      return '${distance.toStringAsFixed(1)} km';
    }
    if (distance != null) {
      return distance.toString();
    }
    return null;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

class PermissionDeniedException implements Exception {
  final String message;

  const PermissionDeniedException(this.message);
}
