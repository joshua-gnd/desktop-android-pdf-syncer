import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_android_pdf_syncer/main.dart';
import 'package:desktop_android_pdf_syncer/services/auth_service.dart';

void main() {
  testWidgets('App basic mount smoke test', (WidgetTester tester) async {
    // Satisfies compiler dependency requirement
    final authService = AuthService();

    // Renders the main app layout inside the test environment
    await tester.pumpWidget(MyApp(authService: authService));

    // Verifies that the app successfully initialized without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
