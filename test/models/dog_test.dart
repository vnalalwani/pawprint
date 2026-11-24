import 'package:flutter_test/flutter_test.dart';
import 'package:pawprint/models/dog.dart';

void main() {
  test('sent-for-sterilization survives copies and map round-trips', () {
    final now = DateTime(2026, 1, 1);
    final dog = Dog(
      id: 'dog-1',
      name: 'Coco',
      breed: 'Indie',
      sentForSterilization: true,
      createdAt: now,
      updatedAt: now,
    );

    expect(dog.copyWith(name: 'Coco 2').sentForSterilization, isTrue);
    expect(
      dog.copyWith(sentForSterilization: false).sentForSterilization,
      isFalse,
    );
    expect(Dog.fromMap(dog.toMap()).sentForSterilization, isTrue);
  });
}
