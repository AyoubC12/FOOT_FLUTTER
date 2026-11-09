import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/app/app.dart';
import 'package:footgpt_ai/app/theme/app_theme.dart';
import 'package:footgpt_ai/core/network/api_exception.dart';
import 'package:footgpt_ai/core/widgets/app_error.dart';
import 'package:footgpt_ai/features/players/presentation/screens/players_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _reachDesk(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: FootGptApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1900));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Skip'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue as guest'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('guest can open tactics and comparison from profile', (
    tester,
  ) async {
    await _reachDesk(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Tactical board'), findsOneWidget);

    await tester.tap(find.text('Tactical board'));
    await tester.pumpAndSettle();
    expect(find.text('Tactical analysis'), findsOneWidget);
    expect(find.text('4-3-3'), findsWidgets);

    final back = find.byTooltip('Back');
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Player comparison'));
    await tester.pumpAndSettle();
    expect(find.text('Player comparison'), findsWidgets);
  });

  testWidgets('sign in without API_BASE_URL opens the home desk', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FootGptApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sample live board'), findsOneWidget);
  });

  testWidgets('player search shows empty-API guidance', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PlayersScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Connect the Django API'), findsOneWidget);
    expect(find.text('Player analysis'), findsOneWidget);
  });

  testWidgets('API error view exposes retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AppErrorView(
            message: 'Could not reach FootGPT. Check your connection.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(
      find.text('Could not reach FootGPT. Check your connection.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
    expect(const ApiException('down', statusCode: 502).isUnauthorized, isFalse);
  });
}
