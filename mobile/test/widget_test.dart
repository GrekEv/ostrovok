import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ostrovok/widgets/mascot.dart';

void main() {
  testWidgets('mascot renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Mascot())),
    );

    expect(find.byType(Mascot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
