import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pawprint/data/dog_repository.dart';
import 'package:pawprint/main.dart';

void main() {
  testWidgets('registry home page can open the record form', (
    WidgetTester tester,
  ) async {
    final repository = await DogRepository.open();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record a furfriend'));
    await tester.pumpAndSettle();

    expect(find.text('Record a furfriend'), findsAtLeastNWidgets(2));
    expect(find.text('Breed'), findsOneWidget);
    expect(find.text('Color / Identifying marks'), findsOneWidget);
    expect(find.text('Tag ID'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Coco');
    await tester.pump();
    expect(find.text('Color / Identifying marks is required'), findsNothing);
    expect(find.text('Building / Area is required'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Color / Identifying marks is required'), findsOneWidget);
    expect(find.text('Building / Area is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), 'Cream');
    await tester.enterText(find.byType(TextFormField).at(6), 'Park');
    await tester.pump();
    expect(find.text('Name is required'), findsNothing);
    expect(find.text('Color / Identifying marks is required'), findsNothing);
    expect(find.text('Building / Area is required'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Health details'), findsOneWidget);
    expect(find.text('Sterilized'), findsOneWidget);
    expect(find.text('Rabies vaccinated'), findsOneWidget);
    expect(find.text('9-in-1 vaccinated'), findsOneWidget);
  });
}
