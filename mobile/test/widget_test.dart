import 'package:flutter_test/flutter_test.dart';

import 'package:mypeugeot/app.dart';

void main() {
  testWidgets('App démarre directement sur le dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyPeugeotApp());
    await tester.pumpAndSettle();

    expect(find.text('Ma e-208'), findsOneWidget);
    // Pas de backend joignable dans les tests : le dashboard doit afficher
    // une erreur plutôt que planter.
    expect(find.textContaining('Erreur'), findsOneWidget);
  });
}
