// ignore_for_file: unused_import, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kafee_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KafeeApp());

    expect(find.byType(KafeeApp), findsOneWidget);
  });
}
