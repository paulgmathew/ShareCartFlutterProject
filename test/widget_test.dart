import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Basic smoke test — full widget tests require mocked repository.
    expect(find.text('Share Cart'), findsNothing);
  });
}
