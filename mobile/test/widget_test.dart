import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypeugeot/app.dart';

void main() {
  testWidgets('App démarre sur l\'écran de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const MyPeugeotApp());
    await tester.pumpAndSettle();

    expect(find.text('MyPeugeot'), findsWidgets);
    expect(find.byIcon(Icons.electric_car), findsOneWidget);
  });
}
