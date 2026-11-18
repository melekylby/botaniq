import 'package:flutter/material.dart';

import '../models/my_plant.dart';

/// Sulama planı hesaplamaları.
///
/// Bu sınıf hiçbir ekrana veya veritabanına bağlı değildir; sadece
/// bitki listesi ve tarih alıp sonuç döndürür. Bu yüzden test etmesi
/// çok kolaydır (test/watering_schedule_test.dart).
class WateringSchedule {
  WateringSchedule._();

  /// Bitki verilen günde sulanmalı mı?
  ///
  /// Kural: Bir sonraki sulama tarihinden itibaren her "aralık" günde bir.
  /// Gecikmiş bitkiler bugüne sayılır (bugün sulanırsa plan bugünden
  /// devam eder). Geçmiş günler için kayıt tutmadığımızdan false döner.
  static bool isDueOn(MyPlant plant, DateTime day, {DateTime? today}) {
    final todayDate = DateUtils.dateOnly(today ?? DateTime.now());
    final dayDate = DateUtils.dateOnly(day);
    if (dayDate.isBefore(todayDate)) return false;

    var firstDue = DateUtils.dateOnly(plant.nextWateringDate);
    if (firstDue.isBefore(todayDate)) firstDue = todayDate;

    final difference = _daysBetween(firstDue, dayDate);
    return difference >= 0 && difference % plant.wateringIntervalDays == 0;
  }

  /// Verilen günde sulanması gereken bitkiler.
  static List<MyPlant> plantsDueOn(
    List<MyPlant> plants,
    DateTime day, {
    DateTime? today,
  }) {
    return plants.where((p) => isDueOn(p, day, today: today)).toList();
  }

  /// Önümüzdeki [withinDays] gün içinde (gecikmişler dahil) sulanacak
  /// bitkiler; en acil olan en üstte.
  static List<MyPlant> upcoming(
    List<MyPlant> plants, {
    int withinDays = 3,
    DateTime? today,
  }) {
    return plants
        .where((p) => p.daysUntilWatering(today) <= withinDays)
        .toList()
      ..sort((a, b) =>
          a.daysUntilWatering(today).compareTo(b.daysUntilWatering(today)));
  }

  /// Bugün (ya da gecikmiş olarak) su bekleyen bitki sayısı.
  static int dueTodayCount(List<MyPlant> plants, {DateTime? today}) {
    return plants.where((p) => p.daysUntilWatering(today) <= 0).length;
  }

  static int _daysBetween(DateTime from, DateTime to) =>
      (to.difference(from).inHours / 24).round();
}
