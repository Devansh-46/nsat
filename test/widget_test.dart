// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:niu_sat_app/main.dart';

void main() {
  testWidgets('App launches and shows role selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NiuSatApp());

    expect(find.text('Noida International University'), findsOneWidget);
    expect(find.text('Student login'), findsOneWidget);
    expect(find.text('Admin login'), findsOneWidget);
  });
}
