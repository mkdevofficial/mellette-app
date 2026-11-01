import 'package:flutter_test/flutter_test.dart';
import 'package:mallette/main.dart';

void main() {
  testWidgets('MalletteApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MalletteApp());
    expect(find.byType(MalletteApp), findsOneWidget);
  });
}
