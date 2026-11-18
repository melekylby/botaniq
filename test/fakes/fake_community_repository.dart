import 'package:botaniq/models/comment.dart';
import 'package:botaniq/models/post.dart';
import 'package:botaniq/repositories/community_repository.dart';

/// Testlerde gerçek SQLite yerine kullanılan, bellekte çalışan sahte depo.
class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({List<Post> initialPosts = const []}) {
    for (final post in initialPosts) {
      _posts.add(post.copyWith(id: _nextPostId++));
    }
  }

  final List<Post> _posts = [];
  final List<Comment> _comments = [];
  int _nextPostId = 1;
  int _nextCommentId = 1;

  @override
  Future<List<Post>> getPosts() async {
    final posts = [
      for (final p in _posts)
        p.copyWith(commentCount: _comments.where((c) => c.postId == p.id).length),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  @override
  Future<Post> insertPost(Post post) async {
    final saved = post.copyWith(id: _nextPostId++);
    _posts.add(saved);
    return saved;
  }

  @override
  Future<void> deletePost(int postId) async {
    _comments.removeWhere((c) => c.postId == postId);
    _posts.removeWhere((p) => p.id == postId);
  }

  @override
  Future<List<Comment>> getComments(int postId) async =>
      _comments.where((c) => c.postId == postId).toList();

  @override
  Future<Comment> insertComment(Comment comment) async {
    final saved = comment.copyWith(id: _nextCommentId++);
    _comments.add(saved);
    return saved;
  }
}
