import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Bitki fotoğraflarını uygulamanın kendi klasöründe saklar.
///
/// Neden kopyalıyoruz? image_picker'ın verdiği dosya geçici bir klasörde
/// durur ve sistem onu her an silebilir. Fotoğrafı kalıcı bir klasöre
/// kopyalarsak uygulama kapanıp açılsa da kaybolmaz.
///
/// Veritabanına tam yol yerine yalnızca dosya adını yazıyoruz. Uygulama
/// klasörünün yolu (özellikle iOS'ta) güncellemelerde değişebilir; dosya
/// adı ise hep aynı kalır.
class PhotoStorageService {
  PhotoStorageService._();

  static final PhotoStorageService instance = PhotoStorageService._();

  late Directory _photoDirectory;

  /// Uygulama açılırken bir kez çağrılır (main.dart).
  Future<void> init() async {
    final documents = await getApplicationDocumentsDirectory();
    _photoDirectory = Directory(p.join(documents.path, 'plant_photos'));
    if (!await _photoDirectory.exists()) {
      await _photoDirectory.create(recursive: true);
    }
  }

  /// Dosya adından tam dosya yolunu üretir.
  File fileFor(String photoName) => File(p.join(_photoDirectory.path, photoName));

  /// Geçici fotoğrafı kalıcı klasöre kopyalar ve yeni dosya adını döndürür.
  Future<String> savePhoto(String sourcePath) async {
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final photoName = 'plant_${DateTime.now().millisecondsSinceEpoch}$extension';
    await File(sourcePath).copy(fileFor(photoName).path);
    return photoName;
  }

  /// Bitki silindiğinde ya da fotoğrafı değiştiğinde eski dosyayı siler.
  Future<void> deletePhoto(String photoName) async {
    final file = fileFor(photoName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
