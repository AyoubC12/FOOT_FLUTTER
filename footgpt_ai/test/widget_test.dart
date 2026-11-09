import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/app/app.dart';
import 'package:footgpt_ai/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders FootGPT AI splash then onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FootGptApp()));
    await tester.pump();

    expect(find.text(AppConstants.appName), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('guest login opens home dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FootGptApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.textContaining('Good evening'), findsOneWidget);
    expect(find.text('Sample live board'), findsOneWidget);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('Sample live'), findsWidgets);

    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();
    expect(find.text('Predictions'), findsWidgets);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('FootGPT Chat'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Clubs'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
  });
}
