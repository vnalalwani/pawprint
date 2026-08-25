class Vaccination {
  const Vaccination({
    required this.id,
    required this.dogId,
    required this.name,
    required this.dateGiven,
    this.nextDue,
    this.notes = '',
  });

  final String id;
  final String dogId;
  final String name;
  final DateTime dateGiven;
  final DateTime? nextDue;
  final String notes;

  Map<String, Object?> toMap() => {
    'id': id,
    'dogId': dogId,
    'name': name,
    'dateGiven': dateGiven.toIso8601String(),
    'nextDue': nextDue?.toIso8601String(),
    'notes': notes,
  };

  factory Vaccination.fromMap(Map<String, Object?> map) {
    return Vaccination(
      id: map['id']! as String,
      dogId: map['dogId']! as String,
      name: map['name']! as String,
      dateGiven: DateTime.parse(map['dateGiven']! as String),
      nextDue: map['nextDue'] == null
          ? null
          : DateTime.parse(map['nextDue']! as String),
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
