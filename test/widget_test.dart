import 'package:flutter_test/flutter_test.dart';

import 'package:pawprint/data/dog_repository.dart';
import 'package:pawprint/main.dart';

void main() {
  testWidgets('registry home page can open the record form', (
    WidgetTester tester,
  ) async {
    final repository = await DogRepository.openMemory();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump();

    expect(find.text('Community dog registry'), findsOneWidget);
    expect(find.text('No dogs recorded yet'), findsOneWidget);

    await tester.tap(find.text('Record dog'));
    await tester.pump();

    expect(find.text('Record a stray dog'), findsOneWidget);
    expect(find.text('Breed / description'), findsOneWidget);
  });
}
