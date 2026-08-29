import 'dart:typed_data';

enum SterilizationStatus { unknown, yes, no }

class Dog {
  const Dog({
    required this.id,
    required this.name,
    required this.breed,
    this.identification = '',
    this.animalCategory = 'dog',
    this.photoPath,
    this.photoBytes,
    this.gender = '',
    this.age = '',
    this.color = '',
    this.sterilization = SterilizationStatus.unknown,
    this.vaccinated = false,
    this.rabiesVaccinated = false,
    this.nineInOneVaccinated = false,
    this.sterilizedOn,
    this.medicalIssues = '',
    this.photoKey,
    this.latitude,
    this.longitude,
    this.locationNote = '',
    this.address = '',
    this.area = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String breed;
  final String identification;
  final String animalCategory;
  final String? photoPath;
  final Uint8List? photoBytes;
  final String gender;
  final String age;
  final String color;
  final SterilizationStatus sterilization;
  final bool vaccinated;
  final bool rabiesVaccinated;
  final bool nineInOneVaccinated;
  final DateTime? sterilizedOn;
  final String medicalIssues;
  final String? photoKey;
  final double? latitude;
  final double? longitude;
  final String locationNote;
  final String address;
  final String area;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasLocation => latitude != null && longitude != null;

  Dog copyWith({
    String? name,
    String? breed,
    String? identification,
    String? age,
    SterilizationStatus? sterilization,
    bool? vaccinated,
    bool? rabiesVaccinated,
    bool? nineInOneVaccinated,
    DateTime? sterilizedOn,
    bool clearSterilizedOn = false,
    String? medicalIssues,
    String? photoKey,
    bool clearPhoto = false,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String? locationNote,
    String? notes,
    DateTime? updatedAt,
    String? animalCategory,
    String? photoPath,
    Uint8List? photoBytes,
    String? gender,
    String? color,
    String? address,
    String? area,
  }) {
    return Dog(
      id: id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      identification: identification ?? this.identification,
      age: age ?? this.age,
      sterilization: sterilization ?? this.sterilization,
      vaccinated: vaccinated ?? this.vaccinated,
      rabiesVaccinated: rabiesVaccinated ?? this.rabiesVaccinated,
      nineInOneVaccinated: nineInOneVaccinated ?? this.nineInOneVaccinated,
      sterilizedOn: clearSterilizedOn
          ? null
          : (sterilizedOn ?? this.sterilizedOn),
      medicalIssues: medicalIssues ?? this.medicalIssues,
      photoKey: clearPhoto ? null : (photoKey ?? this.photoKey),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      locationNote: locationNote ?? this.locationNote,
      notes: notes ?? this.notes,
      animalCategory: animalCategory ?? this.animalCategory,
      photoPath: photoPath ?? this.photoPath,
      photoBytes: photoBytes ?? this.photoBytes,
      gender: gender ?? this.gender,
      color: color ?? this.color,
      address: address ?? this.address,
      area: area ?? this.area,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'breed': breed,
    'identification': identification,
    'age': age,
    'sterilization': sterilization.name,
    'vaccinated': vaccinated,
    'rabiesVaccinated': rabiesVaccinated,
    'nineInOneVaccinated': nineInOneVaccinated,
    'sterilizedOn': sterilizedOn?.toIso8601String(),
    'medicalIssues': medicalIssues,
    'photoKey': photoKey,
    'latitude': latitude,
    'longitude': longitude,
    'locationNote': locationNote,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'animalCategory': animalCategory,
    'photoPath': photoPath,
    'gender': gender,
    'color': color,
    'address': address,
    'area': area,
  };

  factory Dog.fromMap(Map<String, Object?> map) {
    return Dog(
      id: map['id']! as String,
      name: map['name']! as String,
      breed: map['breed']! as String,
      identification: (map['identification'] as String?) ?? '',
      age: (map['age'] as String?) ?? '',
      sterilization: SterilizationStatus.values.firstWhere(
        (value) => value.name == map['sterilization'],
        orElse: () => SterilizationStatus.unknown,
      ),
      vaccinated: (map['vaccinated'] as bool?) ?? false,
      rabiesVaccinated: (map['rabiesVaccinated'] as bool?) ?? false,
      nineInOneVaccinated: (map['nineInOneVaccinated'] as bool?) ?? false,
      sterilizedOn: map['sterilizedOn'] == null
          ? null
          : DateTime.parse(map['sterilizedOn']! as String),
      medicalIssues: (map['medicalIssues'] as String?) ?? '',
      photoKey: map['photoKey'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationNote: (map['locationNote'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
      animalCategory: (map['animalCategory'] as String?) ?? 'dog',
      photoPath: map['photoPath'] as String?,
      gender: (map['gender'] as String?) ?? '',
      color: (map['color'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      area: (map['area'] as String?) ?? '',
    );
  }
}
