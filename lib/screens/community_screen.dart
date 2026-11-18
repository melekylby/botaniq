import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/community_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

/// Topluluk: kullanıcıların soruları, deneyimleri ve ipuçları.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  PostTag? _selectedTag; // null = "Tümü"

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Topluluk')),
      floatingActionButton: provider.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => CreatePostScreen.open(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Paylaş'),
            ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildTagChip('Tümü', null),
                for (final tag in PostTag.values) _buildTagChip(tag.label, tag),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, PostTag? tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedTag == tag,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedTag = tag),
      ),
    );
  }

  Widget _buildBody(CommunityProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Bir sorun oluştu',
            message: provider.errorMessage!,
            actionLabel: 'Tekrar Dene',
            onAction: provider.load,
          ),
        ),
      );
    }

    final posts = _selectedTag == null
        ? provider.posts
        : provider.posts.where((p) => p.tag == _selectedTag).toList();

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: EmptyState(
            icon: Icons.forum_outlined,
            title: 'Henüz gönderi yok',
            message: 'Bu kategoride ilk paylaşımı sen yap!',
            actionLabel: 'Paylaş',
            onAction: () => CreatePostScreen.open(context),
          ),
        ),
      );
    }

    // Aşağı çekince yenile.
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => PostCard(post: posts[index]),
      ),
    );
  }
}
