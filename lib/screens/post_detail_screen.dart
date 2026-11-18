import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/post_card.dart';
import '../widgets/section_header.dart';
import '../widgets/user_avatar.dart';

/// Gönderi detayı: gönderinin tamamı, yorumlar ve yorum yazma alanı.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  static Future<void> open(BuildContext context, int postId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
  }

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();

  List<Comment>? _comments; // null = yükleniyor
  bool _loadFailed = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments =
          await context.read<CommunityProvider>().commentsFor(widget.postId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (error) {
      debugPrint('Yorumlar yüklenemedi: $error');
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final provider = context.read<CommunityProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final comment = await provider.addComment(widget.postId, text);
      if (!mounted) return;
      setState(() {
        _comments = [...?_comments, comment];
        _commentController.clear();
      });
      FocusScope.of(context).unfocus(); // Klavyeyi kapat
    } catch (error) {
      debugPrint('Yorum gönderilemedi: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Yorum gönderilemedi. Lütfen tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gönderiyi sil'),
        content: const Text(
          'Gönderin ve altındaki tüm yorumlar silinsin mi? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB85C57)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<CommunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      await provider.deletePost(post);
      messenger.showSnackBar(const SnackBar(content: Text('Gönderin silindi')));
    } catch (error) {
      debugPrint('Gönderi silinemedi: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Gönderi silinemedi. Lütfen tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = context.watch<CommunityProvider>().findById(widget.postId);
    if (post == null) return const Scaffold(); // Silinmiş olabilir

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderi'),
        actions: [
          if (post.isMine)
            IconButton(
              tooltip: 'Gönderiyi sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(post),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                PostCard(post: post, isExpanded: true),
                const SizedBox(height: 24),
                SectionHeader(title: 'Yorumlar (${post.commentCount})'),
                const SizedBox(height: 12),
                ..._buildComments(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  List<Widget> _buildComments() {
    if (_loadFailed) {
      return [
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() => _loadFailed = false);
              _loadComments();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Yorumlar yüklenemedi, tekrar dene'),
          ),
        ),
      ];
    }
    final comments = _comments;
    if (comments == null) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (comments.isEmpty) {
      return [
        Text(
          'Henüz yorum yok. İlk yorumu sen yaz!',
          style: TextStyle(color: AppColors.darkGreen.withValues(alpha: 0.6)),
        ),
      ];
    }
    return [
      for (final comment in comments)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _CommentTile(comment: comment),
        ),
    ];
  }

  Widget _buildInputBar() {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Yorum yaz...',
                    counterText: '', // Sayaç alanı kaplamasın
                    fillColor: AppColors.cream,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Gönder',
                onPressed: _isSending ? null : _sendComment,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(name: comment.authorName, radius: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: comment.isMine ? AppColors.mint : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.isMine
                            ? '${comment.authorName} (sen)'
                            : comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      timeAgo(comment.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGreen.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
