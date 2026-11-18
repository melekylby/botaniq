import 'package:botaniq/models/my_plant.dart';
import 'package:botaniq/repositories/my_plant_repository.dart';

/// Testlerde gerçek SQLite yerine kullanılan, bellekte çalışan sahte depo.
/// Böylece testler hızlı çalışır ve telefona/emülatöre ihtiyaç duymaz.
class FakeMyPlantRepository implements MyPlantRepository {
  final List<MyPlant> _items = [];
  int _nextId = 1;

  @override
  Future<List<MyPlant>> getAll() async => List.of(_items);

  @override
  Future<MyPlant> insert(MyPlant plant) async {
    final saved = plant.copyWith(id: _nextId++);
    _items.add(saved);
    return saved;
  }

  @override
  Future<void> update(MyPlant plant) async {
    final index = _items.indexWhere((p) => p.id == plant.id);
    if (index != -1) _items[index] = plant;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((p) => p.id == id);
  }
}
