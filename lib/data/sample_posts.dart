import '../models/post.dart';

/// Topluluk ilk açıldığında boş görünmesin diye eklenen örnek gönderiler.
/// Veritabanı ilk oluşturulduğunda bir kez kaydedilir.
/// Zamanlar "kaç saat önce" olarak verilir; kayıt anına göre hesaplanır.
class SamplePost {
  const SamplePost({
    required this.author,
    required this.tag,
    required this.content,
    required this.hoursAgo,
    this.comments = const [],
  });

  final String author;
  final PostTag tag;
  final String content;
  final int hoursAgo;
  final List<SampleComment> comments;
}

class SampleComment {
  const SampleComment({
    required this.author,
    required this.content,
    required this.hoursAgo,
  });

  final String author;
  final String content;
  final int hoursAgo;
}

const List<SamplePost> samplePosts = [
  SamplePost(
    author: 'Ayşe K.',
    tag: PostTag.question,
    hoursAgo: 3,
    content:
        'Deve tabanımın alt yaprakları sararmaya başladı. Haftada iki kez suluyorum, '
        'salonda pencereden 2 metre uzakta duruyor. Sebebi ne olabilir?',
    comments: [
      SampleComment(
        author: 'Mert D.',
        hoursAgo: 2,
        content:
            'Haftada iki kez fazla olabilir. Toprağın üst 3-4 cm’si kurumadan sulama, '
            'saksı altında su birikip birikmediğine de bak.',
      ),
      SampleComment(
        author: 'Zeynep A.',
        hoursAgo: 1,
        content:
            'Bende de aynısı olmuştu, sulamayı azaltınca yeni yapraklar sağlıklı çıktı.',
      ),
    ],
  ),
  SamplePost(
    author: 'Can Y.',
    tag: PostTag.tip,
    hoursAgo: 20,
    content:
        'Sukulentlerde kök çürümesini önlemek için toprağa yaklaşık %30 perlit '
        'karıştırıyorum. Drenaj delikli saksı şart; sulamadan önce toprağın '
        'tamamen kuruduğundan emin olun.',
    comments: [
      SampleComment(
        author: 'Elif S.',
        hoursAgo: 15,
        content: 'Perlit yerine pomza taşı da çok işe yarıyor.',
      ),
    ],
  ),
  SamplePost(
    author: 'Elif S.',
    tag: PostTag.experience,
    hoursAgo: 48,
    content:
        'Orkidem 8 aydır çiçek açmıyordu. Kışın birkaç hafta daha serin bir odaya '
        '(16-18 °C) aldım ve yeni bir çiçek sapı çıktı! Gece-gündüz sıcaklık farkı '
        'gerçekten işe yarıyor.',
    comments: [
      SampleComment(
        author: 'Ayşe K.',
        hoursAgo: 40,
        content: 'Harika! Ben de deneyeceğim. Hangi pencerenin önündeydi?',
      ),
      SampleComment(
        author: 'Elif S.',
        hoursAgo: 38,
        content: 'Kuzeydoğu cephesi, doğrudan güneş almıyor.',
      ),
    ],
  ),
  SamplePost(
    author: 'Mert D.',
    tag: PostTag.question,
    hoursAgo: 72,
    content:
        'Para ağacımın yaprakları buruşmuş ve yumuşak görünüyor. Az mı suluyorum, çok mu?',
    comments: [
      SampleComment(
        author: 'Can Y.',
        hoursAgo: 70,
        content:
            'Buruşuk ama sert yapraklar genelde susuzluk; yumuşak ve sarımsı olanlar '
            'fazla su belirtisi. Gövdenin dibi yumuşadıysa kök çürümesine bak.',
      ),
    ],
  ),
  SamplePost(
    author: 'Zeynep A.',
    tag: PostTag.tip,
    hoursAgo: 120,
    content:
        'Monstera ve potos yapraklarındaki tozu ayda bir nemli bezle siliyorum. '
        'Hem daha parlak görünüyorlar hem de daha fazla ışık alabiliyorlar.',
  ),
  SamplePost(
    author: 'Burak T.',
    tag: PostTag.experience,
    hoursAgo: 150,
    content:
        'Lavantamı saksıda yetiştiriyorum. Çiçeklenme bitince yaklaşık üçte bir '
        'oranında budadım; ertesi yıl çok daha gür oldu.',
  ),
];
