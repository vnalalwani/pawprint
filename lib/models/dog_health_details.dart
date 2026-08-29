import 'dog.dart';

class DogHealthDetails {
  const DogHealthDetails({
    required this.dogId,
    required this.sterilization,
    required this.vaccinated,
    required this.rabies,
    required this.nineInOne,
    this.vaccinationDate,
  });

  final String dogId;
  final SterilizationStatus sterilization;
  final bool vaccinated;
  final bool rabies;
  final bool nineInOne;
  final DateTime? vaccinationDate;
}
