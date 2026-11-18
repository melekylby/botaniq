import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/sample_posts.dart';

/// SQLite veritabanını açan ve tabloları oluşturan servis.
///
/// Singleton: uygulama boyunca tek bir veritabanı bağlantısı kullanılır.
/// Veritabanı ilk kez istendiğinde açılır ("lazy").
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'botaniq.db';

  /// Sürüm geçmişi:
  /// 1 → my_plants tablosu
  /// 2 → posts ve comments tabloları (Topluluk)
  static const _databaseVersion = 2;

  static const myPlantsTable = 'my_plants';
  static const postsTable = 'posts';
  static const commentsTable = 'comments';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Uygulama ilk kez kurulduğunda çalışır: tüm tabloları oluşturur.
  Future<void> _onCreate(Database db, int version) async {
    await _createMyPlantsTable(db);
    await _createCommunityTables(db);
    await _insertSamplePosts(db);
  }

  /// Uygulama güncellendiğinde çalışır: eski veritabanını yeni sürüme taşır.
  /// Böylece kullanıcının eklediği bitkiler silinmeden yeni tablolar eklenir.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCommunityTables(db);
      await _insertSamplePosts(db);
    }
  }

  Future<void> _createMyPlantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $myPlantsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        species_id TEXT,
        photo_name TEXT,
        added_at INTEGER NOT NULL,
        watering_interval_days INTEGER NOT NULL,
        last_watered_at INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _createCommunityTables(Database db) async {
    await db.execute('''
      CREATE TABLE $postsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_name TEXT NOT NULL,
        tag TEXT NOT NULL,
        content TEXT NOT NULL,
        photo_name TEXT,
        created_at INTEGER NOT NULL,
        is_mine INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE $commentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER NOT NULL,
        author_name TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_mine INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _insertSamplePosts(Database db) async {
    final now = DateTime.now();
    int hoursAgo(int hours) =>
        now.subtract(Duration(hours: hours)).millisecondsSinceEpoch;

    for (final post in samplePosts) {
      final postId = await db.insert(postsTable, {
        'author_name': post.author,
        'tag': post.tag.name,
        'content': post.content,
        'created_at': hoursAgo(post.hoursAgo),
        'is_mine': 0,
      });
      for (final comment in post.comments) {
        await db.insert(commentsTable, {
          'post_id': postId,
          'author_name': comment.author,
          'content': comment.content,
          'created_at': hoursAgo(comment.hoursAgo),
          'is_mine': 0,
        });
      }
    }
  }
}
