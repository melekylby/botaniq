import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../repositories/community_repository.dart';
import '../services/photo_storage_service.dart';

/// Topluluk gönderilerini ve kullanıcının topluluktaki adını yönetir.
class CommunityProvider extends ChangeNotifier {
  CommunityProvider({
    CommunityRepository? repository,
    PhotoStorageService? photoStorage,
  })  : _repository = repository ?? CommunityRepository(),
        _photoStorage = photoStorage ?? PhotoStorageService.instance;

  final CommunityRepository _repository;
  final PhotoStorageService _photoStorage;

  static const _userNameKey = 'community_user_name';
  static const defaultUserName = 'Bitki Sever';

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';

  List<Post> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Kullanıcının kaydettiği ad (boş olabilir).
  String get userName => _userName;

  /// Gönderi ve yorumlarda görünecek ad.
  String get displayName => _userName.isEmpty ? defaultUserName : _userName;

  Post? findById(int id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  Future<void> load() async {
    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _posts = await _repository.getPosts();
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_userNameKey) ?? '';
    } catch (error) {
      debugPrint('Gönderiler yüklenemedi: $error');
      _errorMessage = 'Gönderiler yüklenemedi. Lütfen tekrar dene.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcının adını kaydeder; sonraki gönderi ve yorumlarda kullanılır.
  Future<void> setUserName(String name) async {
    _userName = name.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, _userName);
  }

  Future<void> addPost({
    required PostTag tag,
    required String content,
    String? photoName,
  }) async {
    final post = Post(
      authorName: displayName,
      tag: tag,
      content: content,
      photoName: photoName,
      createdAt: DateTime.now(),
      isMine: true,
    );
    final saved = await _repository.insertPost(post);
    _posts = [saved, ..._posts];
    notifyListeners();
  }

  /// Gönderiyi, yorumlarını ve varsa fotoğrafını siler.
  Future<void> deletePost(Post post) async {
    await _repository.deletePost(post.id!);
    if (post.photoName != null) {
      await _photoStorage.deletePhoto(post.photoName!);
    }
    _posts = _posts.where((p) => p.id != post.id).toList();
    notifyListeners();
  }

  Future<List<Comment>> commentsFor(int postId) =>
      _repository.getComments(postId);

  /// Yorumu kaydeder ve gönderinin yorum sayısını bir artırır.
  Future<Comment> addComment(int postId, String content) async {
    final comment = Comment(
      postId: postId,
      authorName: displayName,
      content: content,
      createdAt: DateTime.now(),
      isMine: true,
    );
    final saved = await _repository.insertComment(comment);
    _posts = [
      for (final p in _posts)
        p.id == postId ? p.copyWith(commentCount: p.commentCount + 1) : p,
    ];
    notifyListeners();
    return saved;
  }
}
