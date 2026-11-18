import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/my_plant.dart';

/// Sulama hatırlatmalarını (yerel bildirimler) yöneten servis.
///
/// Kural: Her bitki için, bir sonraki sulama gününün saat 09:00'ına
/// tek bir bildirim kurulur. Bildirim kimliği = bitkinin veritabanı id'si.
/// Bitki sulanınca, düzenlenince ya da silinince bildirim yenilenir/iptal edilir.
///
/// Bildirimler hiçbir zaman uygulamayı bozmamalı: tüm hatalar burada
/// yakalanır ve sadece konsola yazılır.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Hatırlatma saati (24 saat biçiminde).
  static const reminderHour = 9;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// init() çalışmadıysa (ör. testlerde) servis sessizce hiçbir şey yapmaz.
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'watering_reminders', // Kanal kimliği
      'Sulama hatırlatmaları', // Ayarlarda görünen kanal adı
      channelDescription: 'Bitkilerinin sulama günü geldiğinde hatırlatır.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Uygulama açılırken bir kez çağrılır (main.dart).
  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (error) {
      debugPrint('Bildirimler başlatılamadı: $error');
    }
  }

  /// Android 13 ve sonrasında kullanıcıdan bildirim izni ister.
  /// İzin verildiyse (ya da eski Android'de izin gerekmiyorsa) true döner.
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (error) {
      debugPrint('Bildirim izni istenemedi: $error');
      return false;
    }
  }

  /// Bitki için hatırlatmanın kurulacağı an.
  /// Sulama günü 09:00 geçmişse (bugün geç kalındıysa ya da gecikmişse)
  /// null döner; o bitki zaten Ana Sayfa'da "gecikti" olarak görünür.
  static DateTime? reminderTimeFor(MyPlant plant, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final day = plant.nextWateringDate;
    final reminder = DateTime(day.year, day.month, day.day, reminderHour);
    return reminder.isAfter(current) ? reminder : null;
  }

  /// Bitkinin eski hatırlatmasını iptal edip yenisini kurar.
  Future<void> scheduleFor(MyPlant plant) async {
    if (!_initialized || plant.id == null) return;
    try {
      await _plugin.cancel(id: plant.id!);

      final reminderTime = reminderTimeFor(plant);
      if (reminderTime == null) return;

      await _plugin.zonedSchedule(
        id: plant.id!,
        title: '${plant.name} su bekliyor 💧',
        body: 'Bugün ${plant.name} bitkinin sulama günü.',
        // Yerel saati UTC'ye çevirerek veriyoruz; böylece cihazın saat
        // dilimini ayrıca bulmamız gerekmiyor, an yine doğru olur.
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.UTC),
        notificationDetails: _details,
        // "Inexact": Android pili korumak için birkaç dakika kaydırabilir.
        // Sulama için dakika hassasiyeti gerekmez ve ek izin istemez.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Hatırlatma kurulamadı: $error');
    }
  }

  Future<void> cancelFor(int plantId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: plantId);
    } catch (error) {
      debugPrint('Hatırlatma iptal edilemedi: $error');
    }
  }

  /// Tüm hatırlatmaları sıfırdan kurar. Uygulama her açıldığında
  /// çağrılır; böylece bildirimler veritabanıyla hep uyumlu kalır.
  Future<void> rescheduleAll(List<MyPlant> plants) async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
      for (final plant in plants) {
        await scheduleFor(plant);
      }
    } catch (error) {
      debugPrint('Hatırlatmalar yenilenemedi: $error');
    }
  }

  /// Sunumda bildirimlerin çalıştığını göstermek için anında bildirim.
  Future<void> showTestNotification() async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: 0, // Bitki id'leri 1'den başladığı için 0 boştur.
        title: 'BotanIQ hatırlatmaları açık 🌿',
        body: 'Bitkilerinin sulama günü geldiğinde saat '
            '${reminderHour.toString().padLeft(2, '0')}:00\'da haber vereceğiz.',
        notificationDetails: _details,
      );
    } catch (error) {
      debugPrint('Test bildirimi gösterilemedi: $error');
    }
  }
}
