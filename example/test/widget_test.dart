import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders phone parser example shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text('Try a phone number to see the parsing result below'),
      findsOneWidget,
    );
    expect(find.text('Test Metadata Download'), findsOneWidget);
    expect(find.text('Download metadata to begin'), findsOneWidget);
  });
}
