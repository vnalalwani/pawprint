import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/dog.dart';
import '../models/dog_health_details.dart';

class DogRepository {
  DogRepository._();

  static const _uuid = Uuid();
  static const _photoBucket = 'furryfriends';

  static Future<DogRepository> open() async => DogRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  void _requireConnection() {
    if (!SupabaseConfig.isInitialized) {
      throw StateError('Supabase is not configured.');
    }
  }

  Future<List<Dog>> allDogs() async {
    _requireConnection();
    final rows = await _client
        .from('primary_dog_details')
        .select()
        .order('updated_date', ascending: false);
    final dogIds = rows.map((row) => row['id'] as String).toList();
    final healthByDogId = await _healthDetailsFor(dogIds);
    return Future.wait(
      rows.map(
        (row) =>
            _dogFromSupabase(row, health: healthByDogId[row['id'] as String]),
      ),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _healthDetailsFor(
    List<String> dogIds,
  ) async {
    if (dogIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('sterilization_vaccination_details')
          .select('dog_id, sterilization_status, rabies, nine_in_one')
          .inFilter('dog_id', dogIds);
      return {for (final row in rows) row['dog_id'] as String: row};
    } on PostgrestException {
      return {};
    }
  }

  Future<Dog> _dogFromSupabase(
    Map<String, dynamic> row, {
    Map<String, dynamic>? health,
  }) async {
    final storedPhotoPath = row['photo_path'] as String?;
    final photoPath = await _photoUrl(storedPhotoPath);
    final createdDate = DateTime.parse(row['created_date'] as String);
    final updatedDate = DateTime.parse(row['updated_date'] as String);
    return Dog(
      id: row['id'] as String,
      animalCategory: (row['animal_category'] as String?) ?? 'dog',
      identification: (row['tag_id'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      photoPath: photoPath,
      photoKey: photoPath != null && !photoPath.startsWith('http')
          ? photoPath
          : null,
      gender: (row['gender'] as String?) ?? '',
      age: row['age']?.toString() ?? '',
      sterilization: SterilizationStatus.values.firstWhere(
        (status) => status.name == health?['sterilization_status'],
        orElse: () => SterilizationStatus.unknown,
      ),
      rabiesVaccinated: (health?['rabies'] as bool?) ?? false,
      nineInOneVaccinated: (health?['nine_in_one'] as bool?) ?? false,
      color:
          (row['color'] as String?) ??
          (row['identifying_marks'] as String?) ??
          '',
      breed: (row['breed'] as String?) ?? '',
      medicalIssues: (row['identifying_marks'] as String?) ?? '',
      notes: (row['notes'] as String?) ?? '',
      address: (row['address'] as String?) ?? '',
      locationNote: (row['address'] as String?) ?? '',
      area: (row['area'] as String?) ?? '',
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  Future<String?> _photoUrl(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return null;
    var path = storedPath;
    final marker = '/object/public/$_photoBucket/';
    if (path.startsWith('http') && path.contains(marker)) {
      path = path.substring(path.indexOf(marker) + marker.length);
    } else if (path.startsWith('http')) {
      return path;
    }
    return _client.storage.from(_photoBucket).createSignedUrl(path, 3600);
  }

  Future<Dog?> dogById(String id) async {
    _requireConnection();
    final row = await _client
        .from('primary_dog_details')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final healthByDogId = await _healthDetailsFor([id]);
    return _dogFromSupabase(row, health: healthByDogId[id]);
  }

  Future<Dog> saveDog(Dog dog) async {
    _requireConnection();
    final record = <String, Object?>{
      'id': dog.id,
      'animal_category': dog.animalCategory,
      'photo_path': dog.photoPath,
      'name': dog.name,
      'gender': dog.gender,
      'age': int.tryParse(dog.age),
      'color': dog.color,
      'breed': dog.breed,
      'notes': dog.notes,
      'address': dog.address.isEmpty ? dog.locationNote : dog.address,
      'area': dog.area,
      'latitude': dog.latitude,
      'longitude': dog.longitude,
      'created_date': dog.createdAt.toIso8601String(),
      'updated_date': dog.updatedAt.toIso8601String(),
    };
    final savedRecord = await _client
        .from('primary_dog_details')
        .upsert(record, onConflict: 'id')
        .select('tag_id')
        .single();

    var photoPath = dog.photoPath;
    if (dog.photoBytes != null) {
      final storagePath = 'images/${dog.id}.jpg';
      final storage = _client.storage.from(_photoBucket);
      try {
        await storage.remove([storagePath]);
      } catch (_) {
        // The upload below can still succeed when there is no old file.
      }
      await storage.uploadBinary(storagePath, dog.photoBytes!);
      photoPath = storagePath;
      await _client
          .from('primary_dog_details')
          .update({'photo_path': photoPath})
          .eq('id', dog.id);
      photoPath = await _photoUrl(photoPath);
    }

    return dog.copyWith(
      identification: (savedRecord['tag_id'] as String?) ?? '',
      photoPath: photoPath,
      photoBytes: null,
    );
  }

  Future<void> deleteDog(String id) async {
    _requireConnection();
    await _client.from('primary_dog_details').delete().eq('id', id);
    await _client.storage.from(_photoBucket).remove(['images/$id.jpg']);
  }

  Future<void> saveHealthDetails(DogHealthDetails details) async {
    _requireConnection();
    await _client.from('sterilization_vaccination_details').upsert({
      'dog_id': details.dogId,
      'sterilization_status': details.sterilization.name,
      'rabies': details.rabies,
      'nine_in_one': details.nineInOne,
      'vaccination_date': details.vaccinationDate?.toIso8601String(),
    }, onConflict: 'dog_id');
  }

  Future<String> savePhotoBytes(Uint8List bytes) async {
    _requireConnection();
    final path = 'images/${_uuid.v4()}.jpg';
    final storage = _client.storage.from(_photoBucket);
    await storage.uploadBinary(path, bytes);
    return storage.getPublicUrl(path);
  }

  Future<void> deletePhoto(String path) async {
    _requireConnection();
    await _client.storage.from(_photoBucket).remove([path]);
  }

  static String newId() => _uuid.v4();
}
