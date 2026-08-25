import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:uuid/uuid.dart';

import '../models/dog.dart';
import '../models/vaccination.dart';

class DogRepository {
  DogRepository._(this._db);

  final Database _db;
  final _dogs = stringMapStoreFactory.store('dogs');
  final _vaccinations = stringMapStoreFactory.store('vaccinations');
  final _photos = StoreRef<String, Uint8List>('photos');
  static const _uuid = Uuid();

  static Future<DogRepository> open() async {
    final Database db;
    if (kIsWeb) {
      db = await databaseFactoryWeb.openDatabase('pawprint.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      db = await databaseFactoryIo.openDatabase(p.join(dir.path, 'pawprint.db'));
    }
    return DogRepository._(db);
  }

  static Future<DogRepository> openMemory() async {
    final db = await newDatabaseFactoryMemory().openDatabase('pawprint.db');
    return DogRepository._(db);
  }

  Future<List<Dog>> allDogs() async {
    final records = await _dogs.find(
      _db,
      finder: Finder(sortOrders: [SortOrder('updatedAt', false)]),
    );
    return records.map((record) => Dog.fromMap(record.value)).toList();
  }

  Future<Dog?> dogById(String id) async {
    final value = await _dogs.record(id).get(_db);
    return value == null ? null : Dog.fromMap(value);
  }

  Future<Dog> saveDog(Dog dog) async {
    await _dogs.record(dog.id).put(_db, dog.toMap());
    return dog;
  }

  Future<void> deleteDog(String id) async {
    await _db.transaction((txn) async {
      await _dogs.record(id).delete(txn);
      await _photos.record(id).delete(txn);
      final shots = await _vaccinations.find(
        txn,
        finder: Finder(filter: Filter.equals('dogId', id)),
      );
      for (final shot in shots) {
        await shot.ref.delete(txn);
      }
    });
  }

  Future<List<Vaccination>> vaccinationsFor(String dogId) async {
    final records = await _vaccinations.find(
      _db,
      finder: Finder(
        filter: Filter.equals('dogId', dogId),
        sortOrders: [SortOrder('dateGiven', false)],
      ),
    );
    return records.map((record) => Vaccination.fromMap(record.value)).toList();
  }

  Future<Vaccination> saveVaccination(Vaccination shot) async {
    await _vaccinations.record(shot.id).put(_db, shot.toMap());
    return shot;
  }

  Future<void> deleteVaccination(String id) async {
    await _vaccinations.record(id).delete(_db);
  }

  Future<String> savePhotoBytes(Uint8List bytes) async {
    final key = _uuid.v4();
    await _photos.record(key).put(_db, bytes);
    return key;
  }

  Future<Uint8List?> photoBytes(String key) => _photos.record(key).get(_db);

  Future<void> deletePhoto(String key) => _photos.record(key).delete(_db);

  static String newId() => _uuid.v4();
}
