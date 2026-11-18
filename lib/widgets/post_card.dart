import 'package:flutter/material.dart';

import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'my_plant_photo.dart';
import 'user_avatar.dart';

/// Topluluk gönderisi kartı.
/// [isExpanded] true ise (detay sayfası) metin kısaltılmaz ve kart tıklanmaz.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.isExpanded = false});

  final Post post;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fadedColor = AppColors.darkGreen.withValues(alpha: 0.6);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isExpanded ? null : () => PostDetailScreen.open(context, post.id!),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: avatar, ad, zaman ve etiket
              Row(
                children: [
                  UserAvatar(name: post.authorName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.isMine ? '${post.authorName} (sen)' : post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeAgo(post.createdAt),
                          style: textTheme.bodySmall?.copyWith(color: fadedColor),
                        ),
                      ],
                    ),
                  ),
                  _TagChip(tag: post.tag),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                maxLines: isExpanded ? null : 4,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (post.photoName != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: isExpanded ? 260 : 180,
                    width: double.infinity,
                    child: MyPlantPhoto(photoName: post.photoName),
                  ),
                ),
              ],
              if (!isExpanded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: fadedColor),
                    const SizedBox(width: 6),
                    Text(
                      post.commentCount == 0
                          ? 'Yorum yaz'
                          : '${post.commentCount} yorum',
                      style: textTheme.bodySmall?.copyWith(
                        color: fadedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final PostTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 14, color: AppColors.darkGreen),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
