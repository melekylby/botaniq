/// Bir gönderiye yazılmış yorum.
class Comment {
  const Comment({
    this.id,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isMine = false,
  });

  final int? id;
  final int postId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  Map<String, Object?> toMap() => {
        'id': id,
        'post_id': postId,
        'author_name': authorName,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_mine': isMine ? 1 : 0,
      };

  factory Comment.fromMap(Map<String, Object?> map) => Comment(
        id: map['id'] as int?,
        postId: map['post_id'] as int,
        authorName: map['author_name'] as String,
        content: map['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        isMine: map['is_mine'] == 1,
      );

  Comment copyWith({int? id}) => Comment(
        id: id ?? this.id,
        postId: postId,
        authorName: authorName,
        content: content,
        createdAt: createdAt,
        isMine: isMine,
      );
}
