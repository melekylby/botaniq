import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../config/api_config.dart';
import '../models/analysis_result.dart';

/// Kullanıcıya gösterilebilecek, Türkçe mesajlı analiz hatası.
class AnalysisException implements Exception {
  const AnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fotoğrafı analiz proxy'sine gönderir ve sonucu [AnalysisResult]
/// olarak döndürür. Bütün ağ ve sunucu hataları anlaşılır Türkçe
/// mesajlara çevrilir.
class PlantAnalysisService {
  PlantAnalysisService({
    http.Client? client,
    String? baseUrl,
    String? appToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.analysisUrl,
        _appToken = appToken ?? ApiConfig.appToken;

  final http.Client _client;
  final String _baseUrl;
  final String _appToken;

  /// Yapay zekâ bazen 10-20 saniye düşünebilir; zaman aşımını geniş tutuyoruz.
  static const _timeout = Duration(seconds: 60);

  /// api_config.dart içindeki örnek değerler değiştirilmiş mi?
  bool get isConfigured =>
      _baseUrl.startsWith('https://') &&
      !_baseUrl.contains('KULLANICI_ADIN') &&
      _appToken.isNotEmpty &&
      _appToken != 'BURAYA_APP_TOKEN';

  Future<AnalysisResult> analyze(String imagePath) async {
    if (!isConfigured) {
      throw const AnalysisException(
        'Analiz servisi henüz ayarlanmadı. lib/config/api_config.dart '
        'dosyasına proxy adresini ve APP_TOKEN değerini yaz.',
      );
    }

    final bytes = await File(imagePath).readAsBytes();

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'X-App-Token': _appToken,
            },
            body: jsonEncode({
              'image': base64Encode(bytes),
              'mimeType': _mimeTypeFor(imagePath),
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AnalysisException(
        'Analiz çok uzun sürdü. İnternet bağlantını kontrol edip tekrar dene.',
      );
    } on SocketException {
      throw const AnalysisException(
        'İnternet bağlantısı yok gibi görünüyor. Bağlantını kontrol et.',
      );
    } on http.ClientException {
      throw const AnalysisException(
        'Sunucuya ulaşılamadı. Lütfen biraz sonra tekrar dene.',
      );
    }

    if (response.statusCode != 200) {
      throw AnalysisException(_messageForStatus(response.statusCode));
    }

    try {
      // utf8.decode: Türkçe karakterlerin doğru okunması için.
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return AnalysisResult.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      throw const AnalysisException(
        'Sunucudan beklenmeyen bir yanıt geldi. Lütfen tekrar dene.',
      );
    }
  }

  static String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Uygulama kodu kabul edilmedi. api_config.dart içindeki '
            'APP_TOKEN ile Cloudflare\'deki değer aynı olmalı.';
      case 413:
        return 'Fotoğraf çok büyük. Daha küçük bir fotoğraf dene.';
      case 415:
        return 'Bu fotoğraf biçimi desteklenmiyor. JPG veya PNG dene.';
      case 503:
        return 'Yapay zekâ servisi şu an çok yoğun. Birkaç saniye sonra tekrar dene.';
      case 429:
        return 'Kısa sürede çok fazla analiz yapıldı. Bir dakika bekleyip tekrar dene.';
      default:
        return 'Analiz şu anda yapılamıyor. Lütfen daha sonra tekrar dene.';
    }
  }

  static String _mimeTypeFor(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
