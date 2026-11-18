import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:botaniq/models/post.dart';
import 'package:botaniq/providers/community_provider.dart';
import 'package:botaniq/utils/formatters.dart';

import 'fakes/fake_community_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CommunityProvider> createProvider() async {
    final provider = CommunityProvider(
      repository: FakeCommunityRepository(initialPosts: [
        Post(
          authorName: 'Ayşe K.',
          tag: PostTag.question,
          content: 'Örnek soru',
          createdAt: DateTime(2026, 11, 1),
        ),
      ]),
    );
    await provider.load();
    return provider;
  }

  group('CommunityProvider', () {
    test('Yeni gönderi en üste eklenir ve kullanıcıya ait işaretlenir', () async {
      final provider = await createProvider();
      await provider.setUserName('Melek');
      await provider.addPost(tag: PostTag.tip, content: 'Yeni bir ipucu');

      final first = provider.posts.first;
      expect(provider.posts, hasLength(2));
      expect(first.content, 'Yeni bir ipucu');
      expect(first.authorName, 'Melek');
      expect(first.isMine, isTrue);
    });

    test('Ad girilmezse varsayılan ad kullanılır', () async {
      final provider = await createProvider();
      await provider.addPost(tag: PostTag.question, content: 'Adsız soru');
      expect(provider.posts.first.authorName, CommunityProvider.defaultUserName);
    });

    test('Yorum eklenince yorum sayısı artar', () async {
      final provider = await createProvider();
      final postId = provider.posts.first.id!;

      await provider.addComment(postId, 'Harika bir soru!');
      expect(provider.findById(postId)!.commentCount, 1);
      expect(await provider.commentsFor(postId), hasLength(1));
    });

    test('Gönderi silinince listeden çıkar', () async {
      final provider = await createProvider();
      await provider.addPost(tag: PostTag.experience, content: 'Silinecek deneyim');
      await provider.deletePost(provider.posts.first);
      expect(provider.posts.map((p) => p.content), ['Örnek soru']);
    });
  });

  test('timeAgo okunabilir zaman üretir', () {
    final now = DateTime(2026, 11, 18, 12);
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'az önce');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 dk önce');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 sa önce');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2 gün önce');
    expect(timeAgo(DateTime(2026, 10, 1), now: now), '01.10.2026');
  });
}
