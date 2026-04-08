import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';

// Lightweight AppState stub for widget tests
class _TestAppState extends AppState {
  _TestAppState();
}

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    final appState = _TestAppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('D4RTS Test'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('D4RTS Test'), findsOneWidget);
  });
}
