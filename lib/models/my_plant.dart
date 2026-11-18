import 'package:flutter/material.dart';

/// Kullanıcının kendi koleksiyonuna eklediği bir bitki.
///
/// Kütüphanedeki [Plant] bir "tür"ü anlatır (ör. Deve Tabanı).
/// [MyPlant] ise kullanıcının evindeki belirli bir bitkidir
/// (ör. "Salondaki Monstera") ve kendi sulama bilgilerini taşır.
class MyPlant {
  const MyPlant({
    this.id,
    required this.name,
    required this.species,
    this.speciesId,
    this.photoName,
    required this.addedAt,
    required this.wateringIntervalDays,
    required this.lastWateredAt,
    this.notes = '',
  });

  /// Veritabanı kimliği. Henüz kaydedilmemiş bitkide null'dır.
  final int? id;
  final String name;

  /// Tür adı (ör. "Deve Tabanı" ya da kullanıcının yazdığı bir ad).
  final String species;

  /// Tür kütüphaneden seçildiyse o bitkinin id'si, değilse null.
  final String? speciesId;

  /// Fotoğrafın dosya adı (tam yol değil). Fotoğraf yoksa null.
  final String? photoName;
  final DateTime addedAt;
  final int wateringIntervalDays;
  final DateTime lastWateredAt;
  final String notes;

  /// Bir sonraki sulama tarihi = son sulama + sulama aralığı.
  DateTime get nextWateringDate =>
      lastWateredAt.add(Duration(days: wateringIntervalDays));

  /// Bir sonraki sulamaya kaç gün kaldı?
  /// 0 = bugün, negatif = gecikmiş.
  int daysUntilWatering([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final next = DateUtils.dateOnly(nextWateringDate);
    return (next.difference(today).inHours / 24).round();
  }

  /// Nesneyi veritabanına yazılacak satıra çevirir.
  /// Tarihler, SQLite'ta kolay saklanması için milisaniye olarak tutulur.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'species_id': speciesId,
      'photo_name': photoName,
      'added_at': addedAt.millisecondsSinceEpoch,
      'watering_interval_days': wateringIntervalDays,
      'last_watered_at': lastWateredAt.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  /// Veritabanından okunan satırı nesneye çevirir.
  factory MyPlant.fromMap(Map<String, Object?> map) {
    return MyPlant(
      id: map['id'] as int?,
      name: map['name'] as String,
      species: map['species'] as String,
      speciesId: map['species_id'] as String?,
      photoName: map['photo_name'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      wateringIntervalDays: map['watering_interval_days'] as int,
      lastWateredAt:
          DateTime.fromMillisecondsSinceEpoch(map['last_watered_at'] as int),
      notes: (map['notes'] as String?) ?? '',
    );
  }

  /// Bazı alanları değiştirilmiş yeni bir kopya döndürür.
  /// Nesneler değiştirilemez (immutable) olduğu için güncelleme böyle yapılır.
  MyPlant copyWith({
    int? id,
    String? name,
    String? species,
    String? speciesId,
    String? photoName,
    DateTime? addedAt,
    int? wateringIntervalDays,
    DateTime? lastWateredAt,
    String? notes,
  }) {
    return MyPlant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      speciesId: speciesId ?? this.speciesId,
      photoName: photoName ?? this.photoName,
      addedAt: addedAt ?? this.addedAt,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      notes: notes ?? this.notes,
    );
  }
}
