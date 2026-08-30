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

    await tester.tap(find.text('Record dog'));
    await tester.pumpAndSettle();

    expect(find.text('Record a stray dog'), findsOneWidget);
    expect(find.text('Breed'), findsOneWidget);
    expect(find.text('Color / Identifying marks'), findsOneWidget);
    expect(find.text('Tag ID'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Health details'), findsOneWidget);
    expect(find.text('Sterilized'), findsOneWidget);
    expect(find.text('Rabies vaccinated'), findsOneWidget);
    expect(find.text('9-in-1 vaccinated'), findsOneWidget);
  });
}
