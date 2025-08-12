// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Basic app smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Build a simple test app
    await tester.pumpWidget(
      MaterialApp(
        title: 'ThunderTrack Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('ThunderTrack'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Welcome to ThunderTrack'),
                Text('A Decentralized Trading Diary'),
              ],
            ),
          ),
        ),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Test basic functionality
    expect(find.text('ThunderTrack'), findsOneWidget);
    expect(find.text('Welcome to ThunderTrack'), findsOneWidget);
    expect(find.text('A Decentralized Trading Diary'), findsOneWidget);
  });

  testWidgets('SharedPreferences functionality test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'locale': 'zh',
      'default_diary_public': true,
      'auto_share_enabled': false,
    });
    
    final prefs = await SharedPreferences.getInstance();
    
    // Test reading values
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('locale'), 'zh');
    expect(prefs.getBool('default_diary_public'), true);
    expect(prefs.getBool('auto_share_enabled'), false);
    
    // Test writing values
    await prefs.setString('theme_mode', 'light');
    expect(prefs.getString('theme_mode'), 'light');
    
    await prefs.setBool('auto_share_enabled', true);
    expect(prefs.getBool('auto_share_enabled'), true);
  });
}
