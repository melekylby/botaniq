import 'package:flutter/material.dart';

/// Gönderi türü: kullanıcı bir soru mu soruyor, deneyim mi paylaşıyor,
/// yoksa bir ipucu mu veriyor?
enum PostTag {
  question('Soru', Icons.help_outline),
  experience('Deneyim', Icons.auto_stories_outlined),
  tip('İpucu', Icons.lightbulb_outline);

  const PostTag(this.label, this.icon);

  final String label;
  final IconData icon;

  static PostTag parse(Object? value) => PostTag.values.firstWhere(
        (tag) => tag.name == value,
        orElse: () => PostTag.experience,
      );
}

/// Topluluktaki bir gönderi.
class Post {
  const Post({
    this.id,
    required this.authorName,
    required this.tag,
    required this.content,
    this.photoName,
    required this.createdAt,
    this.isMine = false,
    this.commentCount = 0,
  });

  final int? id;
  final String authorName;
  final PostTag tag;
  final String content;

  /// Fotoğrafın dosya adı (PhotoStorageService klasöründe). Yoksa null.
  final String? photoName;
  final DateTime createdAt;

  /// Gönderi bu cihazdaki kullanıcıya mı ait? (Silme yetkisi için.)
  final bool isMine;

  /// Veritabanında saklanmaz; sorgu sırasında yorumlar sayılarak hesaplanır.
  final int commentCount;

  Map<String, Object?> toMap() => {
        'id': id,
        'author_name': authorName,
        'tag': tag.name,
        'content': content,
        'photo_name': photoName,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_mine': isMine ? 1 : 0, // SQLite'ta bool yok, 0/1 kullanılır.
      };

  factory Post.fromMap(Map<String, Object?> map) => Post(
        id: map['id'] as int?,
        authorName: map['author_name'] as String,
        tag: PostTag.parse(map['tag']),
        content: map['content'] as String,
        photoName: map['photo_name'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        isMine: map['is_mine'] == 1,
        commentCount: (map['comment_count'] as int?) ?? 0,
      );

  Post copyWith({int? id, int? commentCount}) => Post(
        id: id ?? this.id,
        authorName: authorName,
        tag: tag,
        content: content,
        photoName: photoName,
        createdAt: createdAt,
        isMine: isMine,
        commentCount: commentCount ?? this.commentCount,
      );
}
