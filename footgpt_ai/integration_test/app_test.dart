import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/app/app.dart';
import 'package:footgpt_ai/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('app launches splash branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FootGptApp()));
    await tester.pump();
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
