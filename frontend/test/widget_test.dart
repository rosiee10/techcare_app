import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('TechCare app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TechCareApp());
    
    expect(find.text('TECHCARE'), findsWidgets);
  });
}
