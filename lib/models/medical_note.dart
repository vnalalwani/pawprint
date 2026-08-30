class MedicalNote {
  const MedicalNote({
    required this.id,
    required this.dogId,
    required this.condition,
    required this.treatmentStatus,
    required this.startedDate,
    required this.caretaker,
    required this.vetDetails,
  });

  final String id;
  final String dogId;
  final String condition;
  final String treatmentStatus;
  final DateTime startedDate;
  final String caretaker;
  final String vetDetails;
}
