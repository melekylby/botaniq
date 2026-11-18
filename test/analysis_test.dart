import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botaniq/models/analysis_result.dart';
import 'package:botaniq/repositories/plant_repository.dart';
import 'package:botaniq/services/plant_analysis_service.dart';

/// Proxy'nin döndürdüğü örnek cevap.
const sampleJson = {
  'isPlant': true,
  'commonName': 'Deve Tabanı',
  'scientificName': 'Monstera deliciosa',
  'confidence': 0.92,
  'description': 'Büyük, yarıklı yapraklı tropikal bir bitki.',
  'care': {
    'light': 'Parlak dolaylı ışık',
    'water': 'Üst toprak kuruyunca',
    'temperature': '18–30 °C',
    'humidity': 'Orta-yüksek',
  },
  'careTips': ['Destek çubuğu kullanın.'],
  'health': {
    'status': 'attention',
    'summary': 'Bazı yapraklarda sararma var.',
    'issues': [
      {
        'name': 'Aşırı sulama',
        'likelihood': 0.7,
        'description': 'Alt yapraklardaki sararma fazla suya işaret edebilir.',
        'careSteps': ['Sulamayı azaltın.', 'Drenajı kontrol edin.'],
      },
    ],
    'warnings': ['Evcil hayvanlar için zehirli olabilir.'],
  },
};

void main() {
  group('AnalysisResult.fromJson', () {
    test('Tam bir cevabı doğru okur', () {
      final result = AnalysisResult.fromJson(sampleJson);
      expect(result.isPlant, isTrue);
      expect(result.commonName, 'Deve Tabanı');
      expect(result.healthStatus, HealthStatus.attention);
      expect(result.issues.single.careSteps, hasLength(2));
      expect(result.isLowConfidence, isFalse);
    });

    test('Eksik ve hatalı alanlarda çökmez', () {
      final result = AnalysisResult.fromJson({
        'isPlant': true,
        'confidence': 7, // 0-1 dışı → 1'e sabitlenir
        'health': {'status': 'bilinmeyen'},
      });
      expect(result.commonName, '');
      expect(result.confidence, 1.0);
      expect(result.healthStatus, HealthStatus.attention);
      expect(result.issues, isEmpty);
    });
  });

  group('Kütüphane eşleştirme', () {
    const repository = PlantRepository();

    test('Cins + tür eşleşir', () {
      expect(repository.findByScientificName('Monstera deliciosa')?.id, 'deve_tabani');
    });

    test('"spp." olan cinste yalnızca cins yeterli', () {
      expect(repository.findByScientificName('Phalaenopsis amabilis')?.id, 'orkide');
    });

    test('Melez işaretli ad eşleşir', () {
      expect(repository.findByScientificName('Pelargonium x hortorum')?.id, 'sardunya');
      expect(repository.findByScientificName('Pelargonium × hortorum')?.id, 'sardunya');
    });

    test('Bilinmeyen tür null döner', () {
      expect(repository.findByScientificName('Ficus lyrata'), isNull);
    });
  });

  group('PlantAnalysisService', () {
    late File photo;

    setUp(() async {
      photo = File('${Directory.systemTemp.path}/botaniq_test.jpg');
      await photo.writeAsBytes([1, 2, 3]);
    });

    PlantAnalysisService serviceWith(http.Client client) => PlantAnalysisService(
          client: client,
          baseUrl: 'https://test.example.com',
          appToken: 'test-token',
        );

    test('Başarılı cevabı sonuca çevirir ve doğru başlıkları gönderir', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://test.example.com/analyze');
        expect(request.headers['X-App-Token'], 'test-token');
        return http.Response.bytes(
          utf8.encode(jsonEncode(sampleJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await serviceWith(client).analyze(photo.path);
      expect(result.scientificName, 'Monstera deliciosa');
    });

    test('429 hatasını anlaşılır mesaja çevirir', () async {
      final client = MockClient((_) async => http.Response('{}', 429));
      expect(
        () => serviceWith(client).analyze(photo.path),
        throwsA(isA<AnalysisException>().having(
          (e) => e.message,
          'message',
          contains('Bir dakika bekleyip'),
        )),
      );
    });

    test('Ayarlanmamış servis istek göndermeden hata verir', () async {
      final service = PlantAnalysisService(
        baseUrl: 'https://botaniq-proxy.KULLANICI_ADIN.workers.dev',
        appToken: 'BURAYA_APP_TOKEN',
      );
      expect(service.isConfigured, isFalse);
      expect(() => service.analyze(photo.path), throwsA(isA<AnalysisException>()));
    });
  });
}
