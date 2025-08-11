// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_thundertrack_stormg/main.dart';

void main() {
  testWidgets('ThunderTrack app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThunderTrackApp());

    // Verify that the app title is present.
    expect(find.text('ThunderTrack'), findsOneWidget);
    
    // Verify that the initial page shows trading notes content.
    expect(find.text('交易笔记'), findsWidgets);
    expect(find.text('在这里记录你的交易想法和复盘'), findsOneWidget);

    // Verify that bottom navigation is present.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
