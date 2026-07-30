import 'dart:io' show Platform;

import '../models/receipt_extraction_model.dart';
import 'api_client.dart';

class ReceiptExtractionApiService {
  final ApiClient _apiClient;

  ReceiptExtractionApiService(this._apiClient);

  Future<ReceiptExtractionResultModel> extractReceipt({
    required String imagePath,
    required ReceiptScanType scanType,
    double? latitude,
    double? longitude,
  }) async {
    final fields = <String, String>{'scanType': scanType.apiValue};
    if (latitude != null) fields['latitude'] = latitude.toString();
    if (longitude != null) fields['longitude'] = longitude.toString();

    final json = await _apiClient.postMultipart(
      '/receipt/extract',
      fields: fields,
      fileField: 'image',
      filePath: imagePath,
      fileName: imagePath.split(Platform.pathSeparator).last,
    );

    return ReceiptExtractionResultModel.fromJson(json);
  }
}
