import 'package:flutter_test/flutter_test.dart';
import 'package:wisesell_ai/app.dart';

void main() {
  testWidgets('WiseSell dashboard renders core workspace', (tester) async {
    await tester.pumpWidget(const WiseSellApp());

    expect(find.text('WiseSell AI'), findsOneWidget);
    expect(find.text('Business workspace'), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
  });
}
