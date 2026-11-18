import '../models/comment.dart';
import '../models/post.dart';
import '../services/database_service.dart';

/// Topluluk gönderileri ve yorumları için veritabanı işlemleri.
///
/// İleride gerçek kullanıcılar arası paylaşım için Firebase'e geçilirse
/// yalnızca bu sınıfın içi değişir; provider ve ekranlar aynı kalır.
class CommunityRepository {
  CommunityRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  static const _posts = DatabaseService.postsTable;
  static const _comments = DatabaseService.commentsTable;

  /// Tüm gönderiler (en yeni en üstte) ve her birinin yorum sayısı.
  Future<List<Post>> getPosts() async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery('''
      SELECT p.*,
             (SELECT COUNT(*) FROM $_comments c WHERE c.post_id = p.id) AS comment_count
      FROM $_posts p
      ORDER BY p.created_at DESC
    ''');
    return rows.map(Post.fromMap).toList();
  }

  Future<Post> insertPost(Post post) async {
    final db = await _databaseService.database;
    final id = await db.insert(_posts, post.toMap()..remove('id'));
    return post.copyWith(id: id);
  }

  /// Gönderiyi ve ona ait tüm yorumları birlikte siler.
  /// transaction: ikisinden biri başarısız olursa hiçbiri silinmez.
  Future<void> deletePost(int postId) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete(_comments, where: 'post_id = ?', whereArgs: [postId]);
      await txn.delete(_posts, where: 'id = ?', whereArgs: [postId]);
    });
  }

  /// Bir gönderinin yorumları (eskiden yeniye).
  Future<List<Comment>> getComments(int postId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      _comments,
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Comment.fromMap).toList();
  }

  Future<Comment> insertComment(Comment comment) async {
    final db = await _databaseService.database;
    final id = await db.insert(_comments, comment.toMap()..remove('id'));
    return comment.copyWith(id: id);
  }
}
