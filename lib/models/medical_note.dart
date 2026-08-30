class MedicalNote {
  const MedicalNote({
    required this.id,
    required this.dogId,
    required this.condition,
    required this.treatmentStatus,
    required this.treatmentGiven,
    required this.startedDate,
    this.endDate,
    required this.caretaker,
    required this.vetDetails,
  });

  final String id;
  final String dogId;
  final String condition;
  final String treatmentStatus;
  final String treatmentGiven;
  final DateTime startedDate;
  final DateTime? endDate;
  final String caretaker;
  final String vetDetails;
}
