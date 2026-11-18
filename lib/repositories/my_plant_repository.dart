import '../models/my_plant.dart';
import '../services/database_service.dart';

/// Kullanıcının bitkileri için veritabanı işlemleri (ekle, oku, güncelle, sil).
/// SQL sorguları yalnızca bu dosyada bulunur; ekranlar SQL bilmez.
class MyPlantRepository {
  MyPlantRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  static const _table = DatabaseService.myPlantsTable;

  /// Tüm bitkiler, en son eklenen en üstte.
  Future<List<MyPlant>> getAll() async {
    final db = await _databaseService.database;
    final rows = await db.query(_table, orderBy: 'added_at DESC');
    return rows.map(MyPlant.fromMap).toList();
  }

  /// Yeni bitkiyi kaydeder ve veritabanının verdiği id ile geri döndürür.
  Future<MyPlant> insert(MyPlant plant) async {
    final db = await _databaseService.database;
    final row = plant.toMap()..remove('id'); // id'yi SQLite kendisi üretir.
    final id = await db.insert(_table, row);
    return plant.copyWith(id: id);
  }

  Future<void> update(MyPlant plant) async {
    final db = await _databaseService.database;
    await db.update(
      _table,
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id], // "?" kullanmak SQL enjeksiyonunu önler.
    );
  }

  Future<void> delete(int id) async {
    final db = await _databaseService.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
