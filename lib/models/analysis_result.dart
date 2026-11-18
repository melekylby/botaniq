/// Bitki sağlığı genel durumu.
enum HealthStatus {
  healthy('Sağlıklı görünüyor'),
  attention('Dikkat gerektiriyor'),
  unhealthy('Sorun olabilir');

  const HealthStatus(this.label);

  final String label;

  static HealthStatus parse(Object? value) {
    return HealthStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => HealthStatus.attention,
    );
  }
}

/// Yapay zekânın tespit ettiği olası bir sağlık sorunu.
class HealthIssue {
  const HealthIssue({
    required this.name,
    required this.likelihood,
    required this.description,
    required this.careSteps,
  });

  final String name;

  /// 0 ile 1 arası olasılık.
  final double likelihood;
  final String description;
  final List<String> careSteps;

  factory HealthIssue.fromJson(Map<String, dynamic> json) {
    return HealthIssue(
      name: _string(json['name']),
      likelihood: _probability(json['likelihood']),
      description: _string(json['description']),
      careSteps: _stringList(json['careSteps']),
    );
  }
}

/// Analiz proxy'sinden dönen sonucun tamamı.
///
/// Yapay zekâ cevabı her zaman beklediğimiz gibi olmayabilir. fromJson
/// eksik ya da hatalı alanlarda çökmek yerine güvenli varsayılanlar kullanır.
class AnalysisResult {
  const AnalysisResult({
    required this.isPlant,
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    required this.description,
    required this.light,
    required this.water,
    required this.temperature,
    required this.humidity,
    required this.careTips,
    required this.healthStatus,
    required this.healthSummary,
    required this.issues,
    required this.warnings,
  });

  final bool isPlant;
  final String commonName;
  final String scientificName;

  /// 0 ile 1 arası tanıma güveni.
  final double confidence;
  final String description;
  final String light;
  final String water;
  final String temperature;
  final String humidity;
  final List<String> careTips;
  final HealthStatus healthStatus;
  final String healthSummary;
  final List<HealthIssue> issues;
  final List<String> warnings;

  /// Tanıma güveni düşükse arayüzde ek uyarı gösterilir.
  bool get isLowConfidence => confidence < 0.5;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final care = _map(json['care']);
    final health = _map(json['health']);
    final issues = health['issues'];

    return AnalysisResult(
      isPlant: json['isPlant'] == true,
      commonName: _string(json['commonName']),
      scientificName: _string(json['scientificName']),
      confidence: _probability(json['confidence']),
      description: _string(json['description']),
      light: _string(care['light']),
      water: _string(care['water']),
      temperature: _string(care['temperature']),
      humidity: _string(care['humidity']),
      careTips: _stringList(json['careTips']),
      healthStatus: HealthStatus.parse(health['status']),
      healthSummary: _string(health['summary']),
      issues: issues is List
          ? issues
              .whereType<Map<String, dynamic>>()
              .map(HealthIssue.fromJson)
              .toList()
          : const [],
      warnings: _stringList(health['warnings']),
    );
  }
}

// --- Güvenli okuma yardımcıları -------------------------------------------

String _string(Object? value) => value is String ? value.trim() : '';

double _probability(Object? value) =>
    value is num ? value.toDouble().clamp(0.0, 1.0) : 0.0;

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
    : const [];

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
