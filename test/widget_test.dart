import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisesell_ai/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'WiseSell switches Oromo and Amharic without losing framework localizations',
    (tester) async {
      await tester.pumpWidget(const WiseSellApp());
      await tester.pumpAndSettle();

      expect(find.text('Business workspace'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.language_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afaan Oromo'));
      await tester.pumpAndSettle();

      expect(find.text('Iddoo hojii daldalaa'), findsOneWidget);
      expect(find.text('Gargaaraa AI'), findsOneWidget);

      final navigationContext = tester.element(find.byType(NavigationBar));
      expect(MaterialLocalizations.of(navigationContext), isNotNull);
      expect(WidgetsLocalizations.of(navigationContext), isNotNull);

      var preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('wisesell_language_code'), 'om');

      await tester.tap(find.byIcon(Icons.language_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amaariffa'));
      await tester.pumpAndSettle();

      expect(find.text('የንግድ ስራ ቦታ'), findsOneWidget);
      expect(find.text('AI ረዳት'), findsOneWidget);

      preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('wisesell_language_code'), 'am');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const WiseSellApp());
      await tester.pumpAndSettle();

      expect(find.text('የንግድ ስራ ቦታ'), findsOneWidget);
      expect(find.text('AI ረዳት'), findsOneWidget);
    },
  );
}
