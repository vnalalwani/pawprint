enum SterilizationStatus { unknown, yes, no }

class Dog {
  const Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.identification,
    this.age = '',
    this.sterilization = SterilizationStatus.unknown,
    this.sterilizedOn,
    this.medicalIssues = '',
    this.photoKey,
    this.latitude,
    this.longitude,
    this.locationNote = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String breed;
  final String identification;
  final String age;
  final SterilizationStatus sterilization;
  final DateTime? sterilizedOn;
  final String medicalIssues;
  final String? photoKey;
  final double? latitude;
  final double? longitude;
  final String locationNote;
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
  }) {
    return Dog(
      id: id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      identification: identification ?? this.identification,
      age: age ?? this.age,
      sterilization: sterilization ?? this.sterilization,
      sterilizedOn: clearSterilizedOn
          ? null
          : (sterilizedOn ?? this.sterilizedOn),
      medicalIssues: medicalIssues ?? this.medicalIssues,
      photoKey: clearPhoto ? null : (photoKey ?? this.photoKey),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      locationNote: locationNote ?? this.locationNote,
      notes: notes ?? this.notes,
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
    'sterilizedOn': sterilizedOn?.toIso8601String(),
    'medicalIssues': medicalIssues,
    'photoKey': photoKey,
    'latitude': latitude,
    'longitude': longitude,
    'locationNote': locationNote,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
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
    );
  }
}
