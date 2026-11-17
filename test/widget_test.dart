import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisesell_ai/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WiseSell switches language and restores it after restart', (tester) async {
    await tester.pumpWidget(const WiseSellApp());
    await tester.pumpAndSettle();

    expect(find.text('Business workspace'), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amharic'));
    await tester.pumpAndSettle();

    expect(find.text('የንግድ ስራ ቦታ'), findsOneWidget);
    expect(find.text('AI ረዳት'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('wisesell_language_code'), 'am');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const WiseSellApp());
    await tester.pumpAndSettle();

    expect(find.text('የንግድ ስራ ቦታ'), findsOneWidget);
    expect(find.text('AI ረዳት'), findsOneWidget);
  });
}
